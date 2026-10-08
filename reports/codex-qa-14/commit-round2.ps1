$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe.gd' `
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_probe.ps1' `
	'reports/codex-qa-14/round2.md' `
	'reports/codex-qa-14/round2-results.json' `
	'reports/codex-qa-14/probe-round2-final.log' `
	'reports/codex-qa-14/commit-round2.ps1'

git commit -m "Retest smarter bots on QA-14 seeds" -m "Co-Authored-By: Codex <noreply@openai.com>"
