$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location -LiteralPath $repoRoot

# CODEX-ART-20 writable paths only. Do not stage unrelated untracked files in this clone.
git add -- `
  'smash-nine-prototype/assets/art/effects/parry_flash.png' `
  'smash-nine-prototype/assets/art/effects/landing_dust.png' `
  'smash-nine-prototype/assets/art/effects/hit_streak.png' `
  'smash-nine-prototype/assets/art/effects/yuki_seal_break.png' `
  'smash-nine-prototype/assets/art/effects/README.md' `
  'smash-nine-prototype/tests/art_preview/flash_art_20' `
  'reports/codex-art-20'

git commit -m 'Add short flash effect art' -m 'Co-Authored-By: Codex <noreply@openai.com>'
