#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyfatfs", "setuptools==80.4.0"]
# ///
"""EXISTS integration tests; private ROMs/SD/NVRAM, no attached hardware.

Build both repos first. Supply --kernel-dir ../F256_MicroKernel/bin for the
updated kernel, or --legacy-kernel to check safe failure with older ROMs.
"""
import argparse
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile

from pyfatfs.PyFatFS import PyFatFS


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mame', type=Path, required=True)
    parser.add_argument('--rom-dir', type=Path, required=True)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--kernel-dir', type=Path)
    group.add_argument('--legacy-kernel', action='store_true')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    work = Path(tempfile.mkdtemp(prefix='superbasic-exists-'))
    print(f'Test files and logs: {work}', flush=True)
    roms = work / 'roms' / 'f256k2x'
    shutil.copytree(args.rom_dir, roms)
    for i in range(1, 6):
        shutil.copy2(root / '.build' / f'sb{i:02}.bin', roms)
    if args.kernel_dir:
        for bank in range(0x3b, 0x40):
            shutil.copy2(args.kernel_dir / f'{bank:02x}.bin', roms)
    prepare = runpy.run_path(str(root / 'test' / 'prepare-disk.py'))['main']
    prepare.__globals__['WORKING_DIR'] = work
    prepare(test_dir='files')
    with PyFatFS(str(work / 'tests.img'), offset=2048 * 512) as fs:
        fs.create('/EMPTY.DAT')
        fs.writebytes('/LARGE.DAT', b'X' * 300000)
        fs.makedir('/SUBDIR')
        fs.writebytes('/SUBDIR/INNER.DAT', b'A')
        fs.makedir('/MANY')
        for i in range(180):
            fs.create(f'/MANY/F{i:03}.DAT')
        fs.writebytes('/MANY/LAST.DAT', b'last')
    cases = [('EXISTS', 'EXISTS PASS'), ('TYPE', 'Type mismatch at line 10'),
             ('SYNTAX', 'Syntax error at line 10'), ('EMPTY', 'Out of Range at line 10'),
             ('WILD', 'Out of Range at line 10'), ('DRIVE', 'Storage error at line 20')]
    if args.legacy_kernel:
        cases = [('MISSING', 'Storage error at line 10')]
    for name, expected in cases:
        command = [str(args.mame.resolve()), 'f256k2x', '-rompath', str(work / 'roms'),
                   '-nvram_directory', str(work / (name + '-nvram')),
                   '-cfg_directory', str(work / 'cfg'),
                   '-snapshot_directory', str(work / 'snap'),
                   '-harddisk', str(work / 'tests.img'), '-video', 'none', '-sound', 'none',
                   '-nothrottle', '-skip_gameinfo', '-seconds_to_run', '180',
                   '-autoboot_delay', '1', '-autoboot_script', str(root / 'test/trig/check.lua')]
        env = dict(os.environ, SDL_VIDEODRIVER='dummy', MAME_TEST=name + '.BAS',
                   MAME_EXPECT=expected)
        log = work / (name + '.log')
        with log.open('w') as output:
            result = subprocess.run(command, env=env, stdout=output,
                                    stderr=subprocess.STDOUT, timeout=300)
        content = log.read_text()
        if result.returncode or 'RESULT: PASS' not in content or 'RESULT: FAIL' in content:
            raise SystemExit(f'FAIL: {name}; see {log}')
        print(f'PASS: {name}', flush=True)


if __name__ == '__main__':
    main()
