$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))
if ((git branch --show-current).Trim() -ne 'codex/skm-07') { throw 'Wrong branch' }
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read the index' }
if ($alreadyStaged.Count -gt 0) { throw 'Index is not empty; review the existing staged work first.' }
# Literal string array avoids the PowerShell 5.1 ConvertFrom-Json array issue.
# Includes requested prompts; excludes QA JSON, attempts, raws, caches and logs.
$files = @(
    'design/tasks/CODEX-SKM-07.md'
    'art/bakeoff/xion/b/xion-shot_air_down-v2.png'
    'art/bakeoff/xion/b/xion-shot_air_down-v2.json'
    'art/bakeoff/xion/b/xion-shot_air_down-v3.png'
    'art/bakeoff/xion/b/xion-shot_air_down-v3.json'
    'reports/codex-skm-07/README.md'
    'reports/codex-skm-07/prompts.txt'
    'reports/codex-skm-07/xion-shot_air_down-v2.png'
    'reports/codex-skm-07/xion-shot_air_down-v3.png'
    'reports/codex-skm-07/comparison.png'
    'reports/codex-skm-07/config.py'
    'reports/codex-skm-07/ingest.py'
    'reports/codex-skm-07/process.py'
    'reports/codex-skm-07/face_check.py'
    'reports/codex-skm-07/face_grid.py'
    'reports/codex-skm-07/review_faces.py'
    'reports/codex-skm-07/body_grid.py'
    'reports/codex-skm-07/finalize.py'
    'reports/codex-skm-07/prepare_handoff.py'
    'reports/codex-skm-07/verify_skm.py'
    'reports/codex-skm-07/commit.ps1'
)
foreach ($path in $files) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Missing: ' + $path) } }
& git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read staged paths' }
$outside = @($staged | Where-Object { $files -notcontains $_ })
if ($outside.Count -gt 0) { throw ('Out-of-scope paths: ' + ($outside -join ', ')) }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed' }
git commit -m 'art: redraw Xion airborne down-shot candidates (SKM-07)' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
