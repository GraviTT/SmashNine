"""Reproducible sprite/effect/clip measurements for CODEX-QA-19.

Run from the repository root with the bundled Python that has Pillow and NumPy.
Only writes under reports/codex-qa-19/.  Measurements derived from alpha are exact;
`head_height_proxy` is explicitly a heuristic around the largest face-coloured component.
"""
from __future__ import annotations

import hashlib
import json
import math
import re
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageSequence


ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / "smash-nine-prototype"
ART = PROJECT / "assets" / "art"
OUT = ROOT / "reports" / "codex-qa-19"
BOARDS = OUT / "boards"

BASE_ROWS = [
	("idle", 6, 6.3, True), ("walk", 8, 13.3, True),
	("jump", 1, 1.0, False), ("fall", 1, 1.0, False),
	("attack", 6, 21.0, False), ("shield", 6, 12.0, False),
	("hurt", 1, 1.0, False),
]

MOVE_ROWS = {
	"frey": [
		("attack_up", 6, 21.0, False), ("attack_down", 6, 21.0, False),
		("attack_air_side", 6, 21.0, False), ("dash_strike", 6, 21.0, False),
		("rising_cleave", 6, 16.8, False), ("spike_followup", 6, 21.0, False),
		("descent", 6, 14.0, False), ("tumble", 6, 21.0, True),
		("attack_chain", 6, 21.0, False),
	],
	"luna": [
		("star_up", 6, 21.0, False), ("star_down", 6, 21.0, False),
		("star_comet", 6, 21.0, False), ("moon_ring", 6, 16.8, False),
		("transform", 12, 12.0, False), ("tumble", 6, 21.0, True),
		("star_side", 6, 21.0, False),
	],
	"luna_brave": [
		("brave_combo", 6, 16.0, False), ("brave_upper", 6, 24.0, False),
		("brave_low", 6, 24.0, False), ("brave_air_side", 6, 24.0, False),
		("brave_dive", 6, 24.0, False), ("comet_drive", 6, 24.0, False),
		("luna_breaker", 6, 16.0, False), ("heart_laser", 6, 12.0, False),
		("tumble", 6, 21.0, True),
	],
	"yuki": [
		("talisman_side", 6, 28.5, False), ("talisman_up", 6, 25.0, False),
		("ground_ward", 6, 23.1, False), ("talisman_air_side", 6, 33.3, False),
		("talisman_air_down", 6, 22.2, False), ("seal_place", 6, 18.7, False),
		("seal_activate", 6, 19.2, False), ("grand_ward", 6, 9.7, False),
		("tumble", 6, 21.0, True),
	],
	"nova": [
		("vector_side", 6, 35.25, False), ("vector_upper", 6, 33.0, False),
		("compression_stomp", 6, 26.1, False), ("air_side", 6, 40.0, False),
		("meteor_kick", 6, 30.0, False), ("vector_shift", 6, 27.3, False),
		("gravity_brake", 6, 14.3, False), ("slingshot_start", 6, 14.0, False),
		("tumble", 6, 21.0, True),
	],
	"rio": [
		("mana_combo", 6, 18.0, False), ("rising_slash", 6, 30.0, False),
		("low_sweep", 6, 30.0, False), ("air_slash", 6, 40.0, False),
		("plunge", 6, 12.0, False), ("dimension_slash", 6, 23.0, False),
		("rune_shield", 6, 12.0, False), ("infinity_overdrive", 6, 11.0, False),
		("tumble", 6, 21.0, True),
	],
}

FORMS = {
	"frey": {
		"prefix": "frey", "body": "default", "ratio_target": 3.0,
		"base": ART / "frey/frey_sheet.png", "moves": ART / "frey/frey_moves_sheet.png",
	},
	"luna": {
		"prefix": "luna", "body": "default", "ratio_target": 2.2,
		"base": ART / "luna/luna_sheet.png", "moves": ART / "luna/luna_moves_sheet.png",
	},
	"luna_brave": {
		"prefix": "luna_brave", "body": "default", "ratio_target": 2.2,
		"base": ART / "luna/luna_brave_sheet.png", "moves": ART / "luna/luna_brave_moves_sheet.png",
	},
	"yuki": {
		"prefix": "yuki", "body": "default", "ratio_target": 2.5,
		"base": ART / "yuki/yuki_sheet.png", "moves": ART / "yuki/yuki_moves_sheet.png",
	},
	"nova_male": {
		"prefix": "nova", "body": "male", "ratio_target": 2.5,
		"base": ART / "nova/nova_male_sheet.png", "moves": ART / "nova/nova_male_moves_sheet.png",
	},
	"nova_female": {
		"prefix": "nova", "body": "female", "ratio_target": 2.5,
		"base": ART / "nova/nova_female_sheet.png", "moves": ART / "nova/nova_female_moves_sheet.png",
	},
	"rio_male": {
		"prefix": "rio", "body": "male", "ratio_target": 3.0,
		"base": ART / "rio/rio_male_sheet.png", "moves": ART / "rio/rio_male_moves_sheet.png",
	},
	"rio_female": {
		"prefix": "rio", "body": "female", "ratio_target": 3.0,
		"base": ART / "rio/rio_female_sheet.png", "moves": ART / "rio/rio_female_moves_sheet.png",
	},
}

# Generated source of truth, parsed separately from MotionSpeeds.gd at run time.
FPS_RE = re.compile(r'^\s*"([^"]+)":\s*([0-9.]+)')

RELEVANT_VFX = {
	"frey_ult_charge", "frey_ult_wave", "yuki_ult_seal", "yuki_ult_burst",
	"luna_ult_transform", "luna_ult_laser", "luna_ult_laser_head",
	"nova_ult_core", "nova_ult_burst", "rio_ult_circle", "rio_ult_impact",
	"frey_slash", "frey_k", "frey_l", "yuki_slash", "yuki_k", "yuki_l",
	"luna_slash", "luna_k", "luna_l", "luna_brave_slash",
	"nova_slash", "nova_k", "nova_l", "rio_slash", "rio_k", "rio_l",
	"yuki_seal_idle", "parry_flash", "landing_dust", "hit_streak", "yuki_seal_break",
	"luna_star_bloom", "luna_moon_ring", "luna_brave_aura", "luna_comet_trail",
	"luna_comet_burst", "nova_gravity_burst", "nova_momentum_trail",
	"nova_vector_streak", "nova_shift_dash", "nova_shift_ready", "nova_impact_star",
	"nova_launch_flash", "rio_rune_guard", "rio_rune_burst", "rio_blink_trail",
	"yuki_grand_ward", "guard_bubble", "attack_afterimage",
}

