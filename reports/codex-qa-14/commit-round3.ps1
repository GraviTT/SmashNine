$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_probe.ps1' `
	'reports/codex-qa-14/round3.md' `
	'reports/codex-qa-14/round3-results.json' `
	'reports/codex-qa-14/import-round3.log' `
	'reports/codex-qa-14/probe-round3-final.log' `
	'reports/codex-qa-14/commit-round3.ps1'

git commit -m "Retest smarter bots in QA-14 round 3" -m "Co-Authored-By: Codex <noreply@openai.com>"
