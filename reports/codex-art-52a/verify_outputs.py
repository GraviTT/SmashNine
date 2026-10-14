import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-art-52a"
BAKEOFF = ROOT / "art/bakeoff/nova"
ROWS = {
	"walk": (6, 128, True),
	"jump": (1, 128, False),
	"fall": (1, 128, False),
	"hurt": (1, 128, False),
	"shield": (6, 128, True),
	"attack": (6, 128, True),
	"vector_side": (6, 192, True),
	"vector_upper": (6, 192, True),
	"compression_stomp": (6, 192, True),
	"air_side": (6, 192, True),
	"meteor_kick": (6, 192, True),
	"vector_shift": (6, 192, True),
	"gravity_brake": (6, 192, True),
	"slingshot_start": (6, 192, True),
	"tumble": (6, 192, False),
}


for row, (frames, cell, numeric_head) in ROWS.items():
	png = BAKEOFF / f"nova_male-{row}-v1.png"
	metadata = BAKEOFF / f"nova_male-{row}-v1.json"
	with Image.open(png) as image:
		assert image.size == (6 * cell, cell), (row, image.size)
		assert image.mode == "RGBA", (row, image.mode)
	data = json.loads(metadata.read_text(encoding="utf-8"))
	assert data["frames"] == frames
	if cell == 192:
		assert data["cell"] == 192 and data["feet"] == 152
	row_dir = REPORT / row
	for required in ("prompt.txt", "compare.png", "metrics.json", "head-scale.json"):
		assert (row_dir / required).is_file(), (row, required)
	metrics = json.loads((row_dir / "metrics.json").read_text(encoding="utf-8"))
	summary = metrics["summary"]
	assert summary["frame_count"] == frames
	assert summary["borders_clear"] and summary["all_have_4px_margin"]
	assert summary["alpha_binary"]
	assert min(summary["interior_detail_range"]) >= 84
	assert max(summary["remaining_spill_pixels"]) == 0
	if numeric_head:
		head = metrics["head_check"]["result"]
		assert head["used"] >= 2
		assert 0.96 <= head["median"] <= 1.04, (row, head["median"])
	else:
		assert metrics["head_check"]["method"] == "4x_head_crop"
		assert (row_dir / "head-crops.png").is_file()

commit = (REPORT / "commit.ps1").read_text(encoding="utf-8")
assert "git add -f" not in commit
assert "art/raw/" not in commit
assert commit.rstrip().endswith('Co-Authored-By: Codex <noreply@openai.com>\"')
print(f"verified {len(ROWS)} rows")
