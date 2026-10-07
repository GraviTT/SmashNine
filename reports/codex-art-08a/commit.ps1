$ErrorActionPreference = 'Stop'

git add -- `
  'smash-nine-prototype/assets/art/frey' `
  'smash-nine-prototype/assets/art/nova' `
  'smash-nine-prototype/assets/art/yuki' `
  'smash-nine-prototype/tests/art_preview/hires_a' `
  'reports/codex-art-08a'

git commit `
  -m 'art: rework unit A hi-res sprite sheets' `
  -m 'Co-Authored-By: Codex <noreply@openai.com>'
