$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

git -C $repoRoot add -- `
    'smash-nine-prototype/assets/art/hazards/README.md' `
    'smash-nine-prototype/assets/art/hazards/light_beam_mid.png' `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_mid.png' `
    'smash-nine-prototype/tests/art_preview/hazard_art_17/round3_fix.gd' `
    'reports/codex-art-17/README.md' `
    'reports/codex-art-17/round3-godot.log' `
    'reports/codex-art-17/round3-verification.txt' `
    'reports/codex-art-17/round3_before_light_beam_mid.png' `
    'reports/codex-art-17/round3_before_fire_pillar_mid.png' `
    'reports/codex-art-17/round3_self_tiles_2x.png' `
    'reports/codex-art-17/round3_joints_before_after_4x.png' `
    'reports/codex-art-17/commit-round3.ps1'

$message = @'
Fix hazard column self-tiling joints

Co-Authored-By: Codex <noreply@openai.com>
'@

git -C $repoRoot commit -m $message
