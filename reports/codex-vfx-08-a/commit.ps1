$ErrorActionPreference = 'Stop'
$repoPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoPath
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'handoff-files.json') -Encoding UTF8 -Raw | ConvertFrom-Json)
foreach ($file in $files) {
    if ($file -ne 'design/tasks/CODEX-VFX-08.md' -and
        $file -notmatch '^art/bakeoff/effects/pixelfx/(frey|luna)/a/' -and
        $file -notmatch '^reports/codex-vfx-08-a/') {
        throw "Out-of-scope handoff path: $file"
    }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing handoff file: $file" }
}
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read git index.' }
foreach ($file in $staged) {
    if ($file -and $file -notin $files) { throw "Unrelated staged file: $file" }
}
& git -c core.autocrlf=false add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed. No forced add was attempted.' }
& git diff --cached --check -- @files
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
& git commit -m 'art: add Frey and Luna sharp-moment VFX candidates (VFX-08 A)'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
