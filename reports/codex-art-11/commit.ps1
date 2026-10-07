$ErrorActionPreference = "Stop"

$paths = @(
	"smash-nine-prototype/assets/art/monsters/ember_fireball.png",
	"smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png",
	"smash-nine-prototype/assets/art/monsters/mossling_sheet.png",
	"smash-nine-prototype/assets/art/objects/soul_crystal.png",
	"smash-nine-prototype/assets/art/objects/soul_crystal_shatter.png",
	"smash-nine-prototype/tests/art_preview/monsters_v2_b",
	"reports/codex-art-11"
)

git add -- $paths

$staged = @(git diff --cached --name-only)
$allowed = @(
	"smash-nine-prototype/assets/art/monsters/",
	"smash-nine-prototype/assets/art/objects/",
	"smash-nine-prototype/tests/art_preview/monsters_v2_b/",
	"reports/codex-art-11/"
)

foreach ($file in $staged) {
	$permitted = $false
	foreach ($prefix in $allowed) {
		if ($file.StartsWith($prefix)) {
			$permitted = $true
			break
		}
	}
	if (-not $permitted) {
		throw "Staged path is outside CODEX-ART-11 writable paths: $file"
	}
}

git commit -m "art: redraw monsters and soul assets at 1x`n`nCo-Authored-By: Codex <noreply@openai.com>"