DIRECT_EFFECTS = {
	"frey_pursuit_mark": ART / "effects/passive/frey_pursuit_mark.png",
	"frey_spike_ring": ART / "effects/passive/frey_spike_ring.png",
	"luna_star_charge": ART / "effects/passive/luna_star_charge.png",
	"luna_star_projectile": ART / "effects/luna_star.png",
	"yuki_talisman": ART / "effects/yuki_talisman.png",
	"rio_mana_wave": ART / "effects/rio_mana_wave.png",
	"rio_gem_sword": ART / "effects/rio_gem_sword.png",
	"hit_frey": ART / "effects/hit/frey_hit.png",
	"hit_luna": ART / "effects/hit/luna_hit.png",
	"hit_luna_brave": ART / "effects/hit/luna_brave_hit.png",
	"hit_yuki": ART / "effects/hit/yuki_hit.png",
	"hit_nova": ART / "effects/hit/nova_hit.png",
	"hit_rio": ART / "effects/hit/rio_hit.png",
	"status_stun": ART / "ui/status/stun.png",
	"status_super_armor": ART / "ui/status/super_armor.png",
}

# Runtime placement notes.  Values in backticks are deliberately kept as code
# expressions when their world size is dynamic.  Exact draw sites are collected
# below, so the inventory can be checked against the current implementation.
PLACEMENT = {
	"slash": {"centre": "global_position + GameScale.BODY_CENTRE", "size": "uniform reach / AUTHORED_WIDTH (clamped 0.5..3), then Vfx divides by source ratio", "rotation": "aim.angle(); flip_v when aim.x < 0", "layer": 5, "alpha": 1.0, "owner": "PlayerBase._draw_attack_art"},
	"hit": {"centre": "hit_position", "size": "2 * clamp(18 + 1.35*damage + 0.035*knockback, 24..56) * COMBAT", "rotation": "none", "layer": 4, "alpha": 1.0, "owner": "PlayerBase._spawn_hit_effect"},
	"status": {"centre": "local (0, -121 + sin(phase)*2)", "size": "native 24x24", "rotation": "none", "layer": 7, "alpha": 1.0, "owner": "PlayerBase._update_status_icon"},
}

PLACEMENT_BY_ID = {
	**{name: "slash" for name in ("frey_slash", "luna_slash", "luna_brave_slash", "nova_slash", "rio_slash", "yuki_slash")},
	**{name: "hit" for name in ("hit_frey", "hit_luna", "hit_luna_brave", "hit_yuki", "hit_nova", "hit_rio")},
	"status_stun": "status", "status_super_armor": "status",
}

