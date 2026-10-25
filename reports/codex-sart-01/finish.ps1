param(
    [string]$Python = 'C:/Users/TH/AppData/Local/Programs/Python/Python312/python.exe'
)

# Prepared handoff only. Not executed by this Codex run.
# Run from a user session that already has access to Python + Pillow.
# Installs nothing, downloads nothing, and does not commit or touch game files.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $repoRoot
try {
    & $Python -B -c 'import PIL; print(PIL.__version__)'
    if ($LASTEXITCODE -ne 0) { throw 'An existing accessible Python + Pillow environment is required.' }
    & $Python -B -u (Join-Path $PSScriptRoot 'build_candidates.py')
    if ($LASTEXITCODE -ne 0) { throw 'Candidate processing failed. Existing images are never overwritten.' }
    & $Python -B (Join-Path $PSScriptRoot 'make_report.py')
    if ($LASTEXITCODE -ne 0) { throw 'Report update failed.' }
    Write-Output 'Files built. Review every final PNG at 1600x900 and the contact sheets before running commit.ps1.'
}
finally {
    Pop-Location
}
