# Preserve keyword formatting in titles and ToC entries

from docutils import nodes
from sphinx.roles import SphinxRole


class KeywordNode(nodes.Inline, nodes.TextElement):
    pass


class KeywordRole(SphinxRole):
    def __init__(self, role: str):
        self.role = role

    def run(self):
        node = KeywordNode(
            self.rawtext,
            self.text,
            role=self.role,
            classes=[self.role],
        )
        return [node], []


class HtmlVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(translator.starttag(node, "span", ""))

    @staticmethod
    def depart(translator, _node):
        translator.body.append("</span>")


class LatexVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(f"\\DUrole{node['role']}{{")

    @staticmethod
    def depart(translator, _node):
        translator.body.append("}")


def setup(app):
    app.add_node(
        KeywordNode,
        html=(HtmlVisitor.visit, HtmlVisitor.depart),
        latex=(LatexVisitor.visit, LatexVisitor.depart),
    )

    for role in ["kwd", "asm"]:
        app.add_role(role, KeywordRole(role))

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
