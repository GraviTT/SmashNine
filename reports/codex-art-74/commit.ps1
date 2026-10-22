$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$manifest = Join-Path $PSScriptRoot 'delivery-files.txt'
$files = [IO.File]::ReadAllLines($manifest, [Text.Encoding]::UTF8)
if ($files.Count -eq 0) { throw 'Empty ART-74 delivery manifest.' }
$ids = 'midgard_rooftop_slinger|svartalfheim_gear_beetle|svartalfheim_cog_drone|vanaheim_vine_hound|vanaheim_seed_sprite|jotunheim_rune_golem'
foreach ($file in $files) {
    if ($file -match '(^|/)\.\.(/|$)|art/raw/|__pycache__|(^|/)run\.log$|^reports/codex-art-74/fix-1/work/') { throw "Forbidden path: $file" }
    if ($file -notmatch "^reports/codex-art-74/" -and $file -notmatch "^art/bakeoff/monsters/($ids)(-(idle|walk|windup|attack|hurt|defeat)-v1\.(png|json)|_sheet-v1\.png)$") { throw "Outside ART-74: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
}
if ('reports/codex-art-74/fix-1.prompt.md' -notin $files) { throw 'Missing lead review prompt.' }
$existingIndex = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
if ($existingIndex.Count -gt 0) { throw 'Start with a clean index before running the ART-74 commit script.' }
# Explicit manifest only. No wildcard staging, no force, and no ignored raw assets.
& git add "--pathspec-from-file=$manifest"
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
# A clean index is required before using this script; refuse unrelated staged paths.
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
foreach ($file in $staged) { if ($file -notin $files) { throw "Unrelated staged file: $file" } }
$message = @'
art: add ART-74 monster candidates with restored palettes and matched row sizes

Deliver six monsters, 36 animation rows and six assembled candidate sheets.
Restore Vanaheim greens and bark using a shared reference-derived LUT per monster.
Rebuild mismatched rows from raw sources, with before/after size and colour boards.
Keep game sources and raw generations outside this commit.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
