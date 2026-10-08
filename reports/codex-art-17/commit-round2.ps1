$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

git -C $repoRoot add -- `
    'smash-nine-prototype/assets/art/hazards/README.md' `
    'smash-nine-prototype/assets/art/hazards/light_beam_mid.png' `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_mid.png' `
    'smash-nine-prototype/assets/art/hazards/quake_impact.png' `
    'smash-nine-prototype/tests/art_preview/hazard_art_17/round2_fix.gd' `
    'reports/codex-art-17/README.md' `
    'reports/codex-art-17/round2-godot.log' `
    'reports/codex-art-17/round2-verification.txt' `
    'reports/codex-art-17/round2_before_light_beam_mid.png' `
    'reports/codex-art-17/round2_before_fire_pillar_mid.png' `
    'reports/codex-art-17/round2_before_quake_impact.png' `
    'reports/codex-art-17/round2_mid_before_after_2x.png' `
    'reports/codex-art-17/round2_quake_before_after_2x.png' `
    'reports/codex-art-17/round2_tile_sequence_2x.png' `
    'reports/codex-art-17/commit-round2.ps1'

$message = @'
Fix hazard tiling and quake impact timing

Co-Authored-By: Codex <noreply@openai.com>
'@

git -C $repoRoot commit -m $message
