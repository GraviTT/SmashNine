"""Installs Xion B (the user's pick; CODEX-ART-96, -97) into the game under the names the game already loads.

  xion_sheet.png         idle 6 | walk 8 (two rows) | jump 1 | fall 1 | attack 6 | shield 6 | hurt 1  (Xion.SHEET_ROWS)
  xion_jump/fall/hurt/land.png   the motion strips (128-px cells)
  xion_victory/defeat.png        the wide strips (192-px cells)
  xion_illustration.png          main art with her hologram double
  xion_face.png                  cut from her figure only

The base sheet's single jump, fall and hurt drawings are frames of the strips (jump 2, fall 1, hurt 1 by default).
The move sheet (`xion_moves_sheet.png`) and `xion_portrait.png` stay as they are.

  python install_b.py [--jump-frame 2] [--fall-frame 1] [--hurt-frame 1] [--skip-missing]
"""
import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art" / "bakeoff" / "xion" / "b"
DST = ROOT / "smash-nine-prototype" / "assets" / "art" / "xion"
CELL = 128


def single(strip: str, number: int, out: Path) -> Path:
    image = Image.open(SRC / strip).convert("RGBA")
    index = number - 1
    if (index + 1) * CELL > image.width:
        raise SystemExit(f"{strip} has no frame {number}")
    image.crop((index * CELL, 0, (index + 1) * CELL, CELL)).save(out)
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jump-frame", type=int, default=2)
    parser.add_argument("--fall-frame", type=int, default=1)
    parser.add_argument("--hurt-frame", type=int, default=1)
    parser.add_argument("--skip-missing", action="store_true", help="leave a strip in place when its candidate is not drawn yet")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        rows = [
            SRC / "xion-idle-b2.png",
            SRC / "xion-walk-b2.png",
            single("xion-jump-b2.png", args.jump_frame, tmp_dir / "jump1.png"),
            single("xion-fall-b2.png", args.fall_frame, tmp_dir / "fall1.png"),
            SRC / "xion-attack-b2.png",
            SRC / "xion-shield-b2.png",
            single("xion-hurt-b2.png", args.hurt_frame, tmp_dir / "hurt1.png"),
        ]
        subprocess.run([sys.executable, str(ROOT / "tools" / "sprite_pipeline" / "assemble.py"), "--cell", str(CELL),
                        "--out", str(DST / "xion_sheet.png")] + [str(row) for row in rows], check=True)
    copies = {
        "xion-jump-b2.png": "xion_jump.png",
        "xion-fall-b2.png": "xion_fall.png",
        "xion-hurt-b2.png": "xion_hurt.png",
        "xion-land-b2.png": "xion_land.png",
        "xion-victory-b2.png": "xion_victory.png",
        "xion-defeat-b2.png": "xion_defeat.png",
        "xion_illustration-b2.png": "xion_illustration.png",
        "xion_face-b.png": "xion_face.png",
    }
    copied = 0
    for source, target in copies.items():
        if not (SRC / source).exists() and args.skip_missing:
            print(f"kept the current {target}: {source} is not drawn yet")
            continue
        shutil.copyfile(SRC / source, DST / target)
        copied += 1
    sheet = Image.open(DST / "xion_sheet.png")
    print(f"xion_sheet.png {sheet.size}; copied {copied} files into {DST.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
