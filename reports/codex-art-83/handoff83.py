"""Prepare an explicit, lean handoff without staging or committing."""
import os
os.environ['PYTHONDONTWRITEBYTECODE']='1'
import json,hashlib
from datetime import datetime,timezone,timedelta
from pathlib import Path
import repair as r
from verify83 import digest
selection=json.loads((r.REPORT/'selection.json').read_text('utf-8'))
raw_names=['mossling-walk-g1.png','mossling-walk-g2.png','ember_imp-walk-g1.png','ember_imp-walk-g2.png','ember_imp-idle-g1.png','asgard_aegis_ram-idle-g1.png','mossling-attack-g1-rejected.png','mossling-attack-g2.png','vanaheim_seed_sprite-attack-g1.png','vanaheim_seed_sprite-attack-g2.png','vanaheim_seed_sprite-attack-g3.png','alfheim_moon_moth-windup-g1.png','jotunheim_storm_wisp-hurt-g1.png','jotunheim_storm_wisp-hurt-g2.png','jotunheim_storm_wisp-hurt-g3.png','niflheim_glacier_wolf-attack-g1.png']
parts=['ART-83 built-in ImageGen prompts (16 calls)\nCurrent game sheet and v1 idle references were copied into art/raw/monsters-83/references/.\nVine hound: no generation; ART-74 RGB remap only.\n']
for i,name in enumerate(raw_names,1):
 assert (r.RAW/name).is_file();prompt=(r.REPORT/f'prompt-{i:02}.txt').read_text('utf-8');parts.append(f'\n--- CALL {i:02} / OUTPUT art/raw/monsters-83/{name} ---\n{prompt.rstrip()}\n')
r.fresh(r.REPORT/'prompts.txt').write_text('\n'.join(parts),encoding='utf-8')
raws=[dict(file=p.relative_to(r.ROOT).as_posix(),bytes=p.stat().st_size,sha256=digest(p)) for p in sorted(r.RAW.rglob('*')) if p.is_file()]
refchecks=[]
for mid in dict.fromkeys(x['monster'] for x in selection):
 for copy,source in [(r.RAW/'references'/f'{mid}-idle-v1.png',r.BAKE/f'{mid}-idle-v1.png'),(r.RAW/'references'/f'{mid}_current.png',r.ROOT/f'smash-nine-prototype/assets/art/monsters/{mid}_sheet.png')]:
  assert digest(copy)==digest(source);refchecks.append(dict(copy=copy.relative_to(r.ROOT).as_posix(),source=source.relative_to(r.ROOT).as_posix(),sha256=digest(copy)))
r.jsave(r.REPORT/'source-manifest.json',dict(raws=raws,reference_copies=refchecks,builtin_image_calls=16,raws_excluded_from_git=True))
judgements={
 ('mossling','walk'):'밝은 앞다리 전후 교대가 1×에서 식별됨. F4–5 잎 아래 연결부 가림은 남음.',
 ('ember_imp','walk'):'밝은 가까운 다리와 어두운 먼 다리가 전후 순서를 바꿈. 상체 흔들림이 남음.',
 ('ember_imp','idle'):'눈·뿔·꼬리 정체성 유지. 비늘 명암이 조밀해졌으며 기존보다 대비가 강함.',
 ('asgard_aegis_ram','idle'):'금색 뿔과 푸른 털 유지. 털/금속 명암이 세밀해짐.',
 ('mossling','attack'):'몸이 앞으로 뻗고 회복함. 입만 벌어지던 v1보다 돌진이 읽힘. 길게 늘어나는 느낌은 남음.',
 ('vanaheim_seed_sprite','attack'):'녹색 몸과 흰 꽃 유지. F2에서 뒤로 당긴 꽃을 F3–4 앞으로 뻗음. 연속 재생 검수 필요.',
 ('alfheim_moon_moth','windup'):'전 4장 몸 중심/머리 크기가 안정적. 두 번째 더듬이 끝은 여전히 약함.',
 ('jotunheim_storm_wisp','hurt'):'F1에서 핵에 대한 돌 군집의 기울기와 외곽이 바뀜. F2 회복. 색 변경만의 피격이 아님.',
 ('niflheim_glacier_wolf','attack'):'F3 최고점, F4 하강, F5 착지, F6 회복이 식별됨. 실제 재생 연결은 미검증.',
}
reviews=[]
for x in selection:
 mid,row=x['monster'],x['row'];reviews.append(dict(monster=mid,row=row,trial=x['trial'],frames=list(range(1,x['frames']+1)),personally_inspected_scales=[1,4],judgement=judgements.get((mid,row),'색 재매핑의 밝은 청록/노랑 점상 대비가 줄었음. 미세 잎/나무결 점은 남음. 형태는 v1과 같음.'),one_creature_per_frame=True,text_or_added_effect_seen=False,playback_tested=False))
