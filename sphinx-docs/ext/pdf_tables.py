# Apply PDF-specific table layout and column-sizing rules

from docutils import nodes
from sphinx import addnodes


def configure_tables(app, doctree, docname):
    for table in list(doctree.findall(nodes.table)):
        table["align"] = "left"

        if app.builder.format != "latex":
            continue

        tgroup = next(
            (child for child in table.children if isinstance(child, nodes.tgroup)), None
        )

        if tgroup is None:
            continue

        column_count = sum(
            isinstance(child, nodes.colspec) for child in tgroup.children
        )

        if column_count == 0:
            continue

        # Keep every column except the last at its natural width. The final
        # tabulary column receives the remaining width and wraps as needed.
        column_spec = "N" * (column_count - 1) + "T"
        table.parent.insert(
            table.parent.index(table), addnodes.tabular_col_spec(spec=column_spec)
        )


def setup(app):
    app.connect("doctree-resolved", configure_tables)
