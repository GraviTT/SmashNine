$ErrorActionPreference = 'Stop'

$paths = @(
	'art/bakeoff/luna/luna-walk-v4.png',
	'art/bakeoff/luna/luna-walk-v4.json',
	'reports/codex-art-57/luna/README.md',
	'reports/codex-art-57/luna/bob.json',
	'reports/codex-art-57/luna/bob.png',
	'reports/codex-art-57/luna/build_report.py',
	'reports/codex-art-57/luna/commit.ps1',
	'reports/codex-art-57/luna/compare.png',
	'reports/codex-art-57/luna/costume.png',
	'reports/codex-art-57/luna/feet.png',
	'reports/codex-art-57/luna/make_walk_reference.py',
	'reports/codex-art-57/luna/metrics.json',
	'reports/codex-art-57/luna/prompts.txt',
	'reports/codex-art-57/luna/walk.gif',
	'reports/codex-art-57/luna/walk_reference_luna.png'
)

git add -- $paths
git commit -m "art: add Luna 8-frame walk v4 candidate`n`nCo-Authored-By: Codex <noreply@openai.com>"
