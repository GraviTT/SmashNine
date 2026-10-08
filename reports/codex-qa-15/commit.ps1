$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repo

git add -- "reports/codex-qa-15" "smash-nine-prototype/tests/analysis/codex_qa_15"
git commit -m "Add QA-15 in-game art review" -m "Co-Authored-By: Codex <noreply@openai.com>"
