$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repo

git add -- `
	'smash-nine-prototype/assets/art/attack_vfx' `
	'smash-nine-prototype/tests/art_preview/attack_vfx_a' `
	'reports/codex-art-13'

git commit -m 'Add basic attack and skill VFX strips' -m 'Co-Authored-By: Codex <noreply@openai.com>'
