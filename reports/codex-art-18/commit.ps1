$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repo

git add -- `
  'smash-nine-prototype/assets/art/skill_icons' `
  'smash-nine-prototype/tests/art_preview/skill_icons_18' `
  'reports/codex-art-18'

git commit -m "Add HUD skill icons for six fighter forms`n`nCo-Authored-By: Codex <noreply@openai.com>"
