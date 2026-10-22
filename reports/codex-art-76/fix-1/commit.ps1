$ErrorActionPreference = 'Stop'
# Prepared for the lead. Codex did not run this script or stage/commit files.
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location -LiteralPath $repo
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-76-fix-1') {
    throw 'Expected this clone on codex/art-76-fix-1.'
}
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt') -Encoding UTF8 | Where-Object { $_ })
$ids = 'muspelheim_magma_boar|niflheim_glacier_wolf|niflheim_frost_owl|jotunheim_storm_wisp|yggdrasil_root_guardian|yggdrasil_root_oracle'
$candidatePattern = '^art/bakeoff/monsters/(' + $ids + ')(-(idle|walk|windup|attack|hurt|defeat)-v1\.(png|json)|_sheet-v1\.png)$'
foreach ($file in $files) {
    if ($file -match '(^|/)(art/raw|__pycache__)(/|$)' -or $file -match '(^|/)run\.log$' -or $file -match '(^|/)\.\.(/|$)') {
        throw "Excluded file: $file"
    }
    if ($file -notmatch $candidatePattern -and -not $file.StartsWith('reports/codex-art-76/fix-1/')) {
        throw "Outside card scope: $file"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repo $file) -PathType Leaf)) {
        throw "Missing delivery file: $file"
    }
}
$hashes = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-hashes.json') -Encoding UTF8 -Raw | ConvertFrom-Json
foreach ($entry in $hashes.PSObject.Properties) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $repo $entry.Name) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $entry.Value) { throw "Delivery file changed after verification: $($entry.Name)" }
}
$alreadyStaged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
foreach ($file in $alreadyStaged) {
    if ($file -and $file -notin $files) { throw "Unrelated staged file; refusing to commit: $file" }
}
& git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed. No force-add is used.' }
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot verify staged paths.' }
foreach ($file in $staged) {
    if ($file -and $file -notin $files) { throw "Unexpected staged path: $file" }
}
$message = @'
art: align batch-3 monster candidate rows to idle size

Rebuild 19 rows from accepted raws with one factor per row; preserve ground
contacts and rebuild six assembled sheets. Add 4x evidence, nominal size
tables, full pixel verification and corrected attack-reach measurements.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
