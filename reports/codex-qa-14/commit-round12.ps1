$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'reports/codex-qa-14/round12.md' `
	'reports/codex-qa-14/round12-results.json' `
	'reports/codex-qa-14/round12-summary.json' `
	'reports/codex-qa-14/round12-fall-analysis.json' `
	'reports/codex-qa-14/round12-seed-*.json' `
	'reports/codex-qa-14/probe-round12-seed-*.log' `
	'reports/codex-qa-14/import-round12.log' `
	'reports/codex-qa-14/smoke-round12.log' `
	'reports/codex-qa-14/commit-round12.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round12.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round12.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round12.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round12.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round12_recovery.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round12_falls.js'

git commit -m 'Measure bot AI round 12 steered fall check' -m 'Co-Authored-By: Codex <noreply@openai.com>'
