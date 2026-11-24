param([switch]$Commit, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
if ($Commit -and $CheckOnly) { throw 'Choose -Commit or -CheckOnly.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/vfx-10') { throw 'Expected branch codex/vfx-10.' }
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$allowed = '^(art/bakeoff/effects/xion/[^/]+\.(png|json)|art/bakeoff/ui/status/xion_reload-[ab]-v1\.(png|json)|art/bakeoff/skill_icons/xion/[^/]+\.(png|json)|reports/codex-vfx-10/[^/]+|design/tasks/CODEX-VFX-10\.md)$'
$paths = @()
foreach ($entry in $manifest.files) {
    $file = [string]$entry
    if ($file -notmatch $allowed -or $file -match '__pycache__|art/raw' -or $file.Contains('..')) { throw "Out-of-scope path: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
    if ([IO.Path]::GetExtension($file) -in @('.md','.txt','.json','.py','.ps1')) {
        $content = [IO.File]::ReadAllText((Join-Path $repo $file), [Text.Encoding]::UTF8)
        if ($content -match '(?m)[ \t]+\r?$') { throw "Trailing whitespace: $file" }
        if ($content.Contains([char]0xFFFD)) { throw "Broken UTF-8: $file" }
    }
    $paths += $file
}
if ($paths.Count -ne (@($paths | Select-Object -Unique)).Count) { throw 'Duplicate manifest path.' }
$before = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
foreach ($file in $before) {
    if ($file -notin $paths) { throw "Unrelated staged file: $file" }
}
if ($CheckOnly) {
    Write-Host "PASS: $($paths.Count) explicitly listed files; no index changes."
    Write-Host 'Partial delivery: 12 passes, 2 shotgun angle holds, 5 icons not reached.'
    exit 0
}
git add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$staged = @(git diff --cached --name-only)
foreach ($file in $staged) {
    if ($file -notin $paths) { throw "Unexpected staged path: $file" }
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
git diff --cached --stat
if ($Commit) {
    git commit -m 'art: add partial Xion VFX-10 candidates and validation boards'
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
} else {
    Write-Host 'Task files staged. Review shotgun holds and missing icons before merging.'
}
