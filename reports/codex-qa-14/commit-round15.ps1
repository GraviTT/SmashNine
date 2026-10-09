$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'reports/codex-qa-14/round15.md' `
	'reports/codex-qa-14/round15-results.json' `
	'reports/codex-qa-14/round15-summary.json' `
	'reports/codex-qa-14/commit-round15.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round15.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round15.ps1' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round15.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round15.js' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/archive_round15.js'

git commit -m 'Report bot QA round 15 measurements' -m 'Co-Authored-By: Codex <noreply@openai.com>'
