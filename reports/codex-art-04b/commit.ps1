$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
Push-Location $repoRoot
try {
	git add -- `
		"smash-nine-prototype/assets/art/realm_muspelheim" `
		"smash-nine-prototype/assets/art/realm_svartalfheim" `
		"smash-nine-prototype/assets/art/realm_vanaheim" `
		"smash-nine-prototype/assets/art/realm_jotunheim" `
		"smash-nine-prototype/tests/art_preview/realms_b" `
		"reports/codex-art-04b"
	git commit -m "Add original art for four outer realms" -m "Co-Authored-By: Codex <noreply@openai.com>"
}
finally {
	Pop-Location
}
