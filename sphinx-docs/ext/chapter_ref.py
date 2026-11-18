from docutils import nodes
from sphinx.roles import XRefRole


class ChapterReferenceRole(XRefRole):
    innernodeclass = nodes.inline

    def run(self):
        self.refdomain = "std"
        self.reftype = "numref"
        self.classes = ["xref", "std", "std-numref"]
        return self.create_xref_node()

    def process_link(self, env, refnode, has_explicit_title, title, target):
        refnode["refexplicit"] = True
        return "Chapter\N{NO-BREAK SPACE}{number}, {name}", target


def setup(app):
    app.add_role("chapref", ChapterReferenceRole())

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
