$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'reports/codex-qa-14/round9.md' `
	'reports/codex-qa-14/round9-results.json' `
	'reports/codex-qa-14/round9-summary.json' `
	'reports/codex-qa-14/round9-seed-*.json' `
	'reports/codex-qa-14/probe-round9-seed-*.log' `
	'reports/codex-qa-14/import-round9.log' `
	'reports/codex-qa-14/smoke-round9.log' `
	'reports/codex-qa-14/commit-round9.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round9.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round9.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round9.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round9.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round9_recovery.js'

git commit -m 'Measure bot AI round 9 routes and targets' -m 'Co-Authored-By: Codex <noreply@openai.com>'
