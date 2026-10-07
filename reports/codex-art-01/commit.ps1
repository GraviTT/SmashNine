$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $repoRoot

$existingStaged = @(git diff --cached --name-only)
if ($existingStaged.Count -gt 0) {
	throw "The index already contains staged files. Commit or unstage them before running this script."
}

$allowedPaths = @(
	'smash-nine-prototype/assets/art/realm_center',
	'smash-nine-prototype/tests/art_preview/realm',
	'reports/codex-art-01'
)

git add -- $allowedPaths
if ($LASTEXITCODE -ne 0) {
	throw "git add failed"
}

$staged = @(git diff --cached --name-only)
$unexpected = @($staged | Where-Object {
	$_ -notlike 'smash-nine-prototype/assets/art/realm_center/*' -and
	$_ -notlike 'smash-nine-prototype/tests/art_preview/realm/*' -and
	$_ -notlike 'reports/codex-art-01/*'
})
if ($unexpected.Count -gt 0) {
	git restore --staged -- $allowedPaths
	throw ("Unexpected staged paths: " + ($unexpected -join ', '))
}

git commit -m 'Add Yggdrasil Heart realm art' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) {
	throw "git commit failed"
}
