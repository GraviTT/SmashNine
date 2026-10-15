from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[2]
GAME = ROOT / "smash-nine-prototype" / "assets" / "art"
REPORT = ROOT / "reports" / "codex-art-66"
RAW = ROOT / "art" / "raw" / "fx-66"
OUT = ROOT / "art" / "bakeoff" / "effects"


CONTRACTS = {
    "frey_slash": {
        "id": "frey", "src": GAME / "attack_vfx/frey_slash.png",
        "frames": 6, "frame": (384, 256), "anchor": (0, 128), "fps": 36.0,
        "body": GAME / "frey/frey_moves_sheet.png", "body_row": 8, "body_frame": 5,
        "raw_grid": (3, 2), "note": "Frey 금백색 검광을 새 갑옷·검의 명암 밀도에 맞춘 6프레임 J 궤적",
    },
    "luna_slash": {
        "id": "luna", "src": GAME / "attack_vfx/luna_slash.png",
        "frames": 6, "frame": (384, 256), "anchor": (0, 128), "fps": 30.0,
        "body": GAME / "luna/luna_moves_sheet.png", "body_row": 7, "body_frame": 3,
        "raw_grid": (3, 2), "note": "Luna 지팡이 색을 잇는 분홍·보라·청록 별빛 6프레임 J 궤적",
    },
    "luna_star_bloom": {
        "id": "luna", "src": GAME / "effects/skill/luna_star_bloom.png",
        "frames": 6, "frame": (256, 256), "anchor": (128, 128), "fps": 37.5,
        "body": GAME / "luna/luna_moves_sheet.png", "body_row": 7, "body_frame": 4,
        "raw_grid": (3, 2), "note": "Luna J의 지연 판정을 읽히게 하는 청록 코어·분홍 별꽃 6프레임",
    },
    "luna_brave_slash": {
        "id": "luna_brave", "src": GAME / "attack_vfx/luna_brave_slash.png",
        "frames": 6, "frame": (448, 256), "anchor": (0, 128), "fps": 36.0,
        "body": GAME / "luna/luna_brave_moves_sheet.png", "body_row": 0, "body_frame": 5,
        "raw_grid": (3, 2), "note": "Brave Luna 건틀릿·부츠의 금백·분홍·청록을 잇는 근접 J 궤적",
    },
    "yuki_talisman": {
        "id": "yuki", "src": GAME / "effects/yuki_talisman.png",
        "frames": 1, "frame": (128, 64), "anchor": (64, 32), "fps": 0.0,
        "body": GAME / "yuki/yuki_moves_sheet.png", "body_row": 0, "body_frame": 3,
        "raw_grid": (1, 1), "note": "Yuki J의 30×16 판정에 맞춘 상아 종이·주홍 인장의 비행 부적",
    },
    "yuki_slash": {
        "id": "yuki", "src": GAME / "attack_vfx/yuki_slash.png",
        "frames": 6, "frame": (384, 256), "anchor": (0, 128), "fps": 30.0,
        "body": GAME / "yuki/yuki_moves_sheet.png", "body_row": 2, "body_frame": 3,
        "raw_grid": (3, 2), "note": "Yuki ↓J의 낮은 54×46 판정을 따르는 주홍·금·청록 퇴마 궤적",
    },
    "yuki_l": {
        "id": "yuki", "src": GAME / "attack_vfx/yuki_l.png",
        "frames": 6, "frame": (384, 384), "anchor": (192, 192), "fps": 24.0,
        "body": GAME / "yuki/yuki_moves_sheet.png", "body_row": 1, "body_frame": 4,
        "raw_grid": (3, 2), "note": "Yuki ↑J·공중 ↓J의 펼침 판정을 보여 주는 부적 결계 폭발 6프레임",
    },
    "nova_slash": {
        "id": "nova", "src": GAME / "attack_vfx/nova_slash.png",
        "frames": 6, "frame": (320, 256), "anchor": (0, 128), "fps": 36.0,
        "body": GAME / "nova/nova_male_moves_sheet.png", "body_row": 0, "body_frame": 3,
        "body_alt": GAME / "nova/nova_female_moves_sheet.png",
        "raw_grid": (3, 2), "note": "Nova J의 실제 운동 방향을 잇는 인디고·전기 청록·금색 타격 궤적",
    },
    "nova_vector_streak": {
        "id": "nova", "src": GAME / "effects/skill/nova_vector_streak.png",
        "frames": 4, "frame": (192, 48), "anchor": (96, 24), "fps": 33.333,
        "body": GAME / "nova/nova_male_moves_sheet.png", "body_row": 0, "body_frame": 3,
        "body_alt": GAME / "nova/nova_female_moves_sheet.png",
        "raw_grid": (2, 2), "note": "Nova 옆 J의 76→138 이동과 운동량 색 보간을 읽히게 하는 4프레임 벡터 선",
    },
    "nova_impact_star": {
        "id": "nova", "src": GAME / "effects/skill/nova_impact_star.png",
        "frames": 6, "frame": (512, 512), "anchor": (256, 256), "fps": 40.0,
        "body": GAME / "nova/nova_male_moves_sheet.png", "body_row": 1, "body_frame": 4,
        "body_alt": GAME / "nova/nova_female_moves_sheet.png",
        "raw_grid": (3, 2), "note": "Nova ↑J와 중력 J의 운동량 크기·밝기 보간을 받는 방사형 충격별",
    },
    "nova_gravity_burst": {
        "id": "nova", "src": GAME / "effects/skill/nova_gravity_burst.png",
        "frames": 6, "frame": (512, 512), "anchor": (256, 256), "fps": 42.857,
        "body": GAME / "nova/nova_male_moves_sheet.png", "body_row": 2, "body_frame": 4,
        "body_alt": GAME / "nova/nova_female_moves_sheet.png",
        "raw_grid": (3, 2), "note": "Nova ↓J 48→72 반경과 메테오 착지 반경을 따라 수축·폭발하는 중력장",
    },
    "rio_slash": {
        "id": "rio", "src": GAME / "attack_vfx/rio_slash.png",
        "frames": 6, "frame": (384, 256), "anchor": (0, 128), "fps": 36.0,
        "body": GAME / "rio/rio_male_moves_sheet.png", "body_row": 0, "body_frame": 5,
        "body_alt": GAME / "rio/rio_female_moves_sheet.png",
        "raw_grid": (3, 2), "note": "Rio J 검술의 전방·상승·낮은 궤적에 회전되는 청록 마력검광 6프레임",
    },
    "rio_mana_wave": {
        "id": "rio", "src": GAME / "effects/rio_mana_wave.png",
        "frames": 1, "frame": (48, 112), "anchor": (24, 56), "fps": 0.0,
        "body": GAME / "rio/rio_male_moves_sheet.png", "body_row": 0, "body_frame": 5,
        "body_alt": GAME / "rio/rio_female_moves_sheet.png",
        "raw_grid": (1, 1), "note": "Rio J 3타의 24×54 기본 판정과 0.24초 비행을 따르는 세로형 청록 마력 검기",
    },
}


