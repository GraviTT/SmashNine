$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

git -C $repoRoot add -- `
    'smash-nine-prototype/assets/art/hazards/fire_pillar_mid.png' `
    'smash-nine-prototype/tests/art_preview/hazard_art_17/round4_fix.gd' `
    'reports/codex-art-17/README.md' `
    'reports/codex-art-17/round4-godot.log' `
    'reports/codex-art-17/round4-verification.txt' `
    'reports/codex-art-17/round4_before_fire_pillar_mid.png' `
    'reports/codex-art-17/round4_fire_before_after_4x.png' `
    'reports/codex-art-17/round4_fire_self_tiles_2x.png' `
    'reports/codex-art-17/commit-round4.ps1'

$message = @'
Smooth fire pillar internal dark rows

Co-Authored-By: Codex <noreply@openai.com>
'@

git -C $repoRoot commit -m $message
