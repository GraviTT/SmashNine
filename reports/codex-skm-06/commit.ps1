# Prepared for lead review. Codex does not run this script.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$files = @(
    'art/bakeoff/xion/b/xion-shot-v1.json'
    'art/bakeoff/xion/b/xion-shot-v1.png'
    'art/bakeoff/xion/b/xion-shot_alt-v1.json'
    'art/bakeoff/xion/b/xion-shot_alt-v1.png'
    'design/tasks/CODEX-SKM-06.md'
    'reports/codex-skm-06/README.md'
    'reports/codex-skm-06/audit.json'
    'reports/codex-skm-06/board.py'
    'reports/codex-skm-06/clock.ps1'
    'reports/codex-skm-06/commit.ps1'
    'reports/codex-skm-06/config.py'
    'reports/codex-skm-06/deliver.py'
    'reports/codex-skm-06/face_check.py'
    'reports/codex-skm-06/face_grid.py'
    'reports/codex-skm-06/files-to-stage.json'
    'reports/codex-skm-06/generation-ledger.json'
    'reports/codex-skm-06/ingest.py'
    'reports/codex-skm-06/process.py'
    'reports/codex-skm-06/prompts.txt'
    'reports/codex-skm-06/resume_setup.py'
    'reports/codex-skm-06/review_faces.py'
    'reports/codex-skm-06/select_row.py'
    'reports/codex-skm-06/selection.json'
    'reports/codex-skm-06/time-limit.json'
    'reports/codex-skm-06/verify_skm.py'
    'reports/codex-skm-06/xion-double_float-checks.json'
    'reports/codex-skm-06/xion-double_float-faces4x.png'
    'reports/codex-skm-06/xion-double_float.png'
    'reports/codex-skm-06/xion-shot-checks.json'
    'reports/codex-skm-06/xion-shot-faces4x.png'
    'reports/codex-skm-06/xion-shot.png'
    'reports/codex-skm-06/xion-shot_alt-checks.json'
    'reports/codex-skm-06/xion-shot_alt-faces4x.png'
    'reports/codex-skm-06/xion-shot_alt.png'
)
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths' }
$outside = @($alreadyStaged | Where-Object { $files -notcontains $_ })
if ($outside.Count) { throw ('Unrelated staged paths: ' + ($outside -join ', ')) }
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: add Xion SKM-06 body motion candidates and review

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
