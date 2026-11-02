# Prepared for the lead. This script has NOT been executed by the builder.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$branch = (& git -C $repo branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/vfx-04') {
    throw 'Expected branch codex/vfx-04. Review the checkout before committing.'
}
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'delivery-files.txt') -Encoding UTF8 | Where-Object { $_ })
$assetPattern = '^art/bakeoff/(effects/luna/luna_(barrier(?:_break)?-[ab]|cyclone-[ab]|warp-[ab]|star_shot|star_big)-v1\.(png|json)|ui/status/luna_star_mark-v1\.(png|json)|skill_icons/luna/luna_(j|k|l|brave_k|brave_l)-v1\.(png|json))$'
foreach ($file in $files) {
    $allowed = $file -match $assetPattern -or $file -match '^reports/codex-vfx-04/[^/]+$' -or $file -eq 'design/tasks/CODEX-VFX-04.md'
    if (-not $allowed -or $file -match '(^|/)\.\.(/|$)|art/raw/|__pycache__') {
        throw "Out-of-scope path in manifest: $file"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $repo $file) -PathType Leaf)) {
        throw "Missing delivery file: $file"
    }
}
& git -C $repo add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit attempted.' }
& git -C $repo diff --cached --check -- @files
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed; no commit attempted.' }
& git -C $repo commit --only --file (Join-Path $PSScriptRoot 'commit-message.txt') -- @files
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
