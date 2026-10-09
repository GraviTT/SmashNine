$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa16_s0_enemy_ai.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa16_s0_enemy_ai.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa16_u0_enemy_ai.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa16_u0_enemy_ai.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round16.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round16.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round16.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round16.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round16.js' `
	'reports/codex-qa-14/round16.md' `
	'reports/codex-qa-14/round16-summary.json' `
	'reports/codex-qa-14/commit-round16.ps1'

git commit -m "test: compare bot target and ultimate variants" -m "Co-Authored-By: Codex <noreply@openai.com>"
