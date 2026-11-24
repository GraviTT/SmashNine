"""VFX-10c: hand-pixel icons and non-destructive blast v2 correction.

Only writes the follow-up candidates and reports. No package installation.
All production icons are drawn at 40 px; only review boards enlarge them.
"""
from pathlib import Path
from datetime import datetime
import argparse
import hashlib
import json
import math

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-vfx-10"
ICONS = ROOT / "art/bakeoff/skill_icons/xion"
FX = ROOT / "art/bakeoff/effects/xion"
ART = ROOT / "smash-nine-prototype/assets/art"
START = datetime.fromisoformat("2026-11-24T14:46:59.042401+09:00")
DEADLINE = datetime.fromisoformat("2026-11-24T16:16:59.042401+09:00")
NEAREST = Image.Resampling.NEAREST
P = {
    "outline": "#101522",
    "black": "#302933",
    "silver": "#d3d8e0",
    "steel": "#777d8d",
    "crimson": "#d42e4b",
    "red": "#841e32",
    "gold": "#efc671",
}
BG = (21, 25, 35)
TEXT = (222, 226, 234)
MUTED = (164, 176, 195)
FONT = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 15)
SMALL = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 12)
TITLE = ImageFont.truetype("C:/Windows/Fonts/malgunbd.ttf", 23)


def time_check(item):
    # An independent guard also protects each save if a tool call was delayed.
    now = datetime.now().astimezone()
    print(f"CLOCK {now.isoformat()} / {item}", flush=True)
    if now >= DEADLINE:
        raise SystemExit("HARD STOP: only README and commit script may be finished now.")


def save_json(path, data):
    time_check(path.name)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")


def save_image(path, im):
    time_check(path.name)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)


def layer():
    return Image.new("RGBA", (40, 40))


def outlined(src):
    """Exactly one native-pixel dark outline, without smoothing or glow."""
    mask = src.getchannel("A").filter(ImageFilter.MaxFilter(3))
    back = Image.new("RGBA", src.size, P["outline"])
    back.putalpha(mask)
    back.alpha_composite(src)
    return back


def component(im, painter):
    src = layer()
    painter(ImageDraw.Draw(src))
    im.alpha_composite(outlined(src))


def shotgun(mirror=False):
    """A stepped 45-degree pump shotgun, muzzle up-right, stock down-left."""
    g = layer()
    d = ImageDraw.Draw(g)
    # Squared barrel, separate lower magazine tube, rectangular pump and stock.
    d.polygon([(14, 22), (28, 8), (30, 10), (16, 24)], fill=P["silver"])
    d.polygon([(17, 23), (27, 13), (28, 14), (18, 24)], fill=P["steel"])
    d.polygon([(15, 20), (20, 15), (24, 19), (19, 24)], fill=P["black"])
    d.line([(17, 20), (21, 16)], fill=P["crimson"], width=2)
    d.polygon([(10, 25), (14, 21), (18, 25), (15, 28)], fill=P["steel"])
    d.polygon([(7, 29), (11, 25), (15, 29), (13, 33), (10, 32)], fill=P["crimson"])
    d.polygon([(17, 25), (20, 27), (18, 30), (16, 28)], fill=P["black"])
    # Crisp mechanical highlight, two pixels wide.
    d.line([(12, 25), (14, 23)], fill=P["silver"], width=2)
    return g.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if mirror else g


def icon_j():
    im = layer()
    # A single compact flash above the crossed muzzles.
    component(im, lambda d: d.polygon(
        [(20, 3), (22, 7), (26, 8), (23, 10), (23, 13),
         (20, 11), (17, 13), (17, 10), (14, 8), (18, 7)], fill=P["gold"]))
    im.alpha_composite(outlined(shotgun(True)))
    im.alpha_composite(outlined(shotgun(False)))
    return im


