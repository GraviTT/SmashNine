$ErrorActionPreference = 'Stop'

$paths = @(
	'art/bakeoff/luna/luna-walk-v5.png',
	'art/bakeoff/luna/luna-walk-v5.json',
	'reports/codex-art-58/luna/README.md',
	'reports/codex-art-58/luna/bob.json',
	'reports/codex-art-58/luna/bob.png',
	'reports/codex-art-58/luna/build_report.py',
	'reports/codex-art-58/luna/commit.ps1',
	'reports/codex-art-58/luna/costume.png',
	'reports/codex-art-58/luna/feet.json',
	'reports/codex-art-58/luna/metrics.json',
	'reports/codex-art-58/luna/onion.png',
	'reports/codex-art-58/luna/prompts.txt',
	'reports/codex-art-58/luna/walk.gif'
)

git add -- $paths
git commit -m "art: redraw Luna walk passing frames`n`nCo-Authored-By: Codex <noreply@openai.com>"
