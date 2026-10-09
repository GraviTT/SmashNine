$ErrorActionPreference = 'Stop'

$paths = @(
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round14.gd',
	'smash-nine-prototype/tests/analysis/codex_qa_14/bot_behavior_probe_round14.gd.uid',
	'smash-nine-prototype/tests/analysis/codex_qa_14/run_round14.ps1',
	'smash-nine-prototype/tests/analysis/codex_qa_14/merge_round14.js',
	'smash-nine-prototype/tests/analysis/codex_qa_14/analyze_round14.js',
	'smash-nine-prototype/tests/analysis/codex_qa_14/archive_round14.js',
	'reports/codex-qa-14/round14-results.json',
	'reports/codex-qa-14/round14-summary.json',
	'reports/codex-qa-14/round14.md',
	'reports/codex-qa-14/commit-round14.ps1'
)

git add -- $paths
git commit -m 'Report QA-14 round 14 bot measurements' -m 'Co-Authored-By: Codex <noreply@openai.com>'
