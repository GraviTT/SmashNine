$ErrorActionPreference = "Stop"
$repo = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repo

git add -- "smash-nine-prototype/tests/analysis/review03" "reports/codex-analyst-03"
git commit -m "Add independent review of Rio and realm additions" -m "Co-Authored-By: Codex <noreply@openai.com>"
