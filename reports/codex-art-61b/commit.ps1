$ErrorActionPreference = 'Stop'

$paths = @(
	'art/bakeoff/rio/rio_female-jump-v1.png', 'art/bakeoff/rio/rio_female-jump-v1.json',
	'art/bakeoff/rio/rio_female-fall-v1.png', 'art/bakeoff/rio/rio_female-fall-v1.json',
	'art/bakeoff/rio/rio_female-hurt-v1.png', 'art/bakeoff/rio/rio_female-hurt-v1.json',
	'art/bakeoff/rio/rio_female-shield-v1.png', 'art/bakeoff/rio/rio_female-shield-v1.json',
	'art/bakeoff/rio/rio_female-attack-v1.png', 'art/bakeoff/rio/rio_female-attack-v1.json',
	'art/bakeoff/rio/rio_female-mana_combo-v1.png', 'art/bakeoff/rio/rio_female-mana_combo-v1.json',
	'art/bakeoff/rio/rio_female-rising_slash-v1.png', 'art/bakeoff/rio/rio_female-rising_slash-v1.json',
	'art/bakeoff/rio/rio_female-low_sweep-v1.png', 'art/bakeoff/rio/rio_female-low_sweep-v1.json',
	'art/bakeoff/rio/rio_female-air_slash-v3.png', 'art/bakeoff/rio/rio_female-air_slash-v3.json',
	'art/bakeoff/rio/rio_female-plunge-v3.png', 'art/bakeoff/rio/rio_female-plunge-v3.json',
	'art/bakeoff/rio/rio_female-dimension_slash-v1.png', 'art/bakeoff/rio/rio_female-dimension_slash-v1.json',
	'art/bakeoff/rio/rio_female-rune_shield-v1.png', 'art/bakeoff/rio/rio_female-rune_shield-v1.json',
	'art/bakeoff/rio/rio_female-infinity_overdrive-v1.png', 'art/bakeoff/rio/rio_female-infinity_overdrive-v1.json',
	'art/bakeoff/rio/rio_female-tumble-v1.png', 'art/bakeoff/rio/rio_female-tumble-v1.json',
	'reports/codex-art-61b'
)

git add -- $paths
git commit -m 'art: build Rio female phase two rows' -m 'Co-Authored-By: Codex <noreply@openai.com>'
