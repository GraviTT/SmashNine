"""Builds one pick cup clip for a Xion concept (CODEX-ART-94 A-B, -95 C-F): 960x540, 30 fps, about 10.4 s.
Every candidate gets the same three parts, so two clips side by side show the same thing at the same time:

  1. the main illustration and the first idle frame at 3x nearest (4 s)
  2. that frame in Muspelheim, the darkest realm, between Frey and Rio (female), at the match camera x2 (3.2 s)
  3. the same in Asgard, the brightest realm (3.2 s)

The realm shots come from `smash-nine-prototype/tests/analysis/lead/cup_xion_look_capture.gd --still`.

  python compose_concept.py --letter c --shots <dir with muspelheim/ and asgard/> --out <clip.mp4>
"""
import argparse
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SIZE = (960, 540)
BACK = (42, 45, 52)
FPS = 30
# The realm shots are 960x540 at the match camera; this box holds the three fighters.
CROP = (240, 175, 720, 445)


def still(letter: str) -> Image.Image:
    base = ROOT / "art" / "bakeoff" / "xion" / letter
    art = Image.open(base / f"xion_illustration-{letter}.png").convert("RGBA")
    idle = Image.open(base / f"xion-idle-{letter}.png").convert("RGBA").crop((0, 0, 128, 128))
    frame = Image.new("RGBA", SIZE, BACK + (255,))
    height = 520
    art = art.resize((round(art.width * height / art.height), height), Image.LANCZOS)
    frame.alpha_composite(art, (40, 10))
    sprite = idle.resize((384, 384), Image.NEAREST)
    frame.alpha_composite(sprite, (SIZE[0] - 384 - 40, (SIZE[1] - 384) // 2))
    return frame.convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--letter", required=True)
    parser.add_argument("--shots", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    shots = Path(args.shots)
    with tempfile.TemporaryDirectory() as tmp:
        frames: list[Image.Image] = [still(args.letter)] * (4 * FPS)
        for realm in ("muspelheim", "asgard"):
            for path in sorted((shots / realm).glob("*.png")):
                frames.append(Image.open(path).convert("RGB").crop(CROP).resize(SIZE, Image.NEAREST))
        for index, frame in enumerate(frames):
            frame.save(Path(tmp) / f"{index:04d}.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(Path(tmp) / "%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "12", args.out], check=True)
    print(f"{args.out}: {len(frames)} frames")


if __name__ == "__main__":
    main()
