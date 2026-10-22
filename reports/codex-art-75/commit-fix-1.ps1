$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$branch = (& git -C $repo branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-75') { throw 'Expected codex/art-75 in this clone.' }
$files = @(
    'art/bakeoff/yuki/yuki-fall-v2.json'
    'art/bakeoff/yuki/yuki-fall-v2.png'
    'reports/codex-art-75/README.md'
    'reports/codex-art-75/commit-fix-1.ps1'
    'reports/codex-art-75/fix-1.prompt.md'
    'reports/codex-art-75/fix-1/audit.json'
    'reports/codex-art-75/fix-1/before-after-4x.png'
    'reports/codex-art-75/fix-1/before-measured-4x.png'
    'reports/codex-art-75/fix-1/build_delivery.py'
    'reports/codex-art-75/fix-1/face_check_fix.py'
    'reports/codex-art-75/fix-1/files-to-stage.json'
    'reports/codex-art-75/fix-1/final/face-landmarks-proposed.png'
    'reports/codex-art-75/fix-1/final/face-measured.json'
    'reports/codex-art-75/fix-1/final/head-scale.json'
    'reports/codex-art-75/fix-1/final/metrics.json'
    'reports/codex-art-75/fix-1/generation-1.txt'
    'reports/codex-art-75/fix-1/generation-ledger.json'
    'reports/codex-art-75/fix-1/measure_row.py'
    'reports/codex-art-75/fix-1/measurements.json'
    'reports/codex-art-75/fix-1/verify_fix.py'
    'reports/codex-art-75/prompts.txt'
    'reports/codex-art-75/yuki-fall.png'
)
$staged = @(& git -C $repo diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
foreach ($path in $staged) { if ($path -and $path -notin $files) { throw "Unrelated staged file: $path" } }
foreach ($path in $files) { if (-not (Test-Path -LiteralPath (Join-Path $repo $path) -PathType Leaf)) { throw "Missing file: $path" } }
& git -C $repo add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$message = @'
Fix Yuki fall body proportions for ART-75

Regenerate from the idle anchor, deliver one shared-scale two-frame candidate,
and record 4x head/shoulder measurements and static asset checks.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -C $repo commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
