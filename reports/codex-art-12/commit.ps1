$ErrorActionPreference = 'Stop'

# Round 2 only. Deliberately excludes the existing Round 1 audit/baseline files.
git add -- `
  'smash-nine-prototype/assets/art/rio/rio_female_sheet.png' `
  'smash-nine-prototype/assets/art/frey/frey_sheet.png' `
  'smash-nine-prototype/assets/art/luna/luna_sheet.png' `
  'smash-nine-prototype/assets/art/nova/nova_female_sheet.png' `
  'smash-nine-prototype/tests/art_preview/sprite_fix_a3' `
  'reports/codex-art-12/round2' `
  'reports/codex-art-12/commit.ps1'

git commit -m 'art: restore nine cut attack frames' -m 'Co-Authored-By: Codex <noreply@openai.com>'
