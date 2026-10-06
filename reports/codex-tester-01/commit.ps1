$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location -LiteralPath $repoRoot

git add -- 'smash-nine-prototype/tests/playtest' 'reports/codex-tester-01'
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

foreach ($path in $staged) {
	$normalized = $path.Replace('\', '/')
	if (-not ($normalized.StartsWith('smash-nine-prototype/tests/playtest/') -or $normalized.StartsWith('reports/codex-tester-01/'))) {
		throw "refusing to commit path outside tester card: $path"
	}
}

git commit -m 'Add real-input M1 playtest report' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) {
	throw 'git commit failed'
}
