# /// script
# requires-python = ">=3.10"
# dependencies = ["py65==1.2.0"]
# ///
"""CPU-level differential checks: uv run check_core.py BASELINE_BUILD NEW_BUILD."""
import random
import re
import sys
from pathlib import Path
from py65.devices.mpu65c02 import MPU


class Machine:
    def __init__(self, build):
        build = Path(build)
        self.labels = {k: int(v, 16) for k, v in re.findall(
            r"^(\w+)\s*=\s*\$([0-9a-fA-F]+)",
            (build / "debug/basic.lbl").read_text(), re.M)}
        self.ram = bytearray(128 * 8192)
        self.multiplier = bytearray(4)
        self.divider = bytearray(4)
        self.pages = [0, 1, 2, 3, 66, 67, 6, 127]
        for i in range(1, 6):
            data = (build / f"sb0{i}.bin").read_bytes()
            self.ram[(64+i)*8192:(64+i)*8192+len(data)] = data
        self.cpu = MPU(memory=self)
        self.put("Slot3ModulePage", 69)
        self.put("pageTable", 1)

    def __getitem__(self, address):
        if 8 <= address < 16:
            return self.pages[address-8]
        if self.ram[1] == 0:
            if 0xde00 <= address <= 0xde03:
                return self.multiplier[address-0xde00]
            if 0xde10 <= address <= 0xde13:
                product = (int.from_bytes(self.multiplier[:2], "little") *
                           int.from_bytes(self.multiplier[2:], "little"))
                return (product >> (8*(address-0xde10))) & 255
            if 0xde04 <= address <= 0xde07:
                return self.divider[address-0xde04]
            if 0xde14 <= address <= 0xde17:
                divisor = int.from_bytes(self.divider[:2], "little")
                dividend = int.from_bytes(self.divider[2:], "little")
                value = dividend // divisor if address < 0xde16 else dividend % divisor
                return (value >> (8*(address & 1))) & 255
        return self.ram[self.pages[address >> 13]*8192 + (address & 8191)]

    def __setitem__(self, address, value):
        if 8 <= address < 16:
            self.pages[address-8] = value
        elif self.ram[1] == 0 and 0xde00 <= address <= 0xde03:
            self.multiplier[address-0xde00] = value
        elif self.ram[1] == 0 and 0xde04 <= address <= 0xde07:
            self.divider[address-0xde04] = value
        else:
            self.ram[self.pages[address >> 13]*8192 + (address & 8191)] = value

    def put(self, name, *values):
        for i, value in enumerate(values):
            self[self.labels[name]+i] = value

    def call(self, name, a=0, x=0, y=3):
        c = self.cpu
        c.a, c.x, c.y, c.sp = a, x, y, 255
        c.stPushWord(0xcffd)
        c.pc = self.labels[name]
        start = c.processorCycles
        for _ in range(100000):
            if c.pc == 0xcffe:
                return c.processorCycles-start
            if self[c.pc] == 0xdb:
                raise AssertionError(f"STP at {c.pc:04x} in {name}")
            c.step()
        raise AssertionError(f"{name} did not return (PC={c.pc:04x})")

    def result(self):
        return tuple(self[self.labels[s]] for s in (
            "NSStatus", "NSMantissa0", "NSMantissa1", "NSMantissa2",
            "NSMantissa3", "NSExponent")) + (self.cpu.y,)


