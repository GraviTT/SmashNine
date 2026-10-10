$ErrorActionPreference = "Stop"

$paths = @(
	"smash-nine-prototype/assets/art/effects/skill",
	"smash-nine-prototype/assets/art/effects/realm",
	"smash-nine-prototype/assets/art/realm_center/portal_anim.png",
	"smash-nine-prototype/assets/art/realm_center/portal_anim.png.import",
	"smash-nine-prototype/assets/art/effects/README.md",
	"smash-nine-prototype/scripts/Vfx.gd",
	"smash-nine-prototype/characters/luna/Luna.gd",
	"smash-nine-prototype/characters/luna/LunaComet.gd",
	"smash-nine-prototype/characters/nova/Nova.gd",
	"smash-nine-prototype/characters/nova/NovaGravityBurst.gd",
	"smash-nine-prototype/characters/rio/Rio.gd",
	"smash-nine-prototype/characters/yuki/YukiGrandWard.gd",
	"smash-nine-prototype/characters/common/PlayerBase.gd",
	"smash-nine-prototype/scripts/Attack.gd",
	"smash-nine-prototype/scripts/realms/RealmWorld.gd",
	"smash-nine-prototype/tests/test_skill_fx_art.gd",
	"smash-nine-prototype/tests/art_preview/skill_fx_24",
	"reports/codex-art-24"
)

git add -- $paths
git commit -m "Add authored skill and realm effects" -m "Co-Authored-By: Codex <noreply@openai.com>"
