$ErrorActionPreference = 'Stop'

git add -- `
	'reports/codex-art-59/luna_brave' `
	'reports/codex-art-59/yuki' `
	'reports/codex-art-59/commit-a.ps1'

git commit -m "Report ART-59 unit A walk attempts`n`nCo-Authored-By: Codex <noreply@openai.com>"
