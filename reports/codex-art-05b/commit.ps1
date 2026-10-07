$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Push-Location $repoRoot
try {
	git add -- `
		"smash-nine-prototype/assets/art/effects" `
		"smash-nine-prototype/assets/art/ui" `
		"smash-nine-prototype/tests/art_preview/effects_b" `
		"reports/codex-art-05b"
	git commit -m "Add original combat effects and soul card icons" -m "Co-Authored-By: Codex <noreply@openai.com>"
} finally {
	Pop-Location
}
