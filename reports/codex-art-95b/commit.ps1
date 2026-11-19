$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot

$branch = (git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/xion-95b') {
    throw 'Run only in the art-b clone on codex/xion-95b.'
}
$stagedBefore = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths.' }
if ($stagedBefore.Count -gt 0) { throw 'Existing staged changes: review them before running this script.' }

# Literal paths: no JSON enumeration and no force-add. Raw generations excluded.
$paths = @(
    'design/tasks/CODEX-ART-95.md',
    'art/bakeoff/xion/e/xion_illustration-e.png',
    'art/bakeoff/xion/e/xion-idle-e.png',
    'art/bakeoff/xion/e/xion-idle-e.json',
    'art/bakeoff/xion/f/xion_illustration-f.png',
    'art/bakeoff/xion/f/xion-idle-f.png',
    'art/bakeoff/xion/f/xion-idle-f.json',
    'reports/codex-art-95b/README.md',
    'reports/codex-art-95b/commit.ps1',
    'reports/codex-art-95b/metrics.json',
    'reports/codex-art-95b/processing.json',
    'reports/codex-art-95b/provenance.json',
    'reports/codex-art-95b/verification.json',
    'reports/codex-art-95b/lineup.png',
    'reports/codex-art-95b/concepts.png',
    'reports/codex-art-95b/idle-review-4x.png',
    'reports/codex-art-95b/heads-grid-8x.png',
    'reports/codex-art-95b/e-illustration-light.png',
    'reports/codex-art-95b/e-illustration-dark.png',
    'reports/codex-art-95b/f-illustration-light.png',
    'reports/codex-art-95b/f-illustration-dark.png',
    'reports/codex-art-95b/e-hologram-mask-review.png',
    'reports/codex-art-95b/f-hologram-mask-review.png',
    'reports/codex-art-95b/normalize-e/metrics.json',
    'reports/codex-art-95b/normalize-f/metrics.json',
    'reports/codex-art-95b/prompt-e-illustration.txt',
    'reports/codex-art-95b/prompt-e-illustration-fix.txt',
    'reports/codex-art-95b/prompt-f-illustration.txt',
    'reports/codex-art-95b/prompt-f-illustration-fix.txt',
    'reports/codex-art-95b/prompt-e-idle.txt',
    'reports/codex-art-95b/prompt-e-idle-v1.txt',
    'reports/codex-art-95b/prompt-e-idle-v2.txt',
    'reports/codex-art-95b/prompt-e-idle-v3.txt',
    'reports/codex-art-95b/prompt-f-idle.txt',
    'reports/codex-art-95b/prompt-f-idle-v1.txt',
    'reports/codex-art-95b/prompt-f-idle-v2.txt',
    'reports/codex-art-95b/process_art.py',
    'reports/codex-art-95b/package_review.py',
    'reports/codex-art-95b/verify_delivery.py'
)

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing delivery file: $path" }
}
git add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths.' }
foreach ($path in $staged) {
    if ($paths -notcontains $path) { throw "Out-of-scope staged path: $path" }
}
git diff --cached --stat
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged diff.' }
git commit -m 'Add Xion E and F story look candidates' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
