# Classify keyboard literals so letter, cursor, and control keys can be styled
# independently

from docutils import nodes

CURSOR_KEYS = {"down", "left", "right", "up"}
KEY_ICONS = {
    "backspace": "backspace",
    "down": "arrow-down",
    "left": "arrow-left",
    "right": "arrow-right",
    "up": "arrow-up",
}


class KeyboardKeyNode(nodes.Inline, nodes.Element):
    pass


def classify_key(text: str) -> str:
    normalized = text.strip().casefold()

    if normalized in CURSOR_KEYS:
        return "cursor"

    if len(normalized) == 1 and normalized.isascii() and normalized.isalpha():
        return "letter"

    return "control"


def classify_keyboard_keys(_app, doctree):
    for literal in list(doctree.findall(nodes.literal)):
        if "kbd" not in literal.get("classes", ()):
            continue

        label = literal.astext()
        kind = classify_key(label)
        icon = KEY_ICONS.get(label.strip().casefold())
        attributes = literal.attributes.copy()
        attributes["classes"] = ["kbd", f"kbd-{kind}"]
        attributes["key_kind"] = kind
        attributes["label"] = label

        if icon:
            attributes["classes"].extend(["kbd-icon", f"kbd-icon-{icon}"])
            attributes["icon"] = icon

        key = KeyboardKeyNode(literal.rawsource, *literal.children, **attributes)
        key.source = literal.source
        key.line = literal.line
        literal.replace_self(key)


class HtmlVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(translator.starttag(node, "kbd", ""))

    @staticmethod
    def depart(translator, _node):
        translator.body.append("</kbd>")


class LatexVisitor:
    @staticmethod
    def visit(translator, node):
        if icon := node.get("icon"):
            translator.body.append(
                f"\\keybd{node['key_kind']}icon{{{icon}}}{{"
            )
        else:
            translator.body.append(f"\\keybd{node['key_kind']}{{")

    @staticmethod
    def depart(translator, _node):
        translator.body.append("}")


def setup(app):
    app.add_node(
        KeyboardKeyNode,
        html=(HtmlVisitor.visit, HtmlVisitor.depart),
        latex=(LatexVisitor.visit, LatexVisitor.depart),
    )

    app.connect("doctree-read", classify_keyboard_keys)

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
