from pygments.style import Style
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


class BrandColors:
    MIDNIGHT_BLUE = "#1d2c78"
    RIVER_BLUE = "#6ba7bb"
    FERN_GREEN = "#44a348"
    MANGO = "#fdbb3a"
    BURNT_ORGANE = "#f1632b"
    DRAGON_FIRE = "#ee4025"


class HTMLStyle(Style):
    pass


class PDFStyle(Style):
    TEXT_COLOR = "#000000"

    KEYWORD_COLOR = BrandColors.MIDNIGHT_BLUE
    KEYWORD_STYLE = f"bold {KEYWORD_COLOR}"

    ASM_COLOR = "#496f98"
    ASM_STYLE = f"bold {ASM_COLOR}"

    COMMENT_COLOR = "#b58b17"
    COMMENT_STYLE = f"italic {COMMENT_COLOR}"

    LINE_NUMBER_COLOR = "#626262"
    STRING_COLOR = "#ee4025"
    NUMBER_COLOR = "#6ba7bb"

    styles = {
        Keyword: KEYWORD_STYLE,
        Keyword.Pseudo: ASM_STYLE,
        Name.Builtin: KEYWORD_STYLE,
        Name.Label: LINE_NUMBER_COLOR,
        Name.Tag: TEXT_COLOR,
        Name.Function: TEXT_COLOR,
        Name.Variable: TEXT_COLOR,
        Text: TEXT_COLOR,
        String: STRING_COLOR,
        Number: NUMBER_COLOR,
        Comment: COMMENT_STYLE,
        Operator: TEXT_COLOR,
        Punctuation: TEXT_COLOR,
    }
