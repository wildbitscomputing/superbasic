# Apply PDF-only chapter and table-of-contents structure from document metadata

from docutils import nodes


class PdfStructure(nodes.General, nodes.Element):
    pass


class UnnumberedChapterTitle(nodes.title):
    pass


def apply_pdf_structure(app, doctree):
    if app.builder.format != "latex":
        return

    docname = app.env.current_document.docname
    metadata = app.env.metadata.get(docname, {})
    if not metadata:
        return

    section = next(
        (child for child in doctree.children if isinstance(child, nodes.section)),
        None,
    )

    if section is None or not isinstance(section[0], nodes.title):
        return

    if "unnumbered" in metadata:
        title = section[0]
        replacement = UnnumberedChapterTitle(
            title.rawsource,
            *title.children,
            **title.attributes,
        )
        replacement.source = title.source
        replacement.line = title.line
        section.replace(title, replacement)

    toc_group = metadata.get("toc_group")
    is_appendix = "appendix" in metadata
    toc_depth = metadata.get("toc_depth")
    if toc_group or is_appendix or toc_depth is not None:
        section.insert(
            0,
            PdfStructure(
                toc_group=toc_group,
                appendix=is_appendix,
                toc_depth=toc_depth,
            ),
        )


class PdfStructureVisitor:
    @staticmethod
    def visit(translator, node):
        if node["appendix"]:
            translator.body.append(
                "\\appendix\n"
                "\\updatechaptername\n"
                "\\addtocontents{toc}{\\protect\\setlength{\\protect\\cftchapnumwidth}{6.8em}}\n"
                "\\addtocontents{toc}{\\protect\\setcounter{tocdepth}{1}}\n"
            )

        toc_depth = node.get("toc_depth")
        if toc_depth is not None:
            translator.body.append(
                "\\addtocontents{toc}{\\protect\\setcounter{tocdepth}{%s}}\n"
                % toc_depth
            )

        if node["toc_group"]:
            translator.body.append(
                "\\sphinxtocgroup{%s}\n" % translator.escape(node["toc_group"])
            )

        raise nodes.SkipNode


class ChapterTitleVisitor:
    @staticmethod
    def visit(translator, node):
        translator.body.append(r"\sphinxunnumberedchapter{")
        translator.context.append("}\n" + translator.hypertarget_to(node.parent))
        translator.in_title = 1

    @staticmethod
    def depart(translator, node):
        translator.depart_title(node)


def setup(app):
    app.add_node(PdfStructure, latex=(PdfStructureVisitor.visit, None))
    app.add_node(
        UnnumberedChapterTitle,
        latex=(ChapterTitleVisitor.visit, ChapterTitleVisitor.depart),
    )

    app.connect("doctree-read", apply_pdf_structure, priority=800)

    return {
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
