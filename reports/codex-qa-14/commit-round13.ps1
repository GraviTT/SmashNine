$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round13.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round13.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa13_ab_enemy_ai.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/qa13_ab_enemy_ai.gd.uid' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round13.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round13.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round13.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/archive_round13.js' `
	'reports/codex-qa-14/round13.md' `
	'reports/codex-qa-14/round13-summary.json' `
	'reports/codex-qa-14/round13-a-results.json' `
	'reports/codex-qa-14/round13-b-results.json' `
	'reports/codex-qa-14/round13-a-full.json.gz' `
	'reports/codex-qa-14/round13-b-full.json.gz' `
	'reports/codex-qa-14/fixtures-round13' `
	'reports/codex-qa-14/probe-round13-a-seed-*.log' `
	'reports/codex-qa-14/probe-round13-b-seed-*.log' `
	'reports/codex-qa-14/import-round13-clean.log' `
	'reports/codex-qa-14/analyze-round13.log' `
	'reports/codex-qa-14/commit-round13.ps1'

git commit -m 'Report bot QA round 13 fall A/B and fixtures' -m 'Co-Authored-By: Codex <noreply@openai.com>'
