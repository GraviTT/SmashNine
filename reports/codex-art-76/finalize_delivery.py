"""Create an exact handoff manifest and read-only final artifact audit."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json, hashlib, re, subprocess
from pathlib import Path
from PIL import Image
import process as p
r=p.REPORT
ids=['muspelheim_magma_boar','niflheim_glacier_wolf','niflheim_frost_owl','jotunheim_storm_wisp','yggdrasil_root_guardian','yggdrasil_root_oracle']
assets=[]
for mid in ids:
    for row in p.ROWS:
        for ext in ['png','json']:assets.append(p.BAKE/f'{mid}-{row}-v1.{ext}')
    assets.append(p.BAKE/f'{mid}_sheet-v1.png')
assert len(assets)==78 and all(f.is_file() for f in assets)
pattern=re.compile(r'^art/bakeoff/monsters/('+'|'.join(ids)+r')(-(idle|walk|windup|attack|hurt|defeat)-v1\.(png|json)|_sheet-v1\.png)$')
report=[f for f in r.rglob('*') if f.is_file() and f.name!='run.log' and '__pycache__' not in f.parts and f.suffix!='.pyc']
future=[r/'delivery-files.txt',r/'delivery-integrity.json',r/'delivery-check.json']
files=sorted({f.relative_to(p.ROOT).as_posix() for f in assets+report+future})
for name in files:
    assert pattern.fullmatch(name) or name.startswith('reports/codex-art-76/'),name
    assert '..' not in name and 'art/raw/' not in name and '__pycache__' not in name and not name.endswith('/run.log'),name
    assert Path(p.ROOT/name).exists() or p.ROOT/name in future,name
(r/'delivery-files.txt').write_text('\n'.join(files)+'\n','utf-8')
hashes={}
for name in files:
    path=p.ROOT/name
    if path.name in ['delivery-integrity.json','delivery-check.json']:continue
    hashes[name]={'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
for f in report:
    if f.suffix.lower()=='.png':
        with Image.open(f) as im:im.verify()
for f in assets:
    if f.suffix.lower()=='.png':
        with Image.open(f) as im:im.verify()
tracked=subprocess.run(['git','diff','--name-only'],capture_output=True,text=True,check=True).stdout.splitlines()
assert not tracked,tracked
raw=list((p.ROOT/'art/raw/monsters-76').glob('*.png'));assert len(raw)==56
ignore=subprocess.run(['git','check-ignore','--stdin'],input='\n'.join(f.relative_to(p.ROOT).as_posix() for f in raw)+'\n',capture_output=True,text=True)
assert ignore.returncode==0 and len(ignore.stdout.splitlines())==56
new_assets=subprocess.run(['git','ls-files','--',*[f.relative_to(p.ROOT).as_posix() for f in assets]],capture_output=True,text=True,check=True).stdout
assert not new_assets.strip(),'Candidates must be new files'
check={'asset_files':78,'candidate_rows':36,'frames':168,'assembled_sheets':6,'manifest_files':len(files),'raw_images_preserved_ignored':len(raw),'prompts':len(list((r/'prompts').glob('*.txt'))),'tracked_changes':tracked,'all_pngs_decoded':True,'all_candidates_new_files':True,'commit_script':'PowerShell AST parsed only; not executed','Godot_executed':False,'image_tool':'built-in ImageGen','lessons_all_pass':False,'remaining':'Visual limitations in README; no missing monster/row'}
(r/'delivery-integrity.json').write_text(json.dumps(hashes,ensure_ascii=False,indent=2),'utf-8')
(r/'delivery-check.json').write_text(json.dumps(check,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(check,ensure_ascii=False))
print('Deliverable bytes excluding the two audit files:',sum(x['bytes'] for x in hashes.values()))
