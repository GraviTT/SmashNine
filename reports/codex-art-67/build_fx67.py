from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "smash-nine-prototype" / "assets" / "art"
REPORT = ROOT / "reports" / "codex-art-67"
RAW = ROOT / "art" / "raw" / "fx-67"
OUT = ROOT / "art" / "bakeoff" / "effects"


PALETTES = {
    "common": ["17213D", "2E5D86", "5EC9DD", "DDFBFF", "FFF5B8", "FFFFFF"],
    "status_stun": ["241934", "7C3E82", "D56BA7", "FFD85A", "FFF4B8", "FFFFFF"],
    "status_armor": ["132340", "315E8D", "5FCDE4", "A8F4F4", "FFE58A", "FFFFFF"],
    "frey": ["1A2340", "7B3B2C", "B86A32", "F2AD4F", "FFD77A", "FFF5D0", "FFFFFF"],
    "luna": ["27183D", "662A91", "B846A0", "F477C6", "74DAEA", "FFE06B", "FFF7D8", "FFFFFF"],
    "yuki": ["17213C", "31476C", "2F8FB1", "7ADDE9", "9C302A", "DB533A", "F0C763", "F4E6BC", "FFFFFF"],
    "nova": ["141832", "32245E", "315B8E", "2DBBC7", "79E5D8", "E5C95B", "FFF2AF", "FFFFFF"],
    "rio": ["131B36", "243F70", "2C71A4", "35BFD0", "84EDF0", "D8FBF6", "FFFFFF"],
    "grey": ["171717", "343434", "5F5F5F", "929292", "C5C5C5", "EDEDED", "FFFFFF"],
}


def p(path: str) -> Path:
    return GAME / path


def spec(
    ident: str,
    group: str,
    src: str,
    frames: int,
    frame: tuple[int, int],
    anchor: tuple[int, int],
    fps: float,
    palette: str,
    note: str,
    body: str,
    body_row: int,
    body_frame: int,
    body_cell: int,
    placements: list[tuple[tuple[float, float], tuple[float, float], float]] | None = None,
    body_alt: str | None = None,
    body_alt_row: int | None = None,
    body_alt_frame: int | None = None,
) -> dict:
    return {
        "id": ident,
        "group": group,
        "src": p(src),
        "frames": frames,
        "frame": frame,
        "anchor": anchor,
        "fps": fps,
        "palette": palette,
        "note": note,
        "body": p(body),
        "body_row": body_row,
        "body_frame": body_frame,
        "body_cell": body_cell,
        "placements": placements or [((0.0, -32.0), (1.0, 1.0), 0.0)],
        "body_alt": p(body_alt) if body_alt else None,
        "body_alt_row": body_alt_row if body_alt_row is not None else body_row,
        "body_alt_frame": body_alt_frame if body_alt_frame is not None else body_frame,
    }


