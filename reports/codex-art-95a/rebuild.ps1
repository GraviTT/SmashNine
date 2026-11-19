$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:PYTHONIOENCODING = 'utf-8'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $py reports/codex-art-95a/process_illustrations.py
if ($LASTEXITCODE -ne 0) { throw 'Illustration processing failed' }
& $py tools/sprite_pipeline/normalize.py --sheet art/raw/xion-95a/c-idle-02.png --grid 1x1 --cell 128 --bg '#00ff00' --scale-by height:98 --resample lanczos --sharpen 60 --despill auto --palette none --reference smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0:6 --compare-scale 4 --ground-all --out-dir reports/codex-art-95a/normalize-c --name xion-idle-c
if ($LASTEXITCODE -ne 0) { throw 'C normalization failed' }
& $py tools/sprite_pipeline/normalize.py --sheet art/raw/xion-95a/d-idle-01.png --grid 1x1 --cell 128 --bg '#00ff00' --scale-by height:98 --resample lanczos --sharpen 60 --despill auto --palette none --reference smash-nine-prototype/assets/art/rio/rio_female_sheet.png:0:6 --compare-scale 4 --ground-all --out-dir reports/codex-art-95a/normalize-d --name xion-idle-d
if ($LASTEXITCODE -ne 0) { throw 'D normalization failed' }
& $py reports/codex-art-95a/package_review.py
if ($LASTEXITCODE -ne 0) { throw 'Review packaging failed' }
& $py reports/codex-art-95a/verify_delivery.py
if ($LASTEXITCODE -ne 0) { throw 'Delivery verification failed' }