r.jsave(r.REPORT/'visual-review.json',reviews)
now=datetime.now(timezone(timedelta(hours=9)));start=datetime.fromisoformat('2026-10-25T17:36:39+09:00')
r.jsave(r.REPORT/'handoff.json',dict(start=start.isoformat(),prepared=now.isoformat(),elapsed_minutes=round((now-start).total_seconds()/60,2),hard_stop_minutes=150,branch='codex/art-83',candidate_rows=15,sheets=8,missing_rows=[],unresolved=['덩굴 사냥개 미세 잔점 및 idle 질감 저하','나방 더듬이 끝 식별','실제 재생/게임 연결 검수'],commit_script_executed=False,missing_required_reference='reports/codex-art-81/README.md'))
names=['README.md','prompts.txt','selection.json','verification.json','candidate-hashes.json','source-manifest.json','visual-review.json','handoff.json','process71.py','fix74.py','process76.py','reuse71/review.py','repair.py','colour83.py','colour83b.py','align83.py','measure83.py','review_landmarks83.py','deliver83.py','supplement_boards83.py','verify83.py','handoff83.py','overview.png']
files=[r.REPORT/x for x in names]
files += [r.ROOT/'design/tasks/CODEX-ART-83.md',r.ROOT/'design/tasks/CODEX-ART-83.prompt.md']
files += [r.REPORT/'delivery-files.txt',r.REPORT/'delivery-hashes.json',r.REPORT/'commit.ps1']
for x in selection:
 mid,row,label=x['monster'],x['row'],x['trial'];files += [r.BAKE/f'{mid}-{row}-v2.png',r.BAKE/f'{mid}-{row}-v2.json',r.REPORT/f'{mid}-{row}.png']
 files += [r.REPORT/'trials'/f'{mid}-{row}-{label}'/n for n in ['strip.png','metrics.json','review-1x.png','review-4x.png']]
for mid in dict.fromkeys(x['monster'] for x in selection):files.append(r.BAKE/f'{mid}_sheet-v2.png')
for mid,row in [('vanaheim_vine_hound','windup'),('vanaheim_vine_hound','defeat'),('alfheim_moon_moth','windup')]:files.append(r.REPORT/f'{mid}-{row}-with-current.png')
files += [r.REPORT/'trials/vanaheim_seed_sprite-attack-d/strip.png']
files += [p for p in (r.REPORT/'measure-final').glob('*') if p.is_file() and p.name not in ['movement-final.json','mossling-forward-final.png']]
rels=sorted(set(p.relative_to(r.ROOT).as_posix() for p in files))
assert all(not x.startswith('art/raw/') and '__pycache__' not in x and not x.endswith('run.log') for x in rels)
r.fresh(r.REPORT/'delivery-files.txt').write_text('\n'.join(rels)+'\n',encoding='utf-8')
script='''# ART-83 handoff. Prepared only; not executed by the builder.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-83') { throw 'Expected codex/art-83.' }
$alreadyStaged = @(& git diff --cached --name-only --)
if ($LASTEXITCODE -ne 0 -or $alreadyStaged.Count -ne 0) { throw 'Index must be empty before this handoff.' }
$files = @(
'''+''.join(f"    '{x}'\n" for x in rels)+''')
$manifest = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt') -Encoding UTF8)
if (@(Compare-Object $files $manifest).Count -ne 0) { throw 'Manifest differs from the fixed allowlist.' }
$hashes = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-hashes.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($file in $files) {
    if ($file -match '^art/raw/' -or $file -match '__pycache__' -or $file -match '(^|/)run\\.log$') { throw "Forbidden path: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
    $entry = $hashes.PSObject.Properties[$file]
    if ($null -ne $entry) {
        $actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $entry.Value) { throw "File changed since review: $file" }
    }
}
& git -c core.autocrlf=false add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed; no forced adds are allowed.' }
$unexpected = @(& git diff --cached --name-only -- | Where-Object { $_ -notin $files })
if ($LASTEXITCODE -ne 0 -or $unexpected.Count -ne 0) { throw 'Unexpected staged files.' }
$message = @'
art: add ART-83 monster row repair v2 candidates

Repair 15 monster rows, preserve v1 candidates, and include eight assembled
sheets with measurement and visual review evidence. Hound remap retains
fine grain; these are candidates for review, not live game replacements.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -c core.autocrlf=false commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
'''
r.fresh(r.REPORT/'commit.ps1').write_text(script,encoding='utf-8')
for x in rels:
 if x!='reports/codex-art-83/delivery-hashes.json':assert (r.ROOT/x).is_file(),x
r.jsave(r.REPORT/'delivery-hashes.json',{x:digest(r.ROOT/x) for x in rels if x!='reports/codex-art-83/delivery-hashes.json'})
print(json.dumps(dict(files=len(rels),bytes=sum((r.ROOT/x).stat().st_size for x in rels),elapsed_minutes=round((now-start).total_seconds()/60,2)),ensure_ascii=False))
