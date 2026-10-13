$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Push-Location $repo
try {
	git -c core.autocrlf=false add -- `
		"reports/codex-qa-18" `
		"smash-nine-prototype/tests/analysis/codex_qa_18/inspect_sprites.py" `
		"smash-nine-prototype/tests/analysis/codex_qa_18/.gitignore"
	git -c core.autocrlf=false commit `
		-m "qa: inspect all character sprite frames" `
		-m "Co-Authored-By: Codex <noreply@openai.com>"
} finally {
	Pop-Location
}
