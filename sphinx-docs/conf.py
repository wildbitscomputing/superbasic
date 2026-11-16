# Configuration file for the Sphinx documentation builder.

import sys
from pathlib import Path

import colorutils
from docutils import nodes
from sphinx.highlighting import lexers

config_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(config_dir))
sys.path.append(str(config_dir / "ext"))
sys.path.append(str(config_dir / "ext" / "wildbits-help"))

from superbasic_lexer import SuperBASICLexer  # noqa: E402
from superbasic_style import BrandColors, PDFStyle  # noqa: E402


def read_version() -> str:
    with open(config_dir.parent / "VERSION", "r") as version_file:
        full_version = version_file.read().strip()

    return ".".join(full_version.split(".")[:2])


_lexer = SuperBASICLexer()
lexers["basic"] = _lexer
lexers["superbasic"] = _lexer

project = "Wildbits SuperBASIC"
copyright = (
    "2026 Wildbits Computing Company",
    "2022-2023 Paul Robson",
)
author = "Paul Robson; Wildbits Computing Company"
version = read_version()
numfig = True

extensions = [
    "myst_parser",
    "chapter_ref",
    "keyword_role",
    "kwd_title_slash",
    "pdf_structure",
    "sphinxcontrib.mermaid",
    "sphinx_copybutton",
    "sphinx_design",
]

myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "fieldlist",
    "tasklist",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store"]
numfig_format = {"figure": "Figure %s"}


def setup(app):
    app.connect("doctree-resolved", left_align_tables)


def left_align_tables(app, doctree, docname):
    for table in doctree.findall(nodes.table):
        table["align"] = "left"


# -- Options for HTML output -------------------------------------------------

pygments_style = "superbasic_style.HTMLStyle"

html_theme = "furo"
html_static_path = ["_static"]
html_css_files = ["custom.css"]
html_title = "Wildbits SuperBASIC"

html_theme_options = {
    "navigation_with_keys": True,
}

# -- Options for LaTeX output ------------------------------------------------

latex_documents = [
    (
        "index",  # master document
        "f256-superbasic.tex",  # output file name
        "SuperBASIC %s User and Reference Manual" % version,  # title
        r"Paul Robson \\ Wildbits Computing Company",  # author
        "manual",  # Sphinx document class, 'howto' or 'manual'
    ),
]

latex_docclass = {
    "manual": "book",
}

latex_table_style = ["booktabs"]

# Additional files that are referenced in `latex_elements` below and will be
# copied to the build directory when building LaTeX output. Sphinx tries to run
# `pdflatex` on all `.tex` files in the build directory, so we use the `.texp`
# extension for the partials.
latex_additional_files = list(
    str(path.relative_to(config_dir)) for path in (config_dir / "latex").glob("*")
)


def add_font(font_subdir: str):
    fonts_dir = config_dir / "fonts" / "ttf"
    latex_additional_files.extend(
        str(path.relative_to(config_dir))
        for path in (fonts_dir / font_subdir).glob("*.ttf")
    )


add_font("plex-serif")
add_font("plex-mono")
add_font("poppins")


def hex_to_rgb(hex: str):
    return " ,".join([str(c / 255) for c in colorutils.hex_to_rgb(hex)])


latex_elements = {
    "papersize": "letterpaper",
    "pointsize": "10pt",
    "fncychap": r"\usepackage[Sonny]{fncychap}",
    "fontpkg": r"\usepackage[T1]{fontenc}",
    "geometry": r"\usepackage[letterpaper,inner=1.5in,outer=1.0in,top=0.75in,bottom=0.75in,twoside]{geometry}",
    # loaded before hyperref package and packages loaded from Sphinx extensions
    "extrapackages": r"""
\usepackage{xcolor}
\definecolor{primary}{rgb}{%s}
\definecolor{riverblue}{rgb}{%s}
\definecolor{keyword_color}{rgb}{%s}
\definecolor{asm_color}{rgb}{%s}
\definecolor{silver}{rgb}{0.85, 0.85, 0.85}
\definecolor{raspberry}{rgb}{0.65, 0.2, 0.4}
"""
    % (
        hex_to_rgb(BrandColors.MIDNIGHT_BLUE),
        hex_to_rgb(BrandColors.RIVER_BLUE),
        hex_to_rgb(PDFStyle.KEYWORD_COLOR),
        hex_to_rgb(PDFStyle.ASM_COLOR),
    ),
    "hyperref": r"\usepackage[colorlinks=true, linkcolor=black, urlcolor=primary]{hyperref}",
    "contentsname": r"\addto\captionsenglish{\renewcommand{\contentsname}{Contents}}",
    # loaded after hyperref
    "preamble": r"\input{preamble.texp}",
    # "document_TeXextras": r"\lstset{language=BASIC}",
    "maketitle": r"""
\begin{titlepage}
    \colorbox{silver}{\makebox[\textwidth][r]{
    \shortstack{
        \vspace{3cm} \\
        \color{primary}\bfseries\sffamily\Huge SuperBASIC User and Reference Manual}} \\
    }

    \vfill
\end{titlepage}
""",
    "tableofcontents": r"""
\renewcommand{\contentsname}{Contents}
\begingroup
\hypersetup{linkcolor=primary}
\tableofcontents
\endgroup
\updatechaptername
""",
    "atendofbody": r"",
}

# -- Mermaid options ---------------------------------------------------------

mermaid_cmd = "mermaidx"
mermaid_output_format = "svg"
mermaid_config = {
    "theme": "base",
    "themeVariables": {
        "primaryColor": "#272662",
        "primaryTextColor": "#fff",
        "primaryBorderColor": "#1a1a4a",
        "secondaryColor": "#F1632B",
        "secondaryTextColor": "#fff",
        "secondaryBorderColor": "#d14a1a",
        "tertiaryColor": "#44A348",
        "tertiaryTextColor": "#fff",
        "tertiaryBorderColor": "#358a38",
        "lineColor": "#272662",
        "textColor": "#272662",
        "nodeBorder": "#272662",
    },
    "themeCSS": (
        ".node .label { color: #fff !important; } "
        ".edgeLabel { color: #272662 !important; }"
    ),
}
