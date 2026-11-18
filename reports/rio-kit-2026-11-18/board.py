"""Lead board (2026-11-18, D50): the nine rio_kit_capture.gd shots, 1:1 crops in a 3x3 grid with
Korean labels. Usage: python board.py <shots dir> <out png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (shot, crop centre in the 960x540 window, label)
SHOTS = [
    ("1_backstab", (470, 320), "1 급소: 등 뒤에서 맞혀 1.5배, 푸른 X"),
    ("2_pierce", (470, 320), "2 J 3타 관통 베기: 지나가서 돌아봄"),
    ("3_sword_stuck", (420, 320), "3 K 마검 투척: 적에게 꽂힌 검"),
    ("4_sword_blink", (520, 320), "4 다시 K: 꽂힌 적의 등 뒤로 순간이동"),
    ("5_counter_stance", (480, 320), "5 L 받아치기 자세(그림자색)"),
    ("6_counter_strike", (440, 320), "6 맞는 순간 사라져 때린 적의 등 뒤로"),
    ("7_decoy", (480, 320), "7 U 분신: 분신을 두고 물러남"),
    ("8_flurry_swords", (480, 320), "8 I 마검 난무: 두 적에게 꽂힌 검 6자루"),
    ("9_flurry_cut", (480, 320), "9 다시 I: 꽂힌 적의 등 뒤를 차례로 벰"),
]
CELL = (640, 360)
LABEL_H = 36


def font() -> ImageFont.FreeTypeFont:
    for path in ("C:/Windows/Fonts/malgun.ttf", str(Path(__file__).resolve().parents[2] / "smash-nine-prototype/assets/fonts/NotoSansKR-UI.ttf")):
        if Path(path).exists():
            return ImageFont.truetype(path, 22)
    raise SystemExit("no Korean font")


def main() -> None:
    shots, out = Path(sys.argv[1]), Path(sys.argv[2])
    label_font = font()
    board = Image.new("RGB", (CELL[0] * 3, (CELL[1] + LABEL_H) * 3), (14, 17, 26))
    draw = ImageDraw.Draw(board)
    for index, (name, centre, label) in enumerate(SHOTS):
        shot = Image.open(shots / f"{name}.png").convert("RGB")
        left = min(max(centre[0] - CELL[0] // 2, 0), shot.width - CELL[0])
        top = min(max(centre[1] - CELL[1] // 2, 0), shot.height - CELL[1])
        crop = shot.crop((left, top, left + CELL[0], top + CELL[1]))
        x, y = (index % 3) * CELL[0], (index // 3) * (CELL[1] + LABEL_H)
        board.paste(crop, (x, y + LABEL_H))
        draw.text((x + 10, y + 5), label, font=label_font, fill=(240, 232, 210))
    board.save(out)
    print("saved", out)


main()
