# Wrap slashes between keywords in section titles with a custom node,
# so we can style them independently of the rest of the title

from docutils import nodes


def is_keyword(node):
    return isinstance(node, nodes.Inline) and "kwd" in node.get("classes", ())


def is_literal(node):
    return isinstance(node, nodes.literal)


def is_marked_up_term(node):
    return is_keyword(node) or is_literal(node)


def decorate_kwd_title_slash(_app, doctree):
    for title in doctree.findall(nodes.title):
        children = list(title.children)

        for index, child in enumerate(children[1:-1], start=1):
            if not isinstance(child, nodes.Text):
                continue

            if "/" not in str(child):
                continue

            if not (
                is_marked_up_term(children[index - 1])
                and is_marked_up_term(children[index + 1])
            ):
                continue

            text = str(child)
            before, _, after = text.partition("/")

            title.replace(
                child,
                [
                    nodes.Text(before),
                    KwdSeparatorNode("/", "/"),
                    nodes.Text(after),
                ],
            )


class KwdSeparatorNode(nodes.Inline, nodes.TextElement):
    pass


class HtmlVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(translator.starttag(node, "span", CLASS="sep"))

    @staticmethod
    def depart(translator, node):
        translator.body.append("</span>")


class LatexVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(r"\DUrolesep{")

    @staticmethod
    def depart(translator, node):
        translator.body.append("}")


def setup(app):
    app.add_node(
        KwdSeparatorNode,
        html=(HtmlVisitor.visit, HtmlVisitor.depart),
        latex=(LatexVisitor.visit, LatexVisitor.depart),
    )

    app.connect("doctree-read", decorate_kwd_title_slash, priority=400)

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
