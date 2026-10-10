$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Push-Location $repo
try {
	$requiredArtifacts = @(
		"smash-nine-prototype/tests/art_preview/moves_26/stripe_audit.gd",
		"smash-nine-prototype/tests/art_preview/moves_26/nova_male_stripe_changed_before_after.png",
		"smash-nine-prototype/tests/art_preview/moves_26/nova_female_stripe_changed_before_after.png",
		"smash-nine-prototype/tests/art_preview/moves_26/yuki_stripe_changed_before_after.png",
		"smash-nine-prototype/tests/art_preview/moves_26/rio_female_stripe_changed_before_after.png",
		"reports/codex-art-26/stripe-before-godot.log",
		"reports/codex-art-26/stripe-after-godot.log"
	)
	$missingArtifacts = @($requiredArtifacts | Where-Object { -not (Test-Path -LiteralPath $_) })
	if ($missingArtifacts.Count -gt 0) {
		throw "Missing stripe-audit artifacts: $($missingArtifacts -join ', ')"
	}
	$paths = @(
		"reports/codex-art-26",
		"smash-nine-prototype/assets/art/nova/nova_male_moves_README.md",
		"smash-nine-prototype/assets/art/nova/nova_male_moves_sheet.png",
		"smash-nine-prototype/assets/art/nova/nova_male_moves_sheet.png.import",
		"smash-nine-prototype/assets/art/nova/nova_male_moves_source.png",
		"smash-nine-prototype/assets/art/nova/nova_male_moves_source.png.import",
		"smash-nine-prototype/assets/art/nova/nova_female_moves_README.md",
		"smash-nine-prototype/assets/art/nova/nova_female_moves_sheet.png",
		"smash-nine-prototype/assets/art/nova/nova_female_moves_sheet.png.import",
		"smash-nine-prototype/assets/art/nova/nova_female_moves_source.png",
		"smash-nine-prototype/assets/art/nova/nova_female_moves_source.png.import",
		"smash-nine-prototype/assets/art/yuki/yuki_moves_README.md",
		"smash-nine-prototype/assets/art/yuki/yuki_moves_sheet.png",
		"smash-nine-prototype/assets/art/yuki/yuki_moves_sheet.png.import",
		"smash-nine-prototype/assets/art/yuki/yuki_moves_source.png",
		"smash-nine-prototype/assets/art/yuki/yuki_moves_source.png.import",
		"smash-nine-prototype/assets/art/rio/rio_male_moves_README.md",
		"smash-nine-prototype/assets/art/rio/rio_male_moves_sheet.png",
		"smash-nine-prototype/assets/art/rio/rio_male_moves_sheet.png.import",
		"smash-nine-prototype/assets/art/rio/rio_male_moves_source.png",
		"smash-nine-prototype/assets/art/rio/rio_male_moves_source.png.import",
		"smash-nine-prototype/assets/art/rio/rio_female_moves_README.md",
		"smash-nine-prototype/assets/art/rio/rio_female_moves_sheet.png",
		"smash-nine-prototype/assets/art/rio/rio_female_moves_sheet.png.import",
		"smash-nine-prototype/assets/art/rio/rio_female_moves_source.png",
		"smash-nine-prototype/assets/art/rio/rio_female_moves_source.png.import",
		"smash-nine-prototype/tests/art_preview/moves_26",
		"smash-nine-prototype/tests/test_sprite_frames.gd"
	)
	$existingPaths = @($paths | Where-Object { Test-Path -LiteralPath $_ })
	git add -- $existingPaths
	if ($LASTEXITCODE -ne 0) { throw "git add failed" }

	$staged = @(git diff --cached --name-only)
	$outside = @($staged | Where-Object {
		$_ -notmatch '^reports/codex-art-26/' -and
		$_ -notmatch '^smash-nine-prototype/tests/art_preview/moves_26/' -and
		$_ -notmatch '^smash-nine-prototype/tests/test_sprite_frames\.gd$' -and
		$_ -notmatch '^smash-nine-prototype/assets/art/nova/nova_(male|female)_moves_' -and
		$_ -notmatch '^smash-nine-prototype/assets/art/yuki/yuki_moves_' -and
		$_ -notmatch '^smash-nine-prototype/assets/art/rio/rio_(male|female)_moves_'
	})
	if ($outside.Count -gt 0) {
		throw "Refusing to commit staged paths outside CODEX-ART-26 scope: $($outside -join ', ')"
	}
	if ($staged.Count -eq 0) { throw "No CODEX-ART-26 changes were staged" }

	git commit -m "Remove residual move sheet effect stripes" -m "Co-Authored-By: Codex <noreply@openai.com>"
	if ($LASTEXITCODE -ne 0) { throw "git commit failed" }
} finally {
	Pop-Location
}
