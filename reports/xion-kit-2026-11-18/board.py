"""Lead board (2026-11-18, D51): the nine xion_kit_capture.gd shots, 1:1 crops in a 3x3 grid with
Korean labels. Usage: python board.py <shots dir> <out png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (shot, crop centre in the 960x540 window, label)
SHOTS = [
    ("1_shot", (450, 320), "1 J 산탄 사격: 산탄 줄과 총구 섬광"),
    ("2_point_blank", (470, 320), "2 붙어서 맞힘: 2배, 진홍 고리"),
    ("3_roll", (440, 320), "3 K 장전 구르기: 구르며 +2발"),
    ("4_recoil", (480, 300), "4 L 반동 도약: 발밑 일제 사격, 떠오름"),
    ("5_double_hunt", (440, 320), "5 U 도플갱어: 맞힌 적을 쫓아감"),
    ("6_double_pin", (560, 300), "6 붙잡음: 적 머리 위에 앉아 3초"),
    ("7_dive", (540, 300), "7 다시 U: 도플갱어 자리로 날아듦"),
    ("8_barrage", (450, 300), "8 I 이퀄리브리엄: 둘이 함께 사방 난사"),
    ("9_reload", (480, 300), "9 탄이 떨어지면 머리 위 장전 고리"),
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
