# Handoff only. This script has NOT been executed by Codex.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$listPath = Join-Path $PSScriptRoot 'files-to-stage.txt'
$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
$paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8 | Where-Object { $_.Trim() })
if ($paths.Count -eq 0) { throw 'Empty delivery list.' }
foreach ($item in $paths) {
    if ($item -match '(^|/)(art/raw|qa23|__pycache__)(/|$)' -or $item -match '(^|/)run\.log$') {
        throw "Forbidden delivery path: $item"
    }
    if ($item -match '[\*\?\[\]:]' -or $item -match '(^|/)\.\.(/|$)') { throw "Non-literal delivery path: $item" }
    $inScope = $item -match '^reports/codex-art-90/' -or
        $item -match '^design/tasks/CODEX-ART-90(\.prompt)?\.md$' -or
        $item -match '^art/bakeoff/monsters/yggdrasil_root_guardian-(attack|defeat)-v2\.(png|json)$' -or
        $item -match '^art/bakeoff/monsters/yggdrasil_root_guardian_sheet-v2\.png$' -or
        $item -match '^art/bakeoff/monsters/vanaheim_vine_hound-(idle|walk|windup|attack|hurt|defeat)-v2\.(png|json)$' -or
        $item -match '^art/bakeoff/monsters/vanaheim_vine_hound_sheet-v2\.png$' -or
        $item -match '^art/bakeoff/monsters/legacy/alfheim_moon_stag_sheet-fix1\.(png|json)$'
    if (-not $inScope) { throw "Outside ART-90 delivery scope: $item" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $item) -PathType Leaf)) { throw "Missing file: $item" }
}
$message = [System.IO.File]::ReadAllText($messagePath).TrimEnd()
if (-not $message.EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) { throw 'Missing required commit footer.' }
Push-Location -LiteralPath $repoRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-90') { throw 'Expected branch codex/art-90.' }
    $stagedBefore = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0 -or $stagedBefore.Count -ne 0) { throw 'Index must be empty before ART-90 staging.' }
    & git -c core.autocrlf=false add --pathspec-from-file=$listPath
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; inspect the index. No commit attempted.' }
    $staged = @(& git -c core.quotepath=false diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
    foreach ($item in $staged) {
        if ($paths -notcontains $item) { throw "Unexpected staged file: $item" }
    }
    & git commit --file=$messagePath
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally { Pop-Location }
