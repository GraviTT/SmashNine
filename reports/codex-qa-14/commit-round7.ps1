$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- 'smash-nine-prototype/tests/analysis/codex_qa_14' 'reports/codex-qa-14/round7.md' 'reports/codex-qa-14/round7-results.json' 'reports/codex-qa-14/round7-summary.json' 'reports/codex-qa-14/round7-seed-*.json' 'reports/codex-qa-14/probe-round7-seed-*.log' 'reports/codex-qa-14/commit-round7.ps1'
git commit -m 'Measure bot AI round 7' -m 'Co-Authored-By: Codex <noreply@openai.com>'
