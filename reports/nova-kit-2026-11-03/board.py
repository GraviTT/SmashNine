"""Lead board (2026-11-03, D47): the nine nova_kit_capture.gd shots, 1:1 crops in a 3x3 grid with
Korean labels. Usage: python board.py <shots dir> <out png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# (shot, crop centre in the 960x540 window, label)
SHOTS = [
    ("1_chain_stack", (420, 320), "1 J 3타째: Frey 머리 위 중첩 1"),
    ("2_orb_pull", (480, 320), "2 중력 구체: 터진 자리로 둘을 끌어옴"),
    ("3_field", (450, 300), "3 중력 필드: 나는 Nova, 뜬 몬스터, 느린 Luna"),
    ("4_beam_drag", (420, 330), "4 중력 광선: 땅의 적을 끌어옴"),
    ("5_beam_slam", (420, 250), "5 중력 광선: 공중의 적을 내리꽂음"),
    ("6_root", (440, 320), "6 3단계 고정: 점 셋과 발밑 고리"),
    ("7_sphere", (480, 230), "7 사건의 지평선: 구체 둘레를 도는 적"),
    ("8_launch_fall", (480, 250), "8 다시 I: Nova 사출, 구체 낙하"),
    ("9_sphere_burst", (480, 330), "9 구체가 땅에서 터짐: 피해와 중첩"),
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
