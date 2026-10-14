$ErrorActionPreference = 'Stop'

$files = @(
	'art/bakeoff/luna/luna-transform-v2.png',
	'art/bakeoff/luna/luna-transform-v2.json',
	'reports/codex-art-46/prompt-1.txt',
	'reports/codex-art-46/prompt-2.txt',
	'reports/codex-art-46/compare.png',
	'reports/codex-art-46/preview.gif',
	'reports/codex-art-46/metrics.json',
	'reports/codex-art-46/README.md',
	'reports/codex-art-46/commit.ps1'
)

git add -- $files
git commit -m "art: add Luna transformation showcase`n`nCo-Authored-By: Codex <noreply@openai.com>"
