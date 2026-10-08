$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_probe.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round5.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/summarize_round4.js' `
	'reports/codex-qa-14/import-round5.log' `
	'reports/codex-qa-14/smoke-round5.log' `
	'reports/codex-qa-14/probe-round5-seed-*.log' `
	'reports/codex-qa-14/round5-seed-*.json' `
	'reports/codex-qa-14/round5-results.json' `
	'reports/codex-qa-14/round5-summary.json' `
	'reports/codex-qa-14/round5.md' `
	'reports/codex-qa-14/commit-round5.ps1'

git commit -m 'Measure bot AI round 5 confirmation' -m 'Co-Authored-By: Codex <noreply@openai.com>'
