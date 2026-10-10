$ErrorActionPreference = "Stop"

git add -- `
	"smash-nine-prototype/assets/art/monsters" `
	"smash-nine-prototype/scripts/realms/RealmCatalog.gd" `
	"smash-nine-prototype/scripts/RealmMonsterSpawner.gd" `
	"smash-nine-prototype/tests/test_realm_monsters.gd" `
	"smash-nine-prototype/tests/art_preview/monsters_31" `
	"reports/codex-art-31"

git commit -m "art: add second monster for every realm" -m "Co-Authored-By: Codex <noreply@openai.com>"
