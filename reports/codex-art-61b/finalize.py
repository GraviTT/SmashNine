from __future__ import annotations

import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
REPORT = Path(__file__).resolve().parent
ANCHOR = ROOT / "art/bakeoff/rio/rio_female-idle-v2.png"
ROWS = {
	"jump": ("v1", 1, 1.0, 128, 0.190),
	"fall": ("v1", 1, 1.0, 128, 0.150),
	"hurt": ("v1", 1, 1.0, 128, 0.170),
	"shield": ("v1", 6, 12.0, 128, 0.240),
	"attack": ("v1", 6, 21.0, 128, 0.225),
	"mana_combo": ("v1", 6, 18.0, 192, 0.261),
	"rising_slash": ("v1", 6, 30.0, 192, 0.267),
	"low_sweep": ("v1", 6, 30.0, 192, 0.240),
	"air_slash": ("v3", 6, 40.0, 192, 0.264),
	"plunge": ("v3", 6, 12.0, 192, 0.300),
	"dimension_slash": ("v1", 6, 23.0, 192, 0.293),
	"rune_shield": ("v1", 6, 12.0, 192, 0.250),
	"infinity_overdrive": ("v1", 6, 11.0, 192, 0.279),
	"tumble": ("v1", 6, 21.0, 192, 0.240),
}
MOTIONS = {
	"jump": "상승하며 무릎을 접고 검을 뒤로 든 단일 점프 자세",
	"fall": "다리를 아래로 뻗고 머리카락과 망토가 위로 뜬 단일 낙하 자세",
	"hurt": "눈을 감고 뒤로 젖혀진 단일 피격 자세",
	"shield": "검을 몸 앞으로 올리고 버티는 6프레임 방어, 장벽 없음",
	"attack": "mana_combo 원본을 128px에 들어가는 최대 배율과 공통 x 이동으로 재정규화",
	"mana_combo": "전진 베기 2f, 되베기 2f, 큰 수평 마무리와 회복 2f",
	"rising_slash": "웅크림, 상승, 머리 위 베기, 후속, 공중 회복, 회복",
	"low_sweep": "낮추기, 회전, 지면 쓸기, 유지, 회복, 준비",
	"air_slash": "전 프레임 공중에서 준비, 수평 베기, 유지, 반동, 회복",
	"plunge": "공중 전환, 준비, 검을 아래로 둔 강하, 착지 고정, 회복",
	"dimension_slash": "집중, 발도, 길게 뻗은 수평 베기, 유지, 제동, 준비; 잔상 없음",
	"rune_shield": "세팅, 빈손 들기, 손바닥 방어, 충격 버팀, 해제; 룬 없음",
	"infinity_overdrive": "집중, 검을 머리 위로 올림, 유지, 전방 지휘, 준비; 궤도검 없음",
	"tumble": "몸을 말고 한 바퀴 뒤로 회전하는 6프레임 피격 텀블",
}


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
	names = ["C:/Windows/Fonts/malgunbd.ttf", "C:/Windows/Fonts/arialbd.ttf"] if bold else ["C:/Windows/Fonts/malgun.ttf", "C:/Windows/Fonts/arial.ttf"]
	for name in names:
		try:
			return ImageFont.truetype(name, size)
		except OSError:
			pass
	return ImageFont.load_default()


def checker(size: tuple[int, int], square: int = 12) -> Image.Image:
	image = Image.new("RGBA", size, (27, 35, 49, 255))
	draw = ImageDraw.Draw(image)
	for y in range(0, size[1], square):
		for x in range(0, size[0], square):
			if (x // square + y // square) % 2:
				draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(39, 49, 68, 255))
	return image


def load_head_module():
	spec = importlib.util.spec_from_file_location("head_scale", ROOT / "tools/sprite_pipeline/head_scale.py")
	if spec is None or spec.loader is None:
		raise RuntimeError("head_scale.py load failed")
	module = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(module)
	return module


