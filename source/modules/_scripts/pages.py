from dataclasses import dataclass


@dataclass
class Page:
    name: str

    @property
    def namespace(self) -> str:
        return self.name.capitalize()

    @property
    def thunk_namespace(self) -> str:
        return f"{self.name.capitalize()}Switch"

    def begin(self) -> str:
        return f"""
.section    {self.name}
.namespace  {self.namespace}
"""

    def end(self) -> str:
        return f"""
.endnamespace
.send {self.name}
"""

    def thunk(self, routine: str) -> str:
        return f"""
    .{self.name}_bank_in
    jsr {self.namespace}.Export_{routine}
    php
    .{self.name}_bank_out
    plp
    rts
"""


PAGE1 = Page("page1")
PAGE2 = Page("page2")
PAGES = dict((page.name, page) for page in [PAGE1, PAGE2])
