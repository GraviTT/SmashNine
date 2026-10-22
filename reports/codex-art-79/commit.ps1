# ART-79: reviewed allowlist only. This file is intentionally NOT executed by the builder.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-79') {
    throw 'Expected branch codex/art-79. No files have been staged.'
}
$files = @(
    'art/bakeoff/monsters/ember_imp-projectile-v1.png',
    'art/bakeoff/monsters/ember_imp-projectile-v1.json',
    'art/bakeoff/monsters/niflheim_frost_owl-projectile-v1.png',
    'art/bakeoff/monsters/niflheim_frost_owl-projectile-v1.json',
    'art/bakeoff/monsters/jotunheim_storm_wisp-projectile-v1.png',
    'art/bakeoff/monsters/jotunheim_storm_wisp-projectile-v1.json',
    'art/bakeoff/monsters/midgard_rooftop_slinger-projectile-v1.png',
    'art/bakeoff/monsters/midgard_rooftop_slinger-projectile-v1.json',
    'art/bakeoff/monsters/vanaheim_seed_sprite-projectile-v1.png',
    'art/bakeoff/monsters/vanaheim_seed_sprite-projectile-v1.json',
    'art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v1.png',
    'art/bakeoff/monsters/svartalfheim_cog_drone-projectile-v1.json',
    'art/bakeoff/monsters/yggdrasil_root_oracle-projectile-v1.png',
    'art/bakeoff/monsters/yggdrasil_root_oracle-projectile-v1.json',
    'art/bakeoff/monsters/slam_shockwave-v1.png',
    'art/bakeoff/monsters/slam_shockwave-v1.json',
    'reports/codex-art-79/ember_imp.png',
    'reports/codex-art-79/niflheim_frost_owl.png',
    'reports/codex-art-79/jotunheim_storm_wisp.png',
    'reports/codex-art-79/midgard_rooftop_slinger.png',
    'reports/codex-art-79/vanaheim_seed_sprite.png',
    'reports/codex-art-79/svartalfheim_cog_drone.png',
    'reports/codex-art-79/yggdrasil_root_oracle.png',
    'reports/codex-art-79/slam_shockwave.png',
    'reports/codex-art-79/overview.png',
    'reports/codex-art-79/overview_compact.png',
    'reports/codex-art-79/slam_shared_context.png',
    'reports/codex-art-79/build.py',
    'reports/codex-art-79/measurements.json',
    'reports/codex-art-79/prompts.txt',
    'reports/codex-art-79/README.md',
    'reports/codex-art-79/sources.json',
    'reports/codex-art-79/commit.ps1'
)
foreach ($path in $files) {
    if ($path -match '(^art/raw/|(^|/)__pycache__(/|$)|(^|/)run\.log$)') {
        throw "Forbidden path in allowlist: $path"
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing deliverable: $path"
    }
}
$stagedBefore = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the index.' }
$unexpected = @($stagedBefore | Where-Object { $_ -and $_ -notin $files })
if ($unexpected.Count -gt 0) {
    throw ('Unrelated files are already staged; preserve them and review separately: ' + ($unexpected -join ', '))
}
& git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed; no commit was attempted.' }
$stagedAfter = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not verify the staged files.' }
$unexpected = @($stagedAfter | Where-Object { $_ -and $_ -notin $files })
if ($unexpected.Count -gt 0) { throw 'The index contains files outside the ART-79 allowlist.' }
if ($stagedAfter.Count -eq 0) { throw 'No ART-79 changes to commit.' }
& git diff --cached --stat
if ($LASTEXITCODE -ne 0) { throw 'Could not show the staged summary.' }
& git commit -m 'art: add monster projectile and slam shockwave candidates (ART-79)' -m 'Add eight four-frame candidate strips, metadata, and measured visual review boards. Candidates only; game wiring is unchanged.' -m 'Co-Authored-By: Codex <noreply@openai.com>'
if ($LASTEXITCODE -ne 0) { throw 'Commit failed. Review the index before retrying.' }
