import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
BAKE = ROOT / "art" / "bakeoff" / "luna"
REPORT = ROOT / "reports" / "codex-art-43"

expected = {
	"luna-idle-v3.png": (768, 128),
	"luna-walk-v1.png": (768, 128),
	"luna-jump-v1.png": (128, 128),
	"luna-fall-v1.png": (128, 128),
	"luna-hurt-v1.png": (128, 128),
	"luna-star_side-v1.png": (1152, 192),
	"luna-shield-v1.png": (768, 128),
	"luna-star_up-v1.png": (1152, 192),
	"luna-star_down-v1.png": (1152, 192),
	"luna-star_comet-v1.png": (1152, 192),
	"luna-moon_ring-v1.png": (1152, 192),
	"luna-tumble-v1.png": (1152, 192),
}

for name, size in expected.items():
	path = BAKE / name
	assert path.exists(), path
	with Image.open(path) as image:
		assert image.size == size, (name, image.size, size)
		assert image.mode == "RGBA", (name, image.mode)
	json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))

for metrics_path in sorted(REPORT.glob("*/metrics.json")):
	metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
	summary = metrics["summary"]
	assert summary["borders_clear"], metrics_path
	assert summary["all_have_4px_margin"], metrics_path
	assert summary["alpha_binary"], metrics_path
	assert min(summary["remaining_spill_pixels"]) == max(summary["remaining_spill_pixels"]) == 0, metrics_path
	assert summary["interior_detail_range"][0] >= 90.0, (metrics_path, summary["interior_detail_range"])
	head = metrics["head_scale"]
	if metrics_path.parent.name != "tumble":
		assert 0.96 <= head["median"] <= 1.04, (metrics_path, head["median"])

assert (REPORT / "overview.png").exists()
assert len(list(REPORT.glob("*/compare.png"))) == 10
print(f"AUDIT_OK candidates={len(expected)} metrics={len(list(REPORT.glob('*/metrics.json')))} compares=10")
