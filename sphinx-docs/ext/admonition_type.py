# Pass explicit custom admonition types through to LaTeX

from docutils import nodes

ADMONITION_TYPES = {
    "caution",
    "compatibility",
    "implementation",
    "note",
    "summary",
}


class LatexVisitor:
    @staticmethod
    def visit(translator, node):
        admonition_type = next(
            (name for name in node.get("classes", ()) if name in ADMONITION_TYPES),
            "note",
        )
        translator.body.append(f"\n\\begin{{sphinxadmonition}}{{{admonition_type}}}")
        translator.no_latex_floats += 1

    @staticmethod
    def depart(translator, _node):
        translator.body.append("\\end{sphinxadmonition}\n")
        translator.no_latex_floats -= 1


def setup(app):
    app.add_node(
        nodes.admonition,
        override=True,
        latex=(LatexVisitor.visit, LatexVisitor.depart),
    )

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
