$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branchName = (git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branchName -ne 'codex/sart-02') { throw 'Expected branch codex/sart-02.' }

function Is-Allowed([string]$candidatePath) {
    return ($candidatePath -match '^reports/codex-sart-02/' -or $candidatePath -match '^art/bakeoff/story/stage_card_[0-9]{2}-v[0-9]+\.(png|json)$')
}
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect git index.' }
foreach ($stagedPath in $alreadyStaged) {
    if (-not (Is-Allowed $stagedPath)) { throw "Unrelated staged path; no changes made: $stagedPath" }
}
$manifestPath = Join-Path $PSScriptRoot 'all-generations.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (@($manifest.jobs).Count -lt 18) { throw 'At least 18 generated jobs required.' }
$pathsToStage = [System.Collections.Generic.List[string]]::new()
foreach ($job in $manifest.jobs) {
    foreach ($extension in @('png', 'json')) {
        $relativePath = "art/bakeoff/story/$($job.id).$extension"
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relativePath) -PathType Leaf)) {
            throw "Final deliverable missing; finish processing and visual review first: $relativePath"
        }
        $pathsToStage.Add($relativePath)
    }
}
foreach ($stageNumber in 1..9) {
    $sheetName = 'stage-{0:D2}-comparison.jpg' -f $stageNumber
    $sheetPath = Join-Path $PSScriptRoot $sheetName
    if (-not (Test-Path -LiteralPath $sheetPath -PathType Leaf)) { throw "Missing contact sheet: $sheetName" }
    if ((Get-Item -LiteralPath $sheetPath).Length -gt 2000000) { throw "Contact sheet too large: $sheetName" }
}
$setSheet = Join-Path $PSScriptRoot 'set-board.jpg'
if (-not (Test-Path -LiteralPath $setSheet -PathType Leaf)) { throw 'Missing set-board.jpg' }
if ((Get-Item -LiteralPath $setSheet).Length -gt 2000000) { throw 'Set board too large.' }
foreach ($reportFile in Get-ChildItem -LiteralPath $PSScriptRoot -File -Recurse) {
    $relativePath = $reportFile.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
    if (-not (Is-Allowed $relativePath)) { throw "Outside task scope: $relativePath" }
    $pathsToStage.Add($relativePath)
}
foreach ($relativePath in $pathsToStage) {
    if ($relativePath -like 'art/raw/*' -or -not (Is-Allowed $relativePath)) { throw "Forbidden staging path: $relativePath" }
}
$stageArguments = @($pathsToStage | Sort-Object -Unique)
git add -- $stageArguments
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$stagedAfter = @(git diff --cached --name-only)
foreach ($relativePath in $stagedAfter) {
    if (-not (Is-Allowed $relativePath)) { throw "Unexpected staged path: $relativePath" }
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
git commit --file (Join-Path $PSScriptRoot 'commit-message.txt')
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
