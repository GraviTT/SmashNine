$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repo

git add -- `
  "smash-nine-prototype/assets/art/frey/frey_sheet.png" `
  "smash-nine-prototype/assets/art/luna/luna_sheet.png" `
  "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png" `
  "smash-nine-prototype/assets/art/nova/nova_male_sheet.png" `
  "smash-nine-prototype/assets/art/nova/nova_female_sheet.png" `
  "smash-nine-prototype/assets/art/rio/rio_male_sheet.png" `
  "smash-nine-prototype/assets/art/rio/rio_female_sheet.png" `
  "smash-nine-prototype/tests/art_preview/sprite_fix_a" `
  "reports/codex-art-09"

git commit -m "fix: repair v2 sprite frame clipping`n`nCo-Authored-By: Codex <noreply@openai.com>"
