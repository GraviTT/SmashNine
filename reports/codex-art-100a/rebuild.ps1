$ErrorActionPreference = 'Stop'
$env:PYTHONDONTWRITEBYTECODE = '1'
$env:PYTHONIOENCODING = 'utf-8'
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location -LiteralPath $repoRoot
try {
    & $py reports/codex-art-100a/process_row.py idle --attempt 2 --factor 0.24
    if ($LASTEXITCODE -ne 0) { throw 'idle normalization failed' }
    & $py reports/codex-art-100a/process_row.py attack --attempt 2 --factor 0.275
    if ($LASTEXITCODE -ne 0) { throw 'attack normalization failed' }
    & $py reports/codex-art-100a/process_row.py shield --factor 0.275 --anchor-x 176.5
    if ($LASTEXITCODE -ne 0) { throw 'shield normalization failed' }
    & $py reports/codex-art-100a/process_row.py victory --attempt 2 --factor 0.265
    if ($LASTEXITCODE -ne 0) { throw 'held victory normalization failed' }
    & $py reports/codex-art-100a/process_row.py defeat --factor 0.31
    if ($LASTEXITCODE -ne 0) { throw 'held defeat normalization failed' }
    & $py reports/codex-art-100a/finalize.py
    if ($LASTEXITCODE -ne 0) { throw 'packaging failed' }
}
finally { Pop-Location }
