# Prepared for lead review; never run by Codex.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$files = @(
    'design/tasks/CODEX-SKM-04.md'
    'reports/codex-skm-04/README.md'
    'reports/codex-skm-04/audit.json'
    'reports/codex-skm-04/board.py'
    'reports/codex-skm-04/brave_cyclone-checks.json'
    'reports/codex-skm-04/brave_cyclone-faces4x.png'
    'reports/codex-skm-04/brave_grab-checks.json'
    'reports/codex-skm-04/brave_grab-faces4x.png'
    'reports/codex-skm-04/commit.ps1'
    'reports/codex-skm-04/face_check.py'
    'reports/codex-skm-04/face_grid.py'
    'reports/codex-skm-04/files-to-stage.json'
    'reports/codex-skm-04/generation-ledger.json'
    'reports/codex-skm-04/luna-star_warp.png'
    'reports/codex-skm-04/luna_brave-brave_cyclone.png'
    'reports/codex-skm-04/luna_brave-brave_grab.png'
    'reports/codex-skm-04/make_ledger.py'
    'reports/codex-skm-04/package.py'
    'reports/codex-skm-04/process.py'
    'reports/codex-skm-04/prompts.txt'
    'reports/codex-skm-04/recheck_sweep.py'
    'reports/codex-skm-04/selection.json'
    'reports/codex-skm-04/setup.py'
    'reports/codex-skm-04/star_warp-checks.json'
    'reports/codex-skm-04/star_warp-faces4x.png'
    'reports/codex-skm-04/sweep.py'
    'reports/codex-skm-04/verify.py'
)
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: record Luna SKM-04 body motion review and held rows

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
