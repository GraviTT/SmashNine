$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'reports/codex-qa-14/round11.md' `
	'reports/codex-qa-14/round11-results.json' `
	'reports/codex-qa-14/round11-summary.json' `
	'reports/codex-qa-14/round11-fall-analysis.json' `
	'reports/codex-qa-14/round11-seed-*.json' `
	'reports/codex-qa-14/probe-round11-seed-*.log' `
	'reports/codex-qa-14/import-round11.log' `
	'reports/codex-qa-14/smoke-round11-driver.log' `
	'reports/codex-qa-14/commit-round11.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round11.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round11.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round11.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round11.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round11_recovery.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round11_falls.js'

git commit -m 'Measure bot AI round 11 fall arc' -m 'Co-Authored-By: Codex <noreply@openai.com>'
