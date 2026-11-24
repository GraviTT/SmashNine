param([switch]$Commit, [switch]$CheckOnly)
$ErrorActionPreference = 'Stop'
if ($Commit -and $CheckOnly) { throw 'Choose -Commit or -CheckOnly.' }
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/vfx-10c') { throw 'Expected branch codex/vfx-10c.' }
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest-10c.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($manifest.branch -ne $branch) { throw 'Manifest branch mismatch.' }
$base = [string]$manifest.base_commit
if ($base -ne 'e3998e9d7839d35f2b9ae9e848955e63e02bb5b0') { throw 'Unexpected task base commit.' }
git merge-base --is-ancestor $base HEAD
if ($LASTEXITCODE -ne 0) { throw 'Task base must be an ancestor of HEAD.' }
$allowed = '^(art/bakeoff/effects/xion/xion_blast-[ab]-v2\.(png|json)|art/bakeoff/skill_icons/xion/xion_[jklui]-v1\.(png|json)|reports/codex-vfx-10/[^/]+)$'
$pathList = New-Object 'System.Collections.Generic.List[string]'
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
foreach ($entry in $manifest.files) {
    if ($entry -isnot [string]) { throw 'Every manifest entry must be one path string.' }
    $file = [string]$entry
    if ($file -notmatch $allowed -or $file -match '__pycache__|art/raw' -or $file.Contains('..')) { throw "Out-of-scope path: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
    if ([IO.Path]::GetExtension($file) -in @('.md','.txt','.json','.py','.ps1')) {
        $content = $strictUtf8.GetString([IO.File]::ReadAllBytes((Join-Path $repo $file)))
        if ($content -match '(?m)[ \t]+\r?$') { throw "Trailing whitespace: $file" }
        if ($content.Contains([char]0xFFFD)) { throw "Broken UTF-8: $file" }
        if ($content.Contains("`r")) { throw "Text must have LF line endings: $file" }
    }
    $pathList.Add($file)
}
$paths = $pathList.ToArray()
if ($paths.Count -ne (@($paths | Select-Object -Unique)).Count) { throw 'Duplicate manifest path.' }
# Only the explicitly requested README and script may be edits to old files.
# This prevents re-staging v1 art or the previous run's report manifest.
$baseFiles = @(git ls-tree -r --name-only $base -- $paths)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect task base tree.' }
$existingAllowed = @('reports/codex-vfx-10/README.md', 'reports/codex-vfx-10/commit.ps1')
foreach ($file in $baseFiles) {
    if ($file -notin $existingAllowed) { throw "Already present at task base: $file" }
}
$before = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
foreach ($file in $before) {
    if ($file -notin $paths) { throw "Unrelated staged file: $file" }
}
python (Join-Path $PSScriptRoot 'validate_10c.py') --check-only
if ($LASTEXITCODE -ne 0) { throw 'Candidate validation failed.' }
if ($CheckOnly) {
    Write-Host "PASS: $($paths.Count) explicit follow-up files; no index or file changes."
    Write-Host '5 skill icons and 2 blast v2 candidates; 7 PASS. Existing v1 delivery excluded.'
    exit 0
}
git add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
foreach ($file in $staged) {
    if ($file -notin $paths) { throw "Unexpected staged path: $file" }
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
git diff --cached --stat
if ($Commit) {
    git commit -m 'art: finish Xion skill icons and narrow blast v2 candidates to 14 degrees'
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
} else {
    Write-Host 'Only VFX-10c follow-up files staged. Candidate choices remain with the lead/user.'
}
