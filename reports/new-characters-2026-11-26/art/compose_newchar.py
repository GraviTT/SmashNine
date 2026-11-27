"""Builds one pick cup clip for a new character candidate (CODEX-ART-98): 960x540, 30 fps, about 10.4 s,
in the same three parts as the Xion concept clips (reports/xion-art-2026-11-19/compose_concept.py):

  1. the main illustration and the idle frame, nearest-neighbour (3x for a 128-px cell, 2x for 192) (4 s)
  2. the frame in Muspelheim, the darkest realm, between Frey and Rio (female), at the match camera x2 (3.2 s)
  3. the same in Asgard, the brightest realm (3.2 s)

The realm shots come from `smash-nine-prototype/tests/analysis/lead/cup_newchar_capture.gd` (48 shots a realm;
each is shown twice so the part lasts as long as the Xion clips).

  python compose_newchar.py --id borok:1 --shots <dir with borok1/muspelheim/ and borok1/asgard/> --out <clip.mp4>
An id `c:n` reads art/bakeoff/newchar-2026-11-26/c/n/ (CODEX-ART-99); a plain id `c` reads .../c/ (ART-98).
"""
import argparse
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
ART = ROOT / "art" / "bakeoff" / "newchar-2026-11-26"
SIZE = (960, 540)
BACK = (42, 45, 52)
FPS = 30
# The realm shots are 960x540 at the match camera; this box holds the three fighters.
CROP = (240, 175, 720, 445)


def files(cid: str) -> tuple[Path, Path]:
    if ":" in cid:
        name, look = cid.split(":")
        base = ART / name / look
        return base / f"{name}_illustration-{look}.png", base / f"{name}-idle-{look}.png"
    return ART / cid / f"{cid}_illustration.png", ART / cid / f"{cid}-idle.png"


def still(cid: str) -> Image.Image:
    art_path, idle_path = files(cid)
    art = Image.open(art_path).convert("RGBA")
    idle = Image.open(idle_path).convert("RGBA")
    cell = idle.height
    idle = idle.crop((0, 0, cell, cell))
    frame = Image.new("RGBA", SIZE, BACK + (255,))
    height = 520
    art = art.resize((round(art.width * height / art.height), height), Image.LANCZOS)
    frame.alpha_composite(art, (40, 10))
    zoom = 3 if cell <= 128 else 2
    sprite = idle.resize((cell * zoom, cell * zoom), Image.NEAREST)
    frame.alpha_composite(sprite, (SIZE[0] - sprite.width - 40, (SIZE[1] - sprite.height) // 2))
    return frame.convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--id", required=True)
    parser.add_argument("--shots", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    shots = Path(args.shots) / args.id.replace(":", "")
    with tempfile.TemporaryDirectory() as tmp:
        frames: list[Image.Image] = [still(args.id)] * (4 * FPS)
        for realm in ("muspelheim", "asgard"):
            for path in sorted((shots / realm).glob("*.png")):
                shot = Image.open(path).convert("RGB").crop(CROP).resize(SIZE, Image.NEAREST)
                frames.extend([shot, shot])
        for index, frame in enumerate(frames):
            frame.save(Path(tmp) / f"{index:04d}.png")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-framerate", str(FPS), "-i", str(Path(tmp) / "%04d.png"),
                        "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "12", args.out], check=True)
    print(f"{args.out}: {len(frames)} frames")


if __name__ == "__main__":
    main()
