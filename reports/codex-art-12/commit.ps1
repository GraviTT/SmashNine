$ErrorActionPreference = 'Stop'

git add -- `
  'smash-nine-prototype/assets/art/rio/rio_female_sheet.png' `
  'smash-nine-prototype/tests/art_preview/sprite_fix_a2' `
  'reports/codex-art-12/README.md' `
  'reports/codex-art-12/commit.ps1' `
  'reports/codex-art-12/verification.txt' `
  'reports/codex-art-12/rio_female_shield_row_after_2x.png' `
  'reports/codex-art-12/before_after/rio_female_before_after_3x.png' `
  'reports/codex-art-12/audit_final/frame_audit.csv' `
  'reports/codex-art-12/audit_final/frey_sheet_flags.png' `
  'reports/codex-art-12/audit_final/nova_female_sheet_flags.png' `
  'reports/codex-art-12/audit_final/rio_female_sheet_flags.png'

git commit -m "art: restore four Rio female shield frames" -m "Co-Authored-By: Codex <noreply@openai.com>"
