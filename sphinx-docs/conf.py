# Configuration file for the Sphinx documentation builder.

project = "F256 SuperBASIC"
copyright = "2026, Paul Robson & Matthias Brukner"
author = "Paul Robson & Matthias Brukner"
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
html_title = "F256 SuperBASIC"

html_theme_options = {
    "navigation_with_keys": True,
}

# -- Options for LaTeX output ------------------------------------------------

latex_documents = [
    (
        "index",
        "f256-superbasic.tex",
        "F256 SuperBASIC Reference Manual",
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
