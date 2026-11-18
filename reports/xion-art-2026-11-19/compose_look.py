"""Builds one pick cup clip for a Xion look candidate (CODEX-ART-94): 960x540, 30 fps, about 12.5 s.

  1. the main illustration and the face (3 s)
  2. her idle in Muspelheim, the darkest realm, between Frey and Rio (female), at the match camera x2 (3.2 s)
  3. the same in Asgard, the brightest realm (3.2 s)
  4. the idle strip at 4x nearest, at 6.3 fps (3 s)

The realm shots come from `smash-nine-prototype/tests/analysis/lead/cup_xion_look_capture.gd`.

  python compose_look.py --letter a --shots <dir with muspelheim/ and asgard/> --out <clip.mp4>
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
    face = Image.open(base / f"xion_face-{letter}.png").convert("RGBA")
    frame = Image.new("RGBA", SIZE, BACK + (255,))
    height = 520
    art = art.resize((round(art.width * height / art.height), height), Image.LANCZOS)
    frame.alpha_composite(art, (190 - art.width // 2 + 140, 10))
    frame.alpha_composite(face, (620, (SIZE[1] - face.height) // 2))
    return frame.convert("RGB")


def strip_frames(letter: str) -> list[Image.Image]:
    strip = Image.open(ROOT / "art" / "bakeoff" / "xion" / letter / f"xion-idle-{letter}.png").convert("RGBA")
    return [strip.crop((i * 128, 0, i * 128 + 128, 128)) for i in range(6)]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--letter", required=True)
    parser.add_argument("--shots", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    shots = Path(args.shots)
    with tempfile.TemporaryDirectory() as tmp:
        frames: list[Image.Image] = [still(args.letter)] * (3 * FPS)
        for realm in ("muspelheim", "asgard"):
            for path in sorted((shots / realm).glob("*.png")):
                frames.append(Image.open(path).convert("RGB").crop(CROP).resize(SIZE, Image.NEAREST))
        idle = strip_frames(args.letter)
        for index in range(3 * FPS):
            frame = Image.new("RGBA", SIZE, BACK + (255,))
            cell = idle[int(index / FPS * 6.3) % 6].resize((512, 512), Image.NEAREST)
            frame.alpha_composite(cell, ((SIZE[0] - 512) // 2, (SIZE[1] - 512) // 2))
            frames.append(frame.convert("RGB"))
        for index, frame in enumerate(frames):
            frame.save(Path(tmp) / f"{index:04d}.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(Path(tmp) / "%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "12", args.out], check=True)
    print(f"{args.out}: {len(frames)} frames")


if __name__ == "__main__":
    main()
