# Written by Codex; deliberately not executed.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
Set-Location -LiteralPath $repoRoot
if ((git branch --show-current) -ne 'codex/art-71-fix-1') { throw 'Wrong branch' }
$paths = @(Get-Content -Encoding UTF8 -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt'))
foreach ($path in $paths) {
    if ($path -match '(^|/)(art/raw|__pycache__)(/|$)|(^|/)run\.log$|(^|/)\.\.?(/|$)') { throw "Excluded path: $path" }
    $candidate = $path -match '^art/bakeoff/monsters/(mossling|ember_imp|asgard_aegis_ram|asgard_runic_raven|alfheim_moon_stag|alfheim_moon_moth)(-.*-v1\.(png|json)|_sheet-v1\.png)$'
    $report = $path.StartsWith('reports/codex-art-71/fix-1/')
    if (-not ($candidate -or $report)) { throw "Outside card: $path" }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing file: $path" }
}
$staged = @(git diff --cached --name-only)
if ($staged.Count -gt 0) { throw 'Index is not empty; review it first. No staging was done.' }
for ($i = 0; $i -lt $paths.Count; $i += 40) {
    $last = [Math]::Min($i + 39, $paths.Count - 1)
    git add -- $paths[$i..$last]
    if ($LASTEXITCODE -ne 0) { throw 'git add failed (no force add was used)' }
}
git commit -m 'art: align batch-1 monster row sizes and ram charge feet' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
