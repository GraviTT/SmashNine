$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $Root
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:PYTHONIOENCODING = 'utf-8'
$Py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$Normalize = 'reports/codex-art-97b/normalize_trial.py'
$Jobs = @(
    @('walk-f1-a1', 'walk-f1', '0.102', '1x1', 'ground'),
    @('walk-f2-a1', 'walk-f2', '0.102', '1x1', 'ground'),
    @('walk-f3-a3', 'walk-f3-a3', '0.102', '1x1', 'ground'),
    @('walk-f4-a1', 'walk-f4', '0.11086957', '1x1', 'ground'),
    @('walk-f5-a1', 'walk-f5', '0.102', '1x1', 'ground'),
    @('walk-f6-a2', 'walk-f6-a2', '0.102', '1x1', 'ground'),
    @('walk-f7-a2', 'walk-f7-a2', '0.1055', '1x1', 'ground'),
    @('walk-f8-a1', 'walk-f8', '0.11086957', '1x1', 'ground'),
    @('jump-a1', 'jump', '0.18', '3x1', 'air:8'),
    @('fall-a2', 'fall-a2', '0.15', '2x1', 'air:8'),
    @('hurt-a1', 'hurt', '0.176', '3x1', 'ground'),
    @('land-a1', 'land', '0.145', '2x1', 'ground')
)
foreach ($Job in $Jobs) {
    & $Py $Normalize "art/raw/xion-97b/$($Job[0]).png" $Job[1] $Job[2] $Job[3] $Job[4]
    if ($LASTEXITCODE -ne 0) { throw "Normalise failed: $($Job[0])" }
}
& $Py reports/codex-art-97b/check_walk.py
if ($LASTEXITCODE -ne 0) { throw 'Walk assembly failed' }
& $Py tools/sprite_pipeline/walk_bob.py --strip reports/codex-art-97b/walk-before-bob.png --face 65,36,80,50 --out reports/codex-art-97b/walk-after-bob.png --report reports/codex-art-97b/bob.json --board reports/codex-art-97b/bob.png
if ($LASTEXITCODE -ne 0) { throw 'Walk bob failed' }
& $Py tools/sprite_pipeline/walk_feet.py --strip reports/codex-art-97b/walk-after-bob.png --onion reports/codex-art-97b/onion.png --report reports/codex-art-97b/feet.json
if ($LASTEXITCODE -ne 0) { throw 'Walk feet failed' }
foreach ($Script in @('review_assets.py', 'audit.py', 'publish.py')) {
    & $Py "reports/codex-art-97b/$Script"
    if ($LASTEXITCODE -ne 0) { throw "Failed: $Script" }
}
