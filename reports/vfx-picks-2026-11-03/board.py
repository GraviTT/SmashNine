"""Lead board (2026-11-03): the picked Frey (CODEX-VFX-03) and Luna (CODEX-VFX-04) effects in the
game, from frey_kit_capture.gd and luna_kit_capture.gd, 1:1 crops in a 3x3 grid with Korean labels.
Usage: python board.py <shots dir with frey/ and luna/> <out png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (shot, crop centre in the 960x540 window, label)
SHOTS = [
    ("frey/1_wing_hover", (420, 270), "Frey 날개 A: 공중에서 점프 꾹 누르기"),
    ("frey/3_sword_wave", (470, 300), "Frey 검기 B: 회오리 검기 투사체"),
    ("frey/4_descent_light", (330, 300), "Frey 강림 빛 B, Luna 머리 위 모래시계(슬로우)"),
    ("luna/1_star_volley", (450, 320), "Luna 큰 별 탄환, Frey 머리 위 별 표식"),
    ("luna/2_warp_burst", (420, 320), "Luna 반짝 도약 도착 폭발 B"),
    ("luna/3_barrier", (480, 330), "Luna 별의 방어막 B: Rio 검기를 막음"),
    ("luna/3b_barrier_break", (480, 330), "Luna 방어막 깨짐 B"),
    ("luna/7_cyclone_spin", (480, 330), "Luna 별의 회오리, 회전 중 B"),
    ("luna/8_cyclone_shot", (500, 330), "Luna 별의 회오리, 날아가는 투사체 A"),
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
