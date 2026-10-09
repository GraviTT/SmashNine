$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../../..")
Set-Location $repoRoot

$allowedPaths = @(
	"reports/codex-qa-17/round-2-codex",
	"smash-nine-prototype/tests/analysis/codex_qa_17/analyze_nova_ringouts_r2b.js",
	"smash-nine-prototype/tests/analysis/codex_qa_17/combo_probe_r2b.gd",
	"smash-nine-prototype/tests/analysis/codex_qa_17/match_probe_r2b.gd"
)

git add -- $allowedPaths
git commit -m "QA-17 round 2b independent verification" -m "Co-Authored-By: Codex <noreply@openai.com>"
