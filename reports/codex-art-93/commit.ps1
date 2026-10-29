# Handoff only. Not executed by Codex. Stage the explicit delivery; do not commit.
$ErrorActionPreference = 'Stop'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$listPath = Join-Path $PSScriptRoot 'commit-paths.txt'
$paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8 | Where-Object { $_.Trim() })
if ($paths.Count -eq 0) { throw 'Empty delivery list.' }
foreach ($item in $paths) {
    if ($item -match '[\*\?\[\]:]' -or $item -match '(^|/)\.\.(/|$)') { throw "Non-literal path: $item" }
    if ($item -match '(^|/)(art/raw|__pycache__)(/|$)' -or $item -match '(^|/)run\.log$') { throw "Forbidden path: $item" }
    $allowed = $item -match '^reports/codex-art-93/' -or
        $item -match '^design/tasks/CODEX-ART-93(\.prompt)?\.md$' -or
        $item -match '^art/bakeoff/monsters/(alfheim_moon_moth|yggdrasil_root_oracle|asgard_aegis_ram|asgard_runic_raven|niflheim_frost_owl|ember_imp|yggdrasil_root_guardian|jotunheim_storm_wisp)-(windup|defeat)-v[23]\.(png|json)$'
    if (-not $allowed) { throw "Outside ART-93 scope: $item" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $item) -PathType Leaf)) { throw "Missing: $item" }
}
Push-Location -LiteralPath $repoRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-93') { throw 'Expected codex/art-93.' }
    $before = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0 -or $before.Count -ne 0) { throw 'Index must be empty before staging.' }
    & git -c core.autocrlf=false add --pathspec-from-file=$listPath
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    $staged = @(& git -c core.quotepath=false diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
    foreach ($item in $staged) {
        if ($paths -notcontains $item) { throw "Unexpected staged file: $item" }
    }
    & git diff --cached --stat
    Write-Host 'ART-93 staged for lead review. No commit performed.'
}
finally { Pop-Location }
