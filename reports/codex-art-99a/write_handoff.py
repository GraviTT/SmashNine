"""Write provenance and a literal-path commit script. Does NOT execute git mutations."""
from pathlib import Path
import json,re,hashlib
from PIL import Image

ROOT=Path(__file__).resolve().parents[2]
R=Path(__file__).resolve().parent
raw=ROOT/'art/raw/newchar-99a'
text=(R/'prompts.txt').read_text(encoding='utf-8')
entries=[]
for order,pid in re.findall(r'^\[(\d+)\] (p_\w+)$',text,re.M):
    match=re.fullmatch(r'p_(borok|jupi)(\d)_(illustration|idle)(?:_v(\d+))?',pid)
    c,n,kind,v=match.groups();name=f'{c}{n}-{kind}-v{v or 1}.png';p=raw/name
    assert p.exists(),name
    im=Image.open(p)
    entries.append({'order':int(order),'prompt_id':pid,'raw':p.relative_to(ROOT).as_posix(),'size':list(im.size),'mode':im.mode,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
assert len(entries)==23
provenance={
    'tool':'built-in image_gen.imagegen','started_utc':'2026-11-26 15:53:37 UTC','hard_stop_minutes':110,
    'clock_checked_after_every_generation':True,'generations':entries,
    'references':[{'file':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(raw.glob('*-ref*.png'))],
    'selected':{'borok1':{'illustration':'v2','idle':'v6'},'borok2':{'illustration':'v2','idle':'v6'},'borok3':{'illustration':'v2','idle':'v2'},'jupi1':{'illustration':'v1','idle':'v2'}},
    'notes':['All 23 raw generations retained locally, excluded from git.','Initial idle requests use installed Rio female or Nova female at4x plus own illustration. Refinements use prior whole outputs; no body parts were pasted.','Borok1 idle was developed against illustration v1. Final illustration v2 changes head proportion only.','Final Borok2 idle v6 corrects grey materials of v5.','Head landmarks are manual estimates, not automated anatomical validation.']}
(R/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
paths=['design/tasks/CODEX-ART-99.md']
for c,n in [('borok',1),('borok',2),('borok',3),('jupi',1)]:
    d=f'art/bakeoff/newchar-2026-11-26/{c}/{n}'
    paths += [f'{d}/{c}_illustration-{n}.png',f'{d}/{c}_face-{n}.png',f'{d}/{c}-idle-{n}.png',f'{d}/{c}-idle-{n}.json']
for name in ['README.md','lineup.png','concepts.png','faces.png','heads-4x.png','prompts.txt','metrics.json','provenance.json','verification.json','package_art.py','verify_delivery.py','write_handoff.py','rebuild.ps1','commit.ps1']:
    paths.append(f'reports/codex-art-99a/{name}')
for c,n in [('borok',1),('borok',2),('borok',3),('jupi',1)]:
    paths.append(f'reports/codex-art-99a/{c}{n}-framing.json')
    for tail in ['metrics.json','closeup.png',f'frames/{c}-idle-{n}-00.png']:
        paths.append(f'reports/codex-art-99a/normalize/{c}{n}/{tail}')
script="""# Prepared for lead review only. This file has NOT been executed.
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location $repo
try {
    if ((& git branch --show-current).Trim() -ne 'codex/newchar-99a') { throw 'Wrong branch' }
    if (@(& git diff --cached --name-only).Count -ne 0) { throw 'Index already contains staged changes; inspect it first' }
    $paths = @(
"""
script += ',\n'.join("        '"+x+"'" for x in paths)
script += """
    )
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $path" }
        if ($path.StartsWith('art/raw/') -or $path.StartsWith('smash-nine-prototype/')) { throw 'Out-of-scope path' }
    }
    & git add -- $paths
    if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
    $message = @'
ART-99a: Borok looks 1-3 and Jupi look 1 candidates

Deliver illustrations, face crops, one-frame idle candidates and measured visual review.

Co-Authored-By: Codex <noreply@openai.com>
'@
    & git commit -m $message
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
} finally { Pop-Location }
# Co-Authored-By: Codex <noreply@openai.com>
"""
(R/'commit.ps1').write_text(script,encoding='utf-8',newline='\n')
print('provenance',len(entries),'generations; commit literal paths',len(paths))