def icon_k():
    im = layer()

    def arrow(d):
        d.line([(12, 8), (17, 5), (25, 5), (31, 10), (34, 17),
                (34, 24), (29, 31), (21, 34), (14, 32), (9, 27), (6, 20)],
               fill=P["crimson"], width=3)
        d.polygon([(6, 13), (3, 24), (6, 22), (12, 25)], fill=P["crimson"])

    component(im, arrow)
    # Two readable, parallel shotgun shells: silver caps and small brass bases.
    for x, y in [(14, 13), (22, 16)]:
        def shell(d, x=x, y=y):
            d.rectangle((x, y, x + 4, y + 8), fill=P["silver"])
            d.rectangle((x, y + 2, x + 4, y + 7), fill=P["red"])
            d.rectangle((x, y + 2, x + 1, y + 7), fill=P["crimson"])
            d.rectangle((x - 1, y + 9, x + 5, y + 10), fill=P["gold"])
        component(im, shell)
    return im


def icon_l():
    im = layer()
    component(im, lambda d: d.polygon(
        [(20, 3), (28, 11), (23, 11), (23, 19),
         (17, 19), (17, 11), (12, 11)], fill=P["silver"]))

    def down_blast(d):
        d.polygon([(17, 23), (23, 23), (27, 29), (31, 35), (24, 31),
                   (20, 36), (16, 31), (9, 35), (13, 29)], fill=P["crimson"])
        d.rectangle((18, 23, 21, 26), fill=P["gold"])
        d.polygon([(18, 26), (21, 26), (21, 30), (19, 32)], fill=P["gold"])
        d.line([(15, 26), (12, 31)], fill=P["red"], width=2)
        d.line([(24, 26), (27, 31)], fill=P["red"], width=2)

    component(im, down_blast)
    return im


def icon_u():
    im = layer()
    body = layer()
    d = ImageDraw.Draw(body)
    # Bob, side fringe, scarf and split short coat, deliberately not a face portrait.
    d.polygon([(16, 5), (22, 5), (25, 8), (25, 15), (22, 14),
               (21, 16), (17, 16), (15, 14), (13, 15), (13, 9)], fill=P["red"])
    d.rectangle((17, 9, 22, 14), fill=P["crimson"])
    d.rectangle((16, 6, 17, 10), fill=P["silver"])
    d.polygon([(16, 17), (22, 17), (26, 20), (27, 26),
               (30, 29), (23, 29), (20, 26), (17, 29),
               (11, 29), (14, 23), (13, 21)], fill=P["crimson"])
    d.polygon([(14, 17), (22, 17), (24, 19), (16, 20),
               (12, 22), (6, 23), (8, 20)], fill=P["crimson"])
    d.polygon([(14, 28), (18, 28), (18, 33), (16, 35), (12, 35)], fill=P["red"])
    d.polygon([(22, 28), (26, 28), (26, 33), (29, 35), (23, 35)], fill=P["red"])
    # Opaque scan bars use the dark crimson from the same restricted palette.
    px = body.load()
    scan = tuple(bytes.fromhex(P["red"][1:])) + (255,)
    for y in (12, 22, 25, 31):
        for x in range(40):
            if px[x, y][3]:
                px[x, y] = scan
    im.alpha_composite(outlined(body))
    # Two detached signal ticks, each a 2-pixel cluster.
    component(im, lambda q: q.rectangle((29, 13, 32, 14), fill=P["crimson"]))
    component(im, lambda q: q.rectangle((6, 29, 8, 30), fill=P["crimson"]))
    return im


