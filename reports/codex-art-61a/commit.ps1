$ErrorActionPreference = 'Stop'

$files = @(
	'art/bakeoff/rio/rio_male-air_slash-v1.png',
	'art/bakeoff/rio/rio_male-air_slash-v1.json',
	'art/bakeoff/rio/rio_male-attack-v1.png',
	'art/bakeoff/rio/rio_male-attack-v1.json',
	'art/bakeoff/rio/rio_male-dimension_slash-v1.png',
	'art/bakeoff/rio/rio_male-dimension_slash-v1.json',
	'art/bakeoff/rio/rio_male-hurt-v1.png',
	'art/bakeoff/rio/rio_male-hurt-v1.json',
	'art/bakeoff/rio/rio_male-jump-v1.png',
	'art/bakeoff/rio/rio_male-jump-v1.json',
	'art/bakeoff/rio/rio_male-low_sweep-v1.png',
	'art/bakeoff/rio/rio_male-low_sweep-v1.json',
	'art/bakeoff/rio/rio_male-mana_combo-v1.png',
	'art/bakeoff/rio/rio_male-mana_combo-v1.json',
	'art/bakeoff/rio/rio_male-plunge-v1.png',
	'art/bakeoff/rio/rio_male-plunge-v1.json',
	'art/bakeoff/rio/rio_male-rising_slash-v1.png',
	'art/bakeoff/rio/rio_male-rising_slash-v1.json',
	'art/bakeoff/rio/rio_male-rune_shield-v1.png',
	'art/bakeoff/rio/rio_male-rune_shield-v1.json',
	'art/bakeoff/rio/rio_male-tumble-v1.png',
	'art/bakeoff/rio/rio_male-tumble-v1.json',
	'reports/codex-art-61a'
)

git add -- $files
git commit -m "art: add Rio male ART-61 motion rows`n`nCo-Authored-By: Codex <noreply@openai.com>"
