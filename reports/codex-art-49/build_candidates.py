from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PYTHON = Path("C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe")
NORMALIZE = ROOT / "tools/sprite_pipeline/normalize.py"
HEAD_SCALE = ROOT / "tools/sprite_pipeline/head_scale.py"
ANCHOR = ROOT / "art/bakeoff/yuki/yuki-idle-v2.png"
REFERENCE = ROOT / "smash-nine-prototype/assets/art/yuki/yuki_sheet.png"


CONFIGS = {
    "walk": {"raw": "walk", "grid": "3x2", "cell": 128, "ground": True},
    "jump": {"raw": "jump-fall-hurt", "grid": "3x1", "pick": "0", "cell": 128, "lift": 12},
    "fall": {"raw": "jump-fall-hurt", "grid": "3x1", "pick": "1", "cell": 128, "lift": 12},
    "hurt": {"raw": "jump-fall-hurt", "grid": "3x1", "pick": "2", "cell": 128, "ground": True, "offset": -5},
    "shield": {"raw": "shield", "grid": "3x2", "cell": 128, "ground": True},
    "talisman_side": {"raw": "talisman_side", "grid": "3x2", "cell": 192, "ground": True},
    "talisman_up": {"raw": "talisman_up", "grid": "3x2", "cell": 192, "ground": True},
    "ground_ward": {"raw": "ground_ward", "grid": "3x2", "cell": 192, "ground": True},
    "talisman_air_side": {"raw": "talisman_air_side", "grid": "3x2", "cell": 192, "lift": 12},
    "talisman_air_down": {"raw": "talisman_air_down", "grid": "3x2", "cell": 192, "lift": 12},
    "seal_place": {"raw": "seal_place", "grid": "3x2", "cell": 192, "ground": True},
    "seal_activate": {"raw": "seal_activate", "grid": "3x2", "cell": 192, "ground": True},
    "grand_ward": {"raw": "grand_ward", "grid": "3x2", "cell": 192, "ground": True},
    "tumble": {"raw": "tumble", "grid": "3x2", "cell": 192, "lift": 12},
}
VERSIONS = {"talisman_side": 3}


def run(args: list[str]) -> None:
    subprocess.run([str(PYTHON), *args], cwd=ROOT, check=True)


def normalize_args(name: str, cfg: dict, out_dir: Path, scale_by: str, candidate: Path | None = None) -> list[str]:
    raw = ROOT / "art/raw/yuki-49" / cfg["raw"] / "raw.png"
    args = [
        str(NORMALIZE), "--sheet", str(raw), "--grid", cfg["grid"],
        "--bg", "#00ff00", "--cell", str(cfg["cell"]),
        "--scale-by", scale_by, "--resample", "lanczos", "--sharpen", "60",
        "--despill", "auto", "--palette", "none",
        "--reference", f"{REFERENCE}:0:4", "--compare-scale", "4",
        "--title", f"YUKI {name.upper()}", "--out-dir", str(out_dir),
        "--name", f"yuki-{name}-v1",
    ]
    if "pick" in cfg:
        args += ["--pick", cfg["pick"]]
    if cfg.get("ground"):
        args.append("--ground-all")
    if cfg.get("lift"):
        args += ["--lift-all", str(cfg["lift"])]
    if cfg.get("offset"):
        args += ["--offset-x", str(cfg["offset"])]
    if cfg["cell"] == 192:
        args += ["--feet-y", "152"]
    if candidate is not None:
        args += ["--candidate-out", str(candidate)]
    return args


def probe_and_factor(name: str, cfg: dict) -> tuple[float, dict]:
    probe_dir = ROOT / "art/raw/yuki-49" / cfg["raw"] / f"probe-{name}"
    probe_target = 100
    while True:
        try:
            run(normalize_args(name, cfg, probe_dir, f"height:{probe_target}"))
            break
        except subprocess.CalledProcessError:
            probe_target -= 4
            if probe_target < 72:
                raise
    metrics = json.loads((probe_dir / "metrics.json").read_text(encoding="utf-8"))
    probe_factor = float(metrics["summary"]["common_scale"])
    head_json = probe_dir / "head-scale.json"
    run([
        str(HEAD_SCALE), "--anchor", f"{ANCHOR}:0", "--sheet", str(probe_dir / f"yuki-{name}-v1.png"),
        "--factor", str(probe_factor), "--json", str(head_json),
    ])
    head = json.loads(head_json.read_text(encoding="utf-8"))[0]
    if int(head.get("used", 0)) >= 2 and head.get("head_matched_factor"):
        factor = float(head["head_matched_factor"])
        method = "head_scale"
    else:
        # Card fallback: put a standing/whole-body frame near the 89–91 px anchor height.
        # This is only a numeric starting point; the 4x board is still inspected by eye.
        heights = metrics["summary"]["body_height_range"]
        middle = (float(heights[0]) + float(heights[1])) / 2.0
        factor = probe_factor * 90.0 / middle
        method = "height_and_4x_crop"
    return factor, {
        "probe_factor": probe_factor,
        "probe_target_height": probe_target,
        "factor_method": method,
        "head_scale": head,
    }


