from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / "art/raw/walk-59/yuki"


def save_frame(source: Path, index: int, target: Path) -> None:
	image = Image.open(source).convert("RGBA")
	frame = image.crop((index * 128, 0, (index + 1) * 128, 128))
	frame.resize((512, 512), Image.Resampling.NEAREST).save(target)


RAW.joinpath("refs").mkdir(parents=True, exist_ok=True)
save_frame(ROOT / "art/bakeoff/yuki/yuki-idle-v2.png", 0, RAW / "refs/idle_frame0_4x.png")
save_frame(ROOT / "art/bakeoff/yuki/yuki-walk-v1.png", 0, RAW / "refs/walk_frame0_4x.png")
save_frame(ROOT / "art/bakeoff/yuki/yuki-walk-v1.png", 1, RAW / "refs/legacy_legs_together_4x.png")

accepted = RAW / "normalized/frame-01-f010.png"
if accepted.exists():
	Image.open(accepted).convert("RGBA").crop((0, 0, 128, 128)).resize((512, 512), Image.Resampling.NEAREST).save(RAW / "refs/accepted_frame01_4x.png")
