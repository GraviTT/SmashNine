$ErrorActionPreference = "Stop"

$expectedBranch = "codex/fx-28"
$branch = git branch --show-current
if ($branch -ne $expectedBranch) {
	throw "Expected branch $expectedBranch, got $branch"
}

git add -- `
	"smash-nine-prototype/assets/art/frey/frey_moves_sheet.png" `
	"smash-nine-prototype/assets/art/frey/README.md" `
	"smash-nine-prototype/assets/art/effects/hit" `
	"smash-nine-prototype/assets/art/effects/README.md" `
	"smash-nine-prototype/characters/common/PlayerBase.gd" `
	"smash-nine-prototype/tests/test_hit_sparks.gd" `
	"smash-nine-prototype/tests/art_preview/fx_28" `
	"reports/codex-art-28"

$message = @"
Add per-fighter hit sparks and status icons

Co-Authored-By: Codex <noreply@openai.com>
"@
git commit -m $message
