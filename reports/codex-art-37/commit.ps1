$ErrorActionPreference = 'Stop'

$paths = @(
	'tools/sprite_pipeline/normalize.py',
	'tools/sprite_pipeline/test_normalize.py',
	'tools/sprite_pipeline/README.md',
	'art/bakeoff/frey/frey-idle-v2.png',
	'art/bakeoff/frey/frey-idle-v2.json',
	'art/bakeoff/frey/frey-attack-v4.png',
	'art/bakeoff/frey/frey-attack-v4.json',
	'reports/codex-art-37'
)

git add -- $paths
git commit -m "art: add detailed six-frame Frey phase 1 candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
