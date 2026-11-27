from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];REP=ROOT/'reports/codex-art-99b'
paths=['design/tasks/CODEX-ART-99.md']
for c,n in [('doron',1),('doron',2),('doron',3),('jupi',2),('jupi',3)]:
    for name in [f'{c}_illustration-{n}.png',f'{c}_face-{n}.png',f'{c}-idle-{n}.png',f'{c}-idle-{n}.json']:
        paths.append(f'art/bakeoff/newchar-2026-11-26/{c}/{n}/{name}')
report_names=['README.md','prompts.txt','metrics.json','provenance.json','baseline.json','verification.json','commit.ps1','commit-message.txt',
 'setup.py','process.py','package_review.py','review_grids.py','review_attempts.py','write_commit.py','verify_delivery.py',
 'concepts.png','faces.png','lineup.png','lineup-candidates.png','lineup-roster.png','attempts-contact.png']
for c,n in [('doron',1),('doron',2),('doron',3),('jupi',2),('jupi',3)]:
    report_names += [f'{c}-{n}-anatomy.jpg',f'{c}-{n}-landmarks.png',f'{c}-{n}-idle-4x.png',f'{c}-{n}-grid.png',f'normalize-{c}-{n}/metrics.json',f'normalize-{c}-{n}/frames/{c}-idle-{n}-00.png']
paths += ['reports/codex-art-99b/'+name for name in report_names]
script='''# Prepared for lead review. NOT executed by this unit.
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if ((git branch --show-current).Trim() -ne 'codex/newchar-99b') { throw 'Unexpected branch' }
[string[]]$paths = @(
'''+''.join("    '"+p+"'\n" for p in paths)+''')
$existing = @(git diff --cached --name-only)
foreach ($item in $existing) { if ($paths -notcontains $item) { throw "Unrelated staged file: $item" } }
foreach ($item in $paths) { if (-not (Test-Path -LiteralPath $item)) { throw "Missing delivery file: $item" } }
git add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'staged whitespace check failed' }
git commit --file 'reports/codex-art-99b/commit-message.txt'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
# Commit message ends with: Co-Authored-By: Codex <noreply@openai.com>
'''
(REP/'commit.ps1').write_text(script,encoding='utf-8')
print(f'Wrote commit.ps1 with {len(paths)} literal paths; NOT executed.')
