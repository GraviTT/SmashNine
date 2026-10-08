$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $repo

git add -- `
  'smash-nine-prototype/assets/art/attack_vfx' `
  'smash-nine-prototype/assets/art/rio/rio_male_sheet.png' `
  'smash-nine-prototype/assets/art/rio/rio_female_sheet.png' `
  'smash-nine-prototype/assets/art/frey/frey_sheet.png' `
  'smash-nine-prototype/tests/art_preview/attack_vfx_2x_a' `
  'reports/codex-art-16/README.md' `
  'reports/codex-art-16/verification.txt' `
  'reports/codex-art-16/measurements.csv' `
  'reports/codex-art-16/commit.ps1' `
  'reports/codex-art-16/attack_vfx_before_after.png' `
  'reports/codex-art-16/attack_vfx_all_frames.png' `
  'reports/codex-art-16/source' `
  'reports/codex-art-16/sheets' `
  'reports/codex-art-16/audit_final'

git commit -m 'Rebuild attack VFX and Rio/Frey frames' -m 'Co-Authored-By: Codex <noreply@openai.com>'
