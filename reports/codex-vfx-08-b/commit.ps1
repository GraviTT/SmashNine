$ErrorActionPreference = 'Stop'
$taskRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $taskRoot
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$staged = @(git -c core.quotepath=false diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the git index.' }
foreach ($path in $staged) {
    if ($path -notin $files -and $path -ne 'design/tasks/CODEX-VFX-08.md') { throw "Unrelated staged file: $path" }
}
git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed. No force-add was attempted.' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
git commit -m 'art: add directional Frey and Luna VFX-08 B candidates'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
