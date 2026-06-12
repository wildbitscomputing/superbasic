"""Generate error handling code and data"""

import sys

eText = []
errors = open("common/errors/text/errors." + sys.argv[1], "r").readlines()
errors = [
    x.replace("\t", " ").strip()
    for x in errors
    if not x.startswith("#") and x.strip() != ""
]

note = ";\n;\tThis is automatically generated.\n;\n"

h1 = open("common/generated/errors.inc", "w")
h2 = open("common/generated/errors.asm", "w")
h1.write(note)
h2.write(note)
h2.write(".section code\n")
for i in range(0, len(errors)):
    e = [x.strip() for x in errors[i].split(":")]
    if e[0].startswith("!"):
        e[0] = e[0][1:]
        h2.write("{0}Error:\n\t.error_{1}\n".format(e[0], e[0].lower()))
    h1.write("ERRID_{0} = {1}\n".format(e[0].upper(), i + 1))
    h1.write(
        "error_{0} .macro\n\tlda\t#{1}\n\tjmp\tErrorHandler\n\t.endm\n".format(
            e[0].lower(), str(i + 1)
        )
    )
    eText.append(e[1])
h2.write(".send code\n")
h1.close()
h2.close()

# error messages
error_messages = "\n".join(['\t.text\t"{0}",0'.format(x) for x in eText])
h3 = open("common/generated/_errortext.asm", "w")
h3.write(note)
h3.write("""
.section code
ErrorText:
""")
h3.write(error_messages)
h3.write("""
.send code
""")
h3.close()

# error messages, page2 variant for slot 3 module page
h4 = open("common/generated/_errortext_p2.asm", "w")
h4.write(note)
h4.write("""
.section page2
.logical * + $2000
ErrorText:
""")
h4.write(error_messages)
h4.write("""
.endlogical
.send page2
""")
h4.close()
