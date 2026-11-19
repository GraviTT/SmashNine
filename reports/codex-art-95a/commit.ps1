# Prepared for lead review. The unit did not execute this script.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = (git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/xion-95a') { throw 'Expected branch codex/xion-95a' }
$paths = @(
    'design/tasks/CODEX-ART-95.md',
    'art/bakeoff/xion/c/xion-idle-c.json',
    'art/bakeoff/xion/c/xion-idle-c.png',
    'art/bakeoff/xion/c/xion_illustration-c.png',
    'art/bakeoff/xion/d/xion-idle-d.json',
    'art/bakeoff/xion/d/xion-idle-d.png',
    'art/bakeoff/xion/d/xion_illustration-d.png',
    'reports/codex-art-95a/anatomy-c.png',
    'reports/codex-art-95a/anatomy-d.png',
    'reports/codex-art-95a/head-landmarks-c.png',
    'reports/codex-art-95a/head-landmarks-d.png',
    'reports/codex-art-95a/heads-4x.png',
    'reports/codex-art-95a/idle-c-4x.png',
    'reports/codex-art-95a/idle-d-4x.png',
    'reports/codex-art-95a/illustration-c-dark.png',
    'reports/codex-art-95a/illustration-c-light.png',
    'reports/codex-art-95a/illustration-d-dark.png',
    'reports/codex-art-95a/illustration-d-light.png',
    'reports/codex-art-95a/illustration-metrics.json',
    'reports/codex-art-95a/lineup.png',
    'reports/codex-art-95a/metrics.json',
    'reports/codex-art-95a/overview.png',
    'reports/codex-art-95a/package_review.py',
    'reports/codex-art-95a/process_illustrations.py',
    'reports/codex-art-95a/prompt-c-idle-02.txt',
    'reports/codex-art-95a/prompt-c-idle-blocked.txt',
    'reports/codex-art-95a/prompt-c-idle-retry.txt',
    'reports/codex-art-95a/prompt-c-idle.txt',
    'reports/codex-art-95a/prompt-c-illustration-fix.txt',
    'reports/codex-art-95a/prompt-c-illustration.txt',
    'reports/codex-art-95a/prompt-d-idle.txt',
    'reports/codex-art-95a/prompt-d-illustration-proportion.txt',
    'reports/codex-art-95a/prompt-d-illustration.txt',
    'reports/codex-art-95a/prompt-illustration-chroma.txt',
    'reports/codex-art-95a/README.md',
    'reports/codex-art-95a/rebuild.ps1',
    'reports/codex-art-95a/sprite-landmarks-4x.png',
    'reports/codex-art-95a/verification.json',
    'reports/codex-art-95a/verify_delivery.py',
    'reports/codex-art-95a/normalize-c/closeup.png',
    'reports/codex-art-95a/normalize-c/compare.png',
    'reports/codex-art-95a/normalize-c/metrics.json',
    'reports/codex-art-95a/normalize-c/xion-idle-c.png',
    'reports/codex-art-95a/normalize-c/frames/xion-idle-c-00.png',
    'reports/codex-art-95a/normalize-d/closeup.png',
    'reports/codex-art-95a/normalize-d/compare.png',
    'reports/codex-art-95a/normalize-d/metrics.json',
    'reports/codex-art-95a/normalize-d/xion-idle-d.png',
    'reports/codex-art-95a/normalize-d/frames/xion-idle-d-00.png',
    'reports/codex-art-95a/rejected-c/closeup.png',
    'reports/codex-art-95a/rejected-c/compare.png',
    'reports/codex-art-95a/rejected-c/metrics.json',
    'reports/codex-art-95a/rejected-c/rejected-c-idle.png',
    'reports/codex-art-95a/rejected-c/frames/rejected-c-idle-00.png',
    'reports/codex-art-95a/commit.ps1'
)
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staging area' }
$outside = @($staged | Where-Object { $_ -notin $paths })
if ($outside.Count -gt 0) { throw ('Unrelated staged files: ' + ($outside -join ', ')) }
git -c core.autocrlf=false add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: add Xion story concepts C and D

Deliver transparent illustrations with crimson timeline doubles and single idle frames.
Include measured alpha, margin, height and detail checks, visual review and prompts.
Candidate only; no product assets changed. Note sprite heads larger than Rio.

Co-Authored-By: Codex <noreply@openai.com>
'@
git -c core.autocrlf=false commit --only -m $message -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
