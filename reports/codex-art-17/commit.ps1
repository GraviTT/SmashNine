$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

git -C $repoRoot add -- `
    'smash-nine-prototype/assets/art/hazards/README.md' `
    'smash-nine-prototype/assets/art/hazards/vine_bridge.png' `
    'smash-nine-prototype/assets/art/hazards/quake_warning.png' `
    'smash-nine-prototype/assets/art/hazards/quake_impact.png' `
    'smash-nine-prototype/assets/art/hazards/light_beam_base.png' `
    'smash-nine-prototype/assets/art/hazards/light_beam_mid.png' `
    'smash-nine-prototype/assets/art/hazards/light_beam_top.png' `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_base.png' `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_mid.png' `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_top.png' `
    'smash-nine-prototype/assets/art/monsters/README.md' `
    'smash-nine-prototype/assets/art/monsters/mossling_sheet.png' `
    'smash-nine-prototype/assets/art/monsters/ember_imp_sheet.png' `
    'smash-nine-prototype/assets/art/effects/yuki_seal_idle.png' `
    'smash-nine-prototype/tests/art_preview/hazard_art_17' `
    'reports/codex-art-17'

$message = @'
Add hazard, monster rim, and Yuki seal art

Co-Authored-By: Codex <noreply@openai.com>
'@

git -C $repoRoot commit -m $message