PLACEMENT_NOTES = {
	"guard_bubble": ["local (0,-58) + right*24, rotated to guard direction", "native 128 square", "direction angle", 5, "0.48 + damage_reduction*0.52"],
	"parry_flash": ["global_position + (0,-32)", "native 128 square", "none", 5, "1; additive"],
	"landing_dust": ["global_position (feet)", "native 96x32", "none", 4, "1"],
	"hit_streak": ["hit_position", "x = slash_length/160, y = 1", "random", 4, "1; additive"],
	"attack_afterimage": ["Attack.global_position", "visual.size / (150,56)", "attack rotation", 1, "tint alpha 0.55"],
	"frey_pursuit_mark": ["target.global_position + (0,-118)", "native 64x40", "none", 6, "0.55..1 pulse"],
	"frey_spike_ring": ["local (0,-40)", "native 96x96", "none", 6, "1"],
	"luna_star_charge": ["local orbit centred (0,-44), radius 44", "native 18x18 per star", "orbit rotation", 5, "1"],
	"luna_star_projectile": ["projectile centre", "projectile art scale * COMBAT", "flight direction", "projectile layer", "1"],
	"yuki_talisman": ["projectile centre", "projectile size/art scale * COMBAT", "flight direction", "projectile layer", "1"],
	"rio_mana_wave": ["projectile centre", "projectile art scale", "flight direction", "projectile layer", "1"],
	"rio_gem_sword": ["orbit/projectile centre", "native 96x32", "orbit or flight direction", "orbit/projectile layer", "1; colour tint"],
	"frey_k": ["body centre", "(172*COMBAT+58)/224 uniform", "dash direction", 5, "1"],
	"frey_l": ["global +(44*COMBAT*facing,0)", "(136*COMBAT+58)/192 uniform", "flip_h by facing", 5, "1"],
	"frey_ult_charge": ["global_position (feet origin)", "1.3*sqrt(COMBAT) uniform", "none", 4, "1; additive"],
	"frey_ult_wave": ["global +(18*facing,2), aftershock +(10*facing,2)", "(facing,1)*COMBAT; aftershock (0.85*facing,1.45)*COMBAT", "horizontal mirror by scale", 4, "1; additive"],
	"luna_k": ["comet.global_position", "0.75*COMBAT uniform", "flight direction", 5, "1"],
	"luna_l": ["body centre", "(180+44)*COMBAT/192 uniform", "none", 5, "1"],
	"luna_star_bloom": ["global_position + attack offset", "art_scale derived from attack radius", "none", 6, "caller colour alpha (normally 0.82)"],
	"luna_moon_ring": ["global +(0,-34)", "radius*2.16/204 uniform", "none", 5, "1"],
	"luna_brave_aura": ["local transformation aura origin", "native 128 square", "none", "aura parent", "parent fades in last second"],
	"luna_comet_trail": ["comet global_position", "native 48 square", "flight direction", 4, "1"],
	"luna_comet_burst": ["comet global_position", "native 224 square", "none", 6, "1"],
	"luna_ult_transform": ["local (0,-42)", "1.4*COMBAT uniform", "none", 5, "1"],
	"luna_ult_laser": ["beam centre, tiled across beam_length", "beam_length x beam height", "beam direction", "beam node", "1"],
	"luna_ult_laser_head": ["local (beam_length/2,0)", "1.3*COMBAT uniform", "beam direction via parent", 1, "1"],
	"nova_k": ["body centre - direction*90", "1.2 uniform", "shift direction", 5, "1"],
	"nova_l": ["global_position", "radius*COMBAT*2/192 uniform", "none", 5, "1"],
	"nova_gravity_burst": ["burst local origin", "radius*2/232 uniform", "none", 1, "caller alpha"],
	"nova_momentum_trail": ["global +(0,-32)", "native 64x32", "velocity/impact direction", 2, "momentum 0.5..0.78"],
	"nova_vector_streak": ["global +(0,-32)+direction*length/2", "(length/180, 0.55..1)", "direction", 5, "momentum 0.5..0.78"],
	"nova_shift_dash": ["global +(0,-32)-direction*26", "(52/88,1)", "direction", 4, "1"],
	"nova_shift_ready": ["global +(0,-32)", "102/116 uniform", "none", 6, "1"],
	"nova_impact_star": ["impact world_position", "radius*2.4/230 uniform", "none", 7, "caller alpha 0.72..0.78"],
	"nova_launch_flash": ["global +(0,-32)+direction*90", "(180/238,1)", "direction", 6, "1"],
	"nova_ult_core": ["singularity local origin", "1.1*COMBAT uniform", "none", 0, "1"],
	"nova_ult_burst": ["core point / global +(0,-30)", "radius*COMBAT*2.2/256 uniform", "none", 6, "1; one call tinted"],
	"rio_k": ["start + body centre", "max(travel/256,0.5) uniform", "travel direction", 5, "1"],
	"rio_l": ["local (14*facing,-36)", "1.3 uniform", "facing", 5, "1"],
	"rio_rune_guard": ["local (0,-34)", "native 128 square", "none", 3, "1"],
	"rio_rune_burst": ["counter burst centre", "288/270 uniform", "none", 4, "1"],
	"rio_blink_trail": ["midpoint(from,to)+(0,-34)", "(travel/238,1)", "travel direction", 2, "1"],
	"rio_ult_circle": ["local (0,-36)", "0.85*COMBAT uniform", "none", -1, "1"],
	"rio_ult_impact": ["projectile impact point", "projectile impact scale", "none", "projectile effect layer", "projectile tint"],
	"yuki_k": ["seal global +(0,-4)", "1.1 uniform", "none", 5, "1"],
	"yuki_l": ["seal/talisman impact global", "burst diameter / 192", "none", "5 or 6", "1"],
	"yuki_seal_idle": ["seal local origin", "native 64 square", "none", "seal child", "remaining-life fade"],
	"yuki_seal_break": ["seal global_position", "native 96 square", "none", 5, "1"],
	"yuki_grand_ward": ["ward local origin", "native 640 square", "none", 0, "SEAL_ACTIVE_ALPHA"],
	"yuki_ult_seal": ["ward local origin", "FIELD_RADIUS*2/256 uniform", "none", 0, "SEAL_WARNING_ALPHA"],
	"yuki_ult_burst": ["ward global_position", "FIELD_RADIUS*2/256 uniform", "none", 4, "1"],
}


def load_font(size: int = 16) -> ImageFont.ImageFont:
	for candidate in [Path("C:/Windows/Fonts/consola.ttf"), Path("C:/Windows/Fonts/arial.ttf")]:
		if candidate.exists():
			return ImageFont.truetype(str(candidate), size)
	return ImageFont.load_default()


FONT = load_font(16)
FONT_SMALL = load_font(13)


def adopted_fps() -> dict[str, float]:
	result: dict[str, float] = {}
	for line in (PROJECT / "characters/common/MotionSpeeds.gd").read_text(encoding="utf-8").splitlines():
		match = FPS_RE.match(line)
		if match:
			result[match.group(1)] = float(match.group(2))
	return result


