from __future__ import annotations

import json
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw


SCRIPT = Path(__file__).with_name("normalize.py")
SPEC = importlib.util.spec_from_file_location("sprite_normalize", SCRIPT)
assert SPEC and SPEC.loader
NORMALIZE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(NORMALIZE)


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

	def run_tool(self, scale="height:80", expect=0, extra: list[str] | None = None) -> tuple[subprocess.CompletedProcess[str], dict | None]:
		sheet = Image.new("RGBA", (200, 100), (0, 0, 0, 0))
		sheet.alpha_composite(frame(12, 90), (0, 0)); sheet.alpha_composite(frame(2, 80), (100, 0))
		source = self.root / "green.png"; sheet.save(source); out = self.root / "out"
		command = [sys.executable, str(SCRIPT), "--sheet", str(source), "--grid", "2x1", "--bg", "auto", "--scale-by", scale, "--palette", str(self.palette), "--outline", "off", "--out-dir", str(out), "--name", "synthetic"]
		command.extend(extra or [])
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

	def test_ground_all_and_common_offset_are_reported(self) -> None:
		_, metrics = self.run_tool("fixed:1", extra=["--ground-all", "--offset-x", "-2"])
		assert metrics is not None
		self.assertTrue(metrics["summary"]["ground_all"])
		self.assertEqual(metrics["summary"]["common_offset_x"], -2)
		self.assertEqual(metrics["summary"]["bottom_range"], [120, 120])

	def test_lift_all_keeps_every_frame_airborne(self) -> None:
		_, metrics = self.run_tool("fixed:1", extra=["--ground-all", "--lift-all", "7"])
		assert metrics is not None
		self.assertEqual(metrics["summary"]["common_lift"], 7)
		self.assertEqual(metrics["summary"]["bottom_range"], [113, 113])
		self.assertEqual(metrics["summary"]["lift_range"], [7, 7])
		self.assertTrue(metrics["summary"]["airborne_lift_preserved"])

	def test_lanczos_sharpen_increases_synthetic_interior_detail(self) -> None:
		large = Image.new("RGBA", (64, 64), (96, 96, 96, 255))
		draw = ImageDraw.Draw(large)
		for x in range(8, 56, 8):
			draw.line((x, 4, x, 59), fill=(180, 180, 180, 255), width=2)
		soft = large.resize((16, 16), Image.Resampling.LANCZOS)
		sharp = NORMALIZE.apply_unsharp(soft, 60)
		self.assertGreater(NORMALIZE.interior_detail(sharp), NORMALIZE.interior_detail(soft))

	def test_despill_auto_removes_green_from_two_pixel_alpha_edge(self) -> None:
		image = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
		ImageDraw.Draw(image).rectangle((2, 2, 6, 6), fill=(30, 190, 40, 255))
		self.assertGreater(NORMALIZE.spill_pixel_count(image), 0)
		cleaned = NORMALIZE.despill_green_edge(image, "auto")
		self.assertEqual(NORMALIZE.spill_pixel_count(cleaned), 0)

	def test_enclosed_chroma_pocket_is_removed_before_shrink(self) -> None:
		image = Image.new("RGBA", (32, 32), (0, 255, 0, 255))
		draw = ImageDraw.Draw(image)
		draw.rectangle((4, 4, 27, 27), fill=(35, 45, 75, 255))
		# This key-colour pocket is enclosed by opaque subject pixels and has no
		# four-connected route to the outer green background.
		draw.rectangle((13, 13, 18, 18), fill=(0, 255, 0, 255))
		cleaned, report = NORMALIZE.clean_background(image, "#00ff00")
		self.assertEqual(report["mode"], "color")
		self.assertEqual(cleaned.getpixel((15, 15))[3], 0)
		self.assertEqual(cleaned.getpixel((8, 8))[3], 255)
		shrunk = cleaned.resize((8, 8), Image.Resampling.LANCZOS)
		shrunk = NORMALIZE.despill_green_edge(shrunk, "auto")
		self.assertEqual(NORMALIZE.spill_pixel_count(shrunk), 0)

	def test_spill_metric_counts_visible_interior_pixels(self) -> None:
		image = Image.new("RGBA", (9, 9), (40, 40, 80, 255))
		image.putpixel((4, 4), (0, 75, 0, 255))
		self.assertEqual(NORMALIZE.spill_pixel_count(image), 1)
		cleaned = NORMALIZE.despill_green_edge(image, "auto")
		self.assertEqual(NORMALIZE.spill_pixel_count(cleaned), 0)

	def test_palette_none_preserves_source_colours(self) -> None:
		_, metrics = self.run_tool("fixed:1", extra=["--palette", "none", "--resample", "box", "--sharpen", "0"])
		assert metrics is not None
		self.assertEqual(metrics["summary"]["palette"], "none")
		self.assertEqual(metrics["summary"]["colour_count_range"], [3, 3])
		self.assertEqual(metrics["summary"]["palette_violations"], 0)

	def test_interior_detail_metric_distinguishes_flat_and_checker(self) -> None:
		flat = Image.new("RGBA", (9, 9), (120, 120, 120, 255))
		checker = Image.new("RGBA", (9, 9), (0, 0, 0, 255))
		pixels = checker.load()
		for y in range(9):
			for x in range(9):
				if (x + y) % 2:
					pixels[x, y] = (255, 255, 255, 255)
		self.assertEqual(NORMALIZE.interior_detail(flat), 0)
		self.assertGreater(NORMALIZE.interior_detail(checker), 0)
		self.assertEqual(NORMALIZE.colour_count(checker), 2)

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
