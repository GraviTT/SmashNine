$ErrorActionPreference = 'Stop'

$paths = @(
	'art/bakeoff/yuki/yuki-idle-v2.png',
	'art/bakeoff/yuki/yuki-idle-v2.json',
	'reports/codex-art-48'
)

git add -- $paths
git commit -m "art: add Yuki anchor idle candidate`n`nCo-Authored-By: Codex <noreply@openai.com>"
