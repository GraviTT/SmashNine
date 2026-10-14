$ErrorActionPreference = 'Stop'

git add -- `
	'art/bakeoff/rio/rio_male-idle-v2.png' `
	'art/bakeoff/rio/rio_male-idle-v2.json' `
	'art/bakeoff/rio/rio_female-idle-v2.png' `
	'art/bakeoff/rio/rio_female-idle-v2.json' `
	'reports/codex-art-60'

git commit -m "art: add Rio idle anchor candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
