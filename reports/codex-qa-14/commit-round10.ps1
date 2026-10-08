$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'reports/codex-qa-14/round10.md' `
	'reports/codex-qa-14/round10-results.json' `
	'reports/codex-qa-14/round10-summary.json' `
	'reports/codex-qa-14/round10-seed-*.json' `
	'reports/codex-qa-14/probe-round10-seed-*.log' `
	'reports/codex-qa-14/import-round10.log' `
	'reports/codex-qa-14/smoke-round10.log' `
	'reports/codex-qa-14/run-round10.log' `
	'reports/codex-qa-14/commit-round10.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round10.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round10.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round10.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round10.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round10_recovery.js'

git commit -m 'Measure bot AI round 10 falls and idle engages' -m 'Co-Authored-By: Codex <noreply@openai.com>'
