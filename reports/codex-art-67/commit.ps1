$ErrorActionPreference = 'Stop'

$candidateFiles = @(
	'art/bakeoff/effects/common/guard_bubble-v1.png',
	'art/bakeoff/effects/common/guard_bubble-v1.json',
	'art/bakeoff/effects/common/parry_flash-v1.png',
	'art/bakeoff/effects/common/parry_flash-v1.json',
	'art/bakeoff/effects/common/status_stun-v1.png',
	'art/bakeoff/effects/common/status_stun-v1.json',
	'art/bakeoff/effects/common/status_super_armor-v1.png',
	'art/bakeoff/effects/common/status_super_armor-v1.json',
	'art/bakeoff/effects/frey/frey_pursuit_mark-v1.png',
	'art/bakeoff/effects/frey/frey_pursuit_mark-v1.json',
	'art/bakeoff/effects/frey/frey_spike_ring-v1.png',
	'art/bakeoff/effects/frey/frey_spike_ring-v1.json',
	'art/bakeoff/effects/frey/frey_ult_charge-v1.png',
	'art/bakeoff/effects/frey/frey_ult_charge-v1.json',
	'art/bakeoff/effects/luna/luna_star_charge-v1.png',
	'art/bakeoff/effects/luna/luna_star_charge-v1.json',
	'art/bakeoff/effects/luna/luna_brave_aura-v1.png',
	'art/bakeoff/effects/luna/luna_brave_aura-v1.json',
	'art/bakeoff/effects/luna/luna_ult_transform-v1.png',
	'art/bakeoff/effects/luna/luna_ult_transform-v1.json',
	'art/bakeoff/effects/luna/luna_moon_ring-v1.png',
	'art/bakeoff/effects/luna/luna_moon_ring-v1.json',
	'art/bakeoff/effects/yuki/yuki_seal_idle-v1.png',
	'art/bakeoff/effects/yuki/yuki_seal_idle-v1.json',
	'art/bakeoff/effects/yuki/yuki_seal_break-v1.png',
	'art/bakeoff/effects/yuki/yuki_seal_break-v1.json',
	'art/bakeoff/effects/yuki/yuki_ult_seal-v1.png',
	'art/bakeoff/effects/yuki/yuki_ult_seal-v1.json',
	'art/bakeoff/effects/nova/nova_momentum_trail-v1.png',
	'art/bakeoff/effects/nova/nova_momentum_trail-v1.json',
	'art/bakeoff/effects/nova/nova_shift_ready-v1.png',
	'art/bakeoff/effects/nova/nova_shift_ready-v1.json',
	'art/bakeoff/effects/nova/nova_ult_core-v1.png',
	'art/bakeoff/effects/nova/nova_ult_core-v1.json',
	'art/bakeoff/effects/rio/rio_rune_guard-v1.png',
	'art/bakeoff/effects/rio/rio_rune_guard-v1.json',
	'art/bakeoff/effects/rio/rio_ult_circle-v1.png',
	'art/bakeoff/effects/rio/rio_ult_circle-v1.json',
	'art/bakeoff/effects/rio/rio_gem_sword-v1.png',
	'art/bakeoff/effects/rio/rio_gem_sword-v1.json'
)

git add -- $candidateFiles
git add -- 'reports/codex-art-67'
git commit -m 'art: redraw character-bound effects' -m 'Co-Authored-By: Codex <noreply@openai.com>'