def write_metadata() -> None:
	for row, (version, frames, fps, cell, _factor) in ROWS.items():
		path = ROOT / f"art/bakeoff/rio/rio_female-{row}-{version}.png"
		payload: dict[str, object] = {"note": f"Rio 여성 {MOTIONS[row]} 후보입니다.", "fps": fps, "frames": frames}
		if cell == 192:
			payload.update({"cell": 192, "feet": 152})
		path.with_suffix(".json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def write_prompts() -> None:
	common = (
		"Built-in ImageGen. Image 1은 채택된 rio_female-idle-v2의 외형·머리·디테일 기준이고, "
		"Image 2는 기존 게임 행의 동작 기준일 뿐이다. 짙은 남색 하이 포니테일, 남색·청록 아카데미 전투복, "
		"은색 테두리, 청록 다이아 장식, 검은 레깅스, 남색 장화, 짧은 분할 망토, 단단한 밝은 청색 검날을 유지한다. "
		"#00FF00 배경, 한 인물·한 얼굴·양손·양발·검 한 자루. 광륜·궤적·잔상·마나 파동·룬·궤도검·장벽 금지.\n"
	)
	for row in ROWS:
		attempt = ""
		if row == "shield":
			attempt = "\n2차 생성: 검과 포니테일을 더 압축해 128px에서 머리 배율과 4px 여백을 함께 맞춤."
		elif row == "plunge":
			attempt = "\n2차 생성: 세로 강하 자세의 머리카락·망토를 몸 가까이 말아 192px에서 앵커 머리 크기를 유지."
		(REPORT / row / "prompt.txt").write_text(common + "Motion: " + MOTIONS[row] + attempt + "\n", encoding="utf-8")


def build_overview() -> None:
	label_w = 250
	width = label_w + 192 * 6
	height = 10 + sum(cell + 8 for _, _, _, cell, _ in ROWS.values())
	canvas = checker((width, height), 12)
	draw = ImageDraw.Draw(canvas)
	y = 10
	for row, (version, frames, fps, cell, factor) in ROWS.items():
		strip = Image.open(ROOT / f"art/bakeoff/rio/rio_female-{row}-{version}.png").convert("RGBA")
		visible = strip.crop((0, 0, frames * cell, cell))
		canvas.alpha_composite(visible, (label_w, y))
		draw.rectangle((0, y, label_w - 1, y + cell - 1), fill=(12, 17, 29, 255))
		draw.text((12, y + 12), row, font=font(22, True), fill=(239, 244, 255, 255))
		draw.text((12, y + 42), f"{frames}f  {fps:g}fps  factor {factor:.3f}", font=font(17), fill=(160, 190, 225, 255))
		y += cell + 8
	canvas.convert("RGB").save(REPORT / "overview.png", quality=95)


def build_head_compare() -> None:
	head = load_head_module()
	anchor = Image.open(ANCHOR).convert("RGBA").crop((0, 0, 128, 128))
	items: list[tuple[str, Image.Image]] = [("ANCHOR", anchor)]
	for row in ("fall", "hurt", "tumble"):
		version, frames, _fps, cell, _factor = ROWS[row]
		sheet = Image.open(ROOT / f"art/bakeoff/rio/rio_female-{row}-{version}.png").convert("RGBA")
		for index in range(frames):
			items.append((f"{row.upper()} {index + 1}", sheet.crop((index * cell, 0, (index + 1) * cell, cell))))
	box = 44
	label_h = 28
	canvas = checker((len(items) * box * 4, box * 4 + label_h), 8)
	draw = ImageDraw.Draw(canvas)
	for index, (label, image) in enumerate(items):
		centre = head.face_centre(__import__("numpy").asarray(image))
		if centre is None:
			crop = image.crop((0, 0, box, box))
		else:
			cy, cx = centre
			x0 = max(0, min(image.width - box, round(cx - box / 2)))
			y0 = max(0, min(image.height - box, round(cy - box / 2)))
			crop = image.crop((x0, y0, x0 + box, y0 + box))
		x = index * box * 4
		canvas.alpha_composite(crop.resize((box * 4, box * 4), Image.Resampling.NEAREST), (x, label_h))
		draw.text((x + 4, 4), label, font=font(14, True), fill=(240, 244, 255, 255))
	canvas.convert("RGB").save(REPORT / "head_compare.png", quality=95)


def build_review_board(name: str, row_names: list[str]) -> None:
	scale = 4
	label_w = 220
	max_cell = max(ROWS[row][3] for row in row_names)
	width = label_w + 6 * max_cell * scale
	height = sum(ROWS[row][3] * scale + 4 for row in row_names)
	canvas = checker((width, height), 16)
	draw = ImageDraw.Draw(canvas)
	y = 0
	for row in row_names:
		version, frames, fps, cell, _factor = ROWS[row]
		sheet = Image.open(ROOT / f"art/bakeoff/rio/rio_female-{row}-{version}.png").convert("RGBA")
		strip = sheet.crop((0, 0, frames * cell, cell)).resize((frames * cell * scale, cell * scale), Image.Resampling.NEAREST)
		canvas.alpha_composite(strip, (label_w, y))
		draw.rectangle((0, y, label_w - 1, y + cell * scale - 1), fill=(12, 17, 29, 255))
		draw.text((12, y + 18), row, font=font(22, True), fill=(239, 244, 255, 255))
		draw.text((12, y + 50), f"{frames}f / {fps:g}fps", font=font(17), fill=(160, 190, 225, 255))
		y += cell * scale + 4
	canvas.convert("RGB").save(REPORT / name, quality=95)


def build_walk_report() -> None:
	walk_dir = REPORT / "walk"
	best = Image.open(walk_dir / "best-attempt.png").convert("RGBA")
	current = Image.open(ROOT / "art/bakeoff/rio/rio_female-walk-v2.png").convert("RGBA")
	anchor = Image.open(ANCHOR).convert("RGBA").crop((0, 0, 128, 128))
	label_w = 220
	rows = [("ANCHOR", anchor), ("CURRENT", current), ("BEST / FAILED", best)]
	canvas = checker((label_w + 8 * 128 * 4, len(rows) * 128 * 4), 16)
	draw = ImageDraw.Draw(canvas)
	for row_index, (label, strip) in enumerate(rows):
		y = row_index * 128 * 4
		canvas.alpha_composite(strip.resize((strip.width * 4, strip.height * 4), Image.Resampling.NEAREST), (label_w, y))
		draw.rectangle((0, y, label_w - 1, y + 128 * 4 - 1), fill=(12, 17, 29, 255))
		draw.text((12, y + 18), label, font=font(21, True), fill=(239, 244, 255, 255))
	canvas.convert("RGB").save(walk_dir / "compare.png", quality=95)

	gif_frames = []
	for index in range(8):
		frame = best.crop((index * 128, 0, (index + 1) * 128, 128))
		bg = checker((128, 128), 8)
		bg.alpha_composite(frame)
		gif_frames.append(bg.resize((512, 512), Image.Resampling.NEAREST).convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
	gif_frames[0].save(walk_dir / "walk.gif", save_all=True, append_images=gif_frames[1:], duration=[80, 70] * 4, loop=0, disposal=2)

	bob = json.loads((walk_dir / "bob.json").read_text(encoding="utf-8"))
	feet = json.loads((walk_dir / "feet.json").read_text(encoding="utf-8"))
	metrics = {
		"measured": {
			"output_size": [1024, 128], "frames": 8, "fps": 13.3,
			"factors": [0.105148, 0.105495, 0.101911, 0.102674, 0.102019, 0.101803, 0.102455, 0.102128],
			"head_scale": [0.96, 1.0, 0.96, 0.96, 0.96, 0.96, 0.96, 0.96],
			"bob": bob, "planted_runs": feet,
			"frame_3_planted_count": len(feet[2]), "frame_7_planted_count": len(feet[6]),
		},
		"judged_at_4x": {
			"costume_matches": True, "opposite_contacts": True,
			"frame_3_true_passing": False, "frame_7_true_passing": True,
			"delivered": False,
			"reason": "3번 프레임의 들린 발끝이 지면 판정 띠에 남아 planted run이 2개다. 3회 생성 상한에 도달했다.",
		},
	}
	(walk_dir / "metrics.json").write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	(walk_dir / "prompt.txt").write_text(
		"Built-in ImageGen. Image 1=idle 외형, Image 2=회색 마네킹 자세, Image 3=승인된 1번 프레임 의상/비율, Image 4=기존 다리 모음 참고.\n"
		"1번을 먼저 확정한 뒤 2·4·5·6·8, 마지막으로 3·7 passing pose를 생성했다. "
		"3번은 가까운 다리만 수직 지지하고 먼 발은 발목 옆 6–12px 공중, 7번은 반대로 지시했다. "
		"의상은 남색·청록 전투복, 은색 테두리, 청록 장식, 남색 장화, 낮고 짧은 은청색 검. 회색 의상과 이펙트 금지.\n",
		encoding="utf-8",
	)


write_metadata()
write_prompts()
build_overview()
build_head_compare()
build_review_board("review4x-base.png", ["jump", "fall", "hurt", "shield", "attack"])
build_review_board("review4x-moves-a.png", ["mana_combo", "rising_slash", "low_sweep", "air_slash", "plunge"])
build_review_board("review4x-moves-b.png", ["dimension_slash", "rune_shield", "infinity_overdrive", "tumble"])
build_walk_report()
