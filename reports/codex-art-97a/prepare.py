from pathlib import Path
import json
import shutil
import subprocess
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'reports/codex-art-97a'
RAW = ROOT / 'art/raw/xion-97a'
RAW.mkdir(parents=True, exist_ok=True)
anchor = ROOT / 'art/bakeoff/xion/b/xion-idle-b2.png'
shutil.copy2(anchor, RAW / anchor.name)
im = Image.open(anchor).convert('RGBA')
frame = im.crop((0, 0, 128, 128)).resize((512, 512), Image.Resampling.NEAREST)
bg = Image.new('RGBA', frame.size, '#00ff00')
bg.alpha_composite(frame)
bg.convert('RGB').save(RAW / 'anchor-f1-4x.png')
im.resize((3072,512), Image.Resampling.NEAREST).save(REPORT / 'anchor-4x.png')
(REPORT / 'baseline-status.txt').write_text(subprocess.check_output(['git','status','--porcelain=v1','-uall'], cwd=ROOT).decode('utf-8'), encoding='utf-8')
print(json.dumps({'free_bytes':shutil.disk_usage(ROOT).free,'planned_new_files_estimate_mib':60,'reference':str(RAW/'anchor-f1-4x.png')}))
