# Prepared by Codex ART-94A. Review and run manually; not executed by the unit.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = (git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/xion-94a') { throw 'Expected branch codex/xion-94a' }
$paths = @(
    'design/tasks/CODEX-ART-94.md',
    'art/bakeoff/xion/a/xion-idle-a.json',
    'art/bakeoff/xion/a/xion-idle-a.png',
    'art/bakeoff/xion/a/xion_face-a.png',
    'art/bakeoff/xion/a/xion_illustration-a.png',
    'reports/codex-art-94a/anatomy-2x.png',
    'reports/codex-art-94a/build_review.py',
    'reports/codex-art-94a/closeup.png',
    'reports/codex-art-94a/compare.png',
    'reports/codex-art-94a/face-2x.png',
    'reports/codex-art-94a/frame-1-4x.png',
    'reports/codex-art-94a/frame-2-4x.png',
    'reports/codex-art-94a/frame-3-4x.png',
    'reports/codex-art-94a/frame-4-4x.png',
    'reports/codex-art-94a/frame-5-4x.png',
    'reports/codex-art-94a/frame-6-4x.png',
    'reports/codex-art-94a/head-scale.json',
    'reports/codex-art-94a/heads-4x.png',
    'reports/codex-art-94a/idle-4x.gif',
    'reports/codex-art-94a/illustration-dark.png',
    'reports/codex-art-94a/illustration-light.png',
    'reports/codex-art-94a/illustration-metrics.json',
    'reports/codex-art-94a/lineup.png',
    'reports/codex-art-94a/metrics.json',
    'reports/codex-art-94a/process_illustration.py',
    'reports/codex-art-94a/prompt-idle-01.txt',
    'reports/codex-art-94a/prompt-idle-02.txt',
    'reports/codex-art-94a/prompt-idle-03.txt',
    'reports/codex-art-94a/prompt-idle.txt',
    'reports/codex-art-94a/prompt-illustration.txt',
    'reports/codex-art-94a/README.md',
    'reports/codex-art-94a/rebuild.ps1',
    'reports/codex-art-94a/size-check-4x.png',
    'reports/codex-art-94a/xion-idle-a.png',
    'reports/codex-art-94a/frames/xion-idle-a-00.png',
    'reports/codex-art-94a/frames/xion-idle-a-01.png',
    'reports/codex-art-94a/frames/xion-idle-a-02.png',
    'reports/codex-art-94a/frames/xion-idle-a-03.png',
    'reports/codex-art-94a/frames/xion-idle-a-04.png',
    'reports/codex-art-94a/frames/xion-idle-a-05.png',
    'reports/codex-art-94a/commit.ps1'
)
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staging area' }
$outside = @($staged | Where-Object { $_ -notin $paths })
if ($outside.Count -gt 0) { throw ('Unrelated staged files: ' + ($outside -join ', ')) }
git -c core.autocrlf=false add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: add Xion long-coat look candidate A

Deliver illustration, face, six-frame idle and measured review material.
Flag remaining 2px foot drift and approximate 3.3-head sprite proportions.
Candidate only; no product assets changed.

Co-Authored-By: Codex <noreply@openai.com>
'@
git -c core.autocrlf=false commit --only -m $message -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }

