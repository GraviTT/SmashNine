$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:PYTHONIOENCODING = 'utf-8'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location $root
try {
    & $py reports/codex-art-96b/normalize_idle.py
    if ($LASTEXITCODE -ne 0) { throw 'Normalization failed' }
    & $py tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b2.png:0 --sheet art/bakeoff/xion/b/xion-idle-b2.png --json reports/codex-art-96b/head-self.json
    if ($LASTEXITCODE -ne 0) { throw 'Self head measurement failed' }
    & $py tools/sprite_pipeline/head_scale.py --anchor smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0 --sheet art/bakeoff/xion/b/xion-idle-b2.png --json reports/codex-art-96b/head-rio.json
    if ($LASTEXITCODE -ne 0) { throw 'Rio head measurement failed' }
    & $py tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b.png:0 --sheet art/bakeoff/xion/b/xion-idle-b2.png --json reports/codex-art-96b/head-v1.json
    if ($LASTEXITCODE -ne 0) { throw 'V1 head measurement failed' }
    & $py reports/codex-art-96b/package_review.py
    if ($LASTEXITCODE -ne 0) { throw 'Packaging failed' }
    & $py reports/codex-art-96b/verify_delivery.py
    if ($LASTEXITCODE -ne 0) { throw 'Verification failed' }
} finally {
    Pop-Location
}
