$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repoRoot

$writablePaths = @(
	"smash-nine-prototype/assets/art/frey/frey_moves_sheet.png",
	"smash-nine-prototype/assets/art/frey/frey_moves_sheet.png.import",
	"smash-nine-prototype/assets/art/frey/frey_moves_body_sheet.png",
	"smash-nine-prototype/assets/art/frey/frey_moves_body_sheet.png.import",
	"smash-nine-prototype/assets/art/frey/frey_moves_fx_sheet.png",
	"smash-nine-prototype/assets/art/frey/frey_moves_fx_sheet.png.import",
	"smash-nine-prototype/assets/art/frey/frey_moves_heads.json",
	"smash-nine-prototype/assets/art/frey/frey_moves_README.md",
	"smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png",
	"smash-nine-prototype/tests/test_sprite_frames.gd",
	"smash-nine-prototype/tests/art_preview/frey_redo_32",
	"reports/codex-art-32"
)

git add -- $writablePaths

$message = @"
art: rebuild Frey move sheets under D32 rules

Co-Authored-By: Codex <noreply@openai.com>
"@

git commit -m $message
