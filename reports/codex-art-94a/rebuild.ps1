$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $py reports/codex-art-94a/process_illustration.py
if ($LASTEXITCODE -ne 0) { throw 'Illustration processing failed' }
& $py tools/sprite_pipeline/normalize.py --sheet art/raw/xion-94a/idle-03.png --grid 3x2 --cell 128 --bg '#00ff00' --scale-by height:97.5 --resample lanczos --sharpen 60 --despill auto --palette none --ground-all --reference smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0:6 --compare-scale 4 --title 'XION A IDLE / RIO FEMALE REFERENCE' --out-dir reports/codex-art-94a --name xion-idle-a --candidate-out art/bakeoff/xion/a/xion-idle-a.png
if ($LASTEXITCODE -ne 0) { throw 'Normalization failed' }
& $py tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/xion/a/xion-idle-a.png:0 --sheet art/bakeoff/xion/a/xion-idle-a.png --frames 6 --json reports/codex-art-94a/head-scale.json
if ($LASTEXITCODE -ne 0) { throw 'Head measurement failed' }
& $py reports/codex-art-94a/build_review.py
if ($LASTEXITCODE -ne 0) { throw 'Review build failed' }

