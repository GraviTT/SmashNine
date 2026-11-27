# Prepared for lead review only. This file has NOT been executed.
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location $repo
try {
    if ((& git branch --show-current).Trim() -ne 'codex/newchar-99a') { throw 'Wrong branch' }
    if (@(& git diff --cached --name-only).Count -ne 0) { throw 'Index already contains staged changes; inspect it first' }
    $paths = @(
        'design/tasks/CODEX-ART-99.md',
        'art/bakeoff/newchar-2026-11-26/borok/1/borok_illustration-1.png',
        'art/bakeoff/newchar-2026-11-26/borok/1/borok_face-1.png',
        'art/bakeoff/newchar-2026-11-26/borok/1/borok-idle-1.png',
        'art/bakeoff/newchar-2026-11-26/borok/1/borok-idle-1.json',
        'art/bakeoff/newchar-2026-11-26/borok/2/borok_illustration-2.png',
        'art/bakeoff/newchar-2026-11-26/borok/2/borok_face-2.png',
        'art/bakeoff/newchar-2026-11-26/borok/2/borok-idle-2.png',
        'art/bakeoff/newchar-2026-11-26/borok/2/borok-idle-2.json',
        'art/bakeoff/newchar-2026-11-26/borok/3/borok_illustration-3.png',
        'art/bakeoff/newchar-2026-11-26/borok/3/borok_face-3.png',
        'art/bakeoff/newchar-2026-11-26/borok/3/borok-idle-3.png',
        'art/bakeoff/newchar-2026-11-26/borok/3/borok-idle-3.json',
        'art/bakeoff/newchar-2026-11-26/jupi/1/jupi_illustration-1.png',
        'art/bakeoff/newchar-2026-11-26/jupi/1/jupi_face-1.png',
        'art/bakeoff/newchar-2026-11-26/jupi/1/jupi-idle-1.png',
        'art/bakeoff/newchar-2026-11-26/jupi/1/jupi-idle-1.json',
        'reports/codex-art-99a/README.md',
        'reports/codex-art-99a/lineup.png',
        'reports/codex-art-99a/concepts.png',
        'reports/codex-art-99a/faces.png',
        'reports/codex-art-99a/heads-4x.png',
        'reports/codex-art-99a/prompts.txt',
        'reports/codex-art-99a/metrics.json',
        'reports/codex-art-99a/provenance.json',
        'reports/codex-art-99a/verification.json',
        'reports/codex-art-99a/package_art.py',
        'reports/codex-art-99a/verify_delivery.py',
        'reports/codex-art-99a/write_handoff.py',
        'reports/codex-art-99a/rebuild.ps1',
        'reports/codex-art-99a/commit.ps1',
        'reports/codex-art-99a/borok1-framing.json',
        'reports/codex-art-99a/normalize/borok1/metrics.json',
        'reports/codex-art-99a/normalize/borok1/closeup.png',
        'reports/codex-art-99a/normalize/borok1/frames/borok-idle-1-00.png',
        'reports/codex-art-99a/borok2-framing.json',
        'reports/codex-art-99a/normalize/borok2/metrics.json',
        'reports/codex-art-99a/normalize/borok2/closeup.png',
        'reports/codex-art-99a/normalize/borok2/frames/borok-idle-2-00.png',
        'reports/codex-art-99a/borok3-framing.json',
        'reports/codex-art-99a/normalize/borok3/metrics.json',
        'reports/codex-art-99a/normalize/borok3/closeup.png',
        'reports/codex-art-99a/normalize/borok3/frames/borok-idle-3-00.png',
        'reports/codex-art-99a/jupi1-framing.json',
        'reports/codex-art-99a/normalize/jupi1/metrics.json',
        'reports/codex-art-99a/normalize/jupi1/closeup.png',
        'reports/codex-art-99a/normalize/jupi1/frames/jupi-idle-1-00.png'
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
