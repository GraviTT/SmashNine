$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $repo
$rows = @(
    @{ Name='attack'; Attempt=1; Factor='0.25'; Cell='128' },
    @{ Name='shield'; Attempt=1; Factor='0.225'; Cell='128' },
    @{ Name='victory'; Attempt=2; Factor='0.23'; Cell='192' }
)
foreach ($row in $rows) {
    $name = $row.Name
    $folder = "reports/codex-art-97a/$name-trial"
    & $py tools/sprite_pipeline/normalize.py --sheet "art/raw/xion-97a/$name-$($row.Attempt).png" --grid 6x1 --bg '#00ff00' --cell $row.Cell --scale-by "fixed:$($row.Factor)" --resample lanczos --sharpen 60 --despill auto --palette none --ground-all --reference art/bakeoff/xion/b/xion-idle-b2.png:0:6 --compare-scale 4 --title "XION $name" --out-dir $folder --name $name
    if ($LASTEXITCODE -ne 0) { throw "normalize failed: $name" }
    & $py tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b2.png:0 --sheet "$folder/$name.png" --frames 6 --factor $row.Factor --json "$folder/heads.json"
    if ($LASTEXITCODE -ne 0) { throw "head measurement failed: $name" }
}
foreach ($script in @('review.py','landmark_board.py','scarf_measure.py','feet_measure.py','finalize.py')) {
    & $py "reports/codex-art-97a/$script"
    if ($LASTEXITCODE -ne 0) { throw "report script failed: $script" }
}
