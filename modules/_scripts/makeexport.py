"""Generate module entry points.

Reads exported function names from `.exports` files in the build directory
and generates corresponding entry points. If paging is enabled, includes
the necessary assembly code to handle memory bank switching.

Page 1 modules use slot 5 (inc/dec 8+5).
Page 2 modules use slot 3 (save/restore 8+3 with depth counter).

Outputs the entry points code to standard output.
"""

import sys
from pathlib import Path


def main(*, build_dir: Path) -> None:
    """Generate module entry points and write to standard output."""
    exports = read_exports(build_dir)
    paging = True

    print(f"PagingEnabled = {1 if paging else 0}")

    has_page2 = any(exports[m]["page"] == 2 for m in exports)

    if paging and has_page2:
        # These routines are included inside an existing .section code block
        # in 00start.asm, so no .section/.send wrappers are needed here.
        print("")
        print("; --- Slot 3 module bank switching ---")
        print(".section storage")
        print("Slot3ModulePage:")
        print("\t.fill\t1")
        print("Slot3Depth:")
        print("\t.fill\t1")
        print("Slot3Saved:")
        print("\t.fill\t1")
        print(".send storage")
        print("")
        print("Slot3Init:")
        print("\tlda 8+4")
        print("\tclc")
        print("\tadc #3")
        print("\tsta Slot3ModulePage")
        print("\trts")
        print("")
        print("Slot3BankIn:")
        print("\tphy")
        print("\tpha")
        print("\tinc Slot3Depth")
        print("\tlda Slot3Depth")
        print("\tcmp #1")
        print("\tbne +")
        print("\tldy 8+3")
        print("\tsty Slot3Saved")
        print("\tldy Slot3ModulePage")
        print("\tsty 8+3")
        print("+\tpla")
        print("\tply")
        print("\trts")
        print("")
        print("Slot3BankOut:")
        print("\tpha")
        print("\tphy")
        print("\tdec Slot3Depth")
        print("\tbne +")
        print("\tldy Slot3Saved")
        print("\tsty 8+3")
        print("+\tply")
        print("\tpla")
        print("\trts")

    for module in exports:
        page = exports[module]["page"]
        routines = exports[module]["routines"]
        module_name = exports[module]["name"]
        print(f"\t.if {module_name}Integrated == 1")
        for routine in routines:
            print(f"{routine}:")
            if paging:
                if page == 1:
                    print("\tinc 8+5")
                    print(f"\tjsr\tExport_{routine}")
                    print("\tphp")
                    print("\tdec 8+5")
                    print("\tplp")
                    print("\trts")
                elif page == 2:
                    print("\tjsr Slot3BankIn")
                    print(f"\tjsr\tExport_{routine}")
                    print("\tphp")
                    print("\tjsr Slot3BankOut")
                    print("\tplp")
                    print("\trts")
            else:
                print(f"\tjmp\tExport_{routine}")

        print("\t.endif")


def read_exports(build_dir: Path) -> dict[str, dict]:
    """Read all `.exports` files from the build directory.

    Files named `<module>_p2.exports` are treated as page 2 exports
    (slot 3 via save/restore 8+3). All others are page 1 (slot 5 via inc/dec 8+5).
    """
    all_exports: dict[str, dict] = {}

    if not build_dir.exists():
        return all_exports

    # Find all .exports files in the build directory
    for file_path in build_dir.glob("*.exports"):
        if module_exports := read_module_exports(file_path):
            stem = file_path.stem  # filename without extension
            if stem.endswith("_p2"):
                module_name = stem[:-3]  # strip _p2 suffix
                page = 2
            else:
                module_name = stem
                page = 1
            module_exports.sort()
            all_exports[stem] = {
                "name": module_name,
                "page": page,
                "routines": module_exports,
            }

    return all_exports


def read_module_exports(file_path: Path) -> list[str]:
    """Read exported function names from a single `.exports` file."""
    module_exports: list[str] = []

    with open(file_path, encoding="utf-8") as f:
        for line in f:
            export_name = line.strip()
            if export_name:
                module_exports.append(export_name)

    return module_exports


if __name__ == "__main__":
    main(build_dir=Path(sys.argv[1] if len(sys.argv) > 1 else ".build"))
