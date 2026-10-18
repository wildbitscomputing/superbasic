"""Fault-inject the assembled EXISTS implementation; build SuperBASIC first.

uv run --with py65 python -m unittest discover -s test/files -p 'test_*.py'
"""
from collections import deque
from pathlib import Path
import runpy
import unittest

ROOT = Path(__file__).resolve().parents[2]
Machine = runpy.run_path(str(ROOT / 'test/runtime/check_core.py'))['Machine']


class ExistsTests(unittest.TestCase):
    def probe(self, events, *, name=b'FILE.DAT', open_fail=False, close_fail=False):
        m = Machine(ROOT / '.build')
        c = m.cpu
        slot, stream = 3, 0x20
        for i, byte in enumerate(name + b'\0'):
            m[0x1800 + i] = byte
        m[m.labels['NSMantissa0'] + slot] = 0
        m[m.labels['NSMantissa1'] + slot] = 0x18
        m.put('KNLDefaultDrive', 1)
        pending = deque(events)
        calls = []
        c.x, c.y, c.sp = slot, 97, 255
        c.stPushWord(0xcffd)
        c.pc = m.labels['ExistsImpl']
        for _ in range(10000):
            if c.pc == 0xcffe:
                self.assertEqual((c.x, c.y, c.sp), (slot, 97, 255))
                self.assertEqual(m.pages[3], 3)
                self.assertEqual(m[m.labels['Slot3Depth']], 0)
                value = m[m.labels['NSMantissa0'] + slot]
                if m[m.labels['NSStatus'] + slot] & 128:
                    value = -value
                return value, calls
            if c.pc == m.labels['ErrorHandler']:
                return ('error', c.a), calls
            if c.pc == 0xff5c:  # File.Open
                calls.append('open')
                self.assertEqual(m[0xf3], 1)  # drive
                self.assertEqual(m[0xf5], 0)  # READ
                self.assertEqual(m[0xfd], len(name))
                c.a = stream
                c.p = (c.p & ~c.CARRY) | (c.CARRY if open_fail else 0)
            elif c.pc == 0xff68:  # File.Close
                calls.append('close')
                self.assertEqual(m[0xf3], stream)
                c.p = (c.p & ~c.CARRY) | (c.CARRY if close_fail else 0)
            elif c.pc == m.labels['GetNextEvent']:
                self.assertTrue(pending, 'Unexpected extra event wait')
                event = pending.popleft()
                c.p &= ~c.CARRY
                if event is None:
                    c.p |= c.CARRY
                else:
                    kind, owner = event
                    m.put('KNLEvent', kind, 0, 0, owner)
            elif c.pc == 0xff0c:  # Yield
                calls.append('yield')
            else:
                self.assertNotIn(c.pc, (0xff60, 0xff64), 'Probe read or wrote file data')
                c.step()
                continue
            c.pc = c.stPopWord() + 1
        self.fail(f'Probe stuck at ${c.pc:04x}')

    def test_success_waits_for_own_open_and_close(self):
        result, calls = self.probe([None, (0x38, 0x30), (0x48, 0x20),
                                   (0x2a, 0x20), (0x32, 0x30), None, (0x32, 0x20)])
        self.assertEqual(result, -1)
        self.assertEqual(calls, ['open', 'yield', 'close', 'yield'])

    def test_missing_is_false_without_close(self):
        self.assertEqual(self.probe([(0x28, 0x20)]), (0, ['open']))

    def test_ambiguous_and_immediate_open_failures_are_errors(self):
        for events, immediate in (([(0x38, 0x20)], False), ([], True)):
            result, calls = self.probe(events, open_fail=immediate)
            self.assertEqual(result, ('error', 26))  # ERRID_DRIVEIO
            self.assertEqual(calls, ['open'])

    def test_close_failures_are_errors(self):
        for events, immediate in (([(0x2a, 0x20), (0x38, 0x20)], False),
                                  ([(0x2a, 0x20)], True)):
            result, calls = self.probe(events, close_fail=immediate)
            self.assertEqual(result, ('error', 26))
            self.assertEqual(calls, ['open', 'close'])

    def test_invalid_names_never_open(self):
        for name in (b'', b'*.DAT', b'A?.DAT', b'X' * 256):
            result, calls = self.probe([], name=name)
            self.assertEqual(result, ('error', 4))  # ERRID_RANGE
            self.assertEqual(calls, [])


if __name__ == '__main__':
    unittest.main()