CONTRACTS = {
    # Common body/head art. Guard uses the exact shield pose and the three code-selected frames.
    "guard_bubble": spec(
        "common", "common", "effects/skill/guard_bubble.png", 3, (128, 128), (64, 64), 1.0, "common",
        "전 캐릭터 공용 Guard의 평상·피격·패리 3상태를 얇은 청록 방패와 금백 패리광으로 정리",
        "frey/frey_sheet.png", 5, 2, 128,
    ),
    "parry_flash": spec(
        "common", "common", "effects/parry_flash.png", 6, (128, 128), (64, 64), 40.0, "common",
        "몸 중심 패리 성공을 가리지 않는 금백 링·십자 섬광 6프레임",
        "frey/frey_sheet.png", 5, 2, 128,
    ),
    "status_stun": spec(
        "common", "common", "ui/status/stun.png", 1, (24, 24), (12, 12), 0.0, "status_stun",
        "이름표 바로 위에서 읽히는 24px 기절 별 아이콘",
        "frey/frey_sheet.png", 0, 0, 128, [((0.0, -121.0), (1.0, 1.0), 0.0)],
    ),
    "status_super_armor": spec(
        "common", "common", "ui/status/super_armor.png", 1, (24, 24), (12, 12), 0.0, "status_armor",
        "이름표 바로 위에서 읽히는 24px 궁극기 슈퍼아머 방패 아이콘",
        "frey/frey_sheet.png", 0, 0, 128, [((0.0, -121.0), (1.0, 1.0), 0.0)],
    ),
    # Frey.
    "frey_pursuit_mark": spec(
        "frey", "frey", "effects/passive/frey_pursuit_mark.png", 1, (64, 40), (32, 20), 0.0, "frey",
        "대상 머리 위 118px에서 펄스하는 흰금 발키리 날개 V 추격 표식",
        "frey/frey_moves_sheet.png", 0, 4, 192, [((0.0, -118.0), (1.0, 1.0), 0.0)],
    ),
    "frey_spike_ring": spec(
        "frey", "frey", "effects/passive/frey_spike_ring.png", 1, (96, 96), (48, 48), 0.0, "frey",
        "Frey 몸을 비워 둔 0.18초 강스파이크 재입력 금백 날개 고리",
        "frey/frey_moves_sheet.png", 4, 4, 192, [((0.0, -40.0), (1.0, 1.0), 0.0)],
    ),
    "frey_ult_charge": spec(
        "frey", "frey", "vfx/frey_ult_charge.png", 6, (256, 256), (128, 248), 24.0, "frey",
        "발 중앙 앵커와 급강하 방향을 지키는 얇은 금빛 날개 충전 6프레임",
        "frey/frey_moves_sheet.png", 6, 2, 192, [((0.0, 0.0), (0.796, 0.796), 0.0)],
    ),
    # Luna. moon ring was discovered in code in addition to the card's minimum list.
    "luna_star_charge": spec(
        "luna", "luna", "effects/passive/luna_star_charge.png", 1, (18, 18), (9, 9), 0.0, "luna",
        "반경 44px에서 최대 5개가 도는 금백 코어·보라 외곽 별빛 충전",
        "luna/luna_sheet.png", 0, 0, 128,
        [
            ((44.0, -44.0), (1.0, 1.0), 0.0), ((13.6, -2.2), (1.0, 1.0), 0.0),
            ((-35.6, -18.1), (1.0, 1.0), 0.0), ((-35.6, -69.9), (1.0, 1.0), 0.0),
            ((13.6, -85.8), (1.0, 1.0), 0.0),
        ],
    ),
    "luna_brave_aura": spec(
        "luna", "luna", "effects/skill/luna_brave_aura.png", 6, (128, 128), (64, 64), 10.0, "luna",
        "Brave Luna 몸 안쪽을 비운 금백 별·청록 원형 오라 6프레임 루프",
        "luna/luna_brave_moves_sheet.png", 0, 3, 192, [((0.0, -34.0), (1.0, 1.0), 0.0)],
    ),
    "luna_ult_transform": spec(
        "luna", "luna", "vfx/luna_ult_transform.png", 8, (384, 384), (192, 192), 24.0, "luna",
        "가슴 중심에서 9번째 몸 프레임 폭발을 읽히게 하는 별·리본 변신광 8프레임",
        "luna/luna_moves_sheet.png", 5, 2, 192, [((0.0, -42.0), (1.05, 1.05), 0.0)],
    ),
    "luna_moon_ring": spec(
        "luna", "luna", "effects/skill/luna_moon_ring.png", 6, (320, 320), (160, 160), 25.0, "luna",
        "몸 중심 반경 90×COMBAT의 빈 중심을 지키는 청록·분홍 달고리 6프레임",
        "luna/luna_moves_sheet.png", 3, 3, 192, [((0.0, -34.0), (1.429, 1.429), 0.0)],
    ),
    # Yuki.
    "yuki_seal_idle": spec(
        "yuki", "yuki", "effects/yuki_seal_idle.png", 4, (64, 64), (32, 63), 4.0, "yuki",
        "설치점에서 5초간 떠 있는 상아 종이·주홍 인장 결박부 4프레임",
        "yuki/yuki_moves_sheet.png", 5, 4, 192, [((78.0, 28.0), (1.0, 1.0), 0.0)],
    ),
    "yuki_seal_break": spec(
        "yuki", "yuki", "effects/yuki_seal_break.png", 5, (96, 96), (48, 48), 33.333, "yuki",
        "설치 부적이 4~6조각과 연청 불꽃으로 찢어지는 5프레임",
        "yuki/yuki_moves_sheet.png", 5, 4, 192, [((78.0, 0.0), (1.0, 1.0), 0.0)],
    ),
    "yuki_ult_seal": spec(
        "yuki", "yuki", "vfx/yuki_ult_seal.png", 8, (512, 512), (256, 256), 12.0, "yuki",
        "실제 반경 307.5px 결계 중심과 사방 부적을 비워 그린 사방봉진 8프레임 루프",
        "yuki/yuki_moves_sheet.png", 7, 3, 192, [((330.0, 0.0), (1.201, 1.201), 0.0)],
    ),
    # Nova, with both body types checked.
    "nova_momentum_trail": spec(
        "nova", "nova", "effects/skill/nova_momentum_trail.png", 4, (64, 32), (32, 16), 40.0, "nova",
        "속도 204→840과 이동 방향을 따르는 청록→금색 운동량 잔상 4프레임",
        "nova/nova_male_moves_sheet.png", 5, 3, 192, [((0.0, -32.0), (1.0, 1.0), 0.0)],
        "nova/nova_female_moves_sheet.png",
    ),
    "nova_shift_ready": spec(
        "nova", "nova", "effects/skill/nova_shift_ready.png", 5, (128, 128), (64, 64), 35.714, "nova",
        "공중 K 회복 기준 0.6을 알리는 몸 중심 청록·금색 개방 링 5프레임",
        "nova/nova_male_moves_sheet.png", 6, 4, 192, [((0.0, -32.0), (0.879, 0.879), 0.0)],
        "nova/nova_female_moves_sheet.png",
    ),
    "nova_ult_core": spec(
        "nova", "nova", "vfx/nova_ult_core.png", 6, (256, 256), (128, 128), 18.0, "nova",
        "몸 중심에서 105px 떨어져 적을 끄는 암흑 코어·청록금 공전링 6프레임",
        "nova/nova_male_moves_sheet.png", 7, 4, 192, [((157.5, -32.0), (0.825, 0.825), 0.0)],
        "nova/nova_female_moves_sheet.png",
    ),
    # Rio, with both body types checked.
    "rio_rune_guard": spec(
        "rio", "rio", "effects/skill/rio_rune_guard.png", 6, (128, 128), (64, 64), 12.0, "rio",
        "공용 Guard와 구분되는 0.5초 청록 육각 룬 방패 6프레임 루프",
        "rio/rio_male_moves_sheet.png", 6, 3, 192, [((0.0, -34.0), (1.0, 1.0), 0.0)],
        "rio/rio_female_moves_sheet.png",
    ),
    "rio_ult_circle": spec(
        "rio", "rio", "vfx/rio_ult_circle.png", 6, (384, 384), (192, 192), 18.0, "rio",
        "몸과 여섯 검 사이를 비워 둔 무한 오버드라이브 청록 소환진 6프레임",
        "rio/rio_male_moves_sheet.png", 7, 3, 192, [((0.0, -36.0), (0.638, 0.638), 0.0)],
        "rio/rio_female_moves_sheet.png",
    ),
    "rio_gem_sword": spec(
        "rio", "rio", "effects/rio_gem_sword.png", 1, (96, 32), (48, 16), 0.0, "grey",
        "런타임 6색 틴트의 명도 정보를 지킨 무채색 보석검",
        "rio/rio_male_moves_sheet.png", 7, 3, 192,
        [
            ((87.0, -36.0), (1.0, 1.0), 90.0), ((43.5, 39.3), (1.0, 1.0), 150.0),
            ((-43.5, 39.3), (1.0, 1.0), 210.0), ((-87.0, -36.0), (1.0, 1.0), 270.0),
            ((-43.5, -111.3), (1.0, 1.0), 330.0), ((43.5, -111.3), (1.0, 1.0), 390.0),
        ],
        "rio/rio_female_moves_sheet.png",
    ),
}

