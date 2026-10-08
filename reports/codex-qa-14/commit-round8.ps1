$ErrorActionPreference = 'Stop'

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round4.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round8.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round8.ps1' `
	'reports/codex-qa-14/round8.md' `
	'reports/codex-qa-14/round8-results.json' `
	'reports/codex-qa-14/round8-summary.json' `
	'reports/codex-qa-14/round8-seed-*.json' `
	'reports/codex-qa-14/probe-round8-seed-*.log' `
	'reports/codex-qa-14/import-round8.log' `
	'reports/codex-qa-14/import-round8-retry.log' `
	'reports/codex-qa-14/commit-round8.ps1'

git commit -m "Measure bot AI round 8`n`nCo-Authored-By: Codex <noreply@openai.com>"
