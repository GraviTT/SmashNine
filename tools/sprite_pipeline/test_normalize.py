from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw


SCRIPT = Path(__file__).with_name("normalize.py")


def frame(top: int, bottom: int, background=(0, 250, 5, 255)) -> Image.Image:
	image = Image.new("RGBA", (100, 100), background)
	draw = ImageDraw.Draw(image)
	draw.ellipse((38, top, 62, top + 24), fill=(240, 190, 145, 255))
	draw.rectangle((34, top + 22, 66, bottom - 17), fill=(30, 100, 215, 255))
	draw.rectangle((37, bottom - 17, 47, bottom), fill=(18, 26, 58, 255))
	draw.rectangle((53, bottom - 17, 63, bottom), fill=(18, 26, 58, 255))
	return image


class NormalizeTests(unittest.TestCase):
	def setUp(self) -> None:
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		palette = {"colors": [{"rgb": list(color)} for color in [(240, 190, 145), (30, 100, 215), (18, 26, 58)]]}
		self.palette = self.root / "palette.json"
		self.palette.write_text(json.dumps(palette), encoding="utf-8")

	def tearDown(self) -> None:
		self.temp.cleanup()

	def run_tool(self, scale="height:80", expect=0) -> tuple[subprocess.CompletedProcess[str], dict | None]:
		sheet = Image.new("RGBA", (200, 100), (0, 0, 0, 0))
		sheet.alpha_composite(frame(12, 90), (0, 0)); sheet.alpha_composite(frame(2, 80), (100, 0))
		source = self.root / "green.png"; sheet.save(source); out = self.root / "out"
		command = [sys.executable, str(SCRIPT), "--sheet", str(source), "--grid", "2x1", "--bg", "auto", "--scale-by", scale, "--palette", str(self.palette), "--outline", "off", "--out-dir", str(out), "--name", "synthetic"]
		result = subprocess.run(command, capture_output=True, text=True, check=False)
		self.assertEqual(result.returncode, expect, result.stderr)
		metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8")) if expect == 0 else None
		return result, metrics

	def test_background_one_scale_ground_lift_palette_alpha_and_six_columns(self) -> None:
		_, metrics = self.run_tool()
		assert metrics is not None
		summary = metrics["summary"]
		self.assertEqual(summary["frame_count"], 2)
		self.assertAlmostEqual(summary["common_scale"], 80 / 79, places=5)
		self.assertTrue(summary["contact_on_y120"])
		self.assertTrue(summary["airborne_lift_preserved"])
		self.assertGreater(metrics["frames"][1]["lift"], 0)
		self.assertEqual(summary["palette_violations"], 0)
		self.assertTrue(summary["alpha_binary"])
		self.assertTrue(summary["borders_clear"])
		self.assertLess(summary["body_width_range"][1], 50)  # green field was removed
		allowed = {(240, 190, 145), (30, 100, 215), (18, 26, 58)}
		for path in sorted((self.root / "out/frames").glob("*.png")):
			with Image.open(path).convert("RGBA") as output:
				self.assertLessEqual(set(output.getchannel("A").get_flattened_data()), {0, 255})
				self.assertLessEqual({pixel[:3] for pixel in output.get_flattened_data() if pixel[3]}, allowed)
		with Image.open(self.root / "out/synthetic.png") as output:
			self.assertEqual(output.size, (768, 128))

	def test_fixed_scale(self) -> None:
		_, metrics = self.run_tool("fixed:1")
		assert metrics is not None
		self.assertEqual(metrics["summary"]["common_scale"], 1)

	def test_border_failure_never_shrinks_one_frame(self) -> None:
		result, _ = self.run_tool("fixed:3", expect=1)
		self.assertIn("does not fit at common scale", result.stderr)

	def test_source_cell_border_contact_fails_and_requests_regeneration(self) -> None:
		sheet = Image.new("RGBA", (200, 100), (0, 250, 5, 255))
		sheet.alpha_composite(frame(12, 90), (0, 0)); sheet.alpha_composite(frame(12, 90), (100, 0))
		ImageDraw.Draw(sheet).rectangle((96, 45, 100, 49), fill=(18, 26, 58, 255))
		source = self.root / "crossed-cell.png"; sheet.save(source); out = self.root / "crossed-cell-out"
		command = [sys.executable, str(SCRIPT), "--sheet", str(source), "--grid", "2x1", "--bg", "auto", "--scale-by", "fixed:1", "--palette", str(self.palette), "--outline", "off", "--out-dir", str(out), "--name", "crossed-cell"]
		result = subprocess.run(command, capture_output=True, text=True, check=False)
		self.assertEqual(result.returncode, 1)
		self.assertIn("source cell subject touches its right border", result.stderr)
		self.assertIn("would be cut", result.stderr)
		self.assertIn("Regenerate the whole motion with more margin", result.stderr)
		self.assertFalse(out.exists())

	def test_min_component_drops_small_detached_specks_and_reports_them(self) -> None:
		sheet = Image.new("RGBA", (200, 100), (0, 250, 5, 255))
		sheet.alpha_composite(frame(12, 90), (0, 0)); sheet.alpha_composite(frame(12, 90), (100, 0))
		draw = ImageDraw.Draw(sheet)
		draw.rectangle((4, 4, 5, 5), fill=(18, 26, 58, 255))
		draw.rectangle((104, 4, 106, 6), fill=(18, 26, 58, 255))
		source = self.root / "specks.png"; sheet.save(source); out = self.root / "specks-out"
		command = [sys.executable, str(SCRIPT), "--sheet", str(source), "--grid", "2x1", "--bg", "auto", "--scale-by", "fixed:1", "--palette", str(self.palette), "--outline", "off", "--min-component", "6", "--out-dir", str(out), "--name", "specks"]
		result = subprocess.run(command, capture_output=True, text=True, check=False)
		self.assertEqual(result.returncode, 0, result.stderr)
		metrics = json.loads((out / "metrics.json").read_text(encoding="utf-8"))
		self.assertEqual(metrics["summary"]["dropped_component_count"], 1)
		self.assertEqual(metrics["summary"]["dropped_component_pixels"], 4)
		bbox = metrics["frames"][0]["dropped_components"][0]["bbox"]
		self.assertEqual([bbox[2] - bbox[0], bbox[3] - bbox[1]], [2, 2])
		self.assertEqual(metrics["frames"][1]["dropped_components"], [])
		self.assertIn("dropped=1 components/4 px", result.stdout)


if __name__ == "__main__":
	unittest.main()