for _name, _specification in CONTRACTS.items():
    _specification["name"] = _name


# Transparent character-shaped openings, in authored frame pixels. These effects are above the
# fighter in game; clearing the core is the hard readability rule from the card.
BODY_HOLES = {
    "guard_bubble": (18, 36, 0),
    "parry_flash": (20, 38, 0),
    "frey_spike_ring": (25, 40, 0),
    "frey_ult_charge": (34, 58, -48),
    "luna_brave_aura": (24, 40, 0),
    "luna_ult_transform": (18, 34, 14),
    "luna_moon_ring": (34, 50, 0),
    "nova_shift_ready": (24, 40, 0),
    "rio_rune_guard": (25, 40, 0),
}

BEHIND_BODY = {"yuki_ult_seal", "nova_momentum_trail", "rio_ult_circle"}


def hex_color(value: str) -> tuple[int, int, int]:
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def font(size: int) -> ImageFont.ImageFont:
    for candidate in [Path("C:/Windows/Fonts/malgun.ttf"), Path("C:/Windows/Fonts/arial.ttf")]:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def checker(size: tuple[int, int], block: int = 12) -> Image.Image:
    image = Image.new("RGB", size, (22, 27, 42))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(34, 41, 59))
    return image


def body_cell(specification: dict, alternate: bool = False) -> Image.Image:
    path = specification["body_alt"] if alternate and specification.get("body_alt") else specification["body"]
    row = specification["body_alt_row"] if alternate and specification.get("body_alt") else specification["body_row"]
    frame = specification["body_alt_frame"] if alternate and specification.get("body_alt") else specification["body_frame"]
    cell = specification["body_cell"]
    sheet = Image.open(path).convert("RGBA")
    return sheet.crop((frame * cell, row * cell, (frame + 1) * cell, (row + 1) * cell))


