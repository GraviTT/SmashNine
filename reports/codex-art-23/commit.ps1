$ErrorActionPreference = "Stop"

git add -- `
	"smash-nine-prototype/assets/art/frey/frey_moves_README.md" `
	"smash-nine-prototype/assets/art/frey/frey_moves_sheet.png" `
	"smash-nine-prototype/assets/art/frey/frey_moves_sheet.png.import" `
	"smash-nine-prototype/assets/art/frey/frey_moves_source.png" `
	"smash-nine-prototype/assets/art/frey/frey_moves_source.png.import" `
	"smash-nine-prototype/assets/art/luna/luna_moves_README.md" `
	"smash-nine-prototype/assets/art/luna/luna_moves_sheet.png" `
	"smash-nine-prototype/assets/art/luna/luna_moves_sheet.png.import" `
	"smash-nine-prototype/assets/art/luna/luna_moves_source.png" `
	"smash-nine-prototype/assets/art/luna/luna_moves_source.png.import" `
	"smash-nine-prototype/assets/art/luna/luna_brave_moves_README.md" `
	"smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png" `
	"smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png.import" `
	"smash-nine-prototype/assets/art/luna/luna_brave_moves_source.png" `
	"smash-nine-prototype/assets/art/luna/luna_brave_moves_source.png.import" `
	"smash-nine-prototype/scripts/ArtSettings.gd" `
	"smash-nine-prototype/characters/common/PlayerBase.gd" `
	"smash-nine-prototype/characters/frey/Frey.gd" `
	"smash-nine-prototype/characters/luna/Luna.gd" `
	"smash-nine-prototype/tests/test_moves_sheet.gd" `
	"smash-nine-prototype/tests/art_preview/moves_23/*.gd" `
	"smash-nine-prototype/tests/art_preview/moves_23/*.png" `
	"smash-nine-prototype/tests/art_preview/moves_23/*_measurements.csv" `
	"reports/codex-art-23/README.md" `
	"reports/codex-art-23/commit.ps1"

git commit -m "Fix move atlas edges and add tumble rows" -m "Co-Authored-By: Codex <noreply@openai.com>"