def split_rows(sheet_path: Path, specs: list[tuple[str, int, float, bool]], cell: int):
	sheet = Image.open(sheet_path).convert("RGBA")
	physical_row = 0
	for name, count, table_fps, loop in specs:
		frames = []
		for frame_index in range(count):
			linear = physical_row * 6 + frame_index
			x = (linear % 6) * cell
			y = (linear // 6) * cell
			frames.append(sheet.crop((x, y, x + cell, y + cell)))
		yield name, count, table_fps, loop, physical_row, frames
		physical_row += math.ceil(count / 6)


def rgba_bbox(frame: Image.Image):
	alpha = np.asarray(frame.getchannel("A"))
	y, x = np.nonzero(alpha)
	if not len(x):
		return None
	return [int(x.min()), int(y.min()), int(x.max()) + 1, int(y.max()) + 1]


def largest_skin_component(frame: Image.Image):
	a = np.asarray(frame.convert("RGBA"))
	r, g, b, al = (a[..., i].astype(int) for i in range(4))
	# Deliberately broad across the cast; false matches are exposed by the component score/bbox.
	mask = (al > 127) & (r > 150) & (g > 80) & (b > 55) & (r > g * 1.02) & (g > b * 0.95)
	h, w = mask.shape
	seen = np.zeros_like(mask, dtype=bool)
	components = []
	for sy, sx in zip(*np.nonzero(mask)):
		if seen[sy, sx]:
			continue
		queue = deque([(int(sy), int(sx))])
		seen[sy, sx] = True
		pts = []
		while queue:
			y, x = queue.popleft()
			pts.append((y, x))
			for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
				ny, nx = y + dy, x + dx
				if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not seen[ny, nx]:
					seen[ny, nx] = True
					queue.append((ny, nx))
		if len(pts) >= 3:
			ys = [p[0] for p in pts]; xs = [p[1] for p in pts]
			components.append((len(pts), min(xs), min(ys), max(xs) + 1, max(ys) + 1))
	if not components:
		return None
	# Face is usually the largest skin component above the body's vertical midpoint.
	body = rgba_bbox(frame)
	if body:
		upper_limit = body[1] + (body[3] - body[1]) * 0.62
		upper = [c for c in components if (c[2] + c[4]) * 0.5 <= upper_limit]
		if upper:
			components = upper
	return max(components, key=lambda c: c[0])


def head_height_proxy(frame: Image.Image):
	face = largest_skin_component(frame)
	if face is None:
		return None
	_, x0, y0, x1, y1 = face
	face_w, face_h = max(3, x1 - x0), max(3, y1 - y0)
	cx = (x0 + x1) / 2
	# Window around the face includes hair/circlet but tries to stop before the torso.
	left = max(0, int(cx - max(18, face_w * 1.45)))
	right = min(frame.width, int(cx + max(18, face_w * 1.45)))
	top = max(0, int(y0 - max(12, face_h * 1.4)))
	bottom = min(frame.height, int(y1 + max(5, face_h * 0.45)))
	alpha = np.asarray(frame.getchannel("A"))[top:bottom, left:right]
	y, x = np.nonzero(alpha)
	if not len(y):
		return None
	return {
		"height": int(y.max() - y.min() + 1),
		"bbox": [left + int(x.min()), top + int(y.min()), left + int(x.max()) + 1, top + int(y.max()) + 1],
		"face_component_pixels": face[0],
		"face_bbox": [x0, y0, x1, y1],
	}


def frame_metrics(frame: Image.Image, intended_feet: int):
	arr = np.asarray(frame.convert("RGBA"))
	alpha = arr[..., 3]
	bbox = rgba_bbox(frame)
	if bbox is None:
		return {"empty": True}
	y, x = np.nonzero(alpha)
	weights = alpha[y, x].astype(float)
	centroid_x = float(np.average(x, weights=weights))
	centroid_y = float(np.average(y, weights=weights))
	edge_mask = np.zeros_like(alpha, dtype=bool)
	edge_mask[:1, :] = True; edge_mask[-1:, :] = True; edge_mask[:, :1] = True; edge_mask[:, -1:] = True
	margin4 = np.zeros_like(alpha, dtype=bool)
	margin4[:4, :] = True; margin4[-4:, :] = True; margin4[:, :4] = True; margin4[:, -4:] = True
	head = head_height_proxy(frame)
	return {
		"empty": False,
		"bbox": bbox,
		"feet_line": int(y.max()),
		"feet_delta_from_contract": int(y.max()) - intended_feet,
		"body_height": int(bbox[3] - bbox[1]),
		"centroid": [round(centroid_x, 2), round(centroid_y, 2)],
		"edge_pixels": int(np.count_nonzero((alpha > 0) & edge_mask)),
		"margin4_pixels": int(np.count_nonzero((alpha > 0) & margin4)),
		"opaque_pixels": int(np.count_nonzero(alpha)),
		"unique_rgba": int(np.unique(arr.reshape(-1, 4), axis=0).shape[0]),
		"head_height_proxy": None if head is None else head["height"],
		"head_proxy_bbox": None if head is None else head["bbox"],
		"face_component_pixels": None if head is None else head["face_component_pixels"],
	}


def checker(size: tuple[int, int], block: int = 12):
	w, h = size
	img = Image.new("RGBA", size, (26, 30, 40, 255))
	d = ImageDraw.Draw(img)
	for y in range(0, h, block):
		for x in range(0, w, block):
			if (x // block + y // block) % 2:
				d.rectangle((x, y, min(x + block - 1, w - 1), min(y + block - 1, h - 1)), fill=(43, 48, 61, 255))
	return img


def audit_sheets():
	fps_map = adopted_fps()
	result = {"method": {
		"alpha_threshold": ">0 for bounds/edges; alpha-weighted centroid",
		"feet_contract": "base y=120, moves y=152 (zero-based file coordinate expected near 119/151 depending on art)",
		"head_height_proxy": "heuristic alpha window around largest upper-body skin-coloured component; inspect low face_component_pixels visually",
	}, "forms": {}}
	for form, cfg in FORMS.items():
		form_out = {"target_heads_tall": cfg["ratio_target"], "sheets": {}}
		for sheet_kind, path, specs, cell, feet in [
			("base", cfg["base"], BASE_ROWS, 128, 120),
			("moves", cfg["moves"], MOVE_ROWS[cfg["prefix"] if cfg["prefix"] != "luna_brave" else "luna_brave"], 192, 152),
		]:
			rows_out = []
			for name, count, table_fps, loop, physical_row, frames in split_rows(path, specs, cell):
				key = f'{cfg["prefix"]}/{cfg["body"]}/{name}'
				actual_fps = fps_map.get(key, table_fps)
				metrics = [frame_metrics(frame, feet) for frame in frames]
				hashes = [hashlib.sha256(frame.tobytes()).hexdigest() for frame in frames]
				dupes = []
				for i in range(len(hashes)):
					for j in range(i):
						if hashes[i] == hashes[j]:
							dupes.append([j + 1, i + 1])
				centroids = [m.get("centroid") for m in metrics if not m.get("empty")]
				drift = 0.0
				if centroids:
					cx = [p[0] for p in centroids]; cy = [p[1] for p in centroids]
					drift = math.hypot(max(cx) - min(cx), max(cy) - min(cy))
				heads = [m["head_height_proxy"] for m in metrics if m.get("head_height_proxy")]
				heights = [m["body_height"] for m in metrics if not m.get("empty")]
				rows_out.append({
					"row": name, "frames_expected": count, "frames_found": len(frames),
					"table_fps": table_fps, "game_fps": actual_fps, "loop": loop,
					"physical_start_row_zero_based": physical_row,
					"cell": cell, "feet_contract": feet,
					"empty_frames": [i + 1 for i, m in enumerate(metrics) if m.get("empty")],
					"duplicate_frame_pairs": dupes,
					"centroid_drift_px": round(drift, 2),
					"feet_line_range": None if not heights else [min(m["feet_line"] for m in metrics if not m.get("empty")), max(m["feet_line"] for m in metrics if not m.get("empty"))],
					"body_height_range": None if not heights else [min(heights), max(heights)],
					"head_height_proxy_range": None if not heads else [min(heads), max(heads)],
					"heads_tall_proxy_median": None if not heads else round(float(np.median(heights)) / float(np.median(heads)), 2),
					"edge_pixels_total": sum(m.get("edge_pixels", 0) for m in metrics),
					"margin4_pixels_total": sum(m.get("margin4_pixels", 0) for m in metrics),
					"frame_metrics": metrics,
				})
			form_out["sheets"][sheet_kind] = {"path": str(path.relative_to(ROOT)).replace("\\", "/"), "cell": cell, "rows": rows_out}
		form_out["summary"] = summarize_form(form_out)
		result["forms"][form] = form_out
		make_sheet_board(form, cfg, result["forms"][form])
		make_detail_board(form, cfg)
	return result


def summarize_form(form_out):
	rows = [r for s in form_out["sheets"].values() for r in s["rows"]]
	return {
		"rows": len(rows), "frames": sum(r["frames_found"] for r in rows),
		"edge_pixels": sum(r["edge_pixels_total"] for r in rows),
		"margin4_pixels": sum(r["margin4_pixels_total"] for r in rows),
		"empty_frames": sum(len(r["empty_frames"]) for r in rows),
		"duplicate_pairs": sum(len(r["duplicate_frame_pairs"]) for r in rows),
		"max_centroid_drift_px": max(r["centroid_drift_px"] for r in rows),
	}


def make_sheet_board(form: str, cfg: dict, measured: dict):
	sections = []
	for kind, path, specs, cell in [
		("base", cfg["base"], BASE_ROWS, 128),
		("moves", cfg["moves"], MOVE_ROWS[cfg["prefix"] if cfg["prefix"] != "luna_brave" else "luna_brave"], 192),
	]:
		rows = list(split_rows(path, specs, cell))
		width = 150 + max(len(frames) * cell for *_, frames in rows)
		height = 34 + len(rows) * (cell + 22)
		section = checker((width, height))
		d = ImageDraw.Draw(section)
		d.text((8, 7), f"{form} {kind} | 1 image px = 1 board px", font=FONT, fill=(255, 232, 150, 255))
		for row_i, (name, _, _, _, _, frames) in enumerate(rows):
			y = 34 + row_i * (cell + 22)
			d.text((6, y + 4), name, font=FONT_SMALL, fill=(230, 235, 245, 255))
			row_measure = measured["sheets"][kind]["rows"][row_i]
			d.text((6, y + 22), f'{row_measure["game_fps"]:g} fps', font=FONT_SMALL, fill=(150, 205, 255, 255))
			for i, frame in enumerate(frames):
				x = 150 + i * cell
				section.alpha_composite(frame, (x, y))
				d.rectangle((x, y, x + cell - 1, y + cell - 1), outline=(95, 105, 125, 255), width=1)
				feet = 120 if kind == "base" else 152
				d.line((x, y + feet, x + cell - 1, y + feet), fill=(50, 220, 130, 170), width=1)
		sections.append(section)
	width = max(s.width for s in sections)
	height = sum(s.height for s in sections) + 10
	board = Image.new("RGBA", (width, height), (18, 21, 29, 255))
	y = 0
	for section in sections:
		board.alpha_composite(section, (0, y)); y += section.height + 10
	board.convert("RGB").save(BOARDS / f"sheets-{form}-1x.png", optimize=True)


def make_detail_board(form: str, cfg: dict):
	items = []
	for kind, path, specs, cell in [
		("base", cfg["base"], BASE_ROWS, 128),
		("moves", cfg["moves"], MOVE_ROWS[cfg["prefix"] if cfg["prefix"] != "luna_brave" else "luna_brave"], 192),
	]:
		for name, _, _, _, _, frames in split_rows(path, specs, cell):
			# Tallest frame tends to expose head/body proportion and cleanup defects.
			frame = max(frames, key=lambda f: 0 if rgba_bbox(f) is None else rgba_bbox(f)[3] - rgba_bbox(f)[1])
			bbox = rgba_bbox(frame) or [0, 0, cell, cell]
			pad = 4
			crop = frame.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad), min(cell, bbox[2] + pad), min(cell, bbox[3] + pad)))
			crop = crop.resize((crop.width * 3, crop.height * 3), Image.Resampling.NEAREST)
			items.append((f"{kind}:{name}", crop))
	tile_w, tile_h = 420, 430
	cols = 4; rows = math.ceil(len(items) / cols)
	board = checker((cols * tile_w, rows * tile_h), 18)
	d = ImageDraw.Draw(board)
	for index, (label, crop) in enumerate(items):
		x = (index % cols) * tile_w; y = (index // cols) * tile_h
		d.text((x + 8, y + 6), f"{label} | 3x nearest", font=FONT_SMALL, fill=(255, 232, 150, 255))
		if crop.width > tile_w - 16 or crop.height > tile_h - 36:
			# Preserve 3x; centre-crop instead of rescaling.
			left = max(0, (crop.width - (tile_w - 16)) // 2)
			top = max(0, (crop.height - (tile_h - 36)) // 2)
			crop = crop.crop((left, top, left + min(crop.width, tile_w - 16), top + min(crop.height, tile_h - 36)))
		board.alpha_composite(crop, (x + (tile_w - crop.width) // 2, y + 30 + (tile_h - 36 - crop.height) // 2))
	board.convert("RGB").save(BOARDS / f"sheets-{form}-3x.png", optimize=True)


def parse_vfx_specs():
	text = (PROJECT / "scripts/Vfx.gd").read_text(encoding="utf-8")
	section = text.split("const SPECS := {", 1)[1].split("}\n", 1)[0]
	auth = text.split("const AUTHORED_WIDTH := {", 1)[1].split("}\n", 1)[0]
	authored = {name: int(width) for name, width in re.findall(r'"([^"]+)":\s*([0-9]+)', auth)}
	result = {}
	for line_no, line in enumerate(text.splitlines(), 1):
		match = re.search(r'^\s*"([^"]+)":\s*\[([0-9]+),\s*([0-9.]+),\s*Vector2\(([^)]+)\),\s*(true|false)(?:,\s*([A-Z_]+))?', line)
		if not match:
			continue
		name, frames, fps, anchor, additive, folder = match.groups()
		if name not in RELEVANT_VFX:
			continue
		folder_name = folder or "DIR"
		directory = {
			"DIR": ART / "vfx", "ATTACK_DIR": ART / "attack_vfx",
			"EFFECTS_DIR": ART / "effects", "SKILL_DIR": ART / "effects/skill",
		}[folder_name]
		path = directory / f"{name}.png"
		image = Image.open(path).convert("RGBA")
		count = int(frames); actual_width = image.width / count
		result[name] = {
			"path": str(path.relative_to(ROOT)).replace("\\", "/"), "vfx_spec_line": line_no,
			"frames_spec": count, "fps": float(fps), "anchor": anchor,
			"additive": additive == "true", "authored_width": authored.get(name),
			"strip_size": [image.width, image.height], "real_frame_size": [actual_width, image.height],
			"frame_count_width_divisible": image.width % count == 0,
			"size_ratio": None if name not in authored else round(actual_width / authored[name], 4),
			"edge_pixels_per_frame": [], "empty_frames": [], "duplicate_frame_pairs": [],
		}
		hashes = []
		for i in range(count):
			frame = image.crop((int(i * actual_width), 0, int((i + 1) * actual_width), image.height))
			m = frame_metrics(frame, image.height - 1)
			result[name]["edge_pixels_per_frame"].append(m.get("edge_pixels", 0))
			if m.get("empty"):
				result[name]["empty_frames"].append(i + 1)
			h = hashlib.sha256(frame.tobytes()).hexdigest(); hashes.append(h)
			for j in range(i):
				if h == hashes[j]:
					result[name]["duplicate_frame_pairs"].append([j + 1, i + 1])
	return result


def audit_direct_effects():
	result = {}
	for name, path in DIRECT_EFFECTS.items():
		image = Image.open(path).convert("RGBA")
		result[name] = {
			"path": str(path.relative_to(ROOT)).replace("\\", "/"),
			"size": [image.width, image.height], "bbox": rgba_bbox(image),
			"edge_pixels": frame_metrics(image, image.height - 1).get("edge_pixels", 0),
		}
	return result


def best_diff_frame(fx_path: Path, nofx_path: Path):
	fx = Image.open(fx_path); nofx = Image.open(nofx_path)
	best = (-1, -1.0, None, None, None)
	count = min(getattr(fx, "n_frames", 1), getattr(nofx, "n_frames", 1))
	for i in range(count):
		fx.seek(i); nofx.seek(i)
		a = fx.convert("RGB"); b = nofx.convert("RGB")
		diff = ImageChops.difference(a, b)
		bbox = diff.getbbox()
		if bbox is None:
			score = 0.0
		else:
			score = float(np.asarray(diff.resize((120, 68)).convert("L"), dtype=np.float32).mean())
		if score > best[1]:
			best = (i, score, bbox, a.copy(), b.copy())
	return best, count


def selected_clip_metrics(fx: Image.Image, nofx: Image.Image, bbox) -> dict:
	"""Simple frame-space measurements; these do not try to infer a hit box."""
	a = np.asarray(fx.convert("RGB"), dtype=np.int16)
	b = np.asarray(nofx.convert("RGB"), dtype=np.int16)
	delta = np.max(np.abs(a - b), axis=2)
	changed = delta >= 24
	# Foreground proxy: pixels unlike the modal dark arena sample at the top-left.
	background = b[0, 0]
	foreground = np.max(np.abs(b - background), axis=2) >= 30
	# The capture's floor/platform is a broad grey band; remove low-saturation runs.
	spread = b.max(axis=2) - b.min(axis=2)
	foreground &= ~((spread < 22) & (b.mean(axis=2) > 35))
	overlap = changed & foreground
	return {
		"changed_pixels_ge24": int(changed.sum()),
		"changed_frame_fraction": round(float(changed.mean()), 4),
		"nofx_foreground_proxy_pixels": int(foreground.sum()),
		"changed_over_foreground_proxy_fraction": round(float(overlap.sum() / max(1, foreground.sum())), 4),
		"difference_reaches_viewport_bottom": bool(bbox and bbox[3] >= fx.height),
		"difference_reaches_viewport_top": bool(bbox and bbox[1] <= 0),
	}


def crop_at(image: Image.Image, center: tuple[float, float], size: tuple[int, int]):
	w, h = size; cx, cy = center
	left = max(0, min(image.width - w, int(round(cx - w / 2))))
	top = max(0, min(image.height - h, int(round(cy - h / 2))))
	return image.crop((left, top, left + w, top + h))


def audit_clips():
	manifest = json.loads((ROOT / "art/clips/manifest.json").read_text(encoding="utf-8"))
	result = {"capture_forms_note": "nova and rio clips use male body (capture_move_clips.gd:26-27); female forms have no game clips", "clips": []}
	by_form = {}
	for clip in manifest["clips"]:
		fx_path = ROOT / "art/clips" / clip["files"]["fx"]
		nofx_path = ROOT / "art/clips" / clip["files"]["nofx"]
		best, count = best_diff_frame(fx_path, nofx_path)
		index, score, bbox, fx_frame, nofx_frame = best
		entry = {
			"form": clip["form"], "move": clip["move"], "name": clip["name"],
			"group": clip["group"], "frames": count, "best_diff_frame_zero_based": index,
			"best_diff_score_downsampled_mean_luma": round(score, 3),
			"best_diff_bbox": bbox, "zoom": clip["zoom"],
			**selected_clip_metrics(fx_frame, nofx_frame, bbox),
		}
		result["clips"].append(entry)
		by_form.setdefault(clip["form"], []).append((clip, entry, fx_frame, nofx_frame))
	for form, entries in by_form.items():
		for page_no in range(math.ceil(len(entries) / 4)):
			chunk = entries[page_no * 4:(page_no + 1) * 4]
			make_clip_page(form, page_no + 1, chunk, 1)
			make_clip_page(form, page_no + 1, chunk, 3)
	return result


def make_clip_page(form: str, page: int, entries, scale: int):
	if scale == 1:
		crop_size = (320, 220); display_size = crop_size
	else:
		crop_size = (160, 110); display_size = (480, 330)
	w = display_size[0] * 2 + 28; row_h = display_size[1] + 44
	board = checker((w, row_h * len(entries)), 16)
	d = ImageDraw.Draw(board)
	for row, (clip, entry, fx, nofx) in enumerate(entries):
		bbox = entry["best_diff_bbox"]
		if bbox:
			center = ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)
		else:
			center = (fx.width / 2, fx.height * 0.68)
		a = crop_at(nofx, center, crop_size); b = crop_at(fx, center, crop_size)
		if scale == 3:
			a = a.resize(display_size, Image.Resampling.NEAREST); b = b.resize(display_size, Image.Resampling.NEAREST)
		y = row * row_h
		d.text((8, y + 5), f'{clip["move"]} f{entry["best_diff_frame_zero_based"]} | nofx / fx | {scale}x nearest', font=FONT_SMALL, fill=(255, 232, 150, 255))
		board.alpha_composite(a.convert("RGBA"), (8, y + 30))
		board.alpha_composite(b.convert("RGBA"), (20 + display_size[0], y + 30))
	board.convert("RGB").save(BOARDS / f"clips-{form}-p{page}-{scale}x.png", optimize=True)


def clip_frame(form: str, move: str, frame_index: int, fx: bool) -> Image.Image:
	manifest = json.loads((ROOT / "art/clips/manifest.json").read_text(encoding="utf-8"))
	entry = next(c for c in manifest["clips"] if c["form"] == form and c["move"] == move)
	path = ROOT / "art/clips" / entry["files"]["fx" if fx else "nofx"]
	image = Image.open(path); image.seek(frame_index)
	return image.convert("RGB")


def make_problem_good_boards(clips: dict):
	lookup = {(e["form"], e["move"]): e for e in clips["clips"]}
	rows = [
		("PROBLEM: Frey ground J", "frey", "ground-j"),
		("PROBLEM: Luna air J", "luna", "air-j"),
		("PROBLEM: Nova ground J", "nova", "ground-j"),
		("PROBLEM: Rio rune counter", "rio", "rune"),
		("GOOD: Yuki ground down-J", "yuki", "down-j"),
		("GOOD: shared guard", "frey", "guard"),
	]
	crop_size = (320, 200); row_h = 236
	board = checker((676, row_h * len(rows)), 16); draw = ImageDraw.Draw(board)
	for row, (label, form, move) in enumerate(rows):
		e = lookup[(form, move)]; bbox = e["best_diff_bbox"]
		center = ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2) if bbox else (480, 300)
		i = e["best_diff_frame_zero_based"]
		nofx = crop_at(clip_frame(form, move, i, False), center, crop_size)
		fx = crop_at(clip_frame(form, move, i, True), center, crop_size)
		y = row * row_h
		draw.text((8, y + 5), f"{label} / frame {i} / nofx -> fx / 1x", font=FONT_SMALL, fill=(255, 232, 150, 255))
		board.alpha_composite(nofx.convert("RGBA"), (8, y + 30)); board.alpha_composite(fx.convert("RGBA"), (348, y + 30))
	board.convert("RGB").save(BOARDS / "problem-vs-good-effects-1x.png", optimize=True)

	ult_rows = [
		("PROBLEM: Luna transform", "luna", "transform"),
		("PROBLEM: Nova ultimate", "nova", "ultimate"),
		("PROBLEM: Yuki ultimate finish", "yuki", "ultimate"),
		("GOOD: Rio ultimate", "rio", "ultimate"),
	]
	board = checker((676, row_h * len(ult_rows)), 16); draw = ImageDraw.Draw(board)
	for row, (label, form, move) in enumerate(ult_rows):
		e = lookup[(form, move)]; bbox = e["best_diff_bbox"]
		center = ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2) if bbox else (480, 300)
		i = e["best_diff_frame_zero_based"]
		nofx = crop_at(clip_frame(form, move, i, False), center, crop_size)
		fx = crop_at(clip_frame(form, move, i, True), center, crop_size)
		y = row * row_h
		draw.text((8, y + 5), f"{label} / frame {i} / nofx -> fx / 1x", font=FONT_SMALL, fill=(255, 232, 150, 255))
		board.alpha_composite(nofx.convert("RGBA"), (8, y + 30)); board.alpha_composite(fx.convert("RGBA"), (348, y + 30))
	board.convert("RGB").save(BOARDS / "ultimate-body-visibility-1x.png", optimize=True)

	# Hurt frame baseline: Nova female is the only grounded hurt cell whose last
	# opaque pixel is y=112 rather than y=120.
	forms = ["frey", "luna", "luna_brave", "yuki", "nova_male", "nova_female", "rio_male", "rio_female"]
	cell = 128; scale = 3; tile = cell * scale
	board = checker((tile * 4, (tile + 34) * 2), 16); draw = ImageDraw.Draw(board)
	for index, form in enumerate(forms):
		frames = list(split_rows(FORMS[form]["base"], BASE_ROWS, 128))
		hurt = next(row[-1][0] for row in frames if row[0] == "hurt")
		shown = hurt.resize((tile, tile), Image.Resampling.NEAREST)
		x = (index % 4) * tile; y = (index // 4) * (tile + 34)
		board.alpha_composite(shown, (x, y + 30))
		draw.line((x, y + 30 + 120 * scale, x + tile - 1, y + 30 + 120 * scale), fill=(255, 70, 70, 255), width=2)
		feet = rgba_bbox(hurt)[3] - 1
		draw.text((x + 6, y + 6), f"{form}: feet y={feet}", font=FONT_SMALL, fill=(255, 232, 150, 255))
	board.convert("RGB").save(BOARDS / "hurt-feet-baseline-3x.png", optimize=True)


def make_effect_boards(vfx: dict, direct: dict):
	items = []
	for name, data in sorted(vfx.items()):
		path = ROOT / data["path"]
		strip = Image.open(path).convert("RGBA")
		count = data["frames_spec"]; fw = strip.width // count
		frames = [strip.crop((i * fw, 0, (i + 1) * fw, strip.height)) for i in range(count)]
		frame = max(frames, key=lambda f: np.asarray(f.getchannel("A"), dtype=np.uint64).sum())
		items.append((name, frame, f'{fw}x{strip.height} {count}f r={data["size_ratio"]}'))
	for name, data in sorted(direct.items()):
		frame = Image.open(ROOT / data["path"]).convert("RGBA")
		items.append((name, frame, f'{frame.width}x{frame.height} direct'))
	cols, rows_per_page = 4, 4
	tile_w, tile_h = 390, 350
	per_page = cols * rows_per_page
	for page in range(math.ceil(len(items) / per_page)):
		chunk = items[page * per_page:(page + 1) * per_page]
		board = checker((cols * tile_w, rows_per_page * tile_h), 16)
		d = ImageDraw.Draw(board)
		for i, (name, frame, note) in enumerate(chunk):
			x = (i % cols) * tile_w; y = (i // cols) * tile_h
			d.text((x + 7, y + 6), name, font=FONT_SMALL, fill=(255, 232, 150, 255))
			d.text((x + 7, y + 23), note, font=FONT_SMALL, fill=(155, 205, 255, 255))
			# 1x actual pixels; centre-crop large effects rather than scaling.
			if frame.width > tile_w - 12 or frame.height > tile_h - 48:
				frame = crop_at(frame, (frame.width / 2, frame.height / 2), (min(frame.width, tile_w - 12), min(frame.height, tile_h - 48)))
			board.alpha_composite(frame, (x + (tile_w - frame.width) // 2, y + 42 + (tile_h - 48 - frame.height) // 2))
		board.convert("RGB").save(BOARDS / f"effects-p{page + 1}-1x.png", optimize=True)


def build_effect_inventory(vfx: dict, direct: dict) -> dict:
	"""Join measured files to the exact runtime references and placement contracts."""
	runtime_files = list((PROJECT / "characters").rglob("*.gd")) + [
		PROJECT / "scripts/Vfx.gd", PROJECT / "scripts/Attack.gd", PROJECT / "scripts/Projectile.gd",
	]
	lines_by_file = {path: path.read_text(encoding="utf-8").splitlines() for path in runtime_files}

	def references(tokens: list[str]) -> list[dict]:
		found = []
		for path, lines in lines_by_file.items():
			for number, line in enumerate(lines, 1):
				if any(token in line for token in tokens):
					found.append({"at": f"{path.relative_to(ROOT).as_posix()}:{number}", "code": line.strip()})
		return found

	items = {}
	for name, measured in vfx.items():
		profile = PLACEMENT_BY_ID.get(name)
		note = PLACEMENT_NOTES.get(name)
		if profile:
			placement = {"profile": profile, **PLACEMENT[profile]}
		elif note:
			placement = dict(zip(("centre", "size", "rotation", "layer", "alpha"), note))
		else:
			placement = {"centre": "see draw_sites", "size": "see draw_sites", "rotation": "see draw_sites", "layer": "see draw_sites", "alpha": "see draw_sites"}
		items[name] = {
			"kind": "Vfx strip", "path": measured["path"], "measured": measured,
			"placement": placement,
			"draw_sites": references([f'"{name}"']),
		}
	# The generic slash draw site is dynamic and therefore contains no literal per fighter.
	for name in ("frey_slash", "luna_slash", "luna_brave_slash", "nova_slash", "rio_slash", "yuki_slash"):
		items[name]["draw_sites"].append({"at": "smash-nine-prototype/characters/common/PlayerBase.gd:1175", "code": "_draw_attack_art: dynamic attack_effect_name() -> <character>_slash"})

	for name, measured in direct.items():
		profile = PLACEMENT_BY_ID.get(name)
		note = PLACEMENT_NOTES.get(name)
		placement = {"profile": profile, **PLACEMENT[profile]} if profile else dict(zip(("centre", "size", "rotation", "layer", "alpha"), note or ["see draw_sites"] * 5))
		basename = Path(measured["path"]).name
		items[name] = {
			"kind": "direct texture", "path": measured["path"], "measured": measured,
			"placement": placement,
			"draw_sites": references([basename, str(Path(basename).with_suffix(""))]),
		}
	# Dynamic templates do not contain the final hit/status file names.
	for name in ("hit_frey", "hit_luna", "hit_luna_brave", "hit_yuki", "hit_nova", "hit_rio"):
		items[name]["draw_sites"].append({"at": "smash-nine-prototype/characters/common/PlayerBase.gd:1750", "code": "_spawn_hit_effect selects effects/hit/<source_id>_hit.png"})
	for name in ("status_stun", "status_super_armor"):
		items[name]["draw_sites"].append({"at": "smash-nine-prototype/characters/common/PlayerBase.gd:1804", "code": "_update_status_icon selects ui/status/<kind>.png"})
	return {
		"count": len(items), "items": items,
		"common_spawn_contract": {
			"at": "smash-nine-prototype/scripts/Vfx.gd:107-133",
			"notes": "centered=false; offset=-anchor*source_ratio; scale=requested/source_ratio; z/tint from caller; additive from SPECS",
		},
	}


def main():
	OUT.mkdir(parents=True, exist_ok=True); BOARDS.mkdir(parents=True, exist_ok=True)
	sheets = audit_sheets()
	(OUT / "sheet_measurements.json").write_text(json.dumps(sheets, ensure_ascii=False, indent=2), encoding="utf-8")
	vfx = parse_vfx_specs(); direct = audit_direct_effects()
	effects = {
		"vfx_strips": vfx, "direct_textures": direct,
		"scope_note": "Only fighter/shared runtime art in QA-19 scope; realm/hazard Vfx specs excluded.",
	}
	(OUT / "effect_measurements.json").write_text(json.dumps(effects, ensure_ascii=False, indent=2), encoding="utf-8")
	(OUT / "effect_inventory.json").write_text(json.dumps(build_effect_inventory(vfx, direct), ensure_ascii=False, indent=2), encoding="utf-8")
	make_effect_boards(vfx, direct)
	clips = audit_clips()
	(OUT / "clip_measurements.json").write_text(json.dumps(clips, ensure_ascii=False, indent=2), encoding="utf-8")
	make_problem_good_boards(clips)
	print(json.dumps({
		"forms": {k: v["summary"] for k, v in sheets["forms"].items()},
		"vfx": len(vfx), "direct_effects": len(direct), "clips": len(clips["clips"]),
	}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
	main()
