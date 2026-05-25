# Split the SuperBASIC ROM file into 8192-byte binary chunks
#
# The assembler produces a binary spanning $4000-$DFFF:
#   $4000-$5FFF: module page 2 code (page2 section)
#   $6000-$7FFF: KernelHeader + headerdata (boot section)
#   $8000-$9FFF: main code block 1 (code section)
#   $A000-$BFFF: main code block 2 (code section)
#   $C000-$DFFF: module page 1 (code section, paged via .offs)
#
# Output block order:
#   sb01 = boot + headerdata  (N+0, slot 3, remapped to RAM after boot)
#   sb02 = main code block 1  (N+1, slot 4)
#   sb03 = main code block 2  (N+2, slot 5 default)
#   sb04 = module page 1      (N+3, inc 8+5 once)
#   sb05 = module page 2      (N+4, inc 8+5 twice)

import sys
from pathlib import Path


PAGE_SIZE = 8192  # size of each page in bytes


def main(*, build_dir: Path):
    with open(build_dir / "basic.rom", "rb") as f:
        data = f.read()

    # Binary layout starts at $4000:
    #   offset $0000 = $4000 (page2 section)
    #   offset $2000 = $6000 (boot section)
    #   offset $4000 = $8000 (main code block 1)
    #   offset $6000 = $A000 (main code block 2)
    #   offset $8000 = $C000 (module page 1)
    page2_offset = 0x0000
    boot_offset = 0x2000
    main_offset = 0x4000
    mod1_offset = 0x8000

    pages = [
        data[boot_offset : boot_offset + PAGE_SIZE],                       # sb01: boot + headerdata
        data[main_offset + 0 * PAGE_SIZE : main_offset + 1 * PAGE_SIZE],   # sb02: main block 1
        data[main_offset + 1 * PAGE_SIZE : main_offset + 2 * PAGE_SIZE],   # sb03: main block 2
        data[mod1_offset : mod1_offset + PAGE_SIZE],                       # sb04: module page 1
        data[page2_offset : page2_offset + PAGE_SIZE],                     # sb05: module page 2
    ]

    for i, chunk in enumerate(pages):
        chunk = chunk.ljust(PAGE_SIZE, b"\xff")
        with open(build_dir / "sb{:02x}.bin".format(i + 1), "wb") as out:
            out.write(chunk)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python splitrom.py <build_dir>")
        sys.exit(1)

    main(
        build_dir=Path(sys.argv[1]),
    )
