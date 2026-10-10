$ErrorActionPreference = "Stop"

git add -- `
	"smash-nine-prototype/assets/art/monsters" `
	"smash-nine-prototype/assets/art/ui" `
	"smash-nine-prototype/scripts/realms/RealmCatalog.gd" `
	"smash-nine-prototype/scripts/RealmMonsterSpawner.gd" `
	"smash-nine-prototype/scripts/RealmMonster.gd" `
	"smash-nine-prototype/scripts/ui/MatchHud.gd" `
	"smash-nine-prototype/tests/test_realm_monsters.gd" `
	"smash-nine-prototype/tests/test_realm_monsters.gd.uid" `
	"smash-nine-prototype/tests/art_preview/monsters_ui_25" `
	"reports/codex-art-25"

$message = @"
Add realm monsters and HUD art

Co-Authored-By: Codex <noreply@openai.com>
"@
git commit -m $message
