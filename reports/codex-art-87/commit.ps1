$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-87') { throw 'Expected branch codex/art-87.' }
$listPath = Join-Path $PSScriptRoot 'files-to-stage.txt'
$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
$paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8 | Where-Object { $_.Length -gt 0 })
if ($paths.Count -eq 0) { throw 'Empty staging list.' }
foreach ($path in $paths) {
    if ($path -match '(^/|^[A-Za-z]:|\\|\.\.|[\*\?]|(^|/)(qa23|raw|__pycache__)(/|$)|(^|/)run\.log$)') { throw "Forbidden staging path: $path" }
    $allowed = $path -like 'art/bakeoff/monsters/legacy/*' -or $path -like 'reports/codex-art-87/*' -or $path -eq 'design/tasks/CODEX-ART-87.md' -or $path -eq 'design/tasks/CODEX-ART-87.prompt.md'
    if (-not $allowed -or -not (Test-Path -LiteralPath (Join-Path $repoRoot $path) -PathType Leaf)) { throw "Unexpected or missing file: $path" }
}
$preStaged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staging area.' }
foreach ($path in $preStaged) { if ($path -notin $paths) { throw "Unrelated staged file; leaving index alone: $path" } }
$message = Get-Content -LiteralPath $messagePath -Raw -Encoding UTF8
if (-not $message.TrimEnd().EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) { throw 'Missing required co-author trailer.' }
& git -c core.autocrlf=false add "--pathspec-from-file=$listPath"
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot verify staging area.' }
foreach ($path in $staged) { if ($path -notin $paths) { throw "Unexpected staged file: $path" } }
& git commit "--file=$messagePath"
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
