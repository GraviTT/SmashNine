$ErrorActionPreference = "Stop"

git add -- `
  smash-nine-prototype/assets/art/yuki `
  smash-nine-prototype/assets/art/nova `
  smash-nine-prototype/tests/art_preview/chars_a `
  reports/codex-art-03a

git commit `
  -m "art: add Yuki and Nova original sheets" `
  -m "Co-Authored-By: Codex <noreply@openai.com>"
