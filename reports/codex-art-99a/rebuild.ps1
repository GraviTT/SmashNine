$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location $repo
try {
    & $py reports/codex-art-99a/package_art.py prepare borok 1 borok1-illustration-v2.png '450,294,690,534'
    if ($LASTEXITCODE -ne 0) { throw 'Illustration 1 failed' }
    & $py reports/codex-art-99a/package_art.py prepare borok 2 borok2-illustration-v2.png '405,284,655,534'
    if ($LASTEXITCODE -ne 0) { throw 'Illustration 2 failed' }
    & $py reports/codex-art-99a/package_art.py prepare borok 3 borok3-illustration-v2.png '393,286,618,511'
    if ($LASTEXITCODE -ne 0) { throw 'Illustration 3 failed' }
    & $py reports/codex-art-99a/package_art.py prepare jupi 1 jupi1-illustration-v1.png '350,215,650,515'
    if ($LASTEXITCODE -ne 0) { throw 'Illustration Jupi failed' }
    $jobs = @(
        @('borok', '1', 'v6', 'height:109', 'rio/rio_female'),
        @('borok', '2', 'v6', 'height:111', 'rio/rio_female'),
        @('borok', '3', 'v2', 'height:108', 'rio/rio_female'),
        @('jupi', '1', 'v2', 'fixed:0.10538642', 'nova/nova_female')
    )
    foreach ($job in $jobs) {
        $c, $n, $v, $scale, $ref = $job
        $tag = "$c$n"
        $name = "$c-idle-$n"
        $out = "reports/codex-art-99a/normalize/$tag"
        & $py tools/sprite_pipeline/normalize.py --sheet "art/raw/newchar-99a/$tag-idle-$v.png" --grid 1x1 --bg '#00ff00' --cell 128 --scale-by $scale --feet-y 120 --resample lanczos --sharpen 60 --despill auto --palette none --reference "smash-nine-prototype/assets/art/${ref}_sheet.png:0:1" --compare-scale 4 --out-dir $out --name $name
        if ($LASTEXITCODE -ne 0) { throw "Normalize failed: $tag" }
        Copy-Item -LiteralPath "$out/frames/$name-00.png" -Destination "art/bakeoff/newchar-2026-11-26/$c/$n/$name.png"
    }
    & $py reports/codex-art-99a/package_art.py boards
    if ($LASTEXITCODE -ne 0) { throw 'Boards failed' }
    & $py reports/codex-art-99a/verify_delivery.py
    if ($LASTEXITCODE -ne 0) { throw 'Verification failed' }
} finally { Pop-Location }
