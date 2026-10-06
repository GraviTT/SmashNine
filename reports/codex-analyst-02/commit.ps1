$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repo

git add -- "smash-nine-prototype/tests/analysis" "reports/codex-analyst-02"
git commit -m "Retest M1 analyst fixes" -m "Co-Authored-By: Codex <noreply@openai.com>"
