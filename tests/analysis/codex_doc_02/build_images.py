"""Build the ten CODEX-DOC-02 picture-report boards from repository assets.

Run from the repository root with the bundled Codex Python runtime.  Titles and
captions are parsed directly from the task card so the contracted Korean text is
never duplicated or hand-transcribed here.
"""

from __future__ import annotations

import io
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[3]
CARD = ROOT / "design/tasks/CODEX-DOC-02.md"
OUT = ROOT / "reports/sprite-audit-2026-10-16/images"

BEFORE = "de5e589"
AFTER = "1b61483"
GUARD_BEFORE = "28ffe0a"
GUARD_AFTER = "de5e589"

BG = "#101522"
PANEL_BG = "#0b101b"
PANEL_LINE = "#2b3547"
WHITE = "#ffffff"
MUTED = "#b9c4d6"
YELLOW = "#ffd166"
RED = "#e5484d"
GREEN = "#30a46c"

TITLE_FONT = ImageFont.truetype("C:/Windows/Fonts/malgunbd.ttf", 44)
TAG_FONT = ImageFont.truetype("C:/Windows/Fonts/malgunbd.ttf", 28)
LABEL_FONT = ImageFont.truetype("C:/Windows/Fonts/malgunbd.ttf", 26)
CAPTION_FONT = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 28)
SMALL_FONT = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 24)


def card_contract() -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    for line in CARD.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if len(cells) != 5 or not cells[0].isdigit():
            continue
        number, filename, _panels, title, caption = cells
        rows[number] = {
            "filename": filename.strip("`"),
            "title": title,
            "caption": caption,
        }
    if len(rows) != 10:
        raise RuntimeError(f"expected 10 contract rows, found {len(rows)}")
    return rows


