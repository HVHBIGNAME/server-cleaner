import importlib.util
import json
import unittest
from copy import deepcopy
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("render_report", ROOT / "tools" / "render_report.py")
RENDERER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RENDERER)


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.report = json.loads((ROOT / "docs" / "example-report.json").read_text())

    def test_both_themes_render_valid_svg_from_report(self):
        for theme in ("dark", "light"):
            with self.subTest(theme=theme):
                svg = RENDERER.render_report(self.report, theme)
                root = ElementTree.fromstring(svg)
                self.assertEqual(root.tag, "{http://www.w3.org/2000/svg}svg")
                self.assertIn("+3.50 GiB", svg)
                self.assertIn("17.00 GiB available", svg)
                self.assertNotIn("<script", svg)

    def test_unknown_measurements_do_not_become_fake_zeroes(self):
        self.report["mode"] = "preview"
        self.report["disk"]["before"] = None
        self.report["disk"]["after"] = None
        svg = RENDERER.render_report(self.report)
        self.assertIn("No measurement", svg)
        self.assertNotIn("+0.00 GiB", svg)

    def test_title_and_path_cannot_inject_svg(self):
        self.report["disk"]["path"] = '<script>alert("x")</script>'
        svg = RENDERER.render_report(self.report, title='<script>alert("x")</script>')
        self.assertNotIn("<script", svg)
        self.assertIn("&lt;script&gt;", svg)
        ElementTree.fromstring(svg)

    def test_invalid_and_inconsistent_data_is_rejected(self):
        broken = []
        for key, value in (("schema_version", 9), ("mode", "unknown"), ("tasks", None), ("summary", {}), ("disk", None)):
            report = deepcopy(self.report)
            report[key] = value
            broken.append(report)
        for value in (True, "10", float("nan"), 2**80):
            report = deepcopy(self.report)
            report["disk"]["before"]["used_kib"] = value
            broken.append(report)
        for report in broken:
            with self.subTest(report=report), self.assertRaises((ValueError, TypeError)):
                RENDERER.render_report(report)

    def test_non_apply_report_cannot_claim_an_after_measurement(self):
        self.report["mode"] = "preview"
        with self.assertRaises(ValueError):
            RENDERER.render_report(self.report)
