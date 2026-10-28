$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$manifest = Join-Path $PSScriptRoot 'commit-paths.txt'
$paths = Get-Content -LiteralPath $manifest -Encoding UTF8
foreach ($item in $paths) {
    if ($item -match 'art/raw/|__pycache__|run\.log|/attempt') { throw "Forbidden path: $item" }
    if (-not (Test-Path -LiteralPath $item -PathType Leaf)) { throw "Missing file: $item" }
}
git add --pathspec-from-file=$manifest
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
Write-Host 'Only the explicit ART-92 manifest has been staged. No commit was made.'
