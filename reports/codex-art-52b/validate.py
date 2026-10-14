import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
ROWS = {
	"walk": ("v1", 6, 128),
	"jump": ("v1", 1, 128),
	"fall": ("v1", 1, 128),
	"hurt": ("v1", 1, 128),
	"shield": ("v1", 6, 128),
	"attack": ("v1", 6, 128),
	"vector_side": ("v3", 6, 192),
	"vector_upper": ("v1", 6, 192),
	"compression_stomp": ("v1", 6, 192),
	"air_side": ("v1", 6, 192),
	"meteor_kick": ("v1", 6, 192),
	"vector_shift": ("v1", 6, 192),
	"gravity_brake": ("v1", 6, 192),
	"slingshot_start": ("v1", 6, 192),
	"tumble": ("v1", 6, 192),
}


for row, (version, frames, cell) in ROWS.items():
	stem = f"nova_female-{row}-{version}"
	png_path = ROOT / f"art/bakeoff/nova/{stem}.png"
	meta_path = png_path.with_suffix(".json")
	assert png_path.exists(), png_path
	assert meta_path.exists(), meta_path
	image = Image.open(png_path).convert("RGBA")
	# normalize.py always emits the six-column strip contract, including one-pose rows.
	assert image.size == (cell * 6, cell), (row, image.size)
	alpha_values = {value for _, value in image.getchannel("A").getcolors(maxcolors=256)}
	assert alpha_values <= {0, 255}, row
	meta = json.loads(meta_path.read_text(encoding="utf-8"))
	assert meta["frames"] == frames, row
	assert "note" in meta and "fps" in meta, row
	if cell == 192:
		assert meta["cell"] == 192 and meta["feet"] == 152, row

	row_report = REPORT / row
	for name in ("prompt.txt", "compare.png", "metrics.json", "head_scale.json"):
		assert (row_report / name).exists(), row_report / name
	metrics = json.loads((row_report / "metrics.json").read_text(encoding="utf-8"))
	summary = metrics["summary"]
	assert summary["frame_count"] == frames, row
	assert summary["borders_clear"] is True, row
	assert summary["all_have_4px_margin"] is True, row
	assert sum(summary["remaining_spill_pixels"]) == 0, row
	assert summary["interior_detail_range"][0] >= 79.0, row

print(f"validated {len(ROWS)} rows: dimensions, metadata, alpha, margins, spill and detail")
