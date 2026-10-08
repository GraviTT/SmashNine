$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

$paths = @(
	'reports/codex-qa-14/commit-round4.ps1',
	'reports/codex-qa-14/round4.md',
	'reports/codex-qa-14/round4-results.json',
	'reports/codex-qa-14/round4-summary.json',
	'reports/codex-qa-14/probe-round4.log',
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd',
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd.uid',
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_probe.ps1',
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round4.ps1',
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round4.js'
)
$paths += @(Get-ChildItem -LiteralPath 'reports/codex-qa-14' -Filter 'round4-seed-*.json' | ForEach-Object { $_.FullName.Substring($repo.Length + 1) })
$paths += @(Get-ChildItem -LiteralPath 'reports/codex-qa-14' -Filter 'probe-round4-seed-*.log' | ForEach-Object { $_.FullName.Substring($repo.Length + 1) })

git add -- $paths
git commit -m 'test: final bot behavior retest round 4' -m 'Co-Authored-By: Codex <noreply@openai.com>'
