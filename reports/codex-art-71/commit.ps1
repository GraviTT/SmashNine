$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
if ((git branch --show-current).Trim() -ne 'codex/art-71') { throw 'Run only in branch codex/art-71.' }
$manifest = Join-Path $PSScriptRoot 'delivery-files.txt'
$files = @(Get-Content -LiteralPath $manifest -Encoding UTF8 | Where-Object { $_.Trim() })
if ($files.Count -lt 80) { throw 'Delivery manifest is missing or incomplete.' }
foreach ($file in $files) {
    $allowed = $file -eq 'tools/motion_viewer/build.mjs' -or $file.StartsWith('art/bakeoff/monsters/') -or $file.StartsWith('reports/codex-art-71/')
    if (-not $allowed -or $file.Contains('..') -or $file.Contains('art/raw/') -or $file.Contains('__pycache__') -or $file.EndsWith('/run.log')) { throw "Out-of-scope file: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
}
git add --pathspec-from-file=$manifest
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. No commit was attempted.' }
$message = @'
Add six monster motion candidates and viewer support for ART-71

Deliver 36 candidate rows and six assembled sheets, with source prompts,
measured checks, comparison boards, and candidate-specific preview loops.

Co-Authored-By: Codex <noreply@openai.com>
'@
$commitMessage = $message.TrimEnd()
git -c commit.gpgsign=false commit --only --pathspec-from-file=$manifest --message $commitMessage
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
