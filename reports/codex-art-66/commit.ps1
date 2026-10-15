$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location -LiteralPath $repo

$paths = @(
	'art/bakeoff/effects/frey/frey_slash-v1.png',
	'art/bakeoff/effects/frey/frey_slash-v1.json',
	'art/bakeoff/effects/luna/luna_slash-v1.png',
	'art/bakeoff/effects/luna/luna_slash-v1.json',
	'art/bakeoff/effects/luna/luna_star_bloom-v1.png',
	'art/bakeoff/effects/luna/luna_star_bloom-v1.json',
	'art/bakeoff/effects/luna_brave/luna_brave_slash-v1.png',
	'art/bakeoff/effects/luna_brave/luna_brave_slash-v1.json',
	'art/bakeoff/effects/yuki/yuki_talisman-v1.png',
	'art/bakeoff/effects/yuki/yuki_talisman-v1.json',
	'art/bakeoff/effects/yuki/yuki_slash-v1.png',
	'art/bakeoff/effects/yuki/yuki_slash-v1.json',
	'art/bakeoff/effects/yuki/yuki_l-v1.png',
	'art/bakeoff/effects/yuki/yuki_l-v1.json',
	'art/bakeoff/effects/nova/nova_slash-v1.png',
	'art/bakeoff/effects/nova/nova_slash-v1.json',
	'art/bakeoff/effects/nova/nova_vector_streak-v1.png',
	'art/bakeoff/effects/nova/nova_vector_streak-v1.json',
	'art/bakeoff/effects/nova/nova_impact_star-v1.png',
	'art/bakeoff/effects/nova/nova_impact_star-v1.json',
	'art/bakeoff/effects/nova/nova_gravity_burst-v1.png',
	'art/bakeoff/effects/nova/nova_gravity_burst-v1.json',
	'art/bakeoff/effects/rio/rio_slash-v1.png',
	'art/bakeoff/effects/rio/rio_slash-v1.json',
	'art/bakeoff/effects/rio/rio_mana_wave-v1.png',
	'art/bakeoff/effects/rio/rio_mana_wave-v1.json',
	'reports/codex-art-66'
)

git add -- $paths
git commit -m "art: redraw every basic attack effect`n`nCo-Authored-By: Codex <noreply@openai.com>"
