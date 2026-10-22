$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$cache = Join-Path $env:TEMP 'SmashNine-QA21-cache'
$env:APPDATA = $cache
$env:LOCALAPPDATA = $cache
$env:GODOT_BIN = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$env:GODOT_TEST_LOG_DIR = Join-Path $PSScriptRoot 'suite'
$watch = [Diagnostics.Stopwatch]::StartNew()
& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'smash-nine-prototype/tests/run_all.ps1') -SoakRuns 1 | Tee-Object -FilePath (Join-Path $PSScriptRoot 'suite-summary.log')
$code = $LASTEXITCODE
"QA21 suite exit=$code wall=$([Math]::Round($watch.Elapsed.TotalSeconds,2))s" | Tee-Object -FilePath (Join-Path $PSScriptRoot 'suite-summary.log') -Append
$summaryPath = Join-Path $PSScriptRoot 'suite-summary.log'
[IO.File]::WriteAllText($summaryPath, [IO.File]::ReadAllText($summaryPath), [Text.UTF8Encoding]::new($false))
exit $code
