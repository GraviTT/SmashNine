# Prepared for lead review. Codex does not run this script.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$files = @(
    'art/bakeoff/xion/b/xion-barrage-v1.json'
    'art/bakeoff/xion/b/xion-barrage-v1.png'
    'art/bakeoff/xion/b/xion-dive-v1.json'
    'art/bakeoff/xion/b/xion-dive-v1.png'
    'art/bakeoff/xion/b/xion-double_cast-v1.json'
    'art/bakeoff/xion/b/xion-double_cast-v1.png'
    'art/bakeoff/xion/b/xion-double_float-v1.json'
    'art/bakeoff/xion/b/xion-double_float-v1.png'
    'art/bakeoff/xion/b/xion-recoil_jump-v1.json'
    'art/bakeoff/xion/b/xion-recoil_jump-v1.png'
    'art/bakeoff/xion/b/xion-shot_down-v1.json'
    'art/bakeoff/xion/b/xion-shot_down-v1.png'
    'art/bakeoff/xion/b/xion-shot_up-v1.json'
    'art/bakeoff/xion/b/xion-shot_up-v1.png'
    'art/bakeoff/xion/b/xion-tumble-v1.json'
    'art/bakeoff/xion/b/xion-tumble-v1.png'
    'reports/codex-skm-06/README.md'
    'reports/codex-skm-06/audit.json'
    'reports/codex-skm-06/commit.ps1'
    'reports/codex-skm-06/continuation-preview.png'
    'reports/codex-skm-06/continue_c.py'
    'reports/codex-skm-06/deliver.py'
    'reports/codex-skm-06/files-to-stage.json'
    'reports/codex-skm-06/generation-failures.json'
    'reports/codex-skm-06/generation-ledger.json'
    'reports/codex-skm-06/overview.py'
    'reports/codex-skm-06/prompts.txt'
    'reports/codex-skm-06/review_faces.py'
    'reports/codex-skm-06/selection.json'
    'reports/codex-skm-06/time-limit.json'
    'reports/codex-skm-06/verify_skm.py'
    'reports/codex-skm-06/xion-barrage-checks.json'
    'reports/codex-skm-06/xion-barrage-faces4x.png'
    'reports/codex-skm-06/xion-barrage.png'
    'reports/codex-skm-06/xion-dive-checks.json'
    'reports/codex-skm-06/xion-dive-faces4x.png'
    'reports/codex-skm-06/xion-dive.png'
    'reports/codex-skm-06/xion-double_cast-checks.json'
    'reports/codex-skm-06/xion-double_cast-faces4x.png'
    'reports/codex-skm-06/xion-double_cast.png'
    'reports/codex-skm-06/xion-double_float-checks.json'
    'reports/codex-skm-06/xion-double_float-faces4x.png'
    'reports/codex-skm-06/xion-recoil_jump-checks.json'
    'reports/codex-skm-06/xion-recoil_jump-faces4x.png'
    'reports/codex-skm-06/xion-recoil_jump.png'
    'reports/codex-skm-06/xion-shot_air_down-checks.json'
    'reports/codex-skm-06/xion-shot_air_down-faces4x.png'
    'reports/codex-skm-06/xion-shot_air_down.png'
    'reports/codex-skm-06/xion-shot_down-checks.json'
    'reports/codex-skm-06/xion-shot_down-faces4x.png'
    'reports/codex-skm-06/xion-shot_down.png'
    'reports/codex-skm-06/xion-shot_up-checks.json'
    'reports/codex-skm-06/xion-shot_up-faces4x.png'
    'reports/codex-skm-06/xion-shot_up.png'
    'reports/codex-skm-06/xion-tumble-checks.json'
    'reports/codex-skm-06/xion-tumble-faces4x.png'
    'reports/codex-skm-06/xion-tumble.png'
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
