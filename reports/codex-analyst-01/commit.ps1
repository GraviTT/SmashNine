$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repo

git add -- "smash-nine-prototype/tests/analysis" "reports/codex-analyst-01"
git commit -m "Add M1 analyst balance sweep" -m "Co-Authored-By: Codex <noreply@openai.com>"
