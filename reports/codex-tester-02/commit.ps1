$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location -LiteralPath $repoRoot

git add -- `
	'reports/codex-tester-02' `
	'smash-nine-prototype/tests/playtest/retest_core_02.gd' `
	'smash-nine-prototype/tests/playtest/retest_new_checks_02.gd' `
	'smash-nine-prototype/tests/playtest/retest_restart_02.gd'
if ($LASTEXITCODE -ne 0) {
	throw 'git add failed'
}

$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) {
	throw 'could not inspect staged paths'
}
if ($staged.Count -eq 0) {
	throw 'nothing is staged'
}

$allowedFiles = @(
	'smash-nine-prototype/tests/playtest/retest_core_02.gd',
	'smash-nine-prototype/tests/playtest/retest_new_checks_02.gd',
	'smash-nine-prototype/tests/playtest/retest_restart_02.gd'
)
foreach ($path in $staged) {
	$normalized = $path.Replace('\', '/')
	if (-not ($normalized.StartsWith('reports/codex-tester-02/') -or $allowedFiles -contains $normalized)) {
		throw "refusing to commit path outside tester-02 card: $path"
	}
}

git commit -m 'Retest real-input fixes and restart lifecycle' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) {
	throw 'git commit failed'
}
