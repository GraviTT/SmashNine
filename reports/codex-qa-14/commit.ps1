$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repo
try {
	git add -- 'smash-nine-prototype/tests/analysis/codex_qa_14' 'reports/codex-qa-14'
	if ($LASTEXITCODE -ne 0) { throw "git add failed with exit code $LASTEXITCODE" }
	git commit -m "Add QA-14 bot behavior probe and analysis`n`nCo-Authored-By: Codex <noreply@openai.com>"
	if ($LASTEXITCODE -ne 0) { throw "git commit failed with exit code $LASTEXITCODE" }
}
finally {
	Pop-Location
}
