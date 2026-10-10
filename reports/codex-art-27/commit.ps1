$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repo

git add -- `
	"smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_sheet.png" `
	"smash-nine-prototype/assets/art/monsters/jotunheim_rune_golem_source.png" `
	"smash-nine-prototype/assets/art/ui/title_bg.png" `
	"smash-nine-prototype/assets/art/ui/title_bg_source.png" `
	"smash-nine-prototype/scripts/RealmMonster.gd" `
	"smash-nine-prototype/scripts/ui/MatchHud.gd" `
	"smash-nine-prototype/tests/test_hud_frames.gd" `
	"smash-nine-prototype/tests/test_hud_frames.gd.uid" `
	"smash-nine-prototype/tests/art_preview/monsters_ui_27" `
	"reports/codex-art-27"

git diff --cached --check
git commit -m "Wire HUD frames and repair review art" -m "Co-Authored-By: Codex <noreply@openai.com>"
