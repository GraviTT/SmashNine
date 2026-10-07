$ErrorActionPreference = "Stop"

$repo = Resolve-Path (Join-Path $PSScriptRoot "../..")
Set-Location $repo

git add -- `
  reports/codex-qa-12 `
  smash-nine-prototype/tests/analysis/codex_qa_12

git commit -m "QA-12: review ultimate changes" -m "Co-Authored-By: Codex <noreply@openai.com>"