# Representative active J placement, transcribed from the drawing functions. Coordinates are
# world pixels from the fighter's feet origin. Scale is the final screen scale after Vfx.gd's
# authored-size ratio (or Projectile.set_art's ratio) has been applied.
PREVIEW = {
    "frey_slash": (2, (0.0, -32.0), (0.5625, 0.5625), -10.2),
    "luna_slash": (2, (0.0, -32.0), (0.434, 0.434), -2.3),
    "luna_star_bloom": (3, (162.0, -29.0), (0.571, 0.571), 0.0),
    "luna_brave_slash": (2, (0.0, -32.0), (0.375, 0.375), -9.1),
    "yuki_talisman": (0, (42.75, -34.0), (0.75, 0.75), 0.0),
    "yuki_slash": (2, (0.0, -32.0), (0.402, 0.402), -5.7),
    "yuki_l": (3, (0.0, -126.0), (0.32, 0.32), 0.0),
    "nova_slash": (2, (0.0, -32.0), (0.773, 0.773), 0.0),
    "nova_vector_streak": (1, (69.0, -32.0), (0.767, 1.0), 0.0),
    "nova_impact_star": (3, (54.0, -152.0), (0.657, 0.657), 0.0),
    "nova_gravity_burst": (3, (0.0, -30.0), (0.931, 0.931), 0.0),
    "rio_slash": (2, (0.0, -32.0), (0.477, 0.477), -8.0),
    "rio_mana_wave": (0, (49.5, -12.0), (0.75, 0.75), 0.0),
}


