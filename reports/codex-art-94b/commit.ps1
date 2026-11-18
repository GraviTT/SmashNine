# Prepared only. This script was not executed by the builder unit.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = (git branch --show-current).Trim()
if ($branch -ne 'codex/xion-94b') { throw "Expected codex/xion-94b; found $branch" }
$paths = @(
    'art/bakeoff/xion/b/xion_illustration-b.png',
    'art/bakeoff/xion/b/xion_face-b.png',
    'art/bakeoff/xion/b/xion-idle-b.png',
    'art/bakeoff/xion/b/xion-idle-b.json',
    'design/tasks/CODEX-ART-94.md',
    'reports/codex-art-94b/README.md',
    'reports/codex-art-94b/commit.ps1',
    'reports/codex-art-94b/prompt-illustration.txt',
    'reports/codex-art-94b/prompt-idle.txt',
    'reports/codex-art-94b/prompt-idle-retry-2.txt',
    'reports/codex-art-94b/compare.png',
    'reports/codex-art-94b/metrics.json',
    'reports/codex-art-94b/head-scale.json',
    'reports/codex-art-94b/feet-check.json',
    'reports/codex-art-94b/delivery-checks.json',
    'reports/codex-art-94b/lineup.png',
    'reports/codex-art-94b/idle-4x.gif',
    'reports/codex-art-94b/idle-review-1.png',
    'reports/codex-art-94b/idle-review-2.png',
    'reports/codex-art-94b/idle-review-3.png',
    'reports/codex-art-94b/head-reference-4x.png',
    'reports/codex-art-94b/face-2x.png',
    'reports/codex-art-94b/illustration-light.png',
    'reports/codex-art-94b/illustration-dark.png',
    'reports/codex-art-94b/idle-v1-contact.png',
    'reports/codex-art-94b/idle-v1-metrics.json',
    'reports/codex-art-94b/idle-v1-head-scale.json',
    'reports/codex-art-94b/process_illustration.py',
    'reports/codex-art-94b/package_review.py',
    'reports/codex-art-94b/verify_delivery.py'
)
foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing delivery: $path" }
}
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect staged files.' }
$unexpected = @($staged | Where-Object { $_ -notin $paths })
if ($unexpected.Count -gt 0) { throw "Unrelated staged files exist: $($unexpected -join ', ')" }
git -c core.autocrlf=false add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
git commit -m 'art: add Xion short-coat B look and idle candidate (ART-94)' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
