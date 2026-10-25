from pathlib import Path
from PIL import Image
import json, shutil

ROOT = Path(__file__).resolve().parents[2]
SOURCES = [
    ('shadow_dissolve-v1_raw.png', 'exec-e3a91fad-8712-4c64-8bb8-991789284931.png'),
    ('shadow_dissolve-v2_raw.png', 'exec-36f4052b-e47d-4c49-8dfc-d259e922a214.png'),
]
raw = ROOT / 'art/raw/story'
raw.mkdir(parents=True, exist_ok=True)
for name, source in SOURCES:
    src = Path('C:/Users/TH/.codex/generated_images/01a17254-1bed-7c43-97c4-5e6eede36eaa') / source
    dst = raw / name
    if not dst.exists():
        shutil.copy2(src, dst)
    im = Image.open(dst).convert('RGBA')
    print(name, im.size)
    for i in range(6):
        x, y = i % 3 * 512, i // 3 * 512
        cell = im.crop((x, y, x+512, y+512))
        a = cell.getchannel('A').point(lambda v: 255 if v >= 128 else 0)
        print(i+1, a.getbbox(), sum(v > 0 for v in a.get_flattened_data()))
bg = Image.open(ROOT / 'smash-nine-prototype/assets/art/ui/title_bg.png').convert('RGB')
print('title background corner', bg.getpixel((0, 0)))
