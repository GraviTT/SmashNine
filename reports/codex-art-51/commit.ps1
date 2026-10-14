$ErrorActionPreference = 'Stop'

git add -- `
	'art/bakeoff/nova/nova_male-idle-v2.png' `
	'art/bakeoff/nova/nova_male-idle-v2.json' `
	'art/bakeoff/nova/nova_female-idle-v2.png' `
	'art/bakeoff/nova/nova_female-idle-v2.json' `
	'reports/codex-art-51'

git commit -m "art: add Nova idle anchor candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
