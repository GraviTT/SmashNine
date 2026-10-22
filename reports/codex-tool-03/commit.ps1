# Handoff only. This builder does not execute staging or committing.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$files = @(
    'tools/motion_viewer/build.mjs'
    'tools/motion_viewer/index.html'
    'tools/motion_viewer/publish-files.mjs'
    'tools/motion_viewer/verify.mjs'
    'tools/motion_viewer/README.md'
    'reports/codex-tool-03/baseline.json'
    'reports/codex-tool-03/viewer-checks.json'
    'reports/codex-tool-03/README.md'
    'reports/codex-tool-03/commit-message.txt'
    'reports/codex-tool-03/commit.ps1'
)
Push-Location -LiteralPath $repoPath
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/tool-03') { throw 'Expected branch codex/tool-03.' }
    foreach ($file in $files) {
        if ($file -notmatch '^(tools/motion_viewer/|reports/codex-tool-03/)' -or $file -match '(^|/)(dist|__pycache__)(/|$)|(^|/)run\.log$') { throw "Forbidden staging target: $file" }
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
        & git check-ignore --quiet -- $file
        if ($LASTEXITCODE -eq 0) { throw "Ignored delivery file: $file" }
        if ($LASTEXITCODE -ne 1) { throw "Cannot check ignore status: $file" }
    }
    $messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
    $message = [System.IO.File]::ReadAllText($messagePath).TrimEnd()
    if (-not $message.EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) { throw 'Missing Codex coauthor trailer.' }
    & git add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; nothing was committed.' }
    # --only keeps any unrelated files already staged by another task out of this commit.
    & git commit --only --file $messagePath -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally {
    Pop-Location
}
