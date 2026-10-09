$ErrorActionPreference = "Stop"

git add -- `
  "smash-nine-prototype/assets/art/effects/passive" `
  "smash-nine-prototype/tests/art_preview/passive_marks_22" `
  "reports/codex-art-22"

git commit -m "art: add Frey and Luna passive marks`n`nCo-Authored-By: Codex <noreply@openai.com>"
