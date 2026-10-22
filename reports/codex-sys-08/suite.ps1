$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$env:APPDATA = Join-Path $env:TEMP 'SmashNine-SYS08-cache'
$env:LOCALAPPDATA = $env:APPDATA
$env:GODOT_TEST_LOG_DIR = Join-Path $PSScriptRoot 'suite'
$watch = [Diagnostics.Stopwatch]::StartNew()
Push-Location (Join-Path $repo 'smash-nine-prototype')
try {
    & powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 2>&1 | Tee-Object -FilePath (Join-Path $PSScriptRoot 'suite-summary.log')
    $code = $LASTEXITCODE
} finally { Pop-Location }
$meta = @{ exit = $code; wall_seconds = $watch.Elapsed.TotalSeconds; finished_utc = [DateTime]::UtcNow.ToString('o'); command = 'powershell -ExecutionPolicy Bypass -File tests/run_all.ps1'; full_suite_invocations = 1 }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'suite-meta.json'), ($meta | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
exit $code
