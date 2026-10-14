$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '../..')
Set-Location $repoRoot

git add -- 'art/bakeoff/frey/main' 'art/bakeoff/luna/main' 'reports/codex-art-47'
git commit -m "art: add Frey Luna main art candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