def font(size: int) -> ImageFont.ImageFont:
    candidates = [
        Path("C:/Windows/Fonts/malgun.ttf"),
        Path("C:/Windows/Fonts/arial.ttf"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size)
    return ImageFont.load_default()


def checker(size: tuple[int, int], block: int = 16) -> Image.Image:
    image = Image.new("RGB", size, (25, 29, 43))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], block):
        for x in range(0, size[0], block):
            if (x // block + y // block) % 2:
                draw.rectangle((x, y, x + block - 1, y + block - 1), fill=(35, 41, 58))
    return image


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    return bbox


def body_cell(path: Path, row: int, frame: int) -> Image.Image:
    sheet = Image.open(path).convert("RGBA")
    cell = 192
    return sheet.crop((frame * cell, row * cell, (frame + 1) * cell, (row + 1) * cell))


def effect_frames(spec: dict, path: Path | None = None) -> list[Image.Image]:
    strip = Image.open(path or spec["src"]).convert("RGBA")
    fw, fh = spec["frame"]
    return [strip.crop((i * fw, 0, (i + 1) * fw, fh)) for i in range(spec["frames"])]


def make_refs() -> None:
    for name, spec in CONTRACTS.items():
        target = REPORT / spec["id"]
        target.mkdir(parents=True, exist_ok=True)
        body = body_cell(spec["body"], spec["body_row"], spec["body_frame"])
        bodies = [("BODY / J POSE", body)]
        if spec.get("body_alt"):
            bodies.append(("ALT BODY / SAME J POSE", body_cell(spec["body_alt"], spec["body_row"], spec["body_frame"])))
        frames = effect_frames(spec)
        scale = 2 if max(spec["frame"]) >= 384 else 4
        thumb_w = spec["frame"][0] * scale
        thumb_h = spec["frame"][1] * scale
        width = max(1024, len(bodies) * (192 * 4 + 40), min(4096, 3 * (thumb_w + 24)))
        rows = math.ceil(len(frames) / 3)
        height = 80 + 192 * 4 + 60 + rows * (thumb_h + 58) + 30
        board = checker((width, height), 32)
        draw = ImageDraw.Draw(board)
        draw.text((24, 18), f"{name}  |  BODY STYLE + CURRENT TIMING", font=font(28), fill=(245, 245, 250))
        x = 24
        y = 64
        for label, body_image in bodies:
            body4 = body_image.resize((768, 768), Image.Resampling.NEAREST)
            board.paste(body4, (x, y), body4)
            draw.text((x, y + 772), label, font=font(18), fill=(210, 220, 238))
            x += 808
        y = 64 + 768 + 54
        for i, frame_image in enumerate(frames):
            gx = i % 3
            gy = i // 3
            px = 24 + gx * (thumb_w + 24)
            py = y + gy * (thumb_h + 58)
            scaled = frame_image.resize((thumb_w, thumb_h), Image.Resampling.NEAREST)
            board.paste(scaled, (px, py), scaled)
            draw.text((px, py + thumb_h + 8), f"CURRENT FRAME {i + 1}", font=font(18), fill=(255, 215, 112))
        board.save(target / f"{name}-reference.png", optimize=True)


def split_raw(raw: Image.Image, columns: int, rows: int, count: int) -> list[Image.Image]:
    frames: list[Image.Image] = []
    cell_w = raw.width // columns
    cell_h = raw.height // rows
    for index in range(count):
        x = index % columns
        y = index // columns
        cell = raw.crop((x * cell_w, y * cell_h, (x + 1) * cell_w, (y + 1) * cell_h))
        bbox = alpha_bbox(cell)
        frames.append(cell.crop(bbox))
    return frames


def hard_alpha(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a < 96:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (r, g, b, 255)
    return image


def isolate_effect(image: Image.Image) -> Image.Image:
    """Remove ImageGen's soft colored aura while retaining a one-logical-pixel dark rim."""
    image = image.convert("RGBA")
    red, green, blue, alpha = image.split()
    value = ImageChops.lighter(red, ImageChops.lighter(green, blue))
    bright = value.point(lambda level: 255 if level >= 92 else 0)
    present = alpha.point(lambda level: 255 if level >= 32 else 0)
    # Generated pixel blocks are about 4-8 source pixels wide. Seven source pixels keep the
    # authored dark contour, but do not keep the broad colored aura around it.
    near_bright = bright.filter(ImageFilter.MaxFilter(15))
    mask = ImageChops.multiply(near_bright, present)
    image.putalpha(mask)
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            if pixels[x, y][3] == 0:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def fit_generated(generated: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    left, top, right, bottom = box
    width = max(1, right - left)
    height = max(1, bottom - top)
    generated = isolate_effect(generated)
    generated = generated.crop(alpha_bbox(generated))
    factor = min(width / max(1, generated.width), height / max(1, generated.height))
    size = (max(1, round(generated.width * factor)), max(1, round(generated.height * factor)))
    resized = generated.resize(size, Image.Resampling.LANCZOS)
    resized = resized.filter(ImageFilter.UnsharpMask(radius=0.8, percent=75, threshold=2))
    return hard_alpha(resized)


def normalize_one(name: str) -> Path:
    spec = CONTRACTS[name]
    raw_path = RAW / spec["id"] / f"{name}-source.png"
    if not raw_path.exists():
        raise FileNotFoundError(raw_path)
    raw = Image.open(raw_path).convert("RGBA")
    columns, rows = spec["raw_grid"]
    generated = split_raw(raw, columns, rows, spec["frames"])
    old_frames = effect_frames(spec)
    fw, fh = spec["frame"]
    strip = Image.new("RGBA", (fw * spec["frames"], fh), (0, 0, 0, 0))
    for index, old in enumerate(old_frames):
        old_box = alpha_bbox(old)
        # Preserve the old timing silhouette and anchor relation, but keep one clear border.
        left = max(1, old_box[0])
        top = max(1, old_box[1])
        right = min(fw - 1, old_box[2])
        bottom = min(fh - 1, old_box[3])
        fitted = fit_generated(generated[min(index, len(generated) - 1)], (left, top, right, bottom))
        centre_x = (left + right) // 2
        centre_y = (top + bottom) // 2
        x = max(1, min(fw - 1 - fitted.width, centre_x - fitted.width // 2))
        y = max(1, min(fh - 1 - fitted.height, centre_y - fitted.height // 2))
        strip.alpha_composite(fitted, (index * fw + x, y))
    out_dir = OUT / spec["id"]
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{name}-v1.png"
    strip.save(out_path, optimize=True)
    metadata = {
        "note": spec["note"],
        "replaces": str(spec["src"].relative_to(ROOT)).replace("\\", "/"),
        "frames": spec["frames"],
        "fps": spec["fps"],
    }
    (out_dir / f"{name}-v1.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return out_path


def paste_rotated_at_anchor(
    canvas: Image.Image,
    effect: Image.Image,
    anchor: tuple[int, int],
    screen_position: tuple[float, float],
    screen_scale: tuple[float, float],
    rotation_degrees: float,
) -> None:
    width = max(1, round(effect.width * screen_scale[0]))
    height = max(1, round(effect.height * screen_scale[1]))
    effect = effect.resize((width, height), Image.Resampling.NEAREST)
    anchor_scaled = (round(anchor[0] * screen_scale[0]), round(anchor[1] * screen_scale[1]))
    diagonal = int(math.ceil(math.hypot(width, height))) * 2 + 16
    layer = Image.new("RGBA", (diagonal, diagonal), (0, 0, 0, 0))
    centre = (diagonal // 2, diagonal // 2)
    layer.alpha_composite(effect, (centre[0] - anchor_scaled[0], centre[1] - anchor_scaled[1]))
    if abs(rotation_degrees) > 0.01:
        layer = layer.rotate(rotation_degrees, resample=Image.Resampling.NEAREST, center=centre)
    canvas.alpha_composite(layer, (round(screen_position[0] - centre[0]), round(screen_position[1] - centre[1])))


def composite_preview(name: str, effect_path: Path) -> Image.Image:
    spec = CONTRACTS[name]
    width, height = 460, 300
    rgb = checker((width, height), 8)
    canvas = rgb.convert("RGBA")
    origin = (132, 230)
    body = body_cell(spec["body"], spec["body_row"], spec["body_frame"])
    canvas.alpha_composite(body, (origin[0] - 96, origin[1] - 152))
    frame_index, effect_origin, scale, rotation = PREVIEW[name]
    frame = effect_frames(spec, effect_path)[frame_index]
    position = (origin[0] + effect_origin[0], origin[1] + effect_origin[1])
    paste_rotated_at_anchor(canvas, frame, spec["anchor"], position, scale, rotation)
    draw = ImageDraw.Draw(canvas)
    draw.line((origin[0] - 4, origin[1], origin[0] + 4, origin[1]), fill=(255, 128, 72, 255), width=1)
    draw.line((origin[0], origin[1] - 4, origin[0], origin[1] + 4), fill=(255, 128, 72, 255), width=1)
    return canvas


def make_compare(name: str, output_path: Path) -> Path:
    spec = CONTRACTS[name]
    scale = 4
    current_composite = composite_preview(name, spec["src"]).resize((1840, 1200), Image.Resampling.NEAREST)
    new_composite = composite_preview(name, output_path).resize((1840, 1200), Image.Resampling.NEAREST)
    fw, fh = spec["frame"]
    pair_width = fw * scale * 2 + 72
    row_height = fh * scale + 72
    width = max(pair_width + 48, 3760)
    height = 72 + 1200 + 88 + spec["frames"] * row_height + 32
    board = checker((width, height), 32)
    draw = ImageDraw.Draw(board)
    draw.text((24, 18), f"{name} | IN-GAME PLACEMENT + EVERY FRAME AT 4X", font=font(28), fill=(245, 245, 250))
    board.paste(current_composite.convert("RGB"), (24, 64))
    board.paste(new_composite.convert("RGB"), (1888, 64))
    draw.text((24, 1274), "CURRENT / BODY ACTIVE J", font=font(20), fill=(255, 208, 100))
    draw.text((1888, 1274), "NEW V1 / SAME CODE PLACEMENT", font=font(20), fill=(118, 240, 210))
    current_frames = effect_frames(spec)
    new_frames = effect_frames(spec, output_path)
    y0 = 1360
    for index, (current, new) in enumerate(zip(current_frames, new_frames)):
        y = y0 + index * row_height
        current4 = current.resize((fw * scale, fh * scale), Image.Resampling.NEAREST)
        new4 = new.resize((fw * scale, fh * scale), Image.Resampling.NEAREST)
        x = 24
        board.paste(current4, (x, y), current4)
        board.paste(new4, (x + fw * scale + 48, y), new4)
        draw.text((x, y + fh * scale + 10), f"F{index + 1} CURRENT", font=font(18), fill=(255, 208, 100))
        draw.text((x + fw * scale + 48, y + fh * scale + 10), f"F{index + 1} NEW", font=font(18), fill=(118, 240, 210))
    target = REPORT / spec["id"] / f"{name}-compare.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    board.save(target, compress_level=6)
    return target


def verify_one(name: str, path: Path) -> dict:
    spec = CONTRACTS[name]
    image = Image.open(path).convert("RGBA")
    expected = (spec["frame"][0] * spec["frames"], spec["frame"][1])
    alpha = image.getchannel("A")
    alpha_values = set(alpha.get_flattened_data())
    frames = effect_frames(spec, path)
    border_clear = all(
        not frame.crop((0, 0, frame.width, 1)).getbbox()
        and not frame.crop((0, frame.height - 1, frame.width, frame.height)).getbbox()
        and not frame.crop((0, 0, 1, frame.height)).getbbox()
        and not frame.crop((frame.width - 1, 0, frame.width, frame.height)).getbbox()
        for frame in frames
    )
    return {
        "file": str(path.relative_to(ROOT)).replace("\\", "/"),
        "size": list(image.size), "expected_size": list(expected), "size_ok": image.size == expected,
        "mode": image.mode, "frames": len(frames), "frame_size": list(spec["frame"]),
        "alpha_values": sorted(alpha_values), "binary_alpha": alpha_values.issubset({0, 255}),
        "border_clear": border_clear,
        "nonempty_frames": [frame.getchannel("A").getbbox() is not None for frame in frames],
        "anchor": list(spec["anchor"]), "fps": spec["fps"],
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refs", action="store_true")
    parser.add_argument("--name", choices=sorted(CONTRACTS))
    parser.add_argument("--all", action="store_true")
    parser.add_argument("--compares", action="store_true")
    args = parser.parse_args()
    if args.refs:
        make_refs()
        return
    if args.compares:
        for name, spec in CONTRACTS.items():
            output_path = OUT / spec["id"] / f"{name}-v1.png"
            make_compare(name, output_path)
        return
    names = list(CONTRACTS) if args.all else [args.name]
    if not names or names == [None]:
        parser.error("use --refs, --name, or --all")
    results = []
    for name in names:
        path = normalize_one(name)
        results.append(verify_one(name, path))
    REPORT.mkdir(parents=True, exist_ok=True)
    (REPORT / "verification.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
