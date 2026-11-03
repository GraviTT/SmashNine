"""Write an explicit handoff script. Never execute git mutations here."""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
REPORT=ROOT/'reports/codex-vfx-05'
measure=json.loads((REPORT/'measurements.json').read_text(encoding='utf-8'))
files=['design/tasks/CODEX-VFX-05.md']
for row in measure['items']:
    p=Path(row['file'])
    files.extend([p.as_posix(),p.with_suffix('.json').as_posix()])
exclude={'baseline-status.txt','ui-draft.png','references.png','commit.ps1'}
files.extend(p.relative_to(ROOT).as_posix() for p in sorted(REPORT.glob('*')) if p.is_file() and p.name not in exclude)
files.append('reports/codex-vfx-05/commit.ps1')
body="""# Prepared only. This script was NOT run by the image builder.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = (git branch --show-current).Trim()
if ($branch -ne 'codex/vfx-05') { throw "Expected codex/vfx-05, got $branch" }
$files = @(
"""
body+=',\n'.join("    '"+p+"'" for p in files)
body+="""
)
$stagedBefore = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
$unrelated = @($stagedBefore | Where-Object { $_ -notin $files })
if ($unrelated.Count -gt 0) { throw ('Unrelated files already staged: ' + ($unrelated -join ', ')) }
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
    if ($file.StartsWith('art/raw/') -or $file.StartsWith('smash-nine-prototype/') -or $file.Contains('__pycache__')) {
        throw "Forbidden delivery path: $file"
    }
}
git -c core.autocrlf=false add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
$stagedAfter = @(git diff --cached --name-only)
$unexpected = @($stagedAfter | Where-Object { $_ -notin $files })
if ($unexpected.Count -gt 0) { throw ('Unexpected staged file: ' + ($unexpected -join ', ')) }
$message = @'
art: add Nova gravity kit VFX-05 candidates and review boards

Deliver A/B gravity stacks, root, orb, field, beam and horizon sphere,
plus five HUD icons. Include metadata, imagegen prompts, exact-size
in-context boards, reproducible processing and asset validation.
No product source or adopted art changes; candidates await user picks.

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
"""
(REPORT/'commit.ps1').write_text(body,encoding='utf-8',newline='\n')
print(f'Prepared commit.ps1: {len(files)} explicit paths; NOT executed.')
