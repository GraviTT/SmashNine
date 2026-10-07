$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

Push-Location $repoRoot
try {
	git add -- "smash-nine-prototype/assets/art/hazards" "smash-nine-prototype/tests/art_preview/hazards_a" "reports/codex-art-07"
	if ($LASTEXITCODE -ne 0) {
		throw "git add failed with exit code $LASTEXITCODE"
	}
	git commit -m "art: add realm hazard effects" -m "Co-Authored-By: Codex <noreply@openai.com>"
	if ($LASTEXITCODE -ne 0) {
		throw "git commit failed with exit code $LASTEXITCODE"
	}
}
finally {
	Pop-Location
}
