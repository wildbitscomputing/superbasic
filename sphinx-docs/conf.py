# Configuration file for the Sphinx documentation builder.

import sys
import os
sys.path.insert(0, os.path.abspath("."))

from superbasic_lexer import SuperBASICLexer
from sphinx.highlighting import lexers

_lexer = SuperBASICLexer()
lexers["basic"] = _lexer
lexers["superbasic"] = _lexer

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
    "papersize": "letterpaper",
    "pointsize": "11pt",
    "fncychap": r"\usepackage[Bjornstrup]{fncychap}",
    "fontpkg": r"""
\usepackage{fontspec}
\setmainfont{NotoSerif}[
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-Italic,
  BoldItalicFont=*-BoldItalic,
]
\setsansfont{NotoSans}[
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-Italic,
  BoldItalicFont=*-BoldItalic,
]
\setmonofont{NotoSansMono}[
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
]
""",
    "geometry": r"\usepackage[letterpaper,inner=1.5in,outer=1.0in,top=0.75in,bottom=0.75in]{geometry}",
    "preamble": r"""
% Match original reference manual styling
\definecolor{darkblue}{rgb}{0.1, 0.0, 0.6}
\definecolor{silver}{rgb}{0.85, 0.85, 0.85}
\ChNumVar{\color{darkblue}\fontsize{76}{80}\usefont{OT1}{pzc}{m}{n}\selectfont}
\ChTitleVar{\color{darkblue}\raggedleft\Huge\sffamily\bfseries}

% Dark blue section headings
\usepackage{sectsty}
\allsectionsfont{\color{darkblue}\bfseries\sffamily}

% Tighter TOC spacing
\usepackage{tocloft}
\setlength{\cftbeforechapskip}{6pt}
\setlength{\cftbeforesecskip}{2pt}
\renewcommand{\cftchapleader}{\cftdotfill{\cftdotsep}}

% Reduce float spacing
\setlength{\floatsep}{8pt plus 2pt minus 2pt}
\setlength{\textfloatsep}{10pt plus 2pt minus 2pt}
\setlength{\intextsep}{8pt plus 2pt minus 2pt}

% Black hyperlinks like the original
\hypersetup{colorlinks=true,linkcolor=black,urlcolor=darkblue}

% Plain code blocks — no frame, no background (like the original verbatim style)
\sphinxsetup{
  VerbatimColor={rgb}{1,1,1},
  VerbatimBorderColor={rgb}{1,1,1},
  verbatimborder=0pt,
}
\fvset{fontsize=\small}
""",
    "maketitle": r"""
\begin{titlepage}
    \colorbox{silver}{\makebox[\textwidth][r]{
    \shortstack{
        \vspace{3cm} \\
        \color{darkblue}\bfseries\sffamily\Huge Wildbits SuperBASIC Reference Manual}} \\
    }
    \vfill
    \hfill\mbox{\color{darkblue}\bfseries\sffamily\Large Paul Robson}
    \hfill\mbox{\color{darkblue}\bfseries\sffamily\large \today}
\end{titlepage}
""",
    "tableofcontents": r"\sphinxtableofcontents",
}

# -- Mermaid options ---------------------------------------------------------

mermaid_init_js = """mermaid.initialize({
  startOnLoad: true,
  theme: 'base',
  themeVariables: {
    primaryColor: '#272662',
    primaryTextColor: '#fff',
    primaryBorderColor: '#1a1a4a',
    secondaryColor: '#F1632B',
    secondaryTextColor: '#fff',
    secondaryBorderColor: '#d14a1a',
    tertiaryColor: '#44A348',
    tertiaryTextColor: '#fff',
    tertiaryBorderColor: '#358a38',
    lineColor: '#272662',
    textColor: '#272662',
    nodeBorder: '#272662',
  },
  themeCSS: '.node .label { color: #fff !important; } .edgeLabel { color: #272662 !important; }'
});"""
mermaid_pdfcrop = "pdfcrop"
