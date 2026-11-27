$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
if ((git branch --show-current).Trim() -ne 'codex/vfx-11') {
    throw 'Expected branch codex/vfx-11.'
}
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $alreadyStaged.Count -gt 0) {
    throw 'Index must be empty before running this script.'
}
$paths = @()
$json = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivered_files.json') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($path in $json) {
    $entry = [string]$path
    if ($entry -ne 'design/tasks/CODEX-VFX-11.md' -and
        $entry -notmatch '^art/bakeoff/effects/rio/rio_(mana_sword(_stuck)?|backstab|shadow_blink|counter_stance|decoy_burst)-[ab]-v1\.(png|json)$' -and
        $entry -notmatch '^art/bakeoff/skill_icons/rio/rio_[jklui]-v1\.(png|json)$' -and
        $entry -notmatch '^reports/codex-vfx-11/[^/]+$') {
        throw "Out-of-contract path: $entry"
    }
    if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) { throw "Missing: $entry" }
    $paths += $entry
}
& git add -- @paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
& git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
$staged = @(git diff --cached --name-only)
foreach ($entry in $staged) {
    if ($paths -notcontains $entry) { throw "Unexpected staged file: $entry" }
}
& git commit -m 'art: add Rio kit v3 effect candidates and skill icons (VFX-11)'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
