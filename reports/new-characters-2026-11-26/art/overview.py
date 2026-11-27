"""One sheet of the nine new-character looks (CODEX-ART-99): a row per character, each look's illustration with its
idle frame at 2x nearest, labelled. Looks that are not drawn yet are left blank.

  python overview.py  ->  reports/new-characters-2026-11-26/art/overview.png
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[3]
ART = ROOT / "art" / "bakeoff" / "newchar-2026-11-26"
OUT = Path(__file__).resolve().parent / "overview.png"
NAMES = {
    "borok": ["대장장이 왕 거인", "강철 거인", "젊은 대장장이 거인"],
    "doron": ["고물 수집가", "자라는 슈트", "조종사 대기생"],
    "jupi": ["폭풍 지휘자", "천둥 북잡이", "번개 운동선수"],
}
TITLES = {"borok": "Borok 보록", "doron": "Doron 도론", "jupi": "Jupi 유피"}
W, H, TOP = 560, 520, 40


def main() -> None:
    font = ImageFont.truetype("C:/Windows/Fonts/malgun.ttf", 22)
    sheet = Image.new("RGB", (W * 3, (H + TOP) * 3), (42, 45, 52))
    draw = ImageDraw.Draw(sheet)
    for row, (cid, looks) in enumerate(NAMES.items()):
        for col, label in enumerate(looks):
            n = str(col + 1)
            x0, y0 = col * W, row * (H + TOP)
            draw.text((x0 + 12, y0 + 8), f"{TITLES[cid]} {n} · {label}", fill=(235, 235, 235), font=font)
            base = ART / cid / n
            art_path, idle_path = base / f"{cid}_illustration-{n}.png", base / f"{cid}-idle-{n}.png"
            if not art_path.exists():
                draw.text((x0 + 12, y0 + TOP + 200), "아직 없음", fill=(150, 150, 150), font=font)
                continue
            tile = Image.new("RGBA", (W, H), (42, 45, 52, 255))
            art = Image.open(art_path).convert("RGBA")
            art = art.resize((round(art.width * H / art.height), H), Image.LANCZOS)
            tile.alpha_composite(art, (0, 0))
            if idle_path.exists():
                idle = Image.open(idle_path).convert("RGBA")
                cell = idle.height
                idle = idle.crop((0, 0, cell, cell)).resize((cell * 2, cell * 2), Image.NEAREST)
                tile.alpha_composite(idle, (W - idle.width - 6, H - idle.height - 4))
            sheet.paste(tile.convert("RGB"), (x0, y0 + TOP))
    sheet.save(OUT)
    print(OUT, sheet.size)


if __name__ == "__main__":
    main()
