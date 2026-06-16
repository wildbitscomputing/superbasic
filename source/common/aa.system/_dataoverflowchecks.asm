;
; End-of-program overflow checks; issuing warnings instead of an error so one can examine output listing for details
;
.section zeropage
    .cwarn * > ZeroPagePreference, "BROKEN BUILD: zeropage section overflowed by ", * - ZeroPagePreference," bytes"
.send zeropage

.section zeropref
    .cwarn * > HardwareStack, "BROKEN BUILD: zeropref section overflowed into hardware stack by ", * - HardwareStack," bytes"
.send zeropref

.section arguments
    .cwarn * > ControlStorage, "BROKEN BUILD: arguments section overflowed into control storage by ", * - ControlStorage," bytes"
.send arguments

.section storage
    .cwarn * > BasicStackBase, "BROKEN BUILD: storage section overflowed into BASIC stack by ", * - BasicStackBase," bytes"
.send storage

.section boot
    .cwarn * > CodeStart, "BROKEN BUILD: boot section overflowed into code by ", * - CodeStart," bytes"
.send boot
