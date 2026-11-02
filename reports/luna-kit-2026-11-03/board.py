"""Lead board (2026-11-03, D45): the nine luna_kit_capture.gd shots in a 3x3 grid with Korean labels.
Usage: python luna_kit_board.py <shots dir> <out png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SHOTS = [
    ("1_star_volley", "1 별빛 연사: 큰 별과 별 표식"),
    ("2_warp_burst", "2 반짝 도약: 나타나며 폭발"),
    ("3_barrier", "3 별의 방어막: Rio 검기를 막음"),
    ("4_mark_burst", "4 변신: 먼 곳의 표식 폭발, 기절"),
    ("5_brave_rush", "5 브레이브 러시: 적 앞에서 타격"),
    ("6_grab", "6 혜성 붙잡기: 잡아 든 상태"),
    ("7_cyclone_spin", "7 별의 회오리: 검기를 막음"),
    ("8_cyclone_shot", "8 회오리 발사: 맞으면 기절"),
    ("9_star_beam", "9 별의 광선(하트 광선 그림)"),
]
CELL = (640, 360)
LABEL_H = 34

def main() -> None:
    shots, out = Path(sys.argv[1]), Path(sys.argv[2])
    font_path = Path(__file__).resolve().parents[2] / "smash-nine-prototype" / "assets" / "fonts" / "NotoSansKR-UI.ttf"
    font = ImageFont.truetype(str(font_path), 22)
    board = Image.new("RGB", (CELL[0] * 3, (CELL[1] + LABEL_H) * 3), (14, 17, 26))
    draw = ImageDraw.Draw(board)
    for index, (name, label) in enumerate(SHOTS):
        shot = Image.open(shots / f"{name}.png").convert("RGB")
        # The action sits in the middle of the 960x540 window.
        left, top = (shot.width - 768) // 2, (shot.height - 432) // 2
        shot = shot.crop((left, top, left + 768, top + 432)).resize(CELL, Image.LANCZOS)
        x, y = (index % 3) * CELL[0], (index // 3) * (CELL[1] + LABEL_H)
        board.paste(shot, (x, y + LABEL_H))
        draw.text((x + 10, y + 4), label, font=font, fill=(240, 232, 210))
    board.save(out)
    print("saved", out)

main()
