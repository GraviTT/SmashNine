import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
ROWS = {
	"jump": ("v1", 1, 128), "fall": ("v1", 1, 128), "hurt": ("v1", 1, 128),
	"shield": ("v1", 6, 128), "attack": ("v1", 6, 128),
	"mana_combo": ("v1", 6, 192), "rising_slash": ("v1", 6, 192),
	"low_sweep": ("v1", 6, 192), "air_slash": ("v3", 6, 192),
	"plunge": ("v3", 6, 192), "dimension_slash": ("v1", 6, 192),
	"rune_shield": ("v1", 6, 192), "infinity_overdrive": ("v1", 6, 192),
	"tumble": ("v1", 6, 192),
}


for row, (version, frames, cell) in ROWS.items():
	stem = f"rio_female-{row}-{version}"
	png = ROOT / f"art/bakeoff/rio/{stem}.png"
	meta = png.with_suffix(".json")
	assert png.exists() and meta.exists(), row
	image = Image.open(png).convert("RGBA")
	assert image.size == (cell * 6, cell), (row, image.size)
	assert set(image.getchannel("A").get_flattened_data()) <= {0, 255}, row
	payload = json.loads(meta.read_text(encoding="utf-8"))
	assert payload["frames"] == frames and "fps" in payload and "note" in payload, row
	if cell == 192:
		assert payload["cell"] == 192 and payload["feet"] == 152, row
	report = ROOT / f"reports/codex-art-61b/{row}"
	for name in ("prompt.txt", "compare.png", "metrics.json", "head_scale.json"):
		assert (report / name).exists(), report / name
	metrics = json.loads((report / "metrics.json").read_text(encoding="utf-8"))["summary"]
	assert metrics["frame_count"] == frames, row
	assert metrics["borders_clear"] and metrics["all_have_4px_margin"], row
	assert sum(metrics["remaining_spill_pixels"]) == 0, row
	assert metrics["interior_detail_range"][0] >= 73.0, row

assert not (ROOT / "art/bakeoff/rio/rio_female-walk-v3.png").exists()
walk = json.loads((ROOT / "reports/codex-art-61b/walk/metrics.json").read_text(encoding="utf-8"))
assert walk["measured"]["frame_3_planted_count"] == 2
assert walk["measured"]["frame_7_planted_count"] == 1
assert walk["judged_at_4x"]["delivered"] is False
print(f"validated {len(ROWS)} delivered rows; walk correctly withheld")
