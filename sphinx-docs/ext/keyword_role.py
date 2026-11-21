# Support semantic keywords and lexer-backed inline SuperBASIC expressions

from docutils import nodes
from pygments.token import Keyword, Name
from sphinx.roles import SphinxRole
from superbasic_lexer import SuperBASICLexer

_basic_lexer = SuperBASICLexer()


def tokenize(text: str) -> list[tuple[str, str]]:
    return [
        (token_type, value)
        for _, token_type, value in _basic_lexer.get_tokens_unprocessed(text)
    ]


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
            term=self.text.casefold(),
        )
        return [node], []


class BasicRole(SphinxRole):
    def run(self):
        literal = nodes.literal(self.rawtext, classes=["basic"])

        for token_type, value in tokenize(self.text):
            if token_type in Keyword or token_type in Name.Builtin:
                role = "asm" if token_type == Keyword.Pseudo else "kwd"
                literal += KeywordNode(
                    value,
                    value,
                    role=role,
                    classes=[role],
                    term=value.casefold(),
                    embedded=True,
                )
            else:
                literal += nodes.Text(value)

        return [literal], []


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
        suffix = "token" if node.get("embedded") else ""
        translator.body.append(f"\\DUrole{node['role']}{suffix}{{")

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

    app.add_role("basic", BasicRole())

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
