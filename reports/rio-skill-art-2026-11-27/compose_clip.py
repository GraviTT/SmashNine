"""Pick cup clips for Rio's kit v3 art (2026-11-27; from the Xion version of 2026-11-24): a frame folder from the
lead captures (`cup_rio_moves_capture.gd`, `cup_rio_fx_capture.gd`, 960x540 at the match camera, 30 fps) becomes
one mp4. The icons have no game scene: `--icons` builds a still of the skill bar at 1x and 4x and holds it for 3 s.
"now" shows the icons the game has (the key letter where there is none); a candidate shows its five icons.

  python compose_clip.py --frames <dir> --out <clip.mp4>
  python compose_clip.py --icons <now|v1> [--char rio] --out <clip.mp4>
"""
import argparse
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SIZE = (960, 540)
BACK = (24, 27, 36)
FPS = 30
SLOTS = ["j", "k", "l", "u", "i"]


def encode(frames: list[Path], out: str) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        for index, path in enumerate(frames):
            Image.open(path).convert("RGB").resize(SIZE, Image.NEAREST).save(Path(tmp) / f"{index:04d}.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(Path(tmp) / "%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "12", out], check=True)
    print(f"{out}: {len(frames)} frames")


def font(size: int) -> ImageFont.ImageFont:
    for path in ("C:/Windows/Fonts/malgun.ttf", str(ROOT / "smash-nine-prototype/assets/fonts/NotoSansKR-UI.ttf")):
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def slot(icon: Image.Image | None, letter: str, scale: int) -> Image.Image:
    cell = Image.new("RGBA", (48 * scale, 48 * scale), (20, 23, 36, 210))
    draw = ImageDraw.Draw(cell)
    draw.rectangle((0, 0, 48 * scale - 1, 48 * scale - 1), outline=(255, 255, 255, 64), width=max(1, scale))
    if icon is not None:
        cell.alpha_composite(icon.resize((40 * scale, 40 * scale), Image.NEAREST), (4 * scale, 4 * scale))
    else:
        text = font(22 * scale)
        box = draw.textbbox((0, 0), letter.upper(), font=text)
        draw.text(((48 * scale - box[2]) // 2, (48 * scale - box[3]) // 2 - 2 * scale), letter.upper(), font=text, fill=(242, 140, 150, 255))
    return cell


def icons_still(variant: str, char: str) -> Image.Image:
    frame = Image.new("RGBA", SIZE, BACK + (255,))
    for row, scale in enumerate((1, 4)):
        y = 70 if scale == 1 else 170
        x = (SIZE[0] - (5 * 48 * scale + 4 * 6 * scale)) // 2 if scale == 1 else 30
        for index, name in enumerate(SLOTS):
            icon = None
            if variant == "now":
                path = ROOT / "smash-nine-prototype/assets/art/skill_icons" / f"{char}_{name}.png"
            else:
                path = ROOT / f"art/bakeoff/skill_icons/{char}" / f"{char}_{name}-{variant}.png"
            if path.exists():
                icon = Image.open(path).convert("RGBA")
            step = (48 + 6) * scale if scale == 1 else 182
            frame.alpha_composite(slot(icon, name, scale if scale == 1 else 3), (x + index * step, y))
    return frame.convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--frames")
    parser.add_argument("--icons")
    parser.add_argument("--char", default="rio")
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    if args.icons:
        with tempfile.TemporaryDirectory() as tmp:
            still = icons_still(args.icons, args.char)
            paths = []
            for index in range(3 * FPS):
                path = Path(tmp) / f"s{index:04d}.png"
                still.save(path)
                paths.append(path)
            encode(paths, args.out)
        return
    encode(sorted(Path(args.frames).glob("*.png")), args.out)


if __name__ == "__main__":
    main()
