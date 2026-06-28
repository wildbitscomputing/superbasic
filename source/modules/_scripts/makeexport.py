"""Generate module entry points.

Reads exported function names from `.exports` files in the build directory
and generates corresponding entry points. If paging is enabled, includes
the necessary assembly code to handle memory bank switching.

Outputs the entry points code to standard output.
"""

import sys
from pathlib import Path
from dataclasses import dataclass

from pages import Page, PAGES


@dataclass
class ModuleExports:
    module_name: str
    exports: list[str]


def main(*, build_dir: Path) -> None:
    paging = True
    if paging:
        for page_name, page in PAGES.items():
            generate_exports(build_dir=build_dir / page_name, page=page)
    else:
        generate_exports(build_dir=build_dir)


def generate_exports(*, build_dir: Path, page: Page | None = None) -> None:
    """Collect module entry points in the specified dir and write them to _exports.asm"""
    exports = read_exports(build_dir)

    with open(build_dir / "_exports.asm", "w") as out:
        if page:
            out.write(f"{page.thunk_namespace}\t.namespace\n")

        for module in exports:
            module_name = exports[module].module_name
            out.write(f".if {module_name}Integrated == 1\n")

            routines = exports[module].exports
            for routine in routines:
                out.write(f"\n{routine}:\n")
                if page:
                    out.write(page.thunk(routine))
                else:
                    out.write(f"\tjmp\tExport_{routine}\n")

            out.write(".endif\n")

        if page:
            out.write(".endnamespace\n")


def read_exports(build_dir: Path) -> dict[str, ModuleExports]:
    """Read all `.exports` files from the build directory."""
    all_exports: dict[str, ModuleExports] = {}

    if not build_dir.exists():
        return all_exports

    # Find all .exports files in the build directory
    for file_path in build_dir.glob("*.exports"):
        if module_exports := read_module_exports(file_path):
            module_name = file_path.stem  # filename without extension

            module_exports.sort()
            all_exports[module_name] = ModuleExports(
                module_name=module_name,
                exports=module_exports,
            )

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
