"""Check that the hardware formula preserves the legacy float truncation.

Run: python test/trig/test_float_multiply.py
FloatMultiply normalises both nonzero operands before MultiplyShort; that
special case makes its shift/add loop exactly floor(A*B/2**31), not a rounded
31-bit product. Exponent wrapping is existing behaviour, not changed here.
"""

import random
import unittest


def software_multiply(a, b):
    result, shifts = 0, 0
    while a:
        if a & 1:
            result += b
        if result & 0x80000000 or b & 0x40000000:
            result >>= 1
            shifts += 1
        else:
            b <<= 1
        a >>= 1
    return result, shifts


def hardware_product(a, b):
    a0, a1 = a & 65535, a >> 16
    b0, b1 = b & 65535, b >> 16
    return a0*b0 + ((a1*b0 + a0*b1) << 16) + ((a1*b1) << 32)


class FloatMultiplyTest(unittest.TestCase):
    def test_normalised_mantissas(self):
        rng = random.Random(65816)
        edges = [0x40000000, 0x40000001, 0x4000ffff, 0x40010000,
                 0x55555555, 0x5a827999, 0x5a82799a, 0x7fff0000,
                 0x7ffffffe, 0x7fffffff]
        pairs = [(a, b) for a in edges for b in edges]
        pairs += [(rng.randrange(1 << 30, 1 << 31),
                   rng.randrange(1 << 30, 1 << 31)) for _ in range(10000)]
        for a, b in pairs:
            product = hardware_product(a, b)
            self.assertEqual(product, a*b)
            self.assertEqual(software_multiply(a, b), (product >> 31, 31))

    def test_preserve_low_bit_loss(self):
        # The legacy routine truncates before the final normalisation, so
        # retaining an extra product bit here would change BASIC results.
        a, b = 0x40000001, 0x40000001
        result, shifts = software_multiply(a, b)
        self.assertEqual(shifts, 31)
        self.assertEqual(result << 1, (hardware_product(a, b) >> 31) << 1)
        a, b = 0x40000001, 0x40000002
        self.assertNotEqual((hardware_product(a, b) >> 31) << 1, (a*b) >> 30)


if __name__ == "__main__":
    unittest.main()
