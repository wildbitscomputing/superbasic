"""Run the banked LIST/edit/array smoke test in a private MAME instance.

python3 test/runtime/run_console.py --mame ../mame/f256k \
    --rom-dir ../mame/roms/f256k --firmware-dir .build
No hardware, shared NVRAM or existing ROM directory is modified.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mame", type=Path, required=True)
    parser.add_argument("--rom-dir", type=Path, required=True)
    parser.add_argument("--firmware-dir", type=Path, default=Path(".build"))
    args = parser.parse_args()
    work = Path(tempfile.mkdtemp(prefix="superbasic-runtime-"))
    roms = work / "roms/f256k2x"
    shutil.copytree(args.rom_dir, roms)
    for n in range(1, 6):
        shutil.copy2(args.firmware_dir / f"sb{n:02}.bin", roms)
    command = [str(args.mame.resolve()), "f256k2x", "-rompath", str(work / "roms"),
               "-nvram_directory", str(work / "nvram"), "-cfg_directory", str(work / "cfg"),
               "-video", "none", "-sound", "none", "-nothrottle", "-skip_gameinfo",
               "-seconds_to_run", "180", "-autoboot_delay", "0",
               "-autoboot_script", str(Path(__file__).with_name("list.lua").resolve())]
    log = work / "console.log"
    with log.open("w") as output:
        result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT,
                                env=dict(os.environ, SDL_VIDEODRIVER="dummy",
                                         SDL_AUDIODRIVER="dummy"), timeout=120)
    content = log.read_text()
    assert result.returncode == 0 and "RESULT: PASS" in content and "RESULT: FAIL" not in content, log
    print(f"PASS: console regression ({log})")


if __name__ == "__main__":
    main()
