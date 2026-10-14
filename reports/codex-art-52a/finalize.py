from __future__ import annotations

import json
import shutil
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-art-52a"
BAKEOFF = ROOT / "art/bakeoff/nova"
ANCHOR = BAKEOFF / "nova_male-idle-v2.png"


ROWS = {
	"walk": {"fps": 10, "frames": 6, "cell": 128, "head": "head_scale"},
	"jump": {"fps": 1, "frames": 1, "cell": 128, "head": "4x_head_crop"},
	"fall": {"fps": 1, "frames": 1, "cell": 128, "head": "4x_head_crop"},
	"hurt": {"fps": 1, "frames": 1, "cell": 128, "head": "4x_head_crop"},
	"shield": {"fps": 12, "frames": 6, "cell": 128, "head": "head_scale"},
	"attack": {"fps": 35.25, "frames": 6, "cell": 128, "head": "head_scale"},
	"vector_side": {"fps": 35.25, "frames": 6, "cell": 192, "head": "head_scale"},
	"vector_upper": {"fps": 33, "frames": 6, "cell": 192, "head": "head_scale"},
	"compression_stomp": {"fps": 26.1, "frames": 6, "cell": 192, "head": "head_scale"},
	"air_side": {"fps": 40, "frames": 6, "cell": 192, "head": "head_scale"},
	"meteor_kick": {"fps": 30, "frames": 6, "cell": 192, "head": "head_scale"},
	"vector_shift": {"fps": 27.3, "frames": 6, "cell": 192, "head": "head_scale"},
	"gravity_brake": {"fps": 14.3, "frames": 6, "cell": 192, "head": "head_scale"},
	"slingshot_start": {"fps": 14, "frames": 6, "cell": 192, "head": "head_scale"},
	"tumble": {"fps": 21, "frames": 6, "cell": 192, "head": "4x_head_crop"},
}


NOTES = {
	"walk": "영웅다운 6프레임 걷기. 양쪽 접지·다운·패싱이 번갈아 읽히며 머리 자동 측정 중앙값 1.00이다.",
	"jump": "무릎을 접고 두 주먹을 든 상승 단일 포즈. 한 프레임이라 4배 머리 크롭으로 앵커와 비교했다.",
	"fall": "다리를 아래로 뻗고 머리카락이 들린 낙하 단일 포즈. 한 프레임이라 4배 머리 크롭으로 앵커와 비교했다.",
	"hurt": "눈을 감고 뒤로 젖혀진 피격 단일 포즈. 자동 측정 대신 4배 머리 크롭으로 앵커와 비교했다.",
	"shield": "팔 올리기부터 얼굴 앞 교차 방어와 유지까지 6프레임. 장벽 이펙트는 없다.",
	"attack": "vector_side 원본과 머리 배율을 그대로 쓴 128px 기본 공격 예비 줄. 배율 축소 없이 공통 x 이동 +6px로 맞췄다.",
	"vector_side": "웅크림·밀어내기·직선 펀치·유지·회복이 읽히는 6프레임 돌진 펀치. 이펙트는 없다.",
	"vector_upper": "웅크림에서 이륙해 주먹을 머리 위로 올리고 공중 회복하는 6프레임 상승 타격.",
	"compression_stomp": "무릎 들기·내리찍기·깊은 충격 스쿼트·유지·복귀의 6프레임 중력 스톰프.",
	"air_side": "전 프레임 공중에서 챔버·직선 비행 펀치·유지·회복하는 6프레임 동작.",
	"meteor_kick": "공중 접기부터 대각 하강과 착지·회복까지. 전신 포즈의 y 위치만 보정해 들림을 41/21/9/4/0/0px로 만들었다.",
	"vector_shift": "공격 판정 없는 순수 가속. 웅크림·발사·수평 유선형 유지·직립 복귀의 6프레임.",
	"gravity_brake": "스키드·발 고정·팔 당김·양옆 밀기·유지·회복의 6프레임 급정지.",
	"slingshot_start": "손을 뒤로 뺐다가 빈 손바닥을 앞으로 내밀고 유지하는 6프레임 궁극기 시작. 중력핵은 그리지 않았다.",
	"tumble": "한 바퀴 뒤회전을 완성하는 6프레임 공중 회전. 자동 측정이 불가능해 4배 머리 크롭으로 앵커와 비교했다.",
}


