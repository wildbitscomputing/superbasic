# Configuration file for the Sphinx documentation builder.

import sys
import os
sys.path.insert(0, os.path.abspath("."))

from superbasic_lexer import SuperBASICLexer
from sphinx.highlighting import lexers

lexers["basic"] = SuperBASICLexer()
lexers["superbasic"] = SuperBASICLexer()

project = "Wildbits SuperBASIC"
copyright = "2023-2026, Paul Robson & Wildbits Computing Company"
author = "Paul Robson & Wildbits Computing Company"
release = "1.1"

extensions = [
    "myst_parser",
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

# -- Options for HTML output -------------------------------------------------

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
        "index",
        "f256-superbasic.tex",
        "Wildbits SuperBASIC Reference Manual",
        "Paul Robson",
        "manual",
    ),
]

latex_elements = {
    "papersize": "a4paper",
    "pointsize": "11pt",
}

# -- Mermaid options ---------------------------------------------------------

mermaid_init_js = "mermaid.initialize({startOnLoad:true, theme: 'base'});"
