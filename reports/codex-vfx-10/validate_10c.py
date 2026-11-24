"""Independent file audit for the seven VFX-10c candidates; no game imports."""
from pathlib import Path
from datetime import datetime
import argparse
import hashlib
import json
import math
import subprocess
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-vfx-10"
BASE = "e3998e9d7839d35f2b9ae9e848955e63e02bb5b0"
DEADLINE = datetime.fromisoformat("2026-11-24T16:16:59.042401+09:00")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pixel_data(im):
    return im.get_flattened_data() if hasattr(im, "get_flattened_data") else im.getdata()


def inspect(path, size, frames, fps, anchor, loop, replaces, blend):
    im = Image.open(path)
    data = json.loads(path.with_suffix(".json").read_text(encoding="utf-8"))
    w, h = size
    slices = [im.crop((k * w, 0, (k + 1) * w, h)).convert("RGBA") for k in range(frames)]
    pixels = [list(pixel_data(f)) for f in slices]
    counts = [sum(p[3] > 0 for p in px) for px in pixels]
    checks = {
        "rgba": im.mode == "RGBA",
        "strip_size": im.size == (w * frames, h),
        "alpha_binary": set(pixel_data(im.getchannel("A"))) <= {0, 255},
        "empty_1px_border": all(
            all(f.getpixel((x, y))[3] == 0 for x in range(w) for y in (0, h - 1)) and
            all(f.getpixel((x, y))[3] == 0 for y in range(h) for x in (0, w - 1)) for f in slices),
        "nonempty_frames": all(counts),
        "distinct_frames": len({hashlib.sha256(f.tobytes()).hexdigest() for f in slices}) == frames,
        "metadata": data["frames"] == frames and data["fps"] == fps and data["anchor"] == anchor
        and data["loop"] == loop and data["replaces"] == replaces and data["blend"] == blend
        and data["filter"] == "nearest" and data["frame_size"] == list(size),
        "korean_note": any("가" <= c <= "힣" for c in data["note"]),
    }
    metrics = {
        "frame_size": list(size), "strip_size": list(im.size), "frames": frames, "fps": fps,
        "anchor": anchor, "loop": loop, "blend": blend, "opaque_pixels": counts,
        "bbox_exclusive": [list(f.getbbox()) for f in slices],
        "opaque_colours": [len({p[:3] for p in px if p[3]}) for px in pixels],
    }
    return slices, data, checks, metrics


def angles(frame, bright=False, corners=False):
    values = []
    for y in range(frame.height):
        for x in range(49, frame.width):
            p = frame.getpixel((x, y))
            if p[3] == 0 or (bright and p[1] <= 140):
                continue
            if corners:
                for dx, dy in [(-.5, -.5), (-.5, .5), (.5, -.5), (.5, .5)]:
                    values.append(math.degrees(math.atan2(y + dy - 64, x + dx - 8)))
            else:
                values.append(math.degrees(math.atan2(y - 64, x - 8)))
    return [min(values), max(values)] if values else None


def union_angle(ranges):
    ranges = [a for a in ranges if a is not None]
    return [min(a[0] for a in ranges), max(a[1] for a in ranges)]