def frames(specification: dict, path: Path | None = None) -> list[Image.Image]:
    image = Image.open(path or specification["src"]).convert("RGBA")
    fw, fh = specification["frame"]
    return [image.crop((index * fw, 0, (index + 1) * fw, fh)) for index in range(specification["frames"])]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    return image.getchannel("A").getbbox() or (1, 1, image.width - 1, image.height - 1)


def source_texture(group: str) -> Image.Image:
    path = RAW / group / f"{group}-style-source.png"
    if not path.exists():
        raise FileNotFoundError(f"ImageGen source missing: {path}")
    image = Image.open(path).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if bbox:
        image = image.crop(bbox)
    return image


def raw_luma_tile(group: str, size: tuple[int, int]) -> np.ndarray:
    image = source_texture(group)
    # The generated concept is used as a real texture/light-frequency source rather than copied
    # verbatim; geometry and timing remain the current contract.
    image = image.resize((max(16, min(96, size[0])), max(16, min(96, size[1]))), Image.Resampling.LANCZOS)
    rgb = np.asarray(image.convert("RGB"), dtype=np.float32)
    luma = rgb[..., 0] * 0.2126 + rgb[..., 1] * 0.7152 + rgb[..., 2] * 0.0722
    luma = Image.fromarray(np.clip(luma, 0, 255).astype(np.uint8), "L").resize(size, Image.Resampling.BILINEAR)
    return np.asarray(luma, dtype=np.uint8)


