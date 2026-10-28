param([switch]$StageOnly)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
if ((git branch --show-current).Trim() -ne 'codex/qa-30') { throw 'Expected branch codex/qa-30.' }
$listPath = Join-Path $PSScriptRoot 'commit-paths.txt'
$allowed = @(Get-Content -LiteralPath $listPath | Where-Object { $_.Trim() -ne '' })
foreach ($path in $allowed) {
    if ($path -match '(^|/)(\.godot|runtime)(/|$)|\.uid$|(^|/)run\.log$') { throw "Forbidden path: $path" }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $path" }
}
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
foreach ($path in $alreadyStaged) {
    if ($path -notin $allowed) { throw "Unrelated staged file; left untouched: $path" }
}
git add --pathspec-from-file=$listPath
if ($LASTEXITCODE -ne 0) { throw 'Staging failed; no commit attempted.' }
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not verify staged paths.' }
foreach ($path in $staged) {
    if ($path -notin $allowed) { throw "Unexpected staged path; no commit attempted: $path" }
}
git diff --cached --stat
if ($StageOnly) { return }
git commit -m 'test: independently audit 222 picks and capture QA-30 evidence'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