def icon_i():
    im = layer()
    # Eight distinct radial tracers form the ring, rather than another round shield.
    for i in range(8):
        angle = i * math.tau / 8
        ux, uy = math.cos(angle), math.sin(angle)
        vx, vy = -uy, ux

        def point(r, across):
            return (round(20 + ux * r + vx * across), round(20 + uy * r + vy * across))

        def tracer(d):
            d.polygon([point(8, -1), point(14, -1), point(16, 0),
                       point(14, 1), point(8, 1)], fill=P["crimson"])
            d.polygon([point(13, -1), point(16, 0), point(13, 1)], fill=P["gold"])

        component(im, tracer)
    component(im, lambda d: d.polygon(
        [(20, 16), (22, 18), (24, 20), (22, 22), (20, 24),
         (18, 22), (16, 20), (18, 18)], fill=P["silver"]))
    d = ImageDraw.Draw(im)
    d.rectangle((19, 19, 21, 21), fill=P["crimson"])
    return im


ICON_NOTES = {
    "j": "교차한 은색 펌프 샷건 두 자루와 작은 금색 발사 섬광. 진홍색 개머리판과 펌프로 시온의 색을 잇는다.",
    "k": "구르기를 나타내는 진홍색 회전 화살표 안에 탄피 두 개. 은색 캡과 작은 금색 밑동을 분리했다.",
    "l": "위로 향한 은색 화살표 아래에서 진홍 산탄이 아래로 터진다. 반동으로 상승하는 기술을 나타낸다.",
    "u": "단발과 은색 머리줄, 흩날리는 스카프, 짧은 코트를 가진 진홍 홀로그램 실루엣. 어두운 주사선과 신호 조각 두 개.",
    "i": "가운데 은색 표식에서 바깥으로 향하는 진홍·금색 탄흔 여덟 개. 사방 난사를 한눈에 보여 주는 고리 배치.",
}


def build_icon(key):
    time_check("icon " + key)
    im = globals()["icon_" + key]()
    path = ICONS / f"xion_{key}-v1.png"
    save_image(path, im)
    save_json(path.with_suffix(".json"), {
        "note": ICON_NOTES[key],
        "replaces": f"assets/art/skill_icons/xion_{key}.png",
        "frames": 1, "fps": 0, "anchor": [20, 20], "loop": False,
        "frame_size": [40, 40], "blend": "normal", "filter": "nearest",
        "alpha": "binary", "method": "Python + Pillow, hand-authored at native 40x40; no resampling",
        "palette": P,
    })


