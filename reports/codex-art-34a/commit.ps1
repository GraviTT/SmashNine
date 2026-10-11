$ErrorActionPreference = 'Stop'

git add -- `
  smash-nine-prototype/assets/art/frey/frey_sheet.png `
  smash-nine-prototype/assets/art/rio/rio_male_sheet.png `
  smash-nine-prototype/assets/art/rio/rio_female_sheet.png `
  smash-nine-prototype/assets/art/yuki/yuki_sheet.png `
  smash-nine-prototype/tests/art_preview/walk_34/a `
  reports/codex-art-34a

git commit -m @"
art: redraw readable walk cycles for fighter set A

Co-Authored-By: Codex <noreply@openai.com>
"@

