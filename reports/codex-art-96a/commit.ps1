# Prepared only. The builder did not execute this script.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = (git branch --show-current).Trim()
if ($branch -ne 'codex/xion-96a') { throw "Expected codex/xion-96a; found $branch" }
$paths = @(
    'art/bakeoff/xion/b/xion_illustration-b2.png',
    'art/bakeoff/xion/b/xion_double-b2-colour.png',
    'design/tasks/CODEX-ART-96.md',
    'reports/codex-art-96a/README.md',
    'reports/codex-art-96a/hologram.py',
    'reports/codex-art-96a/package_review.py',
    'reports/codex-art-96a/verify_delivery.py',
    'reports/codex-art-96a/commit.ps1',
    'reports/codex-art-96a/compare.png',
    'reports/codex-art-96a/full-size-checks.png',
    'reports/codex-art-96a/anatomy-checks.png',
    'reports/codex-art-96a/select-size-check.png',
    'reports/codex-art-96a/foreground-layer.png',
    'reports/codex-art-96a/double-colour-layer.png',
    'reports/codex-art-96a/hologram-layer.png',
    'reports/codex-art-96a/double-colour-dark.png',
    'reports/codex-art-96a/double-colour-light.png',
    'reports/codex-art-96a/metrics.json',
    'reports/codex-art-96a/verification.json',
    'reports/codex-art-96a/provenance.json',
    'reports/codex-art-96a/source-hashes.json',
    'reports/codex-art-96a/prompt-double.txt',
    'reports/codex-art-96a/prompt-double-v2.txt'
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
git commit -m 'art: add preserved Xion B illustration with hologram double (ART-96a)' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