def final_row(name: str, cfg: dict, factor: float, head_info: dict) -> dict:
    out_dir = ROOT / "reports/codex-art-49" / name
    out_dir.mkdir(parents=True, exist_ok=True)
    version = VERSIONS.get(name, 1)
    candidate = ROOT / "art/bakeoff/yuki" / f"yuki-{name}-v{version}.png"
    requested_factor = factor
    while True:
        try:
            run(normalize_args(name, cfg, out_dir, f"fixed:{factor:.8f}", candidate))
        except subprocess.CalledProcessError:
            factor *= 0.98
            if factor < requested_factor * 0.75:
                raise
            continue
        fit_metrics = json.loads((out_dir / "metrics.json").read_text(encoding="utf-8"))
        if fit_metrics["summary"]["borders_clear"] and fit_metrics["summary"]["all_have_4px_margin"]:
            break
        factor *= 0.98
        if factor < requested_factor * 0.75:
            raise RuntimeError(f"{name}: unable to obtain the required 4px margin")
    metrics_path = out_dir / "metrics.json"
    metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
    metrics["head_measurement"] = head_info
    metrics["fit_adjustment"] = {
        "requested_factor": requested_factor,
        "used_factor": factor,
        "reduced_to_fit": factor < requested_factor - 1e-6,
    }
    metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return metrics


def main() -> None:
    force_rows = {item for item in os.environ.get("YUKI49_FORCE_ROWS", "").split(",") if item}
    all_results = {}
    factors = {}
    heads = {}
    for name, cfg in CONFIGS.items():
        metrics_path = ROOT / "reports/codex-art-49" / name / "metrics.json"
        version = VERSIONS.get(name, 1)
        candidate_path = ROOT / "art/bakeoff/yuki" / f"yuki-{name}-v{version}.png"
        if name not in force_rows and metrics_path.exists() and candidate_path.exists():
            metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
            factors[name] = float(metrics["summary"]["common_scale"])
            heads[name] = metrics.get("head_measurement", {})
            all_results[name] = metrics
        else:
            factor, head_info = probe_and_factor(name, cfg)
            factors[name] = factor
            heads[name] = head_info
            all_results[name] = final_row(name, cfg, factor, head_info)

    # Base attack is the same talisman_side raw and factor, but in a 128px cell.
    attack_cfg = dict(CONFIGS["talisman_side"])
    attack_cfg["cell"] = 128
    attack_cfg["offset"] = -1
    attack_out = ROOT / "reports/codex-art-49/attack"
    attack_out.mkdir(parents=True, exist_ok=True)
    factor = factors["talisman_side"]
    for _ in range(30):
        try:
            run(normalize_args("attack", attack_cfg, attack_out, f"fixed:{factor:.8f}", ROOT / "art/bakeoff/yuki/yuki-attack-v1.png"))
        except subprocess.CalledProcessError:
            factor *= 0.98
            continue
        metrics = json.loads((attack_out / "metrics.json").read_text(encoding="utf-8"))
        if metrics["summary"]["borders_clear"] and metrics["summary"]["all_have_4px_margin"]:
            break
        factor *= 0.98
    metrics["head_measurement"] = heads["talisman_side"]
    metrics["attack_fit"] = {
        "source": "talisman_side raw",
        "head_matched_factor": factors["talisman_side"],
        "used_factor": factor,
        "reduced_to_fit": factor < factors["talisman_side"] - 1e-6,
    }
    (attack_out / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    all_results["attack"] = metrics

    summary = {}
    for name, metrics in all_results.items():
        s = metrics["summary"]
        h = metrics.get("head_measurement", {})
        hs = h.get("head_scale", {})
        summary[name] = {
            "factor": s["common_scale"],
            "factor_method": h.get("factor_method"),
            "head_median_probe": hs.get("median"),
            "head_reliable_frames": hs.get("used"),
            "body_height_range": s["body_height_range"],
            "detail_range": s["interior_detail_range"],
            "detail_mean": s["interior_detail_mean"],
            "spill": s["remaining_spill_pixels"],
            "border": s["borders_clear"],
            "margin4": s["all_have_4px_margin"],
            "lift_range": s["lift_range"],
        }
    (ROOT / "reports/codex-art-49/summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
