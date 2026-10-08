$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repoRoot
try {
	git add -- `
		'smash-nine-prototype/assets/art/effects' `
		'smash-nine-prototype/assets/art/vfx' `
		'smash-nine-prototype/tests/art_preview/fx_1x_b' `
		'reports/codex-art-14'
	git commit -m 'Redraw combat effects at 1x density' -m 'Co-Authored-By: Codex <noreply@openai.com>'
}
finally {
	Pop-Location
}
