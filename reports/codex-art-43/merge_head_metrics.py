import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
for metrics_path in sorted(ROOT.glob("*/metrics.json")):
	head_path = metrics_path.with_name("head-scale.json")
	if not head_path.exists():
		continue
	metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
	head = json.loads(head_path.read_text(encoding="utf-8"))[0]
	metrics["head_scale"] = {
		"anchor": "art/bakeoff/luna/luna-idle-v3.png:0" if metrics_path.parent.name != "idle" else "smash-nine-prototype/assets/art/luna/luna_sheet.png:0",
		"median": head.get("median"),
		"used_frames": head.get("used"),
		"per_frame": head.get("frames"),
		"head_matched_factor": head.get("head_matched_factor"),
		"note": "회전 프레임은 자동 측정에서 제외하고 4배 비교판으로 판정" if metrics_path.parent.name in {"moon_ring", "tumble"} else "자동 측정 중앙값과 4배 비교판을 함께 확인",
	}
	metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
