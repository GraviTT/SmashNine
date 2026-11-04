$ErrorActionPreference = 'Stop'
$repoPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Encoding UTF8 -Raw | ConvertFrom-Json)
foreach ($file in $files) {
    if ($file -ne 'design/tasks/CODEX-VFX-09.md' -and $file -notmatch '^art/bakeoff/effects/pixelfx/(luna|luna_brave)/a/' -and $file -notmatch '^reports/codex-vfx-09-a/') {
        throw "Out-of-scope path: $file"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repoPath $file) -PathType Leaf)) {
        throw "Missing file: $file"
    }
}
Push-Location -LiteralPath $repoPath
try {
    & git -c core.autocrlf=false add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; no force-add was attempted.' }
    & git diff --cached --check -- $files
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
    & git -c core.autocrlf=false commit --only -m 'Add VFX-09 A Luna and Brave sharp-moment candidates' -- $files
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
} finally {
    Pop-Location
}