def main(old, new):
    rng = random.Random(256)
    count = 0
    timings = [0, 0]
    numbers = ["0", "1", "9", "10", "255", "65535", "2147483647",
               "2147483648", "4294967295", "0.0", "0.001", "12.375",
               "99999999.999", "1.2.3"]
    numbers += [str(rng.randrange(2**31)) for _ in range(150)]
    for number in numbers:
        for delimiter in (0x80, 0x3a, 0x29):
            results = []
            for i, build in enumerate((old, new)):
                m = Machine(build)
                m.put("codePtr", 0, 0x20, 0, 0)
                for j, byte in enumerate(number.encode()+bytes([delimiter])):
                    m[0x2003+j] = byte
                timings[i] += m.call("EvaluateTerm")
                results.append(m.result())
            assert results[0] == results[1], (number, delimiter, results)
            count += 1
    for status in (0, 8, 16, 32, 36, 40, 44, 48, 52, 33, 34):
        for _ in range(30):
            data = bytes(rng.randrange(256) for _ in range(5))
            results = []
            for build in (old, new):
                m = Machine(build)
                m.put("NSStatus", status)
                m.put("NSMantissa0", 0)
                m.put("NSMantissa1", 0x40)
                for j, byte in enumerate(data):
                    m[0x4000+j] = byte
                m.call("Dereference", y=193)
                results.append(m.result())
            assert results[0] == results[1], (status, data, results)
            count += 1
    m = Machine(new)
    m.put("basicStack", 1, 15)
    m.call("StackOpen", a=0xb3)
    assert m[m.labels["basicStack"]] == 0xfb
    assert m[m.labels["basicStack"]+1] == 14
    assert m[0xefb] == 0xb3
    m.call("StackClose")
    assert m[m.labels["basicStack"]] == 1
    assert m[m.labels["basicStack"]+1] == 15
    # Exercise both fixed runtime callers, nested structures, colliding keys,
    # identical window addresses in distinct banks, invalidation and direct mode.
    m.call("BranchCacheClear")
    for page in (0, 1, 0, 2, 1):
        m[m.labels["pageTable"]+page] = page+1
        for offset in (0, 64, 0, 128, 64):
            for target in ("KWD_ELSE", "KWD_ENDIF"):
                m.pages[1] = page+1
                m.put("codePtr", offset, 0x20, page, 0)
                tokens = [m.labels["KWD_IF"], ord('0'),
                          m.labels["KWD_ELSE"], ord('1'),
                          m.labels["KWD_ENDIF"]]
                tokens += [ord('2')] * (page+1)
                tokens += [m.labels[target]]
                for j, byte in enumerate(tokens):
                    m[0x2000+offset+3+j] = byte
                # Changed token streams require invalidation, just as editing does.
                m.call("BranchCacheClear")
                expected = None
                for entry in ("ScanForward", "BranchScanForward", "BranchScanForward"):
                    m.put("codePtr", offset, 0x20, page, 0)
                    old_slot = m.pages[3]
                    cycles = m.call(entry, a=m.labels[target], x=m.labels[target])
                    state = (m.cpu.a, m.cpu.x, m.cpu.y,
                             tuple(m[m.labels["codePtr"]+j] for j in range(3)))
                    assert m.pages[3] == old_slot
                    if expected is None:
                        expected = state
                    assert state == expected, (entry, state, expected)
                    count += 1
    # Keep entries alive across collisions/page changes (no intervening clear).
    m.call("BranchCacheClear")
    for page, offset in ((0, 0), (1, 0), (0, 64), (0, 0), (1, 0), (1, 0)):
        m.pages[1] = page+1
        m.put("codePtr", offset, 0x20, page, 0)
        end = m.labels["KWD_ENDIF"]
        for j in range(page+2):
            m[0x2000+offset+3+j] = ord('0')
        m[0x2000+offset+5+page] = end
        m.call("BranchScanForward", a=end, x=end)
        assert m.cpu.y == 6+page
        count += 1
    m.put("codePtr", 0, 0x10, 0, 0)
    m[0x1003] = end
    m.call("BranchScanForward", a=end, x=end)
    assert m.cpu.y == 4
    # A cached destination can itself be in a different program bank.
    m.call("BranchCacheClear")
    m.put("pageTable", 1, 2)
    m.pages[1] = 1
    m[0x3ff0], m[0x3ff3] = 16, 0x80
    m.pages[1] = 2
    m[0x2000], m[0x2003] = 5, end
    for entry in ("ScanForward", "BranchScanForward", "BranchScanForward"):
        m.pages[1] = 1
        m.put("codePtr", 0xf0, 0x3f, 0, 0)
        m.call(entry, a=end, x=end)
        assert m.cpu.y == 4 and m.pages[1] == 2 and m.pages[3] == 3
        assert tuple(m[m.labels["codePtr"]+j] for j in range(3)) == (0, 32, 1)
        count += 1
    m[0x2003], m[0x2004] = ord('0'), end
    m.call("BranchCacheClear")
    m.pages[1] = 1
    m.put("codePtr", 0xf0, 0x3f, 0, 0)
    m.call("BranchScanForward", a=end, x=end)
    assert m.cpu.y == 5
    count += 1
    print(f"PASS: {count} literal/reference/branch cases; stack page crossing")
    print(f"Literal cycles: {timings[0]} -> {timings[1]}")
    multiply_cycles = [0, 0]
    pairs = [(0, 65535), (1, 65535), (255, 255), (32767, 65535),
             (65536, 2), (1000000, 123)]
    pairs += [(rng.randrange(32768), rng.randrange(32768)) for _ in range(100)]
    for left, right in pairs:
        for sign in ("", "-"):
            for io_page in (0, 1, 2, 3):
                results = []
                for i, build in enumerate((old, new)):
                    m = Machine(build)
                    m[1] = io_page
                    m.multiplier[:] = b"\x12\x34\x56\x78"
                    m.put("codePtr", 0, 0x20, 0, 0)
                    expression = []
                    if sign:
                        expression.append(m.labels["KWD_MINUS"])
                    expression += list(str(left).encode())
                    expression.append(m.labels["KWD_STAR"])
                    expression += list(str(right).encode()) + [0x80]
                    for j, byte in enumerate(expression):
                        m[0x2003+j] = byte
                    try:
                        multiply_cycles[i] += m.call("EvaluateExpression")
                    except AssertionError as error:
                        raise AssertionError((build, left, right, sign, io_page)) from error
                    results.append(m.result())
                    assert m[1] == io_page
                    assert m.multiplier == b"\x12\x34\x56\x78"
                assert results[0] == results[1], (left, right, sign, results)
    print(f"PASS: {len(pairs)*8} signed multiplication/I/O preservation cases")
    print(f"Expression multiplication cycles: {multiply_cycles[0]} -> {multiply_cycles[1]}")
    modulus_cycles = [0, 0]
    mod_count = 0
    for divisor in [1 << n for n in range(16)] + [3, 7, 255, 65535, 65536, 100000]:
        for dividend in (0, 1, 255, 65535, 65536, 1073741823, 2147483647):
            for negative in (0, 128):
                results = []
                for i, build in enumerate((old, new)):
                    m = Machine(build)
                    for operand, value in enumerate((dividend, divisor)):
                        for byte in range(4):
                            m[m.labels[f"NSMantissa{byte}"]+operand] = (value >> (8*byte)) & 255
                        m[m.labels["NSStatus"]+operand] = negative
                    modulus_cycles[i] += m.call("IntegerModulusNoCheck", y=177)
                    results.append(m.result())
                    assert m.pages[3] == 3
                assert results[0] == results[1], (dividend, divisor, negative, results)
                mod_count += 1
    print(f"PASS: {mod_count} signed modulus cases; cycles {modulus_cycles}")
    divide_cycles = [0, 0]
    div_count = 0
    for divisor in (1, 2, 3, 255, 256, 65535, 65536):
        for dividend in (0, 1, 255, 65535, 65536, 2147483647):
            for io_page in range(4):
                results = []
                for i, build in enumerate((old, new)):
                    m = Machine(build)
                    m[1] = io_page
                    m.divider[:] = b"\x12\x34\x56\x78"
                    for operand, value in enumerate((dividend, divisor)):
                        for byte in range(4):
                            m[m.labels[f"NSMantissa{byte}"]+operand] = (value >> (8*byte)) & 255
                    divide_cycles[i] += m.call("Int32Divide", a=19, y=117)
                    quotient = tuple(m[m.labels[f"NSMantissa{b}"]+2] for b in range(4))
                    results.append((m.result(), quotient, m.cpu.a))
                    assert m[1] == io_page and m.pages[3] == 3
                    assert m.divider == b"\x12\x34\x56\x78"
                assert results[0] == results[1], (dividend, divisor, results)
                div_count += 1
    print(f"PASS: {div_count} division/I/O preservation cases; cycles {divide_cycles}")


if __name__ == "__main__":
    main(*sys.argv[1:])
