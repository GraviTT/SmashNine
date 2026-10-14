$ErrorActionPreference = 'Stop'

$candidateFiles = @(
	'art/bakeoff/nova/nova_female-walk-v1.png',
	'art/bakeoff/nova/nova_female-walk-v1.json',
	'art/bakeoff/nova/nova_female-jump-v1.png',
	'art/bakeoff/nova/nova_female-jump-v1.json',
	'art/bakeoff/nova/nova_female-fall-v1.png',
	'art/bakeoff/nova/nova_female-fall-v1.json',
	'art/bakeoff/nova/nova_female-hurt-v1.png',
	'art/bakeoff/nova/nova_female-hurt-v1.json',
	'art/bakeoff/nova/nova_female-shield-v1.png',
	'art/bakeoff/nova/nova_female-shield-v1.json',
	'art/bakeoff/nova/nova_female-attack-v1.png',
	'art/bakeoff/nova/nova_female-attack-v1.json',
	'art/bakeoff/nova/nova_female-vector_side-v3.png',
	'art/bakeoff/nova/nova_female-vector_side-v3.json',
	'art/bakeoff/nova/nova_female-vector_upper-v1.png',
	'art/bakeoff/nova/nova_female-vector_upper-v1.json',
	'art/bakeoff/nova/nova_female-compression_stomp-v1.png',
	'art/bakeoff/nova/nova_female-compression_stomp-v1.json',
	'art/bakeoff/nova/nova_female-air_side-v1.png',
	'art/bakeoff/nova/nova_female-air_side-v1.json',
	'art/bakeoff/nova/nova_female-meteor_kick-v1.png',
	'art/bakeoff/nova/nova_female-meteor_kick-v1.json',
	'art/bakeoff/nova/nova_female-vector_shift-v1.png',
	'art/bakeoff/nova/nova_female-vector_shift-v1.json',
	'art/bakeoff/nova/nova_female-gravity_brake-v1.png',
	'art/bakeoff/nova/nova_female-gravity_brake-v1.json',
	'art/bakeoff/nova/nova_female-slingshot_start-v1.png',
	'art/bakeoff/nova/nova_female-slingshot_start-v1.json',
	'art/bakeoff/nova/nova_female-tumble-v1.png',
	'art/bakeoff/nova/nova_female-tumble-v1.json'
)

git add -- $candidateFiles
git add -- 'reports/codex-art-52b'

$staged = @(git diff --cached --name-only)
$unexpected = @($staged | Where-Object {
	($_ -notlike 'art/bakeoff/nova/nova_female-*') -and
	($_ -notlike 'reports/codex-art-52b/*')
})
if ($unexpected.Count -gt 0) {
	throw "Unexpected staged paths already exist; aborting commit: $($unexpected -join ', ')"
}
if ($staged | Where-Object { $_ -like 'art/raw/*' }) {
	throw 'art/raw must never be staged'
}

git commit -m "art: add Nova female phase 2 motion candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
