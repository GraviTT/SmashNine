import os, json, shutil, subprocess
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / 'art/raw/newchar-99b'
REPORT = ROOT / 'reports/codex-art-99b'
RAW.mkdir(parents=True, exist_ok=True)
refs = [('frey','frey'), ('rio','rio_female'), ('nova','nova_female'), ('luna','luna'), ('xion','xion')]
for folder, name in refs:
    src = ROOT / f'smash-nine-prototype/assets/art/{folder}/{name}_sheet.png'
    im = Image.open(src).convert('RGBA').crop((0,0,128,128))
    im.save(RAW / f'ref-{name}-idle.png')
    im.resize((512,512),Image.Resampling.NEAREST).save(RAW / f'ref-{name}-idle-4x.png')
for c, nums in [('doron',[1,2,3]),('jupi',[2,3])]:
    for n in nums:
        (ROOT / f'art/bakeoff/newchar-2026-11-26/{c}/{n}').mkdir(parents=True,exist_ok=True)
baseline = {'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),
            'tracked_diff':subprocess.check_output(['git','diff','--name-only'],cwd=ROOT,text=True).splitlines(),
            'staged_diff':subprocess.check_output(['git','diff','--cached','--name-only'],cwd=ROOT,text=True).splitlines(),
            'disk_free_bytes':shutil.disk_usage(ROOT).free,
            'start_utc':'2026-11-27T02:22:13Z','hard_stop_utc':'2026-11-27T04:12:13Z'}
(REPORT/'baseline.json').write_text(json.dumps(baseline,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(baseline,ensure_ascii=False))
