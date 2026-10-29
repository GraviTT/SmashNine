import os, json, shutil
from pathlib import Path
from PIL import Image
os.environ['PYTHONDONTWRITEBYTECODE']='1'
R=Path('reports/codex-art-92'); RAW=Path('art/raw/motions-92'); RAW.mkdir(parents=True,exist_ok=True)
for name in ['process.py','face_check.py','process_75.py','face_check_75.py','process_77.py','face_check_77.py','run_variant_v2.py','package_results.py','verify_delivery.py']:
    with (R/('art89_'+name)).open('xb') as f:f.write((Path('reports/codex-art-89')/name).read_bytes())
forms={'frey':('frey',2),'luna':('luna',3),'luna_brave':('luna',4),'nova_male':('nova',2),'nova_female':('nova',2),'rio_male':('rio',2),'rio_female':('rio',2),'yuki':('yuki',2)}
for stem,(folder,v) in forms.items():
    p=Path(f'art/bakeoff/{folder}/{stem}-idle-v{v}.png')
    im=Image.open(p).convert('RGBA').crop((0,0,128,128)).resize((512,512),Image.Resampling.NEAREST)
    with (RAW/f'{stem}-anchor.png').open('xb') as f:im.save(f,format='PNG')
with (R/'progress.md').open('x',encoding='utf-8') as f:f.write('# ART-92 행별 진행\n\n시간(KST) | 폼 | 행 | 파일 | 프레임 | 검사 | 비고\n---|---|---|---|---|---|---\n')
with (R/'commit-paths.txt').open('x',encoding='utf-8') as f:f.write('design/tasks/CODEX-ART-92.md\ndesign/tasks/CODEX-ART-92.prompt.md\nreports/codex-art-92/progress.md\nreports/codex-art-92/README.md\nreports/codex-art-92/commit.ps1\nreports/codex-art-92/commit-paths.txt\n')
print(json.dumps(forms))
