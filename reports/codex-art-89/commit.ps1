# Prepared only. Do not run until the lead reviews the explicit manifest.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $root
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-89') { throw 'Expected branch codex/art-89.' }
$alreadyStaged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0 -or $alreadyStaged.Count -gt 0) { throw 'Index must be empty; refusing to mix other staged work.' }
$listPath = Join-Path $PSScriptRoot 'commit-paths.txt'
$paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8)
if ($paths.Count -eq 0) { throw 'Empty manifest.' }
foreach ($path in $paths) {
    $allowed = $path -match '^reports/codex-art-89/' -or $path -match '^art/bakeoff/(frey|luna|yuki|nova|rio)/' -or $path -in @('design/tasks/CODEX-ART-89.md','design/tasks/CODEX-ART-89.prompt.md')
    if (-not $allowed -or $path -match 'art/raw/|ref82/|__pycache__|run\.log|/attempts/|/review/|/attempt-|(^|/)\.\.(/|$)') { throw "Disallowed manifest entry: $path" }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $path" }
    & git check-ignore --quiet -- $path
    if ($LASTEXITCODE -eq 0) { throw "Ignored file cannot be staged: $path" }
    if ($LASTEXITCODE -ne 1) { throw "check-ignore failed: $path" }
}
$audit = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'audit.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($audit.status -ne 'pass') { throw 'Delivery audit did not pass.' }
& git -c core.autocrlf=false add "--pathspec-from-file=$listPath"
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect staged paths.' }
$unexpected = @($staged | Where-Object { $_ -notin $paths })
$missing = @($paths | Where-Object { $_ -notin $staged })
if ($unexpected.Count -gt 0 -or $missing.Count -gt 0) { throw 'Staged paths differ from the explicit manifest; inspect the index manually.' }
$message = @'
ART-89: regenerate motion rows and deliver five checked candidates

Regenerate ten whole rows, preserve best attempts and 4x review evidence,
and withhold five rows that still fail face or motion criteria.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -c core.autocrlf=false commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
