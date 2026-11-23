$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
Set-Location -LiteralPath $repo
foreach ($row in @(
    @{ Name = 'victory'; Factor = '0.230' },
    @{ Name = 'defeat'; Factor = '0.205' }
)) {
    & $py reports/codex-art-97a-fix/normalize_fix.py $row.Name --factor $row.Factor
    if ($LASTEXITCODE -ne 0) { throw "normalize failed: $($row.Name)" }
    & $py tools/sprite_pipeline/head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b2.png:0 --sheet "reports/codex-art-97a-fix/$($row.Name)-normalized/$($row.Name).png" --frames 6 --factor $row.Factor --json "reports/codex-art-97a-fix/$($row.Name)-normalized/heads.json"
    if ($LASTEXITCODE -ne 0) { throw "head measurement failed: $($row.Name)" }
}
foreach ($script in @('review.py', 'finalize.py', 'verify.py')) {
    & $py "reports/codex-art-97a-fix/$script"
    if ($LASTEXITCODE -ne 0) { throw "report failed: $script" }
}
