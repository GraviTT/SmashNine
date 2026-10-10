$ErrorActionPreference = 'Stop'
$Repo = Resolve-Path (Join-Path $PSScriptRoot '../..')
Push-Location $Repo
try {
	git add -- `
		'smash-nine-prototype/assets/art/rio/rio_male_sheet.png' `
		'smash-nine-prototype/assets/art/rio/rio_male_sheet.png.import' `
		'smash-nine-prototype/assets/art/rio/rio_female_sheet.png' `
		'smash-nine-prototype/assets/art/rio/rio_female_sheet.png.import' `
		'smash-nine-prototype/assets/art/frey/frey_moves_sheet.png' `
		'smash-nine-prototype/assets/art/frey/frey_moves_sheet.png.import' `
		'smash-nine-prototype/assets/art/luna/luna_moves_sheet.png' `
		'smash-nine-prototype/assets/art/luna/luna_moves_sheet.png.import' `
		'smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png' `
		'smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png.import' `
		'smash-nine-prototype/tests/art_preview/moves_23/rio_male_sheet_v2.png' `
		'smash-nine-prototype/tests/art_preview/moves_23/rio_male_sheet_v2.png.import' `
		'smash-nine-prototype/tests/art_preview/moves_23/rio_female_sheet_v2.png' `
		'smash-nine-prototype/tests/art_preview/moves_23/rio_female_sheet_v2.png.import' `
		'smash-nine-prototype/tests/art_preview/margin_30/*.gd' `
		'smash-nine-prototype/tests/art_preview/margin_30/*.gd.uid' `
		'smash-nine-prototype/tests/art_preview/margin_30/*.png' `
		'smash-nine-prototype/tests/art_preview/margin_30/*.png.import' `
		'smash-nine-prototype/tests/art_preview/margin_30/margin_changes.csv' `
		'smash-nine-prototype/tests/art_preview/margin_30/margin_changes.csv.import' `
		'reports/codex-art-30/README.md' `
		'reports/codex-art-30/commit.ps1' `
		'reports/codex-art-30/run_filtered_tests.ps1' `
		'reports/codex-art-30/filtered-tests.txt'
	git commit -m "art: restore Rio sheets and enforce move margins`n`nCo-Authored-By: Codex <noreply@openai.com>"
} finally {
	Pop-Location
}
