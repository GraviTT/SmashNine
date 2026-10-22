$ErrorActionPreference = 'Stop'
$repo09 = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo09
$branch09 = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch09 -ne 'codex/sys-09') {
	throw 'Run only in the codex/sys-09 clone.'
}
$product09 = @(
	'smash-nine-prototype/scripts/ArtSettings.gd',
	'smash-nine-prototype/scripts/ui/StoryDialogue.gd',
	'smash-nine-prototype/scripts/story/StoryCatalog.gd',
	'smash-nine-prototype/tests/test_story_faces.gd',
	'smash-nine-prototype/tests/run_all.ps1',
	'smash-nine-prototype/assets/art/README.md'
)
$files09 = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'commit-files.txt') -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
if ($files09.Count -eq 0 -or @($files09 | Select-Object -Unique).Count -ne $files09.Count) {
	throw 'Empty or duplicate commit file list.'
}
foreach ($file09 in $files09) {
	if (($product09 -notcontains $file09 -and $file09 -notmatch '^reports/codex-sys-09/[A-Za-z0-9_.-]+$') -or $file09 -match '__pycache__') {
		throw "Path outside SYS-09 allowlist: $file09"
	}
	if (-not (Test-Path -LiteralPath $file09 -PathType Leaf)) { throw "Missing file: $file09" }
	if ($file09 -match '\.log$' -and (Get-Item -LiteralPath $file09).Length -gt 1MB) { throw "Log exceeds 1 MB: $file09" }
}
foreach ($file09 in $product09) {
	if ($files09 -notcontains $file09) { throw "Missing required product file: $file09" }
}
& git -c core.autocrlf=false add -- @files09
if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit attempted.' }
$message09 = @'
feat: wire story expressions and shadow portraits with neutral fallback

Co-Authored-By: Codex <noreply@openai.com>
'@
& git -c core.autocrlf=false commit --only -m $message09 -- @files09
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
