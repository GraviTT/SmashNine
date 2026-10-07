$ErrorActionPreference = 'Stop'

git add -- `
  'smash-nine-prototype/assets/art/monsters' `
  'smash-nine-prototype/assets/art/objects' `
  'smash-nine-prototype/tests/art_preview/monsters_a' `
  'reports/codex-art-05a'

git commit -m 'art: add monster and soul objective sprites' -m 'Co-Authored-By: Codex <noreply@openai.com>'
