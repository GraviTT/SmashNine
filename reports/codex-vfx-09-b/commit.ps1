param([switch]$CheckOnly)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path

# Literal paths: safe in Windows PowerShell 5.1, with no JSON array conversion.
$files = @(
    'art/bakeoff/effects/pixelfx/luna/b/bake-09.mjs'
    'art/bakeoff/effects/pixelfx/luna/b/luna_air_jump-b.json'
    'art/bakeoff/effects/pixelfx/luna/b/luna_air_jump-b.png'
    'art/bakeoff/effects/pixelfx/luna/b/luna_jump-b.json'
    'art/bakeoff/effects/pixelfx/luna/b/luna_jump-b.png'
    'art/bakeoff/effects/pixelfx/luna/b/luna_step-b.json'
    'art/bakeoff/effects/pixelfx/luna/b/luna_step-b.png'
    'art/bakeoff/effects/pixelfx/luna/b/src/luna-feet-b.mjs'
    'art/bakeoff/effects/pixelfx/luna/b/src/sn-luna-air-jump-b.js'
    'art/bakeoff/effects/pixelfx/luna/b/src/sn-luna-jump-b.js'
    'art/bakeoff/effects/pixelfx/luna/b/src/sn-luna-step-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/bake.mjs'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_down_air-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_down_air-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_hit_after-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_hit_after-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_hit_after_big-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_hit_after_big-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_low-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_low-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_1-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_1-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_2-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_2-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_3-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_rush_3-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_side_air-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_side_air-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_up-b.json'
    'art/bakeoff/effects/pixelfx/luna_brave/b/brave_up-b.png'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/brave-linger-b.mjs'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-down-air-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-hit-after-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-hit-after-big-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-low-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-rush-1-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-rush-2-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-rush-3-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-side-air-b.js'
    'art/bakeoff/effects/pixelfx/luna_brave/b/src/sn-brave-up-b.js'
    'reports/codex-vfx-09-b/README.md'
    'reports/codex-vfx-09-b/audit.mjs'
    'reports/codex-vfx-09-b/bake-lib.mjs'
    'reports/codex-vfx-09-b/bench-link.mjs'
    'reports/codex-vfx-09-b/board.png'
    'reports/codex-vfx-09-b/commit.ps1'
    'reports/codex-vfx-09-b/items.json'
    'reports/codex-vfx-09-b/measurements.json'
    'reports/codex-vfx-09-b/qa/brave_down_air-1.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-1x.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-2.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-3.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-4.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-5.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-6.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-7.png'
    'reports/codex-vfx-09-b/qa/brave_down_air-8.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after-1.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after-1x.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after-2.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after-3.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after_big-1.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after_big-1x.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after_big-2.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after_big-3.png'
    'reports/codex-vfx-09-b/qa/brave_hit_after_big-4.png'
    'reports/codex-vfx-09-b/qa/brave_low-1.png'
    'reports/codex-vfx-09-b/qa/brave_low-1x.png'
    'reports/codex-vfx-09-b/qa/brave_low-2.png'
    'reports/codex-vfx-09-b/qa/brave_low-3.png'
    'reports/codex-vfx-09-b/qa/brave_rush_1-1.png'
    'reports/codex-vfx-09-b/qa/brave_rush_1-1x.png'
    'reports/codex-vfx-09-b/qa/brave_rush_1-2.png'
    'reports/codex-vfx-09-b/qa/brave_rush_1-3.png'
    'reports/codex-vfx-09-b/qa/brave_rush_2-1.png'
    'reports/codex-vfx-09-b/qa/brave_rush_2-1x.png'
    'reports/codex-vfx-09-b/qa/brave_rush_2-2.png'
    'reports/codex-vfx-09-b/qa/brave_rush_2-3.png'
    'reports/codex-vfx-09-b/qa/brave_rush_3-1.png'
    'reports/codex-vfx-09-b/qa/brave_rush_3-1x.png'
    'reports/codex-vfx-09-b/qa/brave_rush_3-2.png'
    'reports/codex-vfx-09-b/qa/brave_rush_3-3.png'
    'reports/codex-vfx-09-b/qa/brave_rush_3-4.png'
    'reports/codex-vfx-09-b/qa/brave_side_air-1.png'
    'reports/codex-vfx-09-b/qa/brave_side_air-1x.png'
    'reports/codex-vfx-09-b/qa/brave_side_air-2.png'
    'reports/codex-vfx-09-b/qa/brave_side_air-3.png'
    'reports/codex-vfx-09-b/qa/brave_up-1.png'
    'reports/codex-vfx-09-b/qa/brave_up-1x.png'
    'reports/codex-vfx-09-b/qa/brave_up-2.png'
    'reports/codex-vfx-09-b/qa/brave_up-3.png'
    'reports/codex-vfx-09-b/qa/brave_up-4.png'
    'reports/codex-vfx-09-b/qa/brave_up-5.png'
    'reports/codex-vfx-09-b/qa/brave_up-6.png'
    'reports/codex-vfx-09-b/qa/brave_up-7.png'
    'reports/codex-vfx-09-b/qa/luna_air_jump-1.png'
    'reports/codex-vfx-09-b/qa/luna_air_jump-1x.png'
    'reports/codex-vfx-09-b/qa/luna_air_jump-2.png'
    'reports/codex-vfx-09-b/qa/luna_air_jump-3.png'
    'reports/codex-vfx-09-b/qa/luna_air_jump-4.png'
    'reports/codex-vfx-09-b/qa/luna_jump-1.png'
    'reports/codex-vfx-09-b/qa/luna_jump-1x.png'
    'reports/codex-vfx-09-b/qa/luna_jump-2.png'
    'reports/codex-vfx-09-b/qa/luna_jump-3.png'
    'reports/codex-vfx-09-b/qa/luna_step-1.png'
    'reports/codex-vfx-09-b/qa/luna_step-1x.png'
    'reports/codex-vfx-09-b/qa/luna_step-2.png'
    'reports/codex-vfx-09-b/references-fx.png'
    'reports/codex-vfx-09-b/references.mjs'
    'reports/codex-vfx-09-b/references.png'
    'reports/codex-vfx-09-b/render.mjs'
    'reports/codex-vfx-09-b/setup.mjs'
    'design/tasks/CODEX-VFX-09.md'
)

if (@($files | Select-Object -Unique).Count -ne $files.Count) {
    throw 'Duplicate paths in the commit list.'
}
foreach ($file in $files) {
    $allowed = $file.StartsWith('art/bakeoff/effects/pixelfx/luna/b/') -or
        $file.StartsWith('art/bakeoff/effects/pixelfx/luna_brave/b/') -or
        $file.StartsWith('reports/codex-vfx-09-b/') -or
        $file -eq 'design/tasks/CODEX-VFX-09.md'
    if (-not $allowed -or $file.Contains('..')) { throw "Out-of-scope path: $file" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $file) -PathType Leaf)) {
        throw "Missing file: $file"
    }
}
if ($CheckOnly) {
    Write-Output ("Validated {0} literal paths. No git changes made." -f $files.Count)
    return
}

git -C $repoRoot add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
git -C $repoRoot diff --cached --check -- $files
if ($LASTEXITCODE -ne 0) { throw 'Whitespace validation failed.' }
# --only excludes any unrelated files already staged by another task.
git -C $repoRoot commit --only -m 'art: add VFX-09 B Luna and Brave directional linger candidates' -- $files
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
