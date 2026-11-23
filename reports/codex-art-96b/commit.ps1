# Prepared for the lead. Do not execute during the builder task.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$paths = @(
    'art/bakeoff/xion/b/xion-idle-b2.png'
    'art/bakeoff/xion/b/xion-idle-b2.json'
    'design/tasks/CODEX-ART-96.md'
    'reports/codex-art-96b/README.md'
    'reports/codex-art-96b/compare.png'
    'reports/codex-art-96b/idle-4x.gif'
    'reports/codex-art-96b/scarf.json'
    'reports/codex-art-96b/metrics.json'
    'reports/codex-art-96b/heads-4x.png'
    'reports/codex-art-96b/scarf-landmarks.png'
    'reports/codex-art-96b/illustration-scarf-landmarks.png'
    'reports/codex-art-96b/review-1.png'
    'reports/codex-art-96b/review-2.png'
    'reports/codex-art-96b/review-3.png'
    'reports/codex-art-96b/review-4.png'
    'reports/codex-art-96b/review-5.png'
    'reports/codex-art-96b/review-6.png'
    'reports/codex-art-96b/head-self.json'
    'reports/codex-art-96b/head-rio.json'
    'reports/codex-art-96b/head-v1.json'
    'reports/codex-art-96b/default-anchor.png'
    'reports/codex-art-96b/default-anchor-metrics.json'
    'reports/codex-art-96b/rejected-attempt1-4x.png'
    'reports/codex-art-96b/rejected-attempt2-4x.png'
    'reports/codex-art-96b/prompt-idle.txt'
    'reports/codex-art-96b/prompt-idle-retry-2.txt'
    'reports/codex-art-96b/prompt-idle-retry-3.txt'
    'reports/codex-art-96b/normalize_idle.py'
    'reports/codex-art-96b/package_review.py'
    'reports/codex-art-96b/verify_delivery.py'
    'reports/codex-art-96b/rebuild.ps1'
    'reports/codex-art-96b/provenance.json'
    'reports/codex-art-96b/verification.json'
    'reports/codex-art-96b/workspace-size.json'
    'reports/codex-art-96b/commit.ps1'
)
$message = @'
art: add Xion B full-scarf idle v2 review candidate

Deliver the six-frame candidate, measurement definitions and 4x review.
Hold adoption for horizontal scarf reach, pixel-stable feet and proportions.
Preserve the game and approved v1 art. Raw generations are excluded.

Co-Authored-By: Codex <noreply@openai.com>
'@
Push-Location $root
try {
    $branch = (& git branch --show-current).Trim()
    if ($branch -ne 'codex/xion-96b') { throw "Unexpected branch: $branch" }
    foreach ($path in $paths) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $path) -PathType Leaf)) { throw "Missing file: $path" }
    }
    $alreadyStaged = @(& git diff --cached --name-only)
    foreach ($path in $alreadyStaged) {
        if ($paths -notcontains $path) { throw "Unrelated staged file: $path" }
    }
    & git add -- $paths
    if ($LASTEXITCODE -ne 0) { throw 'Staging failed' }
    $messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
    [System.IO.File]::WriteAllText($messagePath, $message, (New-Object System.Text.UTF8Encoding($false)))
    & git commit --file $messagePath
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed' }
} finally {
    Pop-Location
}