def candidate_path(row: str) -> Path:
	return BAKEOFF / f"nova_male-{row}-v1.png"


def skin_component_center(image: Image.Image) -> tuple[int, int]:
	rgba = image.convert("RGBA")
	w, h = rgba.size
	mask = set()
	for y in range(h):
		for x in range(w):
			r, g, b, a = rgba.getpixel((x, y))
			if a and r >= 130 and r > g * 1.12 and g > b * 1.05:
				mask.add((x, y))
	components = []
	while mask:
		stack = [mask.pop()]
		component = []
		while stack:
			point = stack.pop()
			component.append(point)
			x, y = point
			for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
				if neighbor in mask:
					mask.remove(neighbor)
					stack.append(neighbor)
		components.append(component)
	if not components:
		return w // 2, h // 3
	face = max(components, key=len)
	return round(sum(x for x, _ in face) / len(face)), round(sum(y for _, y in face) / len(face))


def head_crop(frame: Image.Image, size: int = 64) -> Image.Image:
	cx, cy = skin_component_center(frame)
	left = max(0, min(frame.width - size, cx - size // 2))
	top = max(0, min(frame.height - size, cy - size // 2))
	return frame.crop((left, top, left + size, top + size))


def make_head_board(row: str) -> None:
	with Image.open(ANCHOR) as opened:
		anchor = opened.convert("RGBA").crop((0, 0, 128, 128))
	with Image.open(candidate_path(row)) as opened:
		sheet = opened.convert("RGBA")
	cell = ROWS[row]["cell"]
	frames = [sheet.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(ROWS[row]["frames"])]
	crops = [head_crop(anchor), *(head_crop(frame) for frame in frames)]
	zoom = 4
	label_h = 18
	board = Image.new("RGBA", (len(crops) * 64 * zoom, 64 * zoom + label_h), (13, 18, 29, 255))
	draw = ImageDraw.Draw(board)
	for index, crop in enumerate(crops):
		resized = crop.resize((64 * zoom, 64 * zoom), Image.Resampling.NEAREST)
		board.alpha_composite(resized, (index * 64 * zoom, label_h))
		draw.text((index * 64 * zoom + 4, 2), "ANCHOR" if index == 0 else f"F{index}", fill=(235, 240, 248, 255))
	board.save(REPORT / row / "head-crops.png")


def enrich_and_write_json(row: str, config: dict) -> dict:
	metrics_path = REPORT / row / "metrics.json"
	metrics = json.loads(metrics_path.read_text(encoding="utf-8"))
	head = json.loads((REPORT / row / "head-scale.json").read_text(encoding="utf-8"))[0]
	metrics["head_check"] = {
		"method": config["head"],
		"result": head,
		"note": "신뢰 프레임이 2개 미만이라 4배 머리 크롭을 사용" if config["head"] == "4x_head_crop" else "점수 0.6 이상 자동 측정 중앙값 사용",
	}
	if row == "attack":
		metrics["attack_fit"] = {
			"source": "vector_side raw",
			"head_matched_factor": 0.260417,
			"used_factor": metrics["summary"]["common_scale"],
			"common_offset_x": metrics["summary"]["common_offset_x"],
			"reduced_to_fit": False,
		}
	if row == "meteor_kick":
		metrics["whole_pose_y_correction"] = {
			"source_pixel_shifts": [0, 0, -35, 42, 56, 56],
			"output_lifts": [frame["lift"] for frame in metrics["frames"]],
			"frame_scaling_changed": False,
		}
	metrics_path.write_text(json.dumps(metrics, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

	metadata = {
		"note": NOTES[row],
		"fps": config["fps"],
		"frames": config["frames"],
	}
	if config["cell"] == 192:
		metadata["cell"] = 192
		metadata["feet"] = 152
	json_path = candidate_path(row).with_suffix(".json")
	json_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	return metrics


def make_overview() -> None:
	label_w = 180
	row_gap = 8
	header_h = 32
	width = label_w + 6 * 192
	height = header_h + sum(ROWS[row]["cell"] + row_gap for row in ROWS)
	board = Image.new("RGBA", (width, height), (13, 18, 29, 255))
	draw = ImageDraw.Draw(board)
	draw.text((8, 8), "NOVA MALE PHASE 2 - 4x-inspected final candidates", fill=(240, 245, 252, 255))
	y = header_h
	for row, config in ROWS.items():
		with Image.open(candidate_path(row)) as opened:
			sheet = opened.convert("RGBA")
		board.alpha_composite(sheet, (label_w, y))
		draw.text((8, y + 8), f"{row}\n{config['frames']}f @ {config['fps']}\ncell {config['cell']}", fill=(220, 228, 240, 255), spacing=4)
		y += config["cell"] + row_gap
	board.save(REPORT / "overview.png")


def write_readme(summary: dict) -> None:
	lines = [
		"# CODEX-ART-52A · Nova 남성 phase 2 결과",
		"",
		"채택된 `nova_male-idle-v2`를 기준으로 기본 시트 후보 6개와 192px 기술 시트 후보 9개를 카드 순서대로 완성했다. 모든 그림은 후보이며 `smash-nine-prototype/`은 변경하지 않았다. 생성은 Codex 내장 ImageGen을 사용했고, 실제 사용한 원본과 실패한 1차 원본은 `art/raw/nova-52a/`에 보관했다.",
		"",
		"## 행별 결과",
		"",
		"| 행 | 파일 | 프레임 / fps | 머리 검사 | 배율 | 들림(px) | 디테일 |",
		"| --- | --- | ---: | --- | ---: | ---: | ---: |",
	]
	for row, config in ROWS.items():
		item = summary[row]
		head = item["head"]
		if config["head"] == "head_scale":
			head_text = f"{head['median']:.2f} ({head['used']}f)"
		else:
			head_text = "4× 크롭"
		lines.append(
			f"| `{row}` | `nova_male-{row}-v1.png` | {config['frames']} / {config['fps']} | {head_text} | {item['factor']:.6f} | {item['lift'][0]}–{item['lift'][1]} | {item['detail'][0]:.2f}–{item['detail'][1]:.2f} |"
		)
	lines += [
		"",
		"## 배율과 위치 판단",
		"",
		"- `walk`, `shield`, `attack`, 기술 8개는 `head_scale.py`에서 점수 0.6 이상 프레임이 2개 이상 나와 중앙값을 사용했다. 최종 중앙값은 0.96–1.04이다.",
		"- `jump`, `fall`, `hurt`는 한 장짜리 포즈이므로 자동 수치를 채택하지 않고 각 `head-crops.png`의 4배 크롭과 앵커의 머리 크기를 비교했다. `fall`의 101px 높이는 다리를 아래로 뻗은 자세 때문이며 크기 기준으로 쓰지 않았다.",
		"- `tumble`은 회전 자세라 자동 신뢰 프레임이 0개였다. 높이로 배율을 정하지 않고 4배 머리 크롭에서 0.250000의 머리가 약 13% 크게 보여 `0.220000`으로 맞췄다.",
		"- 기본 `attack`은 `vector_side`와 같은 `0.260417`을 유지했다. 128px 칸에서도 들어가므로 축소하지 않았고, 전 프레임 공통 x 이동 `+6px`만 사용했다.",
		"- `meteor_kick`은 2차 원본의 완성된 전신 포즈를 셀 안에서만 위아래로 옮겨 하강 들림을 `41/21/9/4/0/0px`로 만들었다. 프레임 크기와 배율은 모두 동일하다.",
		"",
		"## 검사",
		"",
		"- 전 행: LANCZOS, 선명화 60, 자동 디스필, 팔레트 없음.",
		"- 전 행: 테두리 비움, 최소 4px 여백, 초록 번짐 0px, 이진 알파 통과.",
		"- 전 행: 내부 디테일 최솟값 95.30 이상으로 남성 기준 84를 통과.",
		"- 모든 최종 프레임을 앵커 옆 4배 `compare.png`로 직접 확인했다.",
		"",
		"![Nova male phase 2 후보 전체](./overview.png)",
		"",
		"위 판은 후보 15개를 원래 게임 픽셀 배율로 쌓은 요약이다. 각 행의 정확한 4배 비교는 해당 폴더의 `compare.png`에 있다.",
		"",
		"## 남아 있는 시각 문제",
		"",
		"- `compression_stomp` F2는 발이 바로 아래보다 앞쪽으로 내려와 스톰프보다 짧은 앞차기처럼 잠깐 보일 수 있다.",
		"- `vector_shift`의 선두 주먹은 굽혀져 있지만 정지 화면에서는 공격 준비처럼 보일 수 있다. 이펙트 없이 몸의 수평 유선형으로 이동 동작을 구분했다.",
		"- `hurt`는 얼굴을 정면에 가깝게 돌린 반동 자세라 앵커보다 얼굴 면적이 커 보이지만, 4배 크롭에서 머리 외곽 크기는 맞췄다.",
		"- `tumble`은 피격 상태를 강조해 여섯 프레임 모두 눈을 감고 있다. 얼굴은 전 프레임 보이지만 표정 변화는 작다.",
		"- 정지 4배 검수만 수행했으므로 실제 10/12/21fps 루프 박자는 리드가 모션 뷰어에서 확인해야 한다.",
		"",
		"## 현재 상태",
		"",
		"카드의 모든 행을 완료했다. 도달하지 못한 행은 없다. 제품 파일을 바꾸지 않은 후보 작업이므로 Godot 실행 테스트는 하지 않았다.",
	]
	(REPORT / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_commit_script() -> None:
	paths = ["reports/codex-art-52a"]
	for row in ROWS:
		paths += [f"art/bakeoff/nova/nova_male-{row}-v1.png", f"art/bakeoff/nova/nova_male-{row}-v1.json"]
	quoted = ",\n\t".join(f"'{path}'" for path in paths)
	content = f"""$ErrorActionPreference = 'Stop'\n\n$paths = @(\n\t{quoted}\n)\n\ngit add -- $paths\ngit commit -m \"art: build Nova male phase 2 rows`n`nCo-Authored-By: Codex <noreply@openai.com>\"\n"""
	(REPORT / "commit.ps1").write_text(content, encoding="utf-8")


def main() -> None:
	common_prompt = (REPORT / "jump-fall-hurt/prompt.txt").read_text(encoding="utf-8")
	for row in ("jump", "fall", "hurt"):
		(REPORT / row / "prompt.txt").write_text(common_prompt, encoding="utf-8")
	(REPORT / "attack/prompt.txt").write_text(
		"`attack`은 별도 생성하지 않고 `vector_side`의 최종 원본과 머리 배율을 128px 칸에 재사용했다.\n"
		"최종 생성 프롬프트는 `../vector_side/prompt.txt`와 동일하며, 128px 적합화에는 전 프레임 공통 x 이동 +6px만 사용했다.\n",
		encoding="utf-8",
	)
	summary = {}
	for row, config in ROWS.items():
		metrics = enrich_and_write_json(row, config)
		head = metrics["head_check"]["result"]
		s = metrics["summary"]
		summary[row] = {
			"file": candidate_path(row).name,
			"factor": s["common_scale"],
			"head_method": config["head"],
			"head": head,
			"height": s["body_height_range"],
			"detail": s["interior_detail_range"],
			"lift": s["lift_range"],
			"spill": s["remaining_spill_pixels"],
			"border": s["borders_clear"],
			"margin4": s["all_have_4px_margin"],
			"offset_x": s["common_offset_x"],
		}
	for row in ("jump", "fall", "hurt", "tumble"):
		make_head_board(row)
	(REPORT / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
	make_overview()
	write_readme(summary)
	write_commit_script()


if __name__ == "__main__":
	main()
