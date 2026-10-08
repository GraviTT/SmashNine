$ErrorActionPreference = 'Stop'

git add -- `
  'smash-nine-prototype/assets/art/realm_*/bg_far.png' `
  'smash-nine-prototype/assets/art/realm_*/bg_mid.png' `
  'smash-nine-prototype/assets/art/realm_*/README.md' `
  'smash-nine-prototype/tests/art_preview/realm_bg_c/**' `
  'reports/codex-art-15/**'

$commitMessage = @'
Replace realm backgrounds for 1.5x world scale

Co-Authored-By: Codex <noreply@openai.com>
'@

git commit -m $commitMessage