def redraw_frame(old: Image.Image, specification: dict, frame_index: int) -> Image.Image:
    old = old.convert("RGBA")
    old_rgb = np.asarray(old.convert("RGB"), dtype=np.uint8)
    old_luma_array = (
        old_rgb[..., 0].astype(np.float32) * 0.2126
        + old_rgb[..., 1].astype(np.float32) * 0.7152
        + old_rgb[..., 2].astype(np.float32) * 0.0722
    )
    original_alpha = old.getchannel("A").point(lambda value: 255 if value >= 96 else 0)
    # Several old large VFX keep extremely dark construction/dither pixels across the cell.
    # They were practically invisible, but recolouring them would make bright diagonal curtains.
    # Keep only dark pixels that remain within two pixels of visibly coloured authored art.
    visible = Image.fromarray(np.where(old_luma_array >= 28.0, 255, 0).astype(np.uint8), "L")
    near_visible = visible.filter(ImageFilter.MaxFilter(5))
    alpha = ImageChops.multiply(original_alpha, near_visible)
    hole = BODY_HOLES.get(specification["name"])
    if hole:
        radius_x, radius_y, delta_y = hole
        anchor_x, anchor_y = specification["anchor"]
        bounds = (
            anchor_x - radius_x,
            anchor_y + delta_y - radius_y,
            anchor_x + radius_x,
            anchor_y + delta_y + radius_y,
        )
        alpha_draw = ImageDraw.Draw(alpha)
        alpha_draw.ellipse(bounds, fill=0)
    # Contract silhouettes stay authoritative. The one-pixel dark contour and clustered highlights
    # are rebuilt from the generated style texture and the character palette.
    eroded = alpha.filter(ImageFilter.MinFilter(3))
    border = ImageChops.subtract(alpha, eroded)
    alpha_array = np.asarray(alpha, dtype=np.uint8)
    border_array = np.asarray(border, dtype=np.uint8) > 0
    generated_luma = raw_luma_tile(specification["group"], old.size)
    yy, xx = np.indices((old.height, old.width))
    cluster = ((xx // 2 + yy // 2 + frame_index) % 4) * 3
    # Current art owns readability and animation. The ImageGen source contributes restrained
    # high-frequency material variation so the redraw meets the new sprites without changing shape.
    colors = [hex_color(item) for item in PALETTES[specification["palette"]]]
    palette = np.asarray(colors, dtype=np.float32)
    # Generated luma shifts material clusters by at most +/-12%; original RGB remains the hue
    # authority so Yuki cyan does not become vermilion and Nova teal does not become violet.
    material = 0.88 + generated_luma.astype(np.float32) / 255.0 * 0.24 + cluster / 255.0
    adjusted = np.clip(old_rgb.astype(np.float32) * material[..., None], 0, 255)
    distances = np.sum((adjusted[..., None, :] - palette[None, None, :, :]) ** 2, axis=3)
    indices = np.argmin(distances, axis=2)
    rgb = palette[indices].astype(np.uint8)
    rgb[border_array] = colors[0]
    # A sparse bright square cluster makes the high-energy edge read at 1x without soft alpha.
    highlight = (
        (alpha_array > 0)
        & (~border_array)
        & (old_luma_array >= 150.0)
        & (((xx + yy * 2 + frame_index * 3) % 23) == 0)
    )
    rgb[highlight] = colors[-1]
    rgba = np.dstack([rgb, alpha_array])
    result = Image.fromarray(rgba.astype(np.uint8), "RGBA")
    # Required clear border; transparent RGB is zeroed for clean imports.
    result.paste((0, 0, 0, 0), (0, 0, result.width, 1))
    result.paste((0, 0, 0, 0), (0, result.height - 1, result.width, result.height))
    result.paste((0, 0, 0, 0), (0, 0, 1, result.height))
    result.paste((0, 0, 0, 0), (result.width - 1, 0, result.width, result.height))
    data = np.asarray(result).copy()
    data[data[..., 3] == 0, :3] = 0
    return Image.fromarray(data, "RGBA")


def normalize(name: str, replace: bool = False) -> Path:
    specification = CONTRACTS[name]
    fw, fh = specification["frame"]
    strip = Image.new("RGBA", (fw * specification["frames"], fh), (0, 0, 0, 0))
    for index, old in enumerate(frames(specification)):
        strip.alpha_composite(redraw_frame(old, specification, index), (index * fw, 0))
    out_dir = OUT / specification["id"]
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{name}-v1.png"
    if out.exists() and not replace:
        raise FileExistsError(f"candidate already exists; choose next version: {out}")
    strip.save(out, optimize=True)
    metadata = {
        "note": specification["note"],
        "replaces": str(specification["src"].relative_to(ROOT)).replace("\\", "/"),
        "frames": specification["frames"],
        "fps": specification["fps"],
    }
    out.with_suffix(".json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return out


def paste_at_anchor(
    canvas: Image.Image,
    effect: Image.Image,
    anchor: tuple[int, int],
    position: tuple[float, float],
    scale: tuple[float, float],
    rotation: float,
    tint: tuple[int, int, int] | None = None,
) -> None:
    width = max(1, round(effect.width * scale[0]))
    height = max(1, round(effect.height * scale[1]))
    effect = effect.resize((width, height), Image.Resampling.NEAREST)
    if tint:
        data = np.asarray(effect).copy()
        data[..., 0] = data[..., 0].astype(np.uint16) * tint[0] // 255
        data[..., 1] = data[..., 1].astype(np.uint16) * tint[1] // 255
        data[..., 2] = data[..., 2].astype(np.uint16) * tint[2] // 255
        effect = Image.fromarray(data.astype(np.uint8), "RGBA")
    anchor_scaled = (round(anchor[0] * scale[0]), round(anchor[1] * scale[1]))
    side = int(math.ceil(math.hypot(width, height))) * 2 + 8
    layer = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    centre = (side // 2, side // 2)
    layer.alpha_composite(effect, (centre[0] - anchor_scaled[0], centre[1] - anchor_scaled[1]))
    if abs(rotation) > 0.01:
        layer = layer.rotate(rotation, Image.Resampling.NEAREST, center=centre)
    canvas.alpha_composite(layer, (round(position[0] - centre[0]), round(position[1] - centre[1])))


def idle_body_path(name: str, alternate: bool) -> Path:
    specification = CONTRACTS[name]
    ident = specification["id"]
    if name == "luna_brave_aura":
        return p("luna/luna_brave_sheet.png")
    if ident in {"common", "frey"}:
        return p("frey/frey_sheet.png")
    if ident == "luna":
        return p("luna/luna_sheet.png")
    if ident == "yuki":
        return p("yuki/yuki_sheet.png")
    if ident == "nova":
        return p("nova/nova_female_sheet.png" if alternate else "nova/nova_male_sheet.png")
    if ident == "rio":
        return p("rio/rio_female_sheet.png" if alternate else "rio/rio_male_sheet.png")
    raise KeyError(ident)


def body_scene(name: str, effect_path: Path, frame_index: int, alternate: bool = False, idle: bool = False) -> Image.Image:
    specification = CONTRACTS[name]
    viewport = (760, 520) if name == "yuki_ult_seal" else (420, 300)
    scene = checker(viewport, 8).convert("RGBA")
    origin = (180, 235) if viewport[0] == 420 else (170, 320)
    if idle:
        idle_sheet = Image.open(idle_body_path(name, alternate)).convert("RGBA")
        cell = 128
        body = idle_sheet.crop((0, 0, cell, cell))
    else:
        body = body_cell(specification, alternate)
        cell = specification["body_cell"]
    paste = (origin[0] - cell // 2, origin[1] - (120 if cell == 128 else 152))
    current_frame = frames(specification, effect_path)[min(frame_index, specification["frames"] - 1)]
    tint_cycle = [(255, 92, 112), (255, 191, 76), (128, 255, 128), (90, 217, 255), (153, 128, 255), (255, 128, 242)]
    if name not in BEHIND_BODY:
        scene.alpha_composite(body, paste)
    for index, (offset, scale, rotation) in enumerate(specification["placements"]):
        tint = tint_cycle[index] if name == "rio_gem_sword" else None
        paste_at_anchor(
            scene,
            current_frame,
            specification["anchor"],
            (origin[0] + offset[0], origin[1] + offset[1]),
            scale,
            rotation,
            tint,
        )
    if name in BEHIND_BODY:
        scene.alpha_composite(body, paste)
    draw = ImageDraw.Draw(scene)
    draw.line((origin[0] - 4, origin[1], origin[0] + 4, origin[1]), fill=(255, 110, 72, 255))
    draw.line((origin[0], origin[1] - 4, origin[0], origin[1] + 4), fill=(255, 110, 72, 255))
    return scene


def make_reference_groups() -> None:
    for group in ["common", "frey", "luna", "yuki", "nova", "rio"]:
        names = [name for name, item in CONTRACTS.items() if item["group"] == group]
        body_thumbs: list[tuple[str, Image.Image]] = []
        for name in names:
            item = CONTRACTS[name]
            body = body_cell(item).resize((item["body_cell"] * 2, item["body_cell"] * 2), Image.Resampling.NEAREST)
            body_thumbs.append((name, body))
        width = 1536
        rows = math.ceil(len(names) / 3)
        height = 90 + rows * 470
        board = checker((width, height), 24)
        draw = ImageDraw.Draw(board)
        draw.text((24, 18), f"{group.upper()} | NEW BODY STYLE + CURRENT EFFECT CONTRACTS", font=font(30), fill=(245, 248, 255))
        for index, name in enumerate(names):
            item = CONTRACTS[name]
            x = 24 + (index % 3) * 500
            y = 70 + (index // 3) * 470
            body = body_cell(item)
            body4 = body.resize((body.width * 2, body.height * 2), Image.Resampling.NEAREST)
            board.paste(body4, (x, y), body4)
            sample = frames(item)[min(item["frames"] // 2, item["frames"] - 1)]
            factor = min(2.0, 420 / max(sample.width, sample.height))
            shown = sample.resize((max(1, round(sample.width * factor)), max(1, round(sample.height * factor))), Image.Resampling.NEAREST)
            board.paste(shown, (x + 210, y + 20), shown)
            draw.text((x, y + 390), name, font=font(21), fill=(255, 221, 120))
            draw.text((x, y + 420), f"{item['frames']}f  {item['frame'][0]}x{item['frame'][1]}  {item['fps']}fps", font=font(17), fill=(184, 215, 236))
        target = REPORT / group
        target.mkdir(parents=True, exist_ok=True)
        board.save(target / f"{group}-reference.png", optimize=True)


def contact_strip(specification: dict, path: Path, max_cell: int = 280) -> Image.Image:
    images = frames(specification, path)
    scale = min(4.0, max_cell / max(specification["frame"]))
    thumbs = [image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.NEAREST) for image in images]
    columns = min(4, len(thumbs))
    rows = math.ceil(len(thumbs) / columns)
    tw = max(image.width for image in thumbs)
    th = max(image.height for image in thumbs)
    result = checker((columns * (tw + 16), rows * (th + 34)), 10).convert("RGBA")
    draw = ImageDraw.Draw(result)
    for index, image in enumerate(thumbs):
        x = (index % columns) * (tw + 16)
        y = (index // columns) * (th + 34)
        result.alpha_composite(image, (x, y))
        draw.text((x, y + th + 5), f"F{index + 1}", font=font(14), fill=(230, 236, 248, 255))
    return result


def make_compare(name: str, out_path: Path) -> Path:
    specification = CONTRACTS[name]
    body_variants = [False, True] if specification.get("body_alt") else [False]
    frame_index = min(specification["frames"] // 2, specification["frames"] - 1)
    scene_rows: list[tuple[str, Image.Image, Image.Image]] = []
    for alternate in body_variants:
        body_label = "ALT BODY" if alternate else "BODY"
        for idle in [True, False]:
            pose_label = "IDLE" if idle else "BUSY"
            current = body_scene(name, specification["src"], frame_index, alternate, idle)
            new = body_scene(name, out_path, frame_index, alternate, idle)
            scene_rows.append((f"{body_label} / {pose_label} / 1X", current, new))
            scene_rows.append((
                f"{body_label} / {pose_label} / 4X",
                current.resize((current.width * 4, current.height * 4), Image.Resampling.NEAREST),
                new.resize((new.width * 4, new.height * 4), Image.Resampling.NEAREST),
            ))
    current_strip = contact_strip(specification, specification["src"])
    new_strip = contact_strip(specification, out_path)
    max_scene_width = max(max(current.width, new.width) for _, current, new in scene_rows)
    width = max(current_strip.width + new_strip.width + 90, max_scene_width * 2 + 72)
    row_heights = [max(current.height, new.height) + 58 for _, current, new in scene_rows]
    height = 80 + sum(row_heights) + max(current_strip.height, new_strip.height) + 100
    board = checker((width, height), 24)
    draw = ImageDraw.Draw(board)
    draw.text((24, 18), f"{name} | CODE PLACEMENT AT 1X + 4X, CURRENT vs NEW", font=font(28), fill=(245, 248, 255))
    y = 70
    for row, (label, current, new) in enumerate(scene_rows):
        board.paste(current.convert("RGB"), (24, y))
        board.paste(new.convert("RGB"), (48 + max_scene_width, y))
        draw.text((24, y + current.height + 8), f"CURRENT / {label}", font=font(18), fill=(255, 220, 112))
        draw.text((48 + max_scene_width, y + new.height + 8), f"NEW V1 / {label}", font=font(18), fill=(115, 240, 205))
        y += row_heights[row]
    board.paste(current_strip.convert("RGB"), (24, y))
    board.paste(new_strip.convert("RGB"), (48 + current_strip.width, y))
    draw.text((24, y + current_strip.height + 10), "CURRENT / ALL FRAMES", font=font(18), fill=(255, 220, 112))
    draw.text((48 + current_strip.width, y + new_strip.height + 10), "NEW V1 / ALL FRAMES", font=font(18), fill=(115, 240, 205))
    target = REPORT / specification["id"] / f"{name}-compare.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    board.save(target, compress_level=6)
    return target


def verify(name: str, path: Path) -> dict:
    specification = CONTRACTS[name]
    image = Image.open(path)
    expected = (specification["frame"][0] * specification["frames"], specification["frame"][1])
    rgba = image.convert("RGBA")
    alpha_values = set(rgba.getchannel("A").get_flattened_data())
    split = frames(specification, path)
    borders = []
    for frame in split:
        alpha = frame.getchannel("A")
        borders.append(
            alpha.crop((0, 0, frame.width, 1)).getbbox() is None
            and alpha.crop((0, frame.height - 1, frame.width, frame.height)).getbbox() is None
            and alpha.crop((0, 0, 1, frame.height)).getbbox() is None
            and alpha.crop((frame.width - 1, 0, frame.width, frame.height)).getbbox() is None
        )
    return {
        "file": str(path.relative_to(ROOT)).replace("\\", "/"),
        "size": list(image.size),
        "expected_size": list(expected),
        "size_ok": image.size == expected,
        "mode": image.mode,
        "frames": len(split),
        "frame_size": list(specification["frame"]),
        "anchor": list(specification["anchor"]),
        "fps": specification["fps"],
        "alpha_values": sorted(alpha_values),
        "binary_alpha": alpha_values.issubset({0, 255}),
        "border_clear": all(borders),
        "nonempty_frames": [frame.getchannel("A").getbbox() is not None for frame in split],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refs", action="store_true")
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--compares", action="store_true")
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--name", choices=sorted(CONTRACTS))
    args = parser.parse_args()
    if args.refs:
        make_reference_groups()
        return
    names = list(CONTRACTS) if args.all or args.compares else ([args.name] if args.name else [])
    if not names:
        parser.error("use --refs, --all, --compares, or --name")
    results = []
    for name in names:
        specification = CONTRACTS[name]
        path = OUT / specification["id"] / f"{name}-v1.png"
        if not args.compares:
            path = normalize(name, args.replace)
        make_compare(name, path)
        results.append(verify(name, path))
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / "verification.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
