$ErrorActionPreference = 'Stop'

Set-Location (Resolve-Path "$PSScriptRoot/../..")

$paths = @(
	'reports/codex-art-56'
)

if (Test-Path 'art/bakeoff/frey/frey-walk-v5.png') {
	$paths += 'art/bakeoff/frey/frey-walk-v5.png'
	$paths += 'art/bakeoff/frey/frey-walk-v5.json'
}
if (Test-Path 'art/bakeoff/luna/luna-walk-v4.png') {
	$paths += 'art/bakeoff/luna/luna-walk-v4.png'
	$paths += 'art/bakeoff/luna/luna-walk-v4.json'
}

git add -- $paths
git commit -m "art: report third walk-cycle pass failures`n`nCo-Authored-By: Codex <noreply@openai.com>"
