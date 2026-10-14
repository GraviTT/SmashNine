$ErrorActionPreference = 'Stop'

$candidateNames = @(
	'yuki-walk-v1',
	'yuki-jump-v1',
	'yuki-fall-v1',
	'yuki-hurt-v1',
	'yuki-shield-v1',
	'yuki-attack-v1',
	'yuki-talisman_side-v3',
	'yuki-talisman_up-v1',
	'yuki-ground_ward-v1',
	'yuki-talisman_air_side-v1',
	'yuki-talisman_air_down-v1',
	'yuki-seal_place-v1',
	'yuki-seal_activate-v1',
	'yuki-grand_ward-v1',
	'yuki-tumble-v1'
)

$reportRows = @(
	'walk', 'jump', 'fall', 'hurt', 'shield', 'attack',
	'talisman_side', 'talisman_up', 'ground_ward',
	'talisman_air_side', 'talisman_air_down',
	'seal_place', 'seal_activate', 'grand_ward', 'tumble'
)

$paths = @(
	'reports/codex-art-49/README.md',
	'reports/codex-art-49/commit.ps1',
	'reports/codex-art-49/build_candidates.py',
	'reports/codex-art-49/summary.json',
	'reports/codex-art-49/overview.png'
)

foreach ($name in $candidateNames) {
	$paths += "art/bakeoff/yuki/$name.png"
	$paths += "art/bakeoff/yuki/$name.json"
}

foreach ($row in $reportRows) {
	$paths += "reports/codex-art-49/$row/prompt.txt"
	$paths += "reports/codex-art-49/$row/compare.png"
	$paths += "reports/codex-art-49/$row/metrics.json"
}

git add -- $paths
git commit -m 'art: add Yuki phase 2 motion candidates' -m 'Co-Authored-By: Codex <noreply@openai.com>'
