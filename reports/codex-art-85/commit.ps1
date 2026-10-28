$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$listPath = Join-Path $PSScriptRoot 'delivery-files.txt'
$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
$paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8 | Where-Object { $_.Length -gt 0 })
if ($paths.Count -ne (@($paths | Sort-Object -Unique)).Count) { throw 'Duplicate delivery paths.' }
foreach ($path in $paths) {
    if ($path -match '(^/|^[A-Za-z]:|\\|\.\.|art/raw/|__pycache__|(^|/)run\.log$)') { throw "Forbidden path: $path" }
    $isCard = $path -in @('design/tasks/CODEX-ART-85.md', 'design/tasks/CODEX-ART-85.prompt.md')
    $isAsset = $path -match '^art/bakeoff/monsters/(svartalfheim_cog_drone-projectile-v2|niflheim_frost_owl-projectile-v2|yggdrasil_root_guardian-shockwave-v1)\.(png|json)$'
    $isReport = $path -match '^reports/codex-art-85/[^/]+\.(md|png|json|py|txt|ps1)$'
    if (-not ($isCard -or $isAsset -or $isReport)) { throw "Outside ART-85 delivery: $path" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $path) -PathType Leaf)) { throw "Missing file: $path" }
}
foreach ($required in @('design/tasks/CODEX-ART-85.md', 'design/tasks/CODEX-ART-85.prompt.md')) {
    if ($required -notin $paths) { throw "Missing task input: $required" }
}
$message = [IO.File]::ReadAllText($messagePath).TrimEnd()
if (-not $message.EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) { throw 'Invalid commit trailer.' }
$branch = & git -C $repoRoot branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-85') { throw 'Expected branch codex/art-85.' }
& git -C $repoRoot diff --cached --quiet
if ($LASTEXITCODE -ne 0) { throw 'Index is not empty; preserve existing staged work.' }
& git -C $repoRoot add "--pathspec-from-file=$listPath"
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. No commit was attempted.' }
$staged = @(& git -C $repoRoot diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged paths.' }
$unexpected = @($staged | Where-Object { $_ -notin $paths })
$missing = @($paths | Where-Object { $_ -notin $staged })
if ($unexpected.Count -gt 0 -or $missing.Count -gt 0) { throw 'Staged set differs from the delivery list; inspect manually.' }
& git -C $repoRoot diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
& git -C $repoRoot commit --file $messagePath
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
