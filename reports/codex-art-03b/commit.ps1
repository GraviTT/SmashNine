$ErrorActionPreference = "Stop"

$repo = Resolve-Path (Join-Path $PSScriptRoot "../..")
Push-Location $repo
try {
	git add -- `
		"smash-nine-prototype/assets/art/luna" `
		"smash-nine-prototype/assets/art/rio" `
		"smash-nine-prototype/tests/art_preview/chars_b" `
		"reports/codex-art-03b"
	git diff --cached --check
	git commit -m "art: add Luna and Rio original sheets" -m "Co-Authored-By: Codex <noreply@openai.com>"
}
finally {
	Pop-Location
}
