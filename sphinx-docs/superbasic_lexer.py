"""Pygments lexer for F256 SuperBASIC."""

from pygments.lexer import RegexLexer, bygroups, words
from pygments.token import (
    Comment,
    Keyword,
    Name,
    Number,
    Operator,
    Punctuation,
    String,
    Text,
)


class SuperBASICLexer(RegexLexer):
    name = "SuperBASIC"
    aliases = ["superbasic", "basic"]
    filenames = ["*.bas"]

    KEYWORDS = (
        "assemble",
        "assert",
        "at",
        "bload",
        "bsave",
        "by",
        "call",
        "clear",
        "cls",
        "cprint",
        "cursor",
        "data",
        "dim",
        "dir",
        "downto",
        "drive",
        "else",
        "end",
        "endfn",
        "endif",
        "endproc",
        "fn",
        "for",
        "from",
        "gosub",
        "goto",
        "if",
        "input",
        "let",
        "list",
        "load",
        "local",
        "lomem",
        "mdelta",
        "memcopy",
        "mouse",
        "new",
        "next",
        "off",
        "on",
        "option",
        "poke",
        "poked",
        "pokel",
        "pokew",
        "print",
        "proc",
        "read",
        "repeat",
        "restore",
        "return",
        "run",
        "save",
        "setdate",
        "settime",
        "step",
        "stop",
        "then",
        "to",
        "try",
        "until",
        "verify",
        "wend",
        "while",
        "xgo",
        "xload",
    )

    GRAPHIC_AND_SOUND = (
        "bitmap",
        "circle",
        "color",
        "colour",
        "explode",
        "gfx",
        "here",
        "image",
        "line",
        "outline",
        "palette",
        "ping",
        "plot",
        "rect",
        "shoot",
        "solid",
        "sound",
        "sprite",
        "sprites",
        "text",
        "tile",
        "tiles",
        "zap",
    )

    FUNCTIONS = (
        "abs",
        "alloc",
        "asc",
        "chr$",
        "event",
        "frac",
        "fre",
        "get",
        "get$",
        "getdate$",
        "gettime$",
        "hit",
        "inkey",
        "inkey$",
        "int",
        "isval",
        "itemcount",
        "itemget$",
        "joyb",
        "joyx",
        "joyy",
        "keydown",
        "left$",
        "len",
        "max",
        "mid$",
        "min",
        "not",
        "peek",
        "peekd",
        "peekl",
        "peekw",
        "playing",
        "random",
        "right$",
        "rnd",
        "screen",
        "screen$",
        "sgn",
        "spc",
        "str$",
        "tile",
        "timer",
        "val",
    )

    ASSEMBLY = (
        "adc", "and", "asl", "bcc", "bcs", "beq", "bit", "bmi",
        "bne", "bpl", "bra", "brk", "bvc", "bvs", "clc", "cld",
        "cli", "clv", "cmp", "cpx", "cpy", "dec", "dex", "dey",
        "eor", "inc", "inx", "iny", "jmp", "jsr", "lda", "ldx",
        "ldy", "lsr", "nop", "ora", "pha", "php", "phx", "phy",
        "pla", "plp", "plx", "ply", "rol", "ror", "rti", "rts",
        "sbc", "sec", "sed", "sei", "sta", "stp", "stx", "sty",
        "stz", "tax", "tay", "trb", "tsb", "tsx", "txa", "txs",
        "tya",
    )  # fmt: skip

    tokens = {
        "root": [
            # Line numbers at start of line
            (r"^\s*\d+", Name.Label),
            # REM comments (keyword form)
            (r"(?i)(\brem\b)(.*)$", bygroups(Keyword, Comment.Single)),
            # Apostrophe comments
            (r"'.*$", Comment.Single),
            # Strings
            (r'"[^"]*"', String.Double),
            # Hex numbers
            (r"\$[0-9A-Fa-f]+", Number.Hex),
            # Decimal numbers (float)
            (r"\b\d+\.\d*", Number.Float),
            # Decimal numbers (integer)
            (r"\b\d+\b", Number.Integer),
            # Fundamental keywords / commands / modifiers
            (words(KEYWORDS, prefix=r"(?i)\b", suffix=r"\b"), Keyword),
            # Graphics & sound commands
            (words(GRAPHIC_AND_SOUND, prefix=r"(?i)\b", suffix=r"\b"), Keyword),
            # Built-in functions
            (words(FUNCTIONS, prefix=r"(?i)\b", suffix=r"(?=\()"), Name.Builtin),
            # Boolean constants
            (r"(?i)\b(true|false)\b", Keyword.Constant),
            # 65C02 assembly mnemonics
            (words(ASSEMBLY, prefix=r"(?i)\b", suffix=r"\b"), Keyword.Pseudo),
            # Assembly labels
            (r"[.][a-zA-Z_][a-zA-Z0-9_]*", Name.Tag),
            # Operators (multi-char before single-char to avoid partial matches)
            (r"<>|<=|>=|<<|>>", Operator),
            (r"[+\-*/\\<>=]", Operator),
            (r"%", Operator),
            # Punctuation
            (r"[(),;:.]", Punctuation),
            # Identifiers (with optional $ or # suffix)
            (r"[a-zA-Z_][a-zA-Z0-9_]*[#$]?", Name.Variable),
            # Whitespace
            (r"\s+", Text.Whitespace),
        ],
    }
