# Explicit reviewed files only. Prepared by Codex; not executed.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
if ((git branch --show-current) -ne 'codex/skm-09') { throw 'Wrong branch' }
$files = @(
    'art/bakeoff/rio/rio_female-sword_throw-v1.json'
    'art/bakeoff/rio/rio_female-sword_throw-v1.png'
    'art/bakeoff/rio/rio_male-pierce-v1.json'
    'art/bakeoff/rio/rio_male-pierce-v1.png'
    'design/tasks/CODEX-SKM-09.md'
    'reports/codex-skm-09/README.md'
    'reports/codex-skm-09/audit.json'
    'reports/codex-skm-09/audit.py'
    'reports/codex-skm-09/board.py'
    'reports/codex-skm-09/commit.ps1'
    'reports/codex-skm-09/compare_boards.py'
    'reports/codex-skm-09/config.py'
    'reports/codex-skm-09/decide.py'
    'reports/codex-skm-09/face-corrections-female.json'
    'reports/codex-skm-09/face-corrections-male.json'
    'reports/codex-skm-09/face_check.py'
    'reports/codex-skm-09/face_grid.py'
    'reports/codex-skm-09/files-to-stage.json'
    'reports/codex-skm-09/finalize.py'
    'reports/codex-skm-09/fix_checks.py'
    'reports/codex-skm-09/generation-ledger.json'
    'reports/codex-skm-09/handoff.py'
    'reports/codex-skm-09/ingest_result.py'
    'reports/codex-skm-09/overview.png'
    'reports/codex-skm-09/overview.py'
    'reports/codex-skm-09/process.py'
    'reports/codex-skm-09/prompts.txt'
    'reports/codex-skm-09/publish.py'
    'reports/codex-skm-09/review_faces.py'
    'reports/codex-skm-09/rio_female-sword_throw-checks.json'
    'reports/codex-skm-09/rio_female-sword_throw-faces4x.png'
    'reports/codex-skm-09/rio_female-sword_throw-fixes.json'
    'reports/codex-skm-09/rio_female-sword_throw-fixes.png'
    'reports/codex-skm-09/rio_female-sword_throw.png'
    'reports/codex-skm-09/rio_male-pierce-checks.json'
    'reports/codex-skm-09/rio_male-pierce-faces4x.png'
    'reports/codex-skm-09/rio_male-pierce-fixes.json'
    'reports/codex-skm-09/rio_male-pierce-fixes.png'
    'reports/codex-skm-09/rio_male-pierce.png'
    'reports/codex-skm-09/selection.json'
    'reports/codex-skm-09/time-limit.json'
)
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths' }
$outside = @($alreadyStaged | Where-Object { $files -notcontains $_ })
if ($outside.Count) { throw ('Unrelated staged paths: ' + ($outside -join ', ')) }
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed' }
git commit -m 'art: redraw Rio female throw and male pierce candidates'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
