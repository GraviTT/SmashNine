$ErrorActionPreference = "Stop"
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Push-Location $repoRoot
try {
	git add -- `
		"smash-nine-prototype/assets/art/realm_asgard" `
		"smash-nine-prototype/assets/art/realm_midgard" `
		"smash-nine-prototype/assets/art/realm_niflheim" `
		"smash-nine-prototype/assets/art/realm_alfheim" `
		"smash-nine-prototype/tests/art_preview/realms_a" `
		"reports/codex-art-04a"
	git diff --cached --check
	git commit -m "Add original art for four outer realms" -m "Co-Authored-By: Codex <noreply@openai.com>"
} finally {
	Pop-Location
}
