# Prepared by Codex; not executed. Run only when ready to commit these candidates.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$files = @(
    'design/tasks/CODEX-VFX-03.md'
    'art/bakeoff/effects/frey/frey_wings-a-v1.png'
    'art/bakeoff/effects/frey/frey_wings-a-v1.json'
    'art/bakeoff/effects/frey/frey_wings-b-v1.png'
    'art/bakeoff/effects/frey/frey_wings-b-v1.json'
    'art/bakeoff/effects/frey/frey_wave-a-v1.png'
    'art/bakeoff/effects/frey/frey_wave-a-v1.json'
    'art/bakeoff/effects/frey/frey_wave-b-v1.png'
    'art/bakeoff/effects/frey/frey_wave-b-v1.json'
    'art/bakeoff/effects/frey/frey_ult_light-a-v1.png'
    'art/bakeoff/effects/frey/frey_ult_light-a-v1.json'
    'art/bakeoff/effects/frey/frey_ult_light-b-v1.png'
    'art/bakeoff/effects/frey/frey_ult_light-b-v1.json'
    'art/bakeoff/ui/status/slow-a-v1.png'
    'art/bakeoff/ui/status/slow-a-v1.json'
    'art/bakeoff/ui/status/slow-b-v1.png'
    'art/bakeoff/ui/status/slow-b-v1.json'
    'art/bakeoff/skill_icons/frey/frey_k-a-v1.png'
    'art/bakeoff/skill_icons/frey/frey_k-a-v1.json'
    'art/bakeoff/skill_icons/frey/frey_k-b-v1.png'
    'art/bakeoff/skill_icons/frey/frey_k-b-v1.json'
    'reports/codex-vfx-03/README.md'
    'reports/codex-vfx-03/baseline-status.txt'
    'reports/codex-vfx-03/board.png'
    'reports/codex-vfx-03/board_manifest.json'
    'reports/codex-vfx-03/build_assets.py'
    'reports/codex-vfx-03/build_boards.py'
    'reports/codex-vfx-03/commit-syntax.json'
    'reports/codex-vfx-03/commit.ps1'
    'reports/codex-vfx-03/delivery_manifest.json'
    'reports/codex-vfx-03/disk-usage.json'
    'reports/codex-vfx-03/hover-reference.png'
    'reports/codex-vfx-03/icons_a_1x.png'
    'reports/codex-vfx-03/icons_a_4x.png'
    'reports/codex-vfx-03/icons_b_1x.png'
    'reports/codex-vfx-03/icons_b_4x.png'
    'reports/codex-vfx-03/light_a_display_2x.png'
    'reports/codex-vfx-03/light_a_f1_4x.png'
    'reports/codex-vfx-03/light_a_f2_4x.png'
    'reports/codex-vfx-03/light_a_f3_4x.png'
    'reports/codex-vfx-03/light_a_f4_4x.png'
    'reports/codex-vfx-03/light_a_f5_4x.png'
    'reports/codex-vfx-03/light_a_f6_4x.png'
    'reports/codex-vfx-03/light_b_display_2x.png'
    'reports/codex-vfx-03/light_b_f1_4x.png'
    'reports/codex-vfx-03/light_b_f2_4x.png'
    'reports/codex-vfx-03/light_b_f3_4x.png'
    'reports/codex-vfx-03/light_b_f4_4x.png'
    'reports/codex-vfx-03/light_b_f5_4x.png'
    'reports/codex-vfx-03/light_b_f6_4x.png'
    'reports/codex-vfx-03/measurements.json'
    'reports/codex-vfx-03/prepare.py'
    'reports/codex-vfx-03/processing.json'
    'reports/codex-vfx-03/product-baseline.json'
    'reports/codex-vfx-03/prompts.txt'
    'reports/codex-vfx-03/raw-info.json'
    'reports/codex-vfx-03/references.png'
    'reports/codex-vfx-03/slow_1x.png'
    'reports/codex-vfx-03/slow_4x.png'
    'reports/codex-vfx-03/source_roots_a.png'
    'reports/codex-vfx-03/source_roots_b.png'
    'reports/codex-vfx-03/verification.json'
    'reports/codex-vfx-03/verify_assets.py'
    'reports/codex-vfx-03/visual-review.json'
    'reports/codex-vfx-03/wave_a_1x.png'
    'reports/codex-vfx-03/wave_a_4x.png'
    'reports/codex-vfx-03/wave_b_1x.png'
    'reports/codex-vfx-03/wave_b_4x.png'
    'reports/codex-vfx-03/wings_a_1x.png'
    'reports/codex-vfx-03/wings_a_2x.png'
    'reports/codex-vfx-03/wings_a_4x.png'
    'reports/codex-vfx-03/wings_b_1x.png'
    'reports/codex-vfx-03/wings_b_2x.png'
    'reports/codex-vfx-03/wings_b_4x.png'

)
Push-Location $repoRoot
try {
    $branch = & git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/vfx-03') { throw 'Expected branch codex/vfx-03.' }
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing delivery file: $file" }
        if ($file.StartsWith('smash-nine-prototype/') -or $file.StartsWith('art/raw/') -or $file.Contains('__pycache__')) { throw "Forbidden path: $file" }
    }
    $staged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect index.' }
    foreach ($file in $staged) {
        if ($file -and $files -notcontains $file) { throw "Unrelated staged file: $file. Leave it untouched; commit this task separately." }
    }
    & git add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
    & git commit -m 'Add Frey VFX-03 A/B candidates and context review boards' -m 'Co-Authored-By: Codex <noreply@openai.com>'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally {
    Pop-Location
}
