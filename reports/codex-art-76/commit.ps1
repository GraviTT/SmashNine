$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
if ((git branch --show-current).Trim() -ne 'codex/art-76') { throw 'Run only in branch codex/art-76.' }
$manifest = Join-Path $PSScriptRoot 'delivery-files.txt'
$files = @(Get-Content -LiteralPath $manifest -Encoding UTF8 | Where-Object { $_.Trim() })
if ($files.Count -lt 80) { throw 'Delivery manifest is incomplete.' }
$ids = 'muspelheim_magma_boar|niflheim_glacier_wolf|niflheim_frost_owl|jotunheim_storm_wisp|yggdrasil_root_guardian|yggdrasil_root_oracle'
$assetPattern = '^art/bakeoff/monsters/(' + $ids + ')(-(idle|walk|windup|attack|hurt|defeat)-v1\.(png|json)|_sheet-v1\.png)$'
foreach ($file in $files) {
    $allowed = $file -match $assetPattern -or $file.StartsWith('reports/codex-art-76/')
    if (-not $allowed -or $file.Contains('..') -or $file.Contains('art/raw/') -or $file.Contains('__pycache__') -or $file.EndsWith('.pyc') -or $file.EndsWith('/run.log')) { throw "Out-of-scope file: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
}
git add --pathspec-from-file=$manifest
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. No commit was attempted.' }
$message = @'
Add six batch-three monster motion candidates for ART-76

Deliver 36 rows and six assembled sheets with comparison boards,
measured checks, exact prompts, and explicit visual limitations.

Co-Authored-By: Codex <noreply@openai.com>
'@
$commitMessage = $message.TrimEnd()
git -c commit.gpgsign=false commit --only --pathspec-from-file=$manifest --message $commitMessage
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
