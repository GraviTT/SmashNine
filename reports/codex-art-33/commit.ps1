$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $repoRoot

git add -- `
	'smash-nine-prototype/assets/art/frey/frey_moves_body_sheet.png' `
	'smash-nine-prototype/assets/art/frey/frey_moves_body_sheet.png.import' `
	'smash-nine-prototype/assets/art/frey/frey_moves_fx_sheet.png' `
	'smash-nine-prototype/assets/art/frey/frey_moves_fx_sheet.png.import' `
	'smash-nine-prototype/assets/art/frey/frey_moves_sheet.png' `
	'smash-nine-prototype/assets/art/frey/frey_moves_sheet.png.import' `
	'smash-nine-prototype/assets/art/frey/frey_moves_heads.json' `
	'smash-nine-prototype/assets/art/frey/frey_moves_README.md' `
	'smash-nine-prototype/tests/art_preview/frey_redo_32/head_audit.gd' `
	'smash-nine-prototype/tests/art_preview/frey_heads_33' `
	'reports/codex-art-33'

git commit `
	-m 'art: rebuild Frey move sheet without pasted heads' `
	-m 'Co-Authored-By: Codex <noreply@openai.com>'