def append_result(results, path, checks, metrics):
    result = {
        "file": path.relative_to(ROOT).as_posix(),
        "status": "PASS" if all(checks.values()) else "FAIL",
        "checks": checks, "metrics": metrics, "sha256": sha(path),
    }
    results.append(result)
    print(result["status"], path.name, [name for name, ok in checks.items() if not ok])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check-only", action="store_true", help="Do not write the report JSON.")
    args = parser.parse_args()
    results = []
    for key in "jklui":
        path = ROOT / f"art/bakeoff/skill_icons/xion/xion_{key}-v1.png"
        frames, data, checks, metrics = inspect(path, (40, 40), 1, 0, [20, 20], False,
                                               f"assets/art/skill_icons/xion_{key}.png", "normal")
        checks["at_most_seven_opaque_colours"] = metrics["opaque_colours"][0] <= 7
        checks["native_hand_drawing"] = data["method"] == "Python + Pillow, hand-authored at native 40x40; no resampling"
        # Every exposed colour pixel is enclosed by the one-pixel dark outline.
        outline = (16, 21, 34)
        f = frames[0]
        checks["coloured_shape_has_dark_outer_border"] = all(
            all(f.getpixel((x + dx, y + dy))[3] for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            for y in range(1, 39) for x in range(1, 39)
            if f.getpixel((x, y))[3] and f.getpixel((x, y))[:3] != outline)
        checks["comparison_boards"] = all((REPORT / name).is_file() for name in
                                            ("icons-10c.png", "icons-10c-1x-4x.png"))
        append_result(results, path, checks, metrics)

    for variant in "ab":
        path = ROOT / f"art/bakeoff/effects/xion/xion_blast-{variant}-v2.png"
        source = path.with_name(f"xion_blast-{variant}-v1.png")
        old_sheet = Image.open(source).convert("RGBA")
        old = [old_sheet.crop((k * 256, 0, (k + 1) * 256, 128)) for k in range(6)]
        frames, data, checks, metrics = inspect(path, (256, 128), 6, 30, [8, 64], False,
                                               "assets/art/effects/xion_blast.png", "additive")
        metrics["pixel_centre_angles_by_frame_deg"] = [angles(f) for f in frames]
        metrics["pixel_corner_angles_by_frame_deg"] = [angles(f, corners=True) for f in frames]
        metrics["legacy_bright_angles_by_frame_deg"] = [angles(f, bright=True) for f in frames]
        metrics["all_pixel_centre_spread_deg"] = union_angle(metrics["pixel_centre_angles_by_frame_deg"])
        metrics["all_pixel_corner_spread_deg"] = union_angle(metrics["pixel_corner_angles_by_frame_deg"])
        metrics["legacy_bright_spread_deg"] = union_angle(metrics["legacy_bright_angles_by_frame_deg"])
        metrics["v1_all_pixel_centre_spread_deg"] = union_angle([angles(f) for f in old])
        metrics["v1_legacy_bright_spread_deg"] = union_angle([angles(f, bright=True) for f in old])
        metrics["max_reach_from_anchor_px"] = max(f.getbbox()[2] - 1 - 8 for f in frames)
        metrics["duration_seconds"] = 6 / 30
        metrics["source_png_sha256"] = sha(source)
        checks["all_pixel_centres_within_14deg_after_x48"] = all(abs(a) <= 14 for a in metrics["all_pixel_centre_spread_deg"])
        checks["all_pixel_corners_within_14deg_after_x48"] = all(abs(a) <= 14 for a in metrics["all_pixel_corner_spread_deg"])
        checks["legacy_bright_pixels_within_14deg"] = all(abs(a) <= 14 for a in metrics["legacy_bright_spread_deg"])
        checks["first_flash_unchanged"] = frames[0].tobytes() == old[0].tobytes()
        checks["muzzle_x_through_32_unchanged"] = all(
            f.crop((0, 0, 33, 128)).tobytes() == o.crop((0, 0, 33, 128)).tobytes()
            for f, o in zip(frames, old))
        checks["same_occupied_x_columns"] = all(
            [any(f.getpixel((x, y))[3] for y in range(128)) for x in range(256)] ==
            [any(o.getpixel((x, y))[3] for y in range(128)) for x in range(256)]
            for f, o in zip(frames, old))
        checks["same_reach"] = metrics["max_reach_from_anchor_px"] == max(f.getbbox()[2] - 1 - 8 for f in old)
        checks["only_original_colours_per_frame"] = all(
            {p for p in pixel_data(f) if p[3]} <= {p for p in pixel_data(o) if p[3]}
            for f, o in zip(frames, old))
        checks["source_hash_matches_metadata"] = data["source_sha256"] == sha(source)
        checks["v1_png_matches_base_commit"] = source.read_bytes() == subprocess.check_output(
            ["git", "show", f"{BASE}:{source.relative_to(ROOT).as_posix()}"], cwd=ROOT)
        checks["v1_png_and_json_unmodified"] = not subprocess.check_output(
            ["git", "diff", BASE, "--name-only", "--", str(source), str(source.with_suffix(".json"))], cwd=ROOT).strip()
        checks["both_frame_boards"] = all((REPORT / f"xion_blast-{variant}-v2-{scale}x.png").is_file() for scale in (1, 4))
        append_result(results, path, checks, metrics)
        print(variant.upper(), "centres", metrics["all_pixel_centre_spread_deg"],
              "corners", metrics["all_pixel_corner_spread_deg"], "reach", metrics["max_reach_from_anchor_px"])

    product_diff = subprocess.check_output(["git", "diff", BASE, "--name-only", "--", "smash-nine-prototype"], cwd=ROOT).decode().strip()
    report = {
        "run": "codex/vfx-10c", "base_commit": BASE,
        "started_kst": "2026-11-24T14:46:59.042401+09:00",
        "deadline_kst": DEADLINE.isoformat(), "validated_at": datetime.now().astimezone().isoformat(),
        "angle_measurement": "atan2(y-64,x-8), opaque pixels x>48; additional four-corner and legacy green>140 checks",
        "production_diff": product_diff, "live_godot_test": False,
        "results": results,
        "summary": {"PASS": sum(r["status"] == "PASS" for r in results),
                    "FAIL": sum(r["status"] == "FAIL" for r in results)},
    }
    if not args.check_only:
        if datetime.now().astimezone() >= DEADLINE:
            raise SystemExit("HARD STOP: no new report; only README/commit script may be finished.")
        (REPORT / "validation-10c.json").write_text(
            json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("SUMMARY", report["summary"], "product diff:", repr(product_diff))
    if report["summary"]["FAIL"] or product_diff:
        sys.exit(1)


if __name__ == "__main__":
    main()
