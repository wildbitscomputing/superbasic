"""Reference checks for the fixed-point kernel, independent of the emulator.

Run: python test/trig/test_tables.py
The integer model mirrors the assembly's Q2.30 rounding. This does not replace
the MAME tests: it checks the table geometry, approximation and error budget.
"""

from contextlib import redirect_stdout
from io import StringIO
import math
from pathlib import Path
import random
import re
import runpy
import unittest

ROOT = Path(__file__).resolve().parents[2]
TABLES = runpy.run_path(str(ROOT / "source/modules/math/make-tables.py"))
ANGLES, SINES, SIXTHS = (TABLES[name] for name in ("ANGLES", "SINES", "SIXTHS"))
SCALE = 1 << 30
HALF_STEP = 13176795


def anchor(angle):
    index = (((angle >> 16) * 163) + 32768) >> 16
    while abs(angle - ANGLES[index]) > HALF_STEP:
        index += 1 if angle > ANGLES[index] else -1
    return index, angle - ANGLES[index]


def multiply(value, delta):
    magnitude = (abs(value) * abs(delta) + (1 << 29)) >> 30
    return -magnitude if (value < 0) != (delta < 0) else magnitude


def shift_add_multiply(value, delta):
    # Exact software 32x24->56 bit implementation of TrigFixedMultiply.
    factor = abs(value)
    product = abs(delta)
    for _ in range(24):
        if product & 1:
            product += factor << 24
        product >>= 1
    magnitude = (product + (1 << 29)) >> 30
    return -magnitude if (value < 0) != (delta < 0) else magnitude


def cubic(angle):
    index, delta = anchor(angle)
    value = multiply(-SIXTHS[64-index], delta)
    value -= SINES[index] >> 1
    value = multiply(value, delta) + SINES[64-index]
    return multiply(value, delta) + SINES[index]


class TablesTest(unittest.TestCase):
    def test_generated_tables(self):
        generated = StringIO()
        with redirect_stdout(generated):
            TABLES["main"]()
        self.assertEqual(generated.getvalue(),
                         (ROOT / "source/modules/math/anchors.inc").read_text())

    def test_basic_reference_data(self):
        source = (ROOT / "test/trig/ANCHORS.BAS").read_text()
        rows = re.findall(r"^\d+ data (\d+),(-?\d+),(-?\d+)$", source, re.M)
        self.assertEqual(len(rows), 411)
        for angle, sine, cosine in rows:
            x = int(angle) / 100000000
            self.assertEqual(int(sine), round(math.sin(x)*1000000000))
            self.assertEqual(int(cosine), round(math.cos(x)*1000000000))

    def test_endpoints(self):
        self.assertEqual(SINES[0], 0)
        self.assertEqual(SINES[64], SCALE)
        self.assertEqual(ANGLES[64], 0x6487ED51)
        self.assertEqual(cubic(ANGLES[64]), SCALE)

    def test_multiplier(self):
        rng = random.Random(6502)
        for _ in range(10000):
            value = rng.randrange(-SCALE, SCALE + 1)
            delta = rng.randrange(-HALF_STEP, HALF_STEP + 1)
            self.assertEqual(shift_add_multiply(value, delta), multiply(value, delta))

    def test_dense_quarter_wave(self):
        worst = 0
        for i in range(65537):
            x = (math.pi / 2) * i / 65536
            angle = int(x * SCALE)
            index, delta = anchor(angle)
            self.assertTrue(0 <= index <= 64)
            self.assertLessEqual(abs(delta), HALF_STEP)
            worst = max(worst, abs(cubic(angle) / SCALE - math.sin(x)))
        print(f"Worst sampled fixed-point absolute error: {worst:.3g}")
        self.assertLess(worst, 4e-9)

    def test_anchor_switches(self):
        for a, b in zip(ANGLES, ANGLES[1:]):
            midpoint = (a+b)//2
            for angle in range(midpoint-3, midpoint+4):
                self.assertLess(abs(cubic(angle)/SCALE - math.sin(angle/SCALE)), 4e-9)


if __name__ == "__main__":
    unittest.main()
