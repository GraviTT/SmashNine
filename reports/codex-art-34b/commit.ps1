$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
Set-Location $repo

git add -- `
  "smash-nine-prototype/assets/art/nova/nova_male_sheet.png" `
  "smash-nine-prototype/assets/art/nova/nova_male_sheet.png.import" `
  "smash-nine-prototype/assets/art/nova/nova_female_sheet.png" `
  "smash-nine-prototype/assets/art/nova/nova_female_sheet.png.import" `
  "smash-nine-prototype/assets/art/nova/README.md" `
  "smash-nine-prototype/assets/art/luna/luna_sheet.png" `
  "smash-nine-prototype/assets/art/luna/luna_sheet.png.import" `
  "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png" `
  "smash-nine-prototype/assets/art/luna/luna_brave_sheet.png.import" `
  "smash-nine-prototype/assets/art/luna/README.md" `
  "smash-nine-prototype/assets/art/luna/luna_brave_README.md" `
  "smash-nine-prototype/tests/art_preview/walk_34/b" `
  "reports/codex-art-34b"

git diff --cached --check

git commit -m "Fix Nova and Luna walk scale and palettes" -m "Co-Authored-By: Codex <noreply@openai.com>"
