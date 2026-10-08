$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

$paths = @(
	'reports/codex-qa-14/round6.md',
	'reports/codex-qa-14/round6-results.json',
	'reports/codex-qa-14/round6-summary.json',
	'reports/codex-qa-14/round3-summary.json',
	'reports/codex-qa-14/import-round6.log',
	'reports/codex-qa-14/smoke-round6.log',
	'reports/codex-qa-14/commit-round6.ps1',
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd',
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round6.ps1',
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round6.ps1'
)
$paths += @(Get-ChildItem -LiteralPath 'reports/codex-qa-14' -Filter 'round6-seed-*.json' | ForEach-Object { $_.FullName })
$paths += @(Get-ChildItem -LiteralPath 'reports/codex-qa-14' -Filter 'probe-round6-seed-*.log' | ForEach-Object { $_.FullName })

git add -- $paths
git commit -m "Measure bot AI round 6 confirmation`n`nCo-Authored-By: Codex <noreply@openai.com>"
