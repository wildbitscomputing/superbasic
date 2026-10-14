#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyfatfs", "setuptools==80.4.0"]
# ///
"""Run the trig regressions with an isolated F256K2X ROM/SD/NVRAM setup.

Build first with `make -C source build`, then run from the repository root:
  uv run test/trig/run-mame.py --mame ../mame/f256k --rom-dir ../mame/roms/f256k

The ROM directory must contain the machine's supporting kernel/font ROMs.
Current .build/sb01.bin through sb05.bin override its SuperBASIC images.
Logs and the temporary disk are retained in the printed temporary directory.
Use --firmware-dir to compare a saved build and --case to select a test.
MULTIPLY exercises the fixed-point kernel directly against exact integer
results, including carry/tie cases and I/O/IRQ/register preservation. It needs
matching debug/basic.lbl (or --labels); saved builds omit it without --labels.
RUN_FRAMES excludes disk loading; printed seconds assume the 60 Hz display.
"""

import argparse
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mame", type=Path, required=True)
    parser.add_argument("--rom-dir", type=Path, required=True)
    parser.add_argument("--skip-bubble", action="store_true")
    parser.add_argument("--firmware-dir", type=Path, help="Use a saved build for comparison")
    parser.add_argument("--labels", type=Path, help="Matching basic.lbl for direct-code tests")
    parser.add_argument("--case", action="append",
                        choices=["TEST", "ANCHORS", "POLE", "TYPE", "SYNTAX", "BUBBLE",
                                 "MULTIPLY"])
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    mame = args.mame.resolve()
    firmware_dir = args.firmware_dir or root / ".build"
    firmware = [firmware_dir / f"sb{i:02}.bin" for i in range(1, 6)]
    for path in [mame, *firmware]:
        if not path.is_file():
            parser.error(f"Missing file: {path}")
    if not args.rom_dir.is_dir():
        parser.error(f"Missing ROM directory: {args.rom_dir}")

    work = Path(tempfile.mkdtemp(prefix="superbasic-trig-"))
    print(f"Test files and logs: {work}", flush=True)
    roms = work / "roms" / "f256k2x"
    shutil.copytree(args.rom_dir, roms)
    for path in firmware:
        shutil.copy2(path, roms)
    prepare = runpy.run_path(str(root / "test" / "prepare-disk.py"))["main"]
    prepare.__globals__["WORKING_DIR"] = work
    prepare(test_dir="trig")

    cases = [
        ("TEST", "TRIG PASS", 180),
        ("ANCHORS", "ANCHORS PASS", 600),
        ("POLE", "Division by zero at line 30", 30),
        ("TYPE", "Type mismatch at line 10", 30),
        ("SYNTAX", "Syntax error at line 10", 30),
    ]
    # Saved firmware needs its matching symbols to run the direct-code test.
    direct_cases = {"MULTIPLY": ("multiply.lua", 120)}
    selected_direct = set(direct_cases) if not args.case else set(args.case) & direct_cases.keys()
    if selected_direct and (not args.firmware_dir or args.labels or args.case):
        labels = args.labels or firmware_dir / "debug" / "basic.lbl"
        if not labels.is_file():
            parser.error(f"Missing labels for direct-code tests: {labels}; use --labels")
        for name, (_, seconds) in direct_cases.items():
            if name in selected_direct:
                cases.append((name, name + " PASS", seconds))
    if not args.skip_bubble:
        cases.append(("BUBBLE", "BUBBLE PASS", 1800))
    if args.case:
        cases = [case for case in cases if case[0] in args.case]
    if not cases:
        parser.error("No tests selected (check --case and --skip-bubble)")
    for name, expected, seconds in cases:
        env = dict(os.environ, SDL_VIDEODRIVER="dummy", MAME_TEST=name + ".BAS",
                   MAME_EXPECT=expected)
        script = "check.lua"
        if name in direct_cases:
            env["MAME_LABELS"] = str(labels.resolve())
            script = direct_cases[name][0]
        command = [
            str(mame), "f256k2x", "-rompath", str(work / "roms"),
            "-nvram_directory", str(work / (name + "-nvram")),
            "-cfg_directory", str(work / "cfg"),
            "-snapshot_directory", str(work / "snap"),
            "-harddisk", str(work / "tests.img"),
            "-video", "none", "-sound", "none", "-nothrottle", "-skip_gameinfo",
            "-seconds_to_run", str(seconds), "-autoboot_delay", "1",
            "-autoboot_script", str(root / "test" / "trig" / script),
        ]
        print(f"Running {name}...", flush=True)
        log = work / (name + ".log")
        with log.open("w") as output:
            result = subprocess.run(command, env=env, stdout=output,
                                    stderr=subprocess.STDOUT, timeout=300)
        content = log.read_text()
        if result.returncode or "RESULT: PASS" not in content or "RESULT: FAIL" in content:
            raise SystemExit(f"FAIL: {name}; see {log}")
        frames = re.search(r"RUN_FRAMES: (\d+)", content)
        timing = f" ({int(frames[1])/60:.0f} emulated seconds)" if frames else ""
        print(f"PASS: {name}{timing}", flush=True)


if __name__ == "__main__":
    main()
