$ErrorActionPreference = 'Stop'
$repo73 = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo73
$branch73 = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch73 -ne 'codex/art-73') {
	throw 'Run this script only from the codex/art-73 clone.'
}
$files73 = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'commit-files.txt') -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
if ($files73.Count -eq 0) { throw 'The explicit ART-73 file list is empty.' }
foreach ($file73 in $files73) {
	$allowed73 = $file73 -match '^reports/codex-art-73/[A-Za-z0-9_.-]+$' -or $file73 -match '^art/bakeoff/(frey|luna|yuki|nova|rio)/[a-z_]+_face-(happy|angry|hurt)-v1\.(png|json)$'
	if (-not $allowed73 -or $file73 -match '(^|/)__pycache__(/|$)' -or $file73 -match '(^|/)art/raw/') {
		throw "Path outside the ART-73 commit allowlist: $file73"
	}
	if (-not (Test-Path -LiteralPath $file73 -PathType Leaf)) { throw "Missing listed file: $file73" }
}
if ($files73 -notcontains 'reports/codex-art-73/fix-1.prompt.md') {
	throw 'The fix-1 prompt must be included in the ART-73 handoff.'
}
if (@($files73 | Select-Object -Unique).Count -ne $files73.Count) {
	throw 'Duplicate paths in the ART-73 file list.'
}
& git add -- @files73
if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit was attempted.' }
$message73 = @'
art: composite ART-73 dialogue expressions onto neutral portraits

Co-Authored-By: Codex <noreply@openai.com>
'@
& git commit --only -m $message73 -- @files73
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
