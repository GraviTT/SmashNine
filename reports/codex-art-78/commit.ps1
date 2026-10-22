$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$branch = (& git -C $repo branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-78') { throw 'Expected codex/art-78 in this clone.' }
$files = @(
    'art/bakeoff/frey/frey-jump-v2.json'
    'art/bakeoff/frey/frey-jump-v2.png'
    'art/bakeoff/luna/luna_brave-fall-v3.json'
    'art/bakeoff/luna/luna_brave-fall-v3.png'
    'reports/codex-art-78/README.md'
    'reports/codex-art-78/audit.json'
    'reports/codex-art-78/best/frey/jump/best-attempt.png'
    'reports/codex-art-78/best/frey/jump/face-landmarks.png'
    'reports/codex-art-78/best/frey/jump/face-measured.json'
    'reports/codex-art-78/best/frey/jump/head-scale.json'
    'reports/codex-art-78/best/frey/jump/metrics.json'
    'reports/codex-art-78/best/frey/victory/best-attempt.png'
    'reports/codex-art-78/best/frey/victory/face-landmarks.png'
    'reports/codex-art-78/best/frey/victory/face-measured.json'
    'reports/codex-art-78/best/frey/victory/head-scale.json'
    'reports/codex-art-78/best/frey/victory/metrics.json'
    'reports/codex-art-78/best/luna/victory/best-attempt.png'
    'reports/codex-art-78/best/luna/victory/face-landmarks.png'
    'reports/codex-art-78/best/luna/victory/face-measured.json'
    'reports/codex-art-78/best/luna/victory/head-scale.json'
    'reports/codex-art-78/best/luna/victory/metrics.json'
    'reports/codex-art-78/best/luna_brave/fall/best-attempt.png'
    'reports/codex-art-78/best/luna_brave/fall/face-landmarks.png'
    'reports/codex-art-78/best/luna_brave/fall/face-measured.json'
    'reports/codex-art-78/best/luna_brave/fall/head-scale.json'
    'reports/codex-art-78/best/luna_brave/fall/metrics.json'
    'reports/codex-art-78/best/luna_brave/hurt/best-attempt.png'
    'reports/codex-art-78/best/luna_brave/hurt/face-landmarks.png'
    'reports/codex-art-78/best/luna_brave/hurt/face-measured.json'
    'reports/codex-art-78/best/luna_brave/hurt/head-scale.json'
    'reports/codex-art-78/best/luna_brave/hurt/metrics.json'
    'reports/codex-art-78/best/luna_brave/jump/best-attempt.png'
    'reports/codex-art-78/best/luna_brave/jump/face-landmarks.png'
    'reports/codex-art-78/best/luna_brave/jump/face-measured.json'
    'reports/codex-art-78/best/luna_brave/jump/head-scale.json'
    'reports/codex-art-78/best/luna_brave/jump/metrics.json'
    'reports/codex-art-78/best/luna_brave/victory/best-attempt.png'
    'reports/codex-art-78/best/luna_brave/victory/face-landmarks.png'
    'reports/codex-art-78/best/luna_brave/victory/face-measured.json'
    'reports/codex-art-78/best/luna_brave/victory/head-scale.json'
    'reports/codex-art-78/best/luna_brave/victory/metrics.json'
    'reports/codex-art-78/boards.py'
    'reports/codex-art-78/commit.ps1'
    'reports/codex-art-78/face_check.py'
    'reports/codex-art-78/files-to-stage.json'
    'reports/codex-art-78/finalize.py'
    'reports/codex-art-78/frey-jump.png'
    'reports/codex-art-78/frey-victory.png'
    'reports/codex-art-78/frey/victory/source-check-1.txt'
    'reports/codex-art-78/frey/victory/source-check-3.txt'
    'reports/codex-art-78/generation-ledger.json'
    'reports/codex-art-78/landmark_pages.py'
    'reports/codex-art-78/luna-victory.png'
    'reports/codex-art-78/luna_brave-fall.png'
    'reports/codex-art-78/luna_brave-hurt.png'
    'reports/codex-art-78/luna_brave-jump.png'
    'reports/codex-art-78/luna_brave-victory.png'
    'reports/codex-art-78/luna_brave/hurt/source-check-1.txt'
    'reports/codex-art-78/package.py'
    'reports/codex-art-78/process.py'
    'reports/codex-art-78/prompts.txt'
    'reports/codex-art-78/qa4x/frey/jump/01-03.png'
    'reports/codex-art-78/qa4x/frey/victory/01-02.png'
    'reports/codex-art-78/qa4x/frey/victory/03-04.png'
    'reports/codex-art-78/qa4x/frey/victory/05-06.png'
    'reports/codex-art-78/qa4x/luna/victory/01-02.png'
    'reports/codex-art-78/qa4x/luna/victory/03-04.png'
    'reports/codex-art-78/qa4x/luna/victory/05-06.png'
    'reports/codex-art-78/qa4x/luna_brave/fall/01-02.png'
    'reports/codex-art-78/qa4x/luna_brave/hurt/01-03.png'
    'reports/codex-art-78/qa4x/luna_brave/jump/01-03.png'
    'reports/codex-art-78/qa4x/luna_brave/victory/01-02.png'
    'reports/codex-art-78/qa4x/luna_brave/victory/03-04.png'
    'reports/codex-art-78/qa4x/luna_brave/victory/05-06.png'
    'reports/codex-art-78/report.py'
    'reports/codex-art-78/review_sources.py'
    'reports/codex-art-78/selection.json'
    'reports/codex-art-78/summary.json'
    'reports/codex-art-78/verify.py'
    'reports/codex-art-78/visual-review.json'
)
foreach ($file in $files) {
    if ($file -notmatch '^(art/bakeoff/(frey|luna)/|reports/codex-art-78/)' -or $file -match '(^art/raw/|__pycache__|(^|/)run[.]log$)') { throw "Disallowed path: $file" }
    if (-not (Test-Path -LiteralPath (Join-Path $repo $file) -PathType Leaf)) { throw "Missing file: $file" }
}
$before = @(& git -C $repo diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
foreach ($file in $before) { if ($file -and $file -notin $files) { throw "Unrelated staged file: $file" } }
& git -C $repo add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
$after = @(& git -C $repo diff --cached --name-only)
foreach ($file in $after) { if ($file -and $file -notin $files) { throw "Unexpected staged file: $file" } }
$message = @'
Deliver two ART-72 motion candidates and ART-78 retry evidence

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -C $repo commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
