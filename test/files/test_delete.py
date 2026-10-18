"""Exercise assembled deletion with injected kernel completion/error events."""
from collections import deque
from pathlib import Path
import runpy
import unittest

ROOT = Path(__file__).resolve().parents[2]
Machine = runpy.run_path(str(ROOT / 'test/runtime/check_core.py'))['Machine']


class DeleteTests(unittest.TestCase):
    def probe(self, events=(), *, name=b'FILE.DAT', fail=False):
        m = Machine(ROOT / '.build')
        c = m.cpu
        for i, byte in enumerate(name + b'\0'):
            m[0x1800+i] = byte
        m.put('zTemp0', 0, 0x18)
        m.put('KNLDefaultDrive', 1)
        pending = deque(events)
        calls = []
        c.y, c.sp = 97, 255
        c.stPushWord(0xcffd)
        c.pc = m.labels['DeleteImpl']
        for _ in range(10000):
            if c.pc == 0xcffe:
                self.assertEqual((c.y, c.sp, m.pages[3]), (97, 255, 3))
                self.assertEqual(m[m.labels['Slot3Depth']], 0)
                return c.a, calls
            if c.pc == m.labels['ErrorHandler']:
                return ('error', c.a), calls
            if c.pc == 0xff70:  # File.Delete
                calls.append('delete')
                self.assertEqual(m[0xf3], 1)
                self.assertEqual(m[0xfd], len(name))
                c.a = 0x20
                c.p = (c.p & ~c.CARRY) | (c.CARRY if fail else 0)
            elif c.pc == m.labels['GetNextEvent']:
                self.assertTrue(pending, 'Unexpected event wait')
                event = pending.popleft()
                c.p &= ~c.CARRY
                if event is None:
                    c.p |= c.CARRY
                else:
                    kind, owner = event
                    m.put('KNLEvent', kind, 0, 0, owner)
            elif c.pc == 0xff0c:
                calls.append('yield')
            else:
                self.assertNotIn(c.pc, (0xff5c, 0xff60, 0xff64, 0xff68),
                                 'Delete must not open/read/write/close')
                c.step()
                continue
            c.pc = c.stPopWord() + 1
        self.fail(f'Stuck at ${c.pc:04x}')

    def test_success_filters_events_and_waits(self):
        self.assertEqual(self.probe([None, (0x38, 0x30), (0x48, 0x20), (0x36, 0x20)]),
                         (0, ['delete', 'yield']))

    def test_errors_return_nonzero(self):
        self.assertEqual(self.probe(fail=True), (0x38, ['delete']))
        for error in (0x28, 0x38):
            self.assertEqual(self.probe([(error, 0x20)]), (error, ['delete']))

    def test_invalid_or_multi_target_names_never_reach_kernel(self):
        for name in (b'', b'*', b'A?', b'A,B', b'0:A', b'/', b'SUB/', b'.', b'..',
                     b'SUB/.', b'SUB/..', b'A\rB', b'A\x7f', b'X'*256):
            with self.subTest(name=name):
                self.assertEqual(self.probe(name=name), (('error', 4), []))

    def test_exact_paths_and_dotfiles_are_allowed(self):
        for name in (b'/SUB/FILE.DAT', b'SUB/FILE.DAT', b'.file', b'..file', b'X'*255):
            with self.subTest(name=name):
                self.assertEqual(self.probe([(0x36, 0x20)], name=name), (0, ['delete']))


if __name__ == '__main__':
    unittest.main()
