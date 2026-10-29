$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/sart-03') {
    throw 'Expected branch codex/sart-03. No files were staged.'
}

function Test-AllowedPath([string]$Path) {
    return ($Path -match '^art/bakeoff/story/(cg_root-|start_card_frame-)[^/]+\.(png|json)$' -or
        ($Path.StartsWith('reports/codex-sart-03/') -and $Path -notmatch '(__pycache__|\.pyc$)'))
}

$alreadyStaged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
foreach ($path in $alreadyStaged) {
    if ($path -and -not (Test-AllowedPath $path)) {
        throw "Unrelated file already staged: $path. Preserve it and commit this task separately."
    }
}

$stagePaths = @()
foreach ($prefix in @('cg_root-', 'start_card_frame-')) {
    foreach ($item in Get-ChildItem -LiteralPath 'art/bakeoff/story' -File) {
        if ($item.Name.StartsWith($prefix) -and $item.Extension -in @('.png','.json')) {
            $stagePaths += 'art/bakeoff/story/' + $item.Name
        }
    }
}
foreach ($item in Get-ChildItem -LiteralPath $PSScriptRoot -File) {
    if ($item.Extension -in @('.md','.json','.jpg','.png','.py','.ps1','.txt')) {
        $stagePaths += 'reports/codex-sart-03/' + $item.Name
    }
}
$stagePaths = @($stagePaths | Sort-Object -Unique)
foreach ($path in $stagePaths) {
    if (-not (Test-AllowedPath $path)) { throw "Refusing path: $path" }
}
if ($stagePaths.Count -eq 0) { throw 'No task files found.' }
& git add -- @stagePaths
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. Run only where .git is writable.' }
foreach ($path in @(& git diff --cached --name-only)) {
    if ($path -and -not (Test-AllowedPath $path)) { throw "Unrelated staged path detected: $path" }
}
& git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
& git commit --file 'reports/codex-sart-03/commit-message.txt'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
Write-Output 'SART-03 committed. No merge or push was performed.'
