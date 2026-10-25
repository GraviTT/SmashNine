$ErrorActionPreference = 'Stop'
# Prepared for the lead. The analyst does not execute this script.
$repo81 = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo81
$branch81 = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch81 -ne 'codex/art-81') {
    throw 'This handoff is only for codex/art-81.'
}
$staged81 = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $staged81.Count -gt 0) {
    throw 'The index must be empty; preserve other work and review it separately.'
}
$files81 = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt') -Encoding UTF8 | Where-Object { $_.Trim() })
if ($files81.Count -eq 0 -or ($files81 | Select-Object -Unique).Count -ne $files81.Count) {
    throw 'Missing or duplicated delivery paths.'
}
foreach ($file81 in $files81) {
    $allowed81 = $file81.StartsWith('reports/codex-art-81/') -or $file81 -eq 'design/tasks/CODEX-ART-81.md' -or $file81 -eq 'design/tasks/CODEX-ART-81.prompt.md'
    if (-not $allowed81 -or $file81 -match '(^|/)(run\.log|__pycache__)(/|$)' -or $file81 -match '(^|/)\.\.(/|$)' -or -not (Test-Path -LiteralPath $file81 -PathType Leaf)) {
        throw "Unexpected delivery path: $file81"
    }
}
foreach ($required81 in @('design/tasks/CODEX-ART-81.md','design/tasks/CODEX-ART-81.prompt.md')) {
    if ($files81 -notcontains $required81) { throw "Required task context missing: $required81" }
}
& git add -- $files81
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. No forced add is used.' }
$actual81 = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or @($actual81 | Where-Object { $files81 -notcontains $_ }).Count -gt 0) {
    throw 'Unexpected staged path; stopped before committing.'
}
& git commit -m 'Audit 219 SmashNine art candidates without modifying assets' -m 'Record per-file measurements, thresholds, unresolved checks, and 4x evidence boards.' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
