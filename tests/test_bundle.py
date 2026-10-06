import hashlib
import unittest
from pathlib import Path


class BundleTests(unittest.TestCase):
    def test_published_manifest_matches_runtime_files(self):
        root = Path(__file__).resolve().parents[1]
        entries = [line.split() for line in (root / "SHA256SUMS").read_text().splitlines()]
        self.assertEqual(len(entries), 1)
        self.assertEqual({entry[1] for entry in entries}, {"server-cleaner.sh"})
        for expected, name in entries:
            with self.subTest(name=name):
                contents = (root / name).read_bytes()
                self.assertEqual(hashlib.sha256(contents).hexdigest(), expected)
                self.assertNotIn(b"\r\n", contents)
