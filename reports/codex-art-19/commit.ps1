$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo
git add -- reports/codex-art-19 reports/bot-behavior/bot-behavior-tree.png
git commit -m "Add bot behaviour tree explainer" -m "Co-Authored-By: Codex <noreply@openai.com>"
