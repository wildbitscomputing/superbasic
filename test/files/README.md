# File-existence regressions

Build SuperBASIC with `make -C source build`. These tests do not flash hardware.

```sh
uv run --with py65 python -m unittest discover -s test/files -p 'test_*.py' -v
uv run test/files/run-mame.py --mame /path/to/f256k --rom-dir /path/to/roms/f256k2x --kernel-dir /path/to/F256_MicroKernel/bin
uv run test/files/run-mame.py --mame /path/to/f256k --rom-dir /path/to/old/roms/f256k2x --legacy-kernel
```

The updated kernel must preserve FAT32 `ERRNO_FILE_NOT_FOUND` as the existing
`file.NOT_FOUND` event. Generic errors must remain `file.ERROR`. The legacy
run expects a missing file to raise `Storage error`, never return false.

The instruction-level tests use the assembled ROM and stub only kernel file
requests/event delivery. They cover successful open/close, explicit absence,
immediate and asynchronous failures, interleaved unrelated events, register
and bank restoration, invalid names, and the absence of data reads/writes.

MAME runs use private ROM, SD, and NVRAM copies. Fixtures include a zero-byte
file, a 300 KB file, subdirectories, and a directory with over 180 entries.
Tests cover expression/array arguments, absolute/relative paths, repeated
probes, subsequent BLOAD/BSAVE, and type/syntax/name/unavailable-drive errors.
Temporary images and logs are retained at the printed path.

Companion kernel fault-injection tests live in `tests/test_file_errors.py`
in the kernel repository. Run its full suite after building:

```sh
make -C /path/to/F256_MicroKernel
uv run --with py65 python -m unittest discover -s /path/to/F256_MicroKernel/tests -v
```
