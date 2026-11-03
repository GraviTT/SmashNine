# Prepared only. This script was NOT run by the image builder.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = (git branch --show-current).Trim()
if ($branch -ne 'codex/vfx-05') { throw "Expected codex/vfx-05, got $branch" }
$files = @(
    'design/tasks/CODEX-VFX-05.md',
    'art/bakeoff/effects/nova/nova_gravity_root-a-v1.png',
    'art/bakeoff/effects/nova/nova_gravity_root-a-v1.json',
    'art/bakeoff/effects/nova/nova_gravity_root-b-v1.png',
    'art/bakeoff/effects/nova/nova_gravity_root-b-v1.json',
    'art/bakeoff/effects/nova/nova_orb-a-v1.png',
    'art/bakeoff/effects/nova/nova_orb-a-v1.json',
    'art/bakeoff/effects/nova/nova_orb-b-v1.png',
    'art/bakeoff/effects/nova/nova_orb-b-v1.json',
    'art/bakeoff/effects/nova/nova_field-a-v1.png',
    'art/bakeoff/effects/nova/nova_field-a-v1.json',
    'art/bakeoff/effects/nova/nova_field-b-v1.png',
    'art/bakeoff/effects/nova/nova_field-b-v1.json',
    'art/bakeoff/effects/nova/nova_beam_head-a-v1.png',
    'art/bakeoff/effects/nova/nova_beam_head-a-v1.json',
    'art/bakeoff/effects/nova/nova_beam_head-b-v1.png',
    'art/bakeoff/effects/nova/nova_beam_head-b-v1.json',
    'art/bakeoff/effects/nova/nova_beam_tile-a-v1.png',
    'art/bakeoff/effects/nova/nova_beam_tile-a-v1.json',
    'art/bakeoff/effects/nova/nova_beam_tile-b-v1.png',
    'art/bakeoff/effects/nova/nova_beam_tile-b-v1.json',
    'art/bakeoff/effects/nova/nova_sphere-a-v1.png',
    'art/bakeoff/effects/nova/nova_sphere-a-v1.json',
    'art/bakeoff/effects/nova/nova_sphere-b-v1.png',
    'art/bakeoff/effects/nova/nova_sphere-b-v1.json',
    'art/bakeoff/ui/status/nova_gravity_1-a-v1.png',
    'art/bakeoff/ui/status/nova_gravity_1-a-v1.json',
    'art/bakeoff/ui/status/nova_gravity_2-a-v1.png',
    'art/bakeoff/ui/status/nova_gravity_2-a-v1.json',
    'art/bakeoff/ui/status/nova_gravity_3-a-v1.png',
    'art/bakeoff/ui/status/nova_gravity_3-a-v1.json',
    'art/bakeoff/ui/status/nova_gravity_1-b-v1.png',
    'art/bakeoff/ui/status/nova_gravity_1-b-v1.json',
    'art/bakeoff/ui/status/nova_gravity_2-b-v1.png',
    'art/bakeoff/ui/status/nova_gravity_2-b-v1.json',
    'art/bakeoff/ui/status/nova_gravity_3-b-v1.png',
    'art/bakeoff/ui/status/nova_gravity_3-b-v1.json',
    'art/bakeoff/skill_icons/nova/nova_j-v1.png',
    'art/bakeoff/skill_icons/nova/nova_j-v1.json',
    'art/bakeoff/skill_icons/nova/nova_k-v1.png',
    'art/bakeoff/skill_icons/nova/nova_k-v1.json',
    'art/bakeoff/skill_icons/nova/nova_l-v1.png',
    'art/bakeoff/skill_icons/nova/nova_l-v1.json',
    'art/bakeoff/skill_icons/nova/nova_u-v1.png',
    'art/bakeoff/skill_icons/nova/nova_u-v1.json',
    'art/bakeoff/skill_icons/nova/nova_i-v1.png',
    'art/bakeoff/skill_icons/nova/nova_i-v1.json',
    'reports/codex-vfx-05/beams.png',
    'reports/codex-vfx-05/board.png',
    'reports/codex-vfx-05/build_boards.py',
    'reports/codex-vfx-05/build_effects.py',
    'reports/codex-vfx-05/build_ui.py',
    'reports/codex-vfx-05/field-a-4x-q1.png',
    'reports/codex-vfx-05/field-a-4x-q2.png',
    'reports/codex-vfx-05/field-a-4x-q3.png',
    'reports/codex-vfx-05/field-a-4x-q4.png',
    'reports/codex-vfx-05/field-b-4x-q1.png',
    'reports/codex-vfx-05/field-b-4x-q2.png',
    'reports/codex-vfx-05/field-b-4x-q3.png',
    'reports/codex-vfx-05/field-b-4x-q4.png',
    'reports/codex-vfx-05/field-phases-4x.png',
    'reports/codex-vfx-05/fields.png',
    'reports/codex-vfx-05/icons.png',
    'reports/codex-vfx-05/measurements.json',
    'reports/codex-vfx-05/orbs.png',
    'reports/codex-vfx-05/prepare_commit.py',
    'reports/codex-vfx-05/preview.html',
    'reports/codex-vfx-05/processing.json',
    'reports/codex-vfx-05/prompts.txt',
    'reports/codex-vfx-05/README.md',
    'reports/codex-vfx-05/roots.png',
    'reports/codex-vfx-05/sphere-a-4x.png',
    'reports/codex-vfx-05/sphere-a-full-4x.png',
    'reports/codex-vfx-05/sphere-b-4x.png',
    'reports/codex-vfx-05/sphere-b-full-4x.png',
    'reports/codex-vfx-05/spheres-a.png',
    'reports/codex-vfx-05/spheres-b.png',
    'reports/codex-vfx-05/stacks-4x.png',
    'reports/codex-vfx-05/stacks.png',
    'reports/codex-vfx-05/verify.py',
    'reports/codex-vfx-05/commit.ps1'
)
$stagedBefore = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
$unrelated = @($stagedBefore | Where-Object { $_ -notin $files })
if ($unrelated.Count -gt 0) { throw ('Unrelated files already staged: ' + ($unrelated -join ', ')) }
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
    if ($file.StartsWith('art/raw/') -or $file.StartsWith('smash-nine-prototype/') -or $file.Contains('__pycache__')) {
        throw "Forbidden delivery path: $file"
    }
}
git -c core.autocrlf=false add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
$stagedAfter = @(git diff --cached --name-only)
$unexpected = @($stagedAfter | Where-Object { $_ -notin $files })
if ($unexpected.Count -gt 0) { throw ('Unexpected staged file: ' + ($unexpected -join ', ')) }
$message = @'
art: add Nova gravity kit VFX-05 candidates and review boards

Deliver A/B gravity stacks, root, orb, field, beam and horizon sphere,
plus five HUD icons. Include metadata, imagegen prompts, exact-size
in-context boards, reproducible processing and asset validation.
No product source or adopted art changes; candidates await user picks.

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
