$ErrorActionPreference = 'Stop'

git add -- `
  'smash-nine-prototype/assets/art/rio' `
  'smash-nine-prototype/assets/art/luna' `
  'smash-nine-prototype/tests/art_preview/hires_b' `
  'reports/codex-art-08b'

git diff --cached --check
git commit -m 'art: rework Rio and Luna v2 sprite sheets' -m 'Co-Authored-By: Codex <noreply@openai.com>'
