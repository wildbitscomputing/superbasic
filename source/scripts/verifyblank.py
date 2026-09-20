# Verify that RAM sections in the build dir don't contain static data

import sys
from pathlib import Path


def main(*, build_dir: Path):
    ram_files = list(build_dir.glob("*.ram"))

    if not ram_files:
        raise SystemExit("BROKEN BUILD: no .ram files found")

    nonempty = [path for path in ram_files if path.stat().st_size]

    if nonempty:
        for path in nonempty:
            print(f"BROKEN BUILD: initialized data found in {path}")
        raise SystemExit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python verifyblank.py <build_dir>")
        sys.exit(1)

    main(
        build_dir=Path(sys.argv[1]),
    )