def git_bytes(commit: str, path: str) -> bytes:
    result = subprocess.run(
        ["git", "show", f"{commit}:{path}"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return result.stdout


def git_image(commit: str, path: str) -> Image.Image:
    return Image.open(io.BytesIO(git_bytes(commit, path))).convert("RGBA")


def clip_frame(commit: str, form: str, scene: str, frame: int, fx: bool = True) -> Image.Image:
    suffix = "fx" if fx else "nofx"
    data = git_bytes(commit, f"art/clips/{form}/{scene}-{suffix}.webp")
    image = Image.open(io.BytesIO(data))
    if frame >= getattr(image, "n_frames", 1):
        raise IndexError(f"{commit} {form}/{scene}: frame {frame} >= {image.n_frames}")
    image.seek(frame)
    return image.convert("RGB")


def diff_bbox(commit: str, form: str, scene: str, frame: int) -> tuple[int, int, int, int] | None:
    fx = clip_frame(commit, form, scene, frame, True)
    nofx = clip_frame(commit, form, scene, frame, False)
    diff = ImageChops.difference(fx, nofx).convert("L")
    mask = diff.point(lambda value: 255 if value >= 18 else 0)
    return mask.getbbox()


def crop_box(
    commit: str,
    form: str,
    scene: str,
    frame: int,
    size: tuple[int, int],
    *,
    floor: bool = False,
) -> tuple[int, int, int, int]:
    image = clip_frame(commit, form, scene, frame, True)
    width, height = size
    bbox = diff_bbox(commit, form, scene, frame)
    if bbox:
        cx = (bbox[0] + bbox[2]) / 2
        cy = (bbox[1] + bbox[3]) / 2
    else:
        cx, cy = image.width / 2, image.height * 0.68
    if floor:
        top = image.height - height
    else:
        top = int(round(cy - height / 2))
        top = max(0, min(image.height - height, top))
    left = int(round(cx - width / 2))
    left = max(0, min(image.width - width, left))
    return left, top, left + width, top + height


def frame_crop(
    commit: str,
    form: str,
    scene: str,
    frame: int,
    box: tuple[int, int, int, int],
) -> Image.Image:
    return clip_frame(commit, form, scene, frame, True).crop(box)


def sheet_frame(commit: str, path: str, cell: int, row: int, frame: int) -> Image.Image:
    sheet = git_image(commit, path)
    x = frame * cell
    y = row * cell
    return sheet.crop((x, y, x + cell, y + cell))


def board(number: str, contract: dict[str, dict[str, str]]) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    image = Image.new("RGB", (1600, 900), BG)
    draw = ImageDraw.Draw(image)
    draw.text((60, 34), contract[number]["title"], font=TITLE_FONT, fill=WHITE)
    return image, draw


def captions(draw: ImageDraw.ImageDraw, number: str, contract: dict[str, dict[str, str]], y: int = 750) -> None:
    lines = contract[number]["caption"].split(" / ")
    if len(lines) != 2:
        raise RuntimeError(f"caption {number} does not have two lines")
    draw.text((60, y), lines[0], font=CAPTION_FONT, fill=WHITE)
    draw.text((60, y + 48), lines[1], font=CAPTION_FONT, fill=MUTED)


def tag(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, colour: str) -> None:
    x, y = xy
    draw.rounded_rectangle((x, y, x + 54, y + 38), radius=8, fill=colour)
    bbox = draw.textbbox((0, 0), text, font=TAG_FONT)
    draw.text((x + (54 - (bbox[2] - bbox[0])) / 2, y + 1), text, font=TAG_FONT, fill=WHITE)


def panel(draw: ImageDraw.ImageDraw, image: Image.Image, xy: tuple[int, int], label: str | None = None) -> None:
    x, y = xy
    draw.rectangle((x - 2, y - 2, x + image.width + 1, y + image.height + 1), fill=PANEL_LINE)
    if "A" in image.getbands():
        opaque = Image.new("RGB", image.size, PANEL_BG)
        opaque.paste(image, (0, 0), image.getchannel("A"))
    else:
        opaque = image.convert("RGB")
    draw._image.paste(opaque, (x, y))
    if label:
        draw.text((x, y - 38), label, font=LABEL_FONT, fill=WHITE)


def make_summary(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("01", contract)
    forms = [
        ("Frey", "frey/frey_sheet.png", GREEN, YELLOW),
        ("Luna", "luna/luna_sheet.png", GREEN, YELLOW),
        ("Brave", "luna/luna_brave_sheet.png", GREEN, YELLOW),
        ("Yuki", "yuki/yuki_sheet.png", GREEN, YELLOW),
        ("Nova 남", "nova/nova_male_sheet.png", GREEN, YELLOW),
        ("Nova 여", "nova/nova_female_sheet.png", RED, YELLOW),
        ("Rio 남", "rio/rio_male_sheet.png", RED, YELLOW),
        ("Rio 여", "rio/rio_female_sheet.png", RED, YELLOW),
    ]
    start_x, gap, floor_y = 25, 194, 500
    for index, (name, relative, sprite_state, effect_state) in enumerate(forms):
        x = start_x + index * gap
        sprite = sheet_frame(
            AFTER,
            f"smash-nine-prototype/assets/art/{relative}",
            128,
            0,
            2,
        )
        sprite = alpha_crop(sprite).resize(
            (alpha_crop(sprite).width * 2, alpha_crop(sprite).height * 2),
            Image.Resampling.NEAREST,
        )
        draw.text((x, 128), name, font=LABEL_FONT, fill=WHITE)
        image.paste(sprite, (x + (180 - sprite.width) // 2, floor_y - sprite.height), sprite)
        draw.ellipse((x + 57, 530, x + 81, 554), fill=sprite_state)
        draw.ellipse((x + 102, 530, x + 126, 554), fill=effect_state)
        if index == 0:
            draw.text((x + 43, 568), "그림", font=SMALL_FONT, fill=MUTED)
            draw.text((x + 91, 600), "이펙트", font=SMALL_FONT, fill=MUTED)
    captions(draw, "01", contract, 680)
    draw.text((60, 786), "왼쪽 점 = 그림 · 오른쪽 점 = 이펙트", font=CAPTION_FONT, fill=MUTED)
    return image


def make_guard(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("02", contract)
    forms = ["frey", "luna", "luna_brave", "yuki", "nova", "rio"]
    names = ["Frey", "Luna", "Brave", "Yuki", "Nova", "Rio"]
    frame = 29
    floor_source_y = 500
    start_x, gap, top_y, bottom_y = 105, 246, 170, 425
    tag(draw, (28, top_y + 72), "전", RED)
    tag(draw, (28, bottom_y + 72), "후", GREEN)
    for index, (form, name) in enumerate(zip(forms, names)):
        x = start_x + index * gap
        box = crop_box(GUARD_AFTER, form, "guard", frame, (220, 190), floor=True)
        before = frame_crop(GUARD_BEFORE, form, "guard", frame, box)
        after = frame_crop(GUARD_AFTER, form, "guard", frame, box)
        draw.text((x, 128), name, font=LABEL_FONT, fill=WHITE)
        panel(draw, before, (x, top_y))
        panel(draw, after, (x, bottom_y))
        line_y = floor_source_y - box[1]
        draw.line((x, top_y + line_y, x + 219, top_y + line_y), fill=YELLOW, width=4)
        draw.line((x, bottom_y + line_y, x + 219, bottom_y + line_y), fill=YELLOW, width=4)
    captions(draw, "02", contract, 680)
    return image


def make_j_trail(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("03", contract)
    examples = [
        ("Frey", "frey", "ground-j", 21, None),
        ("Rio", "rio", "ground-j", 4, (200, 300, 680, 530)),
        ("Luna", "luna", "air-j", 9, (220, 250, 700, 480)),
    ]
    for x, (label, form, scene, frame, fixed_box) in zip([56, 560, 1064], examples):
        box = fixed_box or crop_box(BEFORE, form, scene, frame, (480, 230))
        before = frame_crop(BEFORE, form, scene, frame, box)
        after = frame_crop(AFTER, form, scene, frame, box)
        draw.text((x, 126), label, font=LABEL_FONT, fill=WHITE)
        panel(draw, before, (x, 170))
        panel(draw, after, (x, 440))
        tag(draw, (x + 10, 180), "전", RED)
        tag(draw, (x + 10, 450), "후", GREEN)
    captions(draw, "03", contract, 710)
    return image


def make_three_compare(
    number: str,
    contract: dict[str, dict[str, str]],
    examples: list[tuple[str, str, str, int, bool]],
    *,
    floor_line: bool = False,
) -> Image.Image:
    image, draw = board(number, contract)
    x_positions = [56, 560, 1064]
    top_y, bottom_y = 170, 440
    for x, (label, form, scene, frame, floor) in zip(x_positions, examples):
        box = crop_box(BEFORE, form, scene, frame, (480, 230), floor=floor)
        before = frame_crop(BEFORE, form, scene, frame, box)
        after = frame_crop(AFTER, form, scene, frame, box)
        draw.text((x, 126), label, font=LABEL_FONT, fill=WHITE)
        panel(draw, before, (x, top_y))
        panel(draw, after, (x, bottom_y))
        tag(draw, (x + 10, top_y + 10), "전", RED)
        tag(draw, (x + 10, bottom_y + 10), "후", GREEN)
        if floor_line:
            floor_source_y = 518
            line_y = floor_source_y - box[1]
            if 0 <= line_y < 230:
                draw.line((x, top_y + line_y, x + 479, top_y + line_y), fill=YELLOW, width=4)
                draw.line((x, bottom_y + line_y, x + 479, bottom_y + line_y), fill=YELLOW, width=4)
    captions(draw, number, contract, 710)
    return image


def make_two_compare(
    number: str,
    contract: dict[str, dict[str, str]],
    examples: list[tuple[str, str, str, int, bool]],
    *,
    floor_line: bool = False,
    highlight_target: bool = False,
) -> Image.Image:
    image, draw = board(number, contract)
    x_positions = [280, 840]
    top_y, bottom_y = 170, 440
    for x, (label, form, scene, frame, floor) in zip(x_positions, examples):
        box = crop_box(BEFORE, form, scene, frame, (480, 230), floor=floor)
        before = frame_crop(BEFORE, form, scene, frame, box)
        after = frame_crop(AFTER, form, scene, frame, box)
        draw.text((x, 126), label, font=LABEL_FONT, fill=WHITE)
        panel(draw, before, (x, top_y))
        panel(draw, after, (x, bottom_y))
        tag(draw, (x + 10, top_y + 10), "전", RED)
        tag(draw, (x + 10, bottom_y + 10), "후", GREEN)
        if floor_line:
            floor_source_y = 518
            line_y = floor_source_y - box[1]
            draw.line((x, top_y + line_y, x + 479, top_y + line_y), fill=YELLOW, width=4)
            draw.line((x, bottom_y + line_y, x + 479, bottom_y + line_y), fill=YELLOW, width=4)
        if highlight_target and x == x_positions[0]:
            draw.rectangle((x + 250, top_y + 28, x + 346, top_y + 210), outline=YELLOW, width=4)
            draw.rectangle((x + 250, bottom_y + 28, x + 346, bottom_y + 210), outline=YELLOW, width=4)
    captions(draw, number, contract, 710)
    return image


def alpha_crop(frame: Image.Image, pad: int = 2) -> Image.Image:
    bbox = frame.getbbox()
    if not bbox:
        return frame
    left = max(0, bbox[0] - pad)
    top = max(0, bbox[1] - pad)
    right = min(frame.width, bbox[2] + pad)
    bottom = min(frame.height, bbox[3] + pad)
    return frame.crop((left, top, right, bottom))


def make_rio_head(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("08", contract)
    base_m = "smash-nine-prototype/assets/art/rio/rio_male_sheet.png"
    base_f = "smash-nine-prototype/assets/art/rio/rio_female_sheet.png"
    moves_f = "smash-nine-prototype/assets/art/rio/rio_female_moves_sheet.png"
    male = [
        ("×1.00", sheet_frame(AFTER, base_m, 128, 0, 2), 120),
        ("×0.76", sheet_frame(AFTER, base_m, 128, 5, 2), 120),
    ]
    female = [
        ("×1.00", sheet_frame(AFTER, base_f, 128, 0, 2), 120),
        ("×0.86", sheet_frame(AFTER, base_f, 128, 5, 2), 120),
        ("×0.72", sheet_frame(AFTER, moves_f, 192, 2, 2), 152),
        ("×0.72", sheet_frame(AFTER, moves_f, 192, 5, 2), 152),
    ]

    def draw_group(
        group: list[tuple[str, Image.Image, int]],
        centres: list[int],
        floor_y: int,
        guide_top: int,
        guide_chin: int,
        group_left: int,
        group_right: int,
        group_label: str,
        label_y: int,
    ) -> None:
        draw.text((group_left, label_y), group_label, font=LABEL_FONT, fill=WHITE)
        draw.line((group_left, floor_y, group_right, floor_y), fill=PANEL_LINE, width=4)
        for (ratio, frame, source_floor), centre in zip(group, centres):
            scaled = frame.resize((frame.width * 3, frame.height * 3), Image.Resampling.NEAREST)
            left = centre - scaled.width // 2
            top = floor_y - source_floor * 3
            image.paste(scaled, (left, top), scaled)
            bbox = draw.textbbox((0, 0), ratio, font=LABEL_FONT)
            draw.text((centre - (bbox[2] - bbox[0]) // 2, floor_y + 8), ratio, font=LABEL_FONT, fill=MUTED)
        draw.line((group_left, guide_top, group_right, guide_top), fill=YELLOW, width=2)
        draw.line((group_left, guide_chin, group_right, guide_chin), fill=YELLOW, width=2)

    # Both groups use full 3x figures fixed to their own shared floor line.
    # Guide positions are the idle head template's top and chin at that scale.
    draw_group(male, [370, 790], 400, 130, 220, 55, 990, "Rio 남", 104)
    draw_group(female, [190, 555, 920, 1320], 700, 409, 499, 55, 1545, "Rio 여", 376)
    captions(draw, "08", contract, 760)
    return image


def make_nova_hurt(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("09", contract)
    sources = [
        ("지금 (v1)", "art/bakeoff/nova/nova_female-hurt-v1.png"),
        ("후보 (v2)", "art/bakeoff/nova/nova_female-hurt-v2.png"),
    ]
    x_positions = [250, 830]
    panel_size = (520, 384)
    for index, (x, (label, path)) in enumerate(zip(x_positions, sources)):
        frame = git_image(AFTER, path)
        if frame.width > 128:
            frame = frame.crop((0, 0, 128, 128))
        scaled = frame.resize((frame.width * 3, frame.height * 3), Image.Resampling.NEAREST)
        draw.text((x, 135), label, font=LABEL_FONT, fill=WHITE)
        panel_bg = Image.new("RGBA", panel_size, PANEL_BG)
        art_x = (panel_size[0] - scaled.width) // 2
        panel_bg.alpha_composite(scaled, (art_x, 0))
        panel(draw, panel_bg, (x, 180))
        floor_y = 180 + 120 * 3
        draw.line((x, floor_y, x + panel_size[0] - 1, floor_y), fill=YELLOW, width=4)
        if index == 0:
            bracket_x = x + art_x + 112 * 3 + 12
            foot_y = 180 + 112 * 3
            draw.line((bracket_x, foot_y, bracket_x, floor_y), fill=YELLOW, width=4)
            draw.line((bracket_x - 8, foot_y, bracket_x + 8, foot_y), fill=YELLOW, width=4)
            draw.line((bracket_x - 8, floor_y, bracket_x + 8, floor_y), fill=YELLOW, width=4)
    captions(draw, "09", contract, 660)
    return image


def make_bloom(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("06", contract)
    frey = sheet_frame(
        AFTER,
        "smash-nine-prototype/assets/art/frey/frey_sheet.png",
        128,
        0,
        2,
    ).resize((256, 256), Image.Resampling.NEAREST)
    bloom_strip = git_image(
        AFTER,
        "smash-nine-prototype/assets/art/effects/skill/luna_star_bloom.png",
    )
    bloom = bloom_strip.crop((4 * 256, 0, 5 * 256, 256)).resize(
        (308, 308), Image.Resampling.NEAREST
    )
    panel_size = (600, 430)
    frey_xy = (172, 130)
    chest = (frey_xy[0] + 128, frey_xy[1] + 120)
    bloom_xy = (chest[0] - bloom.width // 2, chest[1] - bloom.height // 2)
    for x, state, colour, bloom_first in [
        (170, "전", RED, False),
        (830, "후", GREEN, True),
    ]:
        composite = Image.new("RGBA", panel_size, PANEL_BG)
        if bloom_first:
            composite.alpha_composite(bloom, bloom_xy)
            composite.alpha_composite(frey, frey_xy)
        else:
            composite.alpha_composite(frey, frey_xy)
            composite.alpha_composite(bloom, bloom_xy)
        panel(draw, composite, (x, 165))
        tag(draw, (x + 10, 175), state, colour)
    captions(draw, "06", contract, 650)
    return image


def make_kept(contract: dict[str, dict[str, str]]) -> Image.Image:
    image, draw = board("10", contract)
    examples = [
        ("Brave Luna", "luna_brave", "aura", 0),
        ("Rio", "rio", "ultimate", 32),
    ]
    for x, (label, form, scene, frame) in zip([80, 585], examples):
        box = crop_box(AFTER, form, scene, frame, (460, 280), floor=True)
        art = frame_crop(AFTER, form, scene, frame, box)
        draw.text((x, 128), label, font=LABEL_FONT, fill=WHITE)
        panel(draw, art, (x, 175))
    frey = sheet_frame(
        AFTER,
        "smash-nine-prototype/assets/art/frey/frey_sheet.png",
        128,
        0,
        2,
    ).resize((256, 256), Image.Resampling.NEAREST)
    x, y = 1225, 185
    draw.text((x, 128), "Frey · 피격 상자 42×64", font=LABEL_FONT, fill=WHITE)
    panel(draw, frey, (x, y))
    # Player origin is at the foot line (64,120); draw the 42x64 box at 2x.
    left = x + (64 - 21) * 2
    top = y + (120 - 64) * 2
    right = x + (64 + 21) * 2
    bottom = y + 120 * 2
    draw.rectangle((left, top, right, bottom), outline=YELLOW, width=4)
    captions(draw, "10", contract, 660)
    return image


def write_images_md() -> None:
    text = """# CODEX-DOC-02 이미지 출처와 프레임

프레임 번호는 0부터 센 값이다. `전`과 `후`는 각 비교에서 같은 번호를 사용했다.

| 파일 | 패널 출처 |
|---|---|
| `01-summary.png` | `1b61483`의 8형태 base sheet `idle`, frame 2 (Frey, Luna, Brave Luna, Yuki, Nova 남/여, Rio 남/여), 2× NEAREST |
| `02-guard.png` | `guard-fx.webp`, frame 29, 6형태. 전 `28ffe0a`, 후 `de5e589`; 바닥 기준선 y=500과 그 아래 40px 표시 |
| `03-j-trail.png` | Frey `ground-j` f21; Rio `ground-j` f4; Luna `air-j` f9. 전 `de5e589`, 후 `1b61483` |
| `04-doubled.png` | Rio `rune` f25; Nova `ground-j` f4; Nova `up-j` f4. 전 `de5e589`, 후 `1b61483` |
| `05-ground-down.png` | Frey `down-j` f8; Luna `down-j` f8. 전 `de5e589`, 후 `1b61483`; 바닥선 y=518 표시 |
| `06-bloom.png` | `1b61483` Frey base sheet `idle` f2(2×)와 `effects/skill/luna_star_bloom.png` f4(2× 게임 표시 크기)의 실제 스프라이트 합성; 전은 별꽃을 Frey 위, 후는 Frey 뒤에 배치 |
| `07-ultimate-flash.png` | Luna `transform` f45; Nova `ultimate` f41; Yuki `ultimate` f118. 전 `de5e589`, 후 `1b61483` |
| `08-rio-head.png` | `1b61483` sheet frame 2: Rio 남 `idle`, base `attack`; Rio 여 `idle`, base `attack`, moves `low_sweep`, moves `dimension_slash`; 모두 3× NEAREST, 형태별 공통 바닥선 |
| `09-nova-hurt.png` | `1b61483`: `art/bakeoff/nova/nova_female-hurt-v1.png` 첫 셀과 `-v2.png` frame 0, 모두 3×; 셀 바닥선 y=120, v1 발끝 y=112의 8px 간격 표시 |
| `10-kept.png` | `1b61483`: Brave Luna `aura` f0, Rio `ultimate` f32; Frey base sheet `idle` f2(2×)와 42×64 피격 상자 |

## 400×225 확인

`images/contact.png`에는 10개 이미지를 각각 400×225로 NEAREST 축소해 그 크기 그대로 2열로 배치했다.

| 파일 | 400×225 판독 결과 |
|---|---|
| 01 | 2×의 8형태와 그림/이펙트 점의 의미가 구분된다. |
| 02 | 섬광이 없는 6형태의 전·후 호와 노란 바닥선이 구분된다. |
| 03 | Frey·Rio·Luna 모두 후 궤적이 얇아졌고 Luna 전신이 보인다. |
| 04 | Rio의 공용 베기 제거와 Nova 두 전용 신호가 구분된다. |
| 05 | 노란 바닥선 위·아래의 궤적 차이가 구분된다. |
| 06 | 같은 Frey와 별꽃의 전후 레이어 순서 차이가 구분된다. |
| 07 | 세 궁극기의 전·후 투명도 차이가 구분된다. |
| 08 | 같은 3× 전신, 공통 바닥선, 머리 위·턱 가이드가 두 그룹 모두 구분된다. |
| 09 | 같은 크기의 두 패널과 v1의 8px 간격 브래킷이 구분된다. |
| 10 | 유지 효과 두 개와 2× Frey의 42×64 상자가 구분된다. |

## 표시하지 못한 것

- Nova·Rio 여성형의 실제 이펙트 클립은 캡처 도구가 남성형만 기록했으므로 넣을 수 없었다. 여성형 스프라이트 자체는 01, 08, 09에 실제 시트/후보 이미지로 표시했다.
"""
    (OUT.parent / "images.md").write_text(text, encoding="utf-8", newline="\n")


def save_all() -> None:
    contract = card_contract()
    OUT.mkdir(parents=True, exist_ok=True)
    images: list[tuple[str, Image.Image]] = []
    images.append((contract["01"]["filename"], make_summary(contract)))
    images.append((contract["02"]["filename"], make_guard(contract)))
    images.append((contract["03"]["filename"], make_j_trail(contract)))
    images.append((contract["04"]["filename"], make_three_compare("04", contract, [
        ("Rio 룬 반격", "rio", "rune", 25, False),
        ("Nova 옆 J", "nova", "ground-j", 4, False),
        ("Nova 위 J", "nova", "up-j", 4, False),
    ])))
    images.append((contract["05"]["filename"], make_two_compare("05", contract, [
        ("Frey", "frey", "down-j", 8, True),
        ("Luna", "luna", "down-j", 8, True),
    ], floor_line=True)))
    images.append((contract["06"]["filename"], make_bloom(contract)))
    images.append((contract["07"]["filename"], make_three_compare("07", contract, [
        ("Luna", "luna", "transform", 45, False),
        ("Nova", "nova", "ultimate", 41, False),
        ("Yuki", "yuki", "ultimate", 118, False),
    ])))
    images.append((contract["08"]["filename"], make_rio_head(contract)))
    images.append((contract["09"]["filename"], make_nova_hurt(contract)))
    images.append((contract["10"]["filename"], make_kept(contract)))

    contact = Image.new("RGB", (800, 1125), BG)
    for index, (filename, image) in enumerate(images):
        path = OUT / filename
        image.save(path, optimize=True)
        thumb = image.resize((400, 225), Image.Resampling.NEAREST)
        contact.paste(thumb, ((index % 2) * 400, (index // 2) * 225))
    contact.save(OUT / "contact.png", optimize=True)
    write_images_md()

    report = {
        "images": len(images),
        "dimensions": sorted({Image.open(OUT / name).size for name, _ in images}),
        "contact": contact.size,
    }
    print(json.dumps(report, ensure_ascii=False))


if __name__ == "__main__":
    save_all()
