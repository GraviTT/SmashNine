$ErrorActionPreference = 'Stop'

$paths = @(
	'reports/codex-art-52a',
	'art/bakeoff/nova/nova_male-walk-v1.png',
	'art/bakeoff/nova/nova_male-walk-v1.json',
	'art/bakeoff/nova/nova_male-jump-v1.png',
	'art/bakeoff/nova/nova_male-jump-v1.json',
	'art/bakeoff/nova/nova_male-fall-v1.png',
	'art/bakeoff/nova/nova_male-fall-v1.json',
	'art/bakeoff/nova/nova_male-hurt-v1.png',
	'art/bakeoff/nova/nova_male-hurt-v1.json',
	'art/bakeoff/nova/nova_male-shield-v1.png',
	'art/bakeoff/nova/nova_male-shield-v1.json',
	'art/bakeoff/nova/nova_male-attack-v1.png',
	'art/bakeoff/nova/nova_male-attack-v1.json',
	'art/bakeoff/nova/nova_male-vector_side-v1.png',
	'art/bakeoff/nova/nova_male-vector_side-v1.json',
	'art/bakeoff/nova/nova_male-vector_upper-v1.png',
	'art/bakeoff/nova/nova_male-vector_upper-v1.json',
	'art/bakeoff/nova/nova_male-compression_stomp-v1.png',
	'art/bakeoff/nova/nova_male-compression_stomp-v1.json',
	'art/bakeoff/nova/nova_male-air_side-v1.png',
	'art/bakeoff/nova/nova_male-air_side-v1.json',
	'art/bakeoff/nova/nova_male-meteor_kick-v1.png',
	'art/bakeoff/nova/nova_male-meteor_kick-v1.json',
	'art/bakeoff/nova/nova_male-vector_shift-v1.png',
	'art/bakeoff/nova/nova_male-vector_shift-v1.json',
	'art/bakeoff/nova/nova_male-gravity_brake-v1.png',
	'art/bakeoff/nova/nova_male-gravity_brake-v1.json',
	'art/bakeoff/nova/nova_male-slingshot_start-v1.png',
	'art/bakeoff/nova/nova_male-slingshot_start-v1.json',
	'art/bakeoff/nova/nova_male-tumble-v1.png',
	'art/bakeoff/nova/nova_male-tumble-v1.json'
)

git add -- $paths
git commit -m "art: build Nova male phase 2 rows`n`nCo-Authored-By: Codex <noreply@openai.com>"