def panel(size, light=False):
    bg = (214, 217, 223, 255) if light else (27, 32, 43, 255)
    grid = (226, 228, 233, 255) if light else (34, 40, 52, 255)
    im = Image.new("RGBA", size, bg)
    d = ImageDraw.Draw(im)
    for y in range(0, size[1], 8):
        for x in range(0, size[0], 8):
            if (x // 8 + y // 8) % 2:
                d.rectangle((x, y, x + 7, y + 7), fill=grid)
    return im


def icon_bar(character):
    im = Image.new("RGBA", (248, 48), (16, 20, 29, 255))
    d = ImageDraw.Draw(im)
    for j, key in enumerate("jklui"):
        x = j * 50
        d.rectangle((x, 0, x + 47, 47), fill=(33, 39, 52), outline=(66, 74, 91))
        path = ICONS / f"xion_{key}-v1.png" if character == "xion" else ART / f"skill_icons/{character}_{key}.png"
        im.alpha_composite(Image.open(path).convert("RGBA"), (x + 4, 4))
    return im


def build_icon_boards():
    time_check("icon comparison board")
    board = Image.new("RGB", (2100, 592), BG)
    d = ImageDraw.Draw(board)
    d.text((24, 16), "XION / SKILL ICONS / VFX-10c", font=TITLE, fill=TEXT)
    d.text((24, 50), "직접 그린 40×40 픽셀 · 일반 합성 · Xion 왼쪽 / 기존 Nova 오른쪽 · J K L U I", font=FONT, fill=MUTED)
    for j, character in enumerate(("xion", "nova")):
        x = 24 + j * 1048
        bar = icon_bar(character)
        d.text((x, 88), character.upper() + " / 1×", font=FONT, fill=TEXT)
        board.paste(bar, (x, 116))
        for k, key in enumerate("JKLUI"):
            d.text((x + k * 50 + 20, 169), key, font=SMALL, fill=MUTED)
        d.text((x, 208), character.upper() + " / 4× nearest", font=FONT, fill=TEXT)
        board.paste(bar.resize((992, 192), NEAREST), (x, 238))
        for k, key in enumerate("JKLUI"):
            d.text((x + k * 200 + 90, 442), key, font=FONT, fill=TEXT)
    d.text((24, 488), "J 쌍샷건 / K 회전·탄피 / L 반동 상승 / U 홀로그램 / I 사방 난사", font=FONT, fill=TEXT)
    d.text((24, 518), "아이콘 PNG에는 슬롯·문자·발광 테두리가 없습니다. 슬롯은 비교 보드에서만 표시했습니다.", font=FONT, fill=MUTED)
    d.text((24, 546), "리오는 U 아이콘이 없어 5칸 기준 비교에는 Nova를 사용했습니다. rio_k의 단순한 외곽선·픽셀 밀도를 참고했습니다.", font=FONT, fill=MUTED)
    save_image(REPORT / "icons-10c-1x-4x.png", board)

    # Compact final-report image, preserving native pixels and exact 4x zooms.
    small = Image.new("RGB", (1050, 590), BG)
    d = ImageDraw.Draw(small)
    d.text((24, 16), "XION / J K L U I", font=TITLE, fill=TEXT)
    d.text((24, 50), "40×40 원본 1×", font=FONT, fill=MUTED)
    small.paste(icon_bar("xion"), (24, 80))
    d.text((24, 147), "4× nearest / 진홍·검정·은색·작은 금색", font=FONT, fill=MUTED)
    small.paste(icon_bar("xion").resize((992, 192), NEAREST), (24, 178))
    labels = ["J  쌍샷건", "K  구르기·장전", "L  반동 도약", "U  홀로그램", "I  사방 난사"]
    for k, label in enumerate(labels):
        d.text((24 + k * 200, 383), label, font=FONT, fill=TEXT)
    d.text((24, 432), "기존 Nova / 같은 J K L U I 순서 / 1×", font=FONT, fill=MUTED)
    small.paste(icon_bar("nova"), (24, 462))
    d.text((24, 538), "정적 검토용 보드 · 후보 파일만 제작 · 게임 미연결", font=FONT, fill=MUTED)
    save_image(REPORT / "icons-10c.png", small)


def blast_frames(version, variant):
    im = Image.open(FX / f"xion_blast-{variant}-{version}.png").convert("RGBA")
    return [im.crop((k * 256, 0, (k + 1) * 256, 128)) for k in range(6)]


def blast_angles(frame, bright=False, pixel_corners=False):
    angles = []
    for y in range(128):
        for x in range(49, 256):
            rgba = frame.getpixel((x, y))
            if rgba[3] == 0 or (bright and rgba[1] <= 140):
                continue
            if pixel_corners:
                angles.extend(math.degrees(math.atan2(y + oy - 64, x + ox - 8))
                              for ox in (-.5, .5) for oy in (-.5, .5))
            else:
                angles.append(math.degrees(math.atan2(y - 64, x - 8)))
    return None if not angles else [min(angles), max(angles)]


def build_blast(variant):
    time_check("blast " + variant + " v2")
    source = FX / f"xion_blast-{variant}-v1.png"
    frames = blast_frames("v1", variant)
    # One smooth angular map for every frame: a straight source ray remains a
    # straight ray. This avoids the wavy streaks a data-driven column bound makes.
    # Near-muzzle x<=32 and the complete F1 flash are untouched. The final floor
    # bound also keeps pixel-square corners, not only centres, inside the cone.
    tangent = math.tan(math.radians(13.9))
    inner = math.tan(math.radians(8.0))
    shoulder = tangent - inner

    out = Image.new("RGBA", (1536, 128))
    changes = []
    for k, f in enumerate(frames):
        if k == 0:
            out.paste(f, (0, 0))
            changes.append({"moved_source_pixels": 0, "merged_source_pixels": 0})
            continue
        target = Image.new("RGBA", (256, 128))
        moved = merged = 0
        for x in range(256):
            for y in range(128):
                rgba = f.getpixel((x, y))
                if not rgba[3]:
                    continue
                dy = y - 64
                offset = abs(dy)
                if x > 32:
                    dx = x - 8
                    slope = abs(dy) / dx
                    new_slope = slope if slope <= inner else inner + shoulder * (
                        1 - math.exp(-(slope - inner) / shoulder))
                    target_offset = dx * new_slope
                    if x < 49:
                        t = (x - 32) / 17
                        t = t * t * (3 - 2 * t)
                        target_offset = abs(dy) + (target_offset - abs(dy)) * t
                    offset = math.floor(target_offset + 1e-9)
                    if x >= 49:
                        offset = min(offset, math.floor(tangent * (dx - .5) - .5))
                ny = 64 + (offset if dy >= 0 else -offset)
                moved += ny != y
                prev = target.getpixel((x, ny))
                if prev[3]:
                    merged += 1
                # Keep a source colour, favouring a bright core on collisions.
                if not prev[3] or sum(rgba[i] * w for i, w in enumerate((.299, .587, .114))) > sum(
                        prev[i] * w for i, w in enumerate((.299, .587, .114))):
                    target.putpixel((x, ny), rgba)
        out.paste(target, (256 * k, 0))
        changes.append({"moved_source_pixels": moved, "merged_source_pixels": merged})
    destination = FX / f"xion_blast-{variant}-v2.png"
    save_image(destination, out)
    meta = json.loads(source.with_suffix(".json").read_text(encoding="utf-8"))
    meta["note"] += " v2: 총구 첫 섬광과 x 위치·팔레트를 보존하고 탄흔의 세로 좌표만 안쪽으로 압축했다. 총구 밖 x>48의 모든 불투명 픽셀 모서리도 ±14도 안이다."
    meta["method"] = "Python + Pillow: native-resolution v1 smooth angular remap; no upscale, no interpolation, no new colours"
    meta["source_candidate"] = str(source.relative_to(ROOT)).replace("\\", "/")
    meta["source_sha256"] = hashlib.sha256(source.read_bytes()).hexdigest()
    # Keep the old extraction as provenance, rather than claiming it made v2 directly.
    meta["source_extraction"] = meta.pop("extraction", [])
    meta["remap"] = {
        "anchor": [8, 64], "axis_changed": "y only", "f1_unchanged": True,
        "all_frames_x_through_32_unchanged": True, "blend_columns": [33, 48],
        "cone_columns": [49, 254], "target_pixel_corner_limit_deg": 13.9,
        "same_angular_map_for_every_frame": True,
        "unchanged_inner_ray_angle_deg": 8.0,
        "outer_slope_formula": "t8 + (t13.9-t8)*(1-exp(-(abs(dy/dx)-t8)/(t13.9-t8)))",
        "pixel_corner_guard": "floor(tan(13.9deg)*(dx-0.5)-0.5)",
        "collision_rule": "retain brighter original RGB; alpha stays binary", "changes": changes,
    }
    save_json(destination.with_suffix(".json"), meta)


def add_paste(background, src, xy):
    im = background.convert("RGB")
    dst = im.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = src.getpixel((x, y))
            tx, ty = x + xy[0], y + xy[1]
            if a and 0 <= tx < im.width and 0 <= ty < im.height:
                base = dst[tx, ty]
                dst[tx, ty] = tuple(min(255, base[c] + round((r, g, b)[c] * a / 255)) for c in range(3))
    return im


def blast_scene(frame, guides=True):
    im = panel((380, 180))
    sheet = Image.open(ART / "xion/xion_sheet.png").convert("RGBA")
    # Same real attack pose and muzzle registration as the accepted v1 boards.
    pose = sheet.crop((128, 5 * 128, 256, 6 * 128))
    im.alpha_composite(pose, (6, 26))
    if guides:
        d = ImageDraw.Draw(im)
        for sign in (-1, 1):
            slope = sign * math.tan(math.radians(14))
            for dx in range(40, 237, 8):
                d.line((114 + dx, 79 + round(dx * slope),
                        114 + dx + 3, 79 + round((dx + 3) * slope)), fill=(64, 79, 99), width=1)
    im = add_paste(im, frame, (106, 15))
    if guides:
        d = ImageDraw.Draw(im)
        d.line((114, 156, 364, 156), fill=(127, 146, 170), width=1)
        for x in (114, 364):
            d.line((x, 152, x, 160), fill=TEXT)
        d.text((152, 161), "250 px / muzzle guide", font=SMALL, fill=TEXT)
    return im


def build_blast_boards(variant):
    time_check("blast " + variant + " boards")
    frames = blast_frames("v2", variant)
    for scale in (1, 4):
        cw, ch = 380 * scale, 180 * scale
        board = Image.new("RGB", (3 * (cw + 12) + 12, 90 + 2 * (ch + 38)), BG)
        d = ImageDraw.Draw(board)
        d.text((16, 12), f"XION BLAST {variant.upper()} v2 / {scale}× nearest / ALL 6 FRAMES", font=TITLE, fill=TEXT)
        d.text((16, 47), "실제 공격 시트 합성 · 가산 합성 · 점선 ±14° · 총구부터 250 px 가이드 · 실행 캡처 아님", font=FONT, fill=MUTED)
        for k, frame in enumerate(frames):
            x = 12 + (k % 3) * (cw + 12)
            y = 90 + (k // 3) * (ch + 38)
            board.paste(blast_scene(frame).resize((cw, ch), NEAREST), (x, y))
            angle = blast_angles(frame, pixel_corners=True)
            label = "총구 섬광" if angle is None else f"전 픽셀 모서리 {angle[0]:.2f}°…{angle[1]:.2f}°"
            d.text((x, y + ch + 7), f"F{k + 1} / {k / 30 * 1000:.0f} ms / {label}", font=SMALL, fill=TEXT)
        save_image(REPORT / f"xion_blast-{variant}-v2-{scale}x.png", board)


def build_blast_comparison():
    time_check("blast v1-v2 comparison")
    board = Image.new("RGB", (1212, 900), BG)
    d = ImageDraw.Draw(board)
    d.text((20, 16), "XION / BLAST v2 / ±14°", font=TITLE, fill=TEXT)
    d.text((20, 54), "같은 프레임 F3 · A 왼쪽 / B 오른쪽 · 위 v1 / 아래 v2 · 점선 = ±14°", font=FONT, fill=MUTED)
    for j, variant in enumerate("ab"):
        x = 20 + j * 602
        for row, version in enumerate(("v1", "v2")):
            frames = blast_frames(version, variant)
            ranges = [a for f in frames if (a := blast_angles(f)) is not None]
            signed = [min(a[0] for a in ranges), max(a[1] for a in ranges)]
            y = 108 + row * 255
            d.text((x, y), f"{variant.upper()} {version} / 불투명 픽셀 {signed[0]:.2f}°…{signed[1]:.2f}°", font=FONT, fill=TEXT)
            board.paste(blast_scene(frames[2]), (x, y + 30))
    d.text((20, 640), "F1 섬광 동일 · 6프레임 / 256×128 / 30 fps / 앵커 (8,64) / 가산 · x 좌표·사거리 동일", font=FONT, fill=TEXT)
    d.text((20, 676), "각도: 앵커 기준 atan2(y-64, x-8). 총구 장식을 제외한 x>48의 모든 불투명 픽셀을 검사.", font=FONT, fill=MUTED)
    d.text((20, 706), "픽셀 중심 외에 네 모서리도 ±14° 검사. 원본 v1 PNG·JSON과 기존 보드는 변경하지 않았습니다.", font=FONT, fill=MUTED)
    d.text((20, 754), "사람 판단: A의 가는 탄흔 / B의 굵은 파편 · 0.2초 재생의 타격감 · 45° 회전·좌우 반전 가독성", font=FONT, fill=TEXT)
    d.text((20, 787), "정적 스프라이트 합성입니다. 실제 게임 연결·재생·판정 테스트는 하지 않았습니다.", font=FONT, fill=MUTED)
    save_image(REPORT / "blasts-v2-compare-10c.png", board)


def build_overview():
    time_check("run 10c overview")
    board = Image.new("RGB", (1090, 930), BG)
    d = ImageDraw.Draw(board)
    d.text((24, 16), "XION / VFX-10c / 아이콘 5종 + 산탄 v2", font=TITLE, fill=TEXT)
    d.text((24, 54), "후보 7개 규격 검사 통과 · 실제 스프라이트 정적 합성 · 게임 미연결", font=FONT, fill=MUTED)
    d.text((24, 88), "J K L U I / 1×", font=SMALL, fill=MUTED)
    board.paste(icon_bar("xion"), (24, 112))
    d.text((24, 184), "Xion / 4× nearest", font=FONT, fill=TEXT)
    board.paste(icon_bar("xion").resize((992, 192), NEAREST), (24, 214))
    for k, label in enumerate(["J 쌍샷건", "K 구르기·탄피", "L 반동 도약", "U 홀로그램", "I 사방 난사"]):
        d.text((24 + k * 200, 417), label, font=FONT, fill=TEXT)
    d.text((24, 462), "기존 Nova / J K L U I / 1×", font=SMALL, fill=MUTED)
    board.paste(icon_bar("nova"), (24, 486))
    for j, variant in enumerate("ab"):
        frames = blast_frames("v2", variant)
        angles = [a for f in frames if (a := blast_angles(f, pixel_corners=True)) is not None]
        limit = max(abs(value) for pair in angles for value in pair)
        x = 24 + j * 530
        d.text((x, 570), f"산탄 {variant.upper()} v2 / 픽셀 모서리 최대 {limit:.2f}°", font=FONT, fill=TEXT)
        board.paste(blast_scene(frames[2]), (x, 604))
    d.text((24, 819), "±14° 통과 · 총구 밖 x>48의 모든 불투명 픽셀 기준 · 6프레임 / 30 fps / 앵커 (8,64)", font=FONT, fill=TEXT)
    d.text((24, 850), "사람 확인: 아이콘 1× 의미 구분 / A의 가는 탄흔과 B의 굵은 파편 / 실제 0.2초 재생·회전 가독성", font=FONT, fill=MUTED)
    d.text((24, 881), "원본 v1·기존 보드·제품 파일 보존. 1×/4× 전 프레임 보드와 실측 JSON을 함께 제공합니다.", font=FONT, fill=MUTED)
    save_image(REPORT / "board-10c.png", board)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("item", choices=["icon", "icon-boards", "blast", "blast-boards", "blast-compare", "overview"])
    parser.add_argument("key", nargs="?", choices=list("jkluiab"))
    args = parser.parse_args()
    if args.item == "icon":
        if args.key is None:
            parser.error("icon needs a key")
        build_icon(args.key)
    elif args.item == "icon-boards":
        build_icon_boards()
    elif args.item == "blast":
        if args.key not in ("a", "b"):
            parser.error("blast needs a or b")
        build_blast(args.key)
    elif args.item == "blast-boards":
        if args.key not in ("a", "b"):
            parser.error("blast-boards needs a or b")
        build_blast_boards(args.key)
    elif args.item == "blast-compare":
        build_blast_comparison()
    elif args.item == "overview":
        build_overview()


if __name__ == "__main__":
    main()
