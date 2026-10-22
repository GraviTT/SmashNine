$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$cache = Join-Path $env:TEMP 'SmashNine-QA22-cache'
$env:APPDATA = $cache
$env:LOCALAPPDATA = $cache
$env:GODOT_TEST_LOG_DIR = Join-Path $PSScriptRoot 'suite'
$env:GODOT_BIN = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$watch = [Diagnostics.Stopwatch]::StartNew()
& powershell -ExecutionPolicy Bypass -File (Join-Path $repo 'smash-nine-prototype/tests/run_all.ps1') 2>&1 | Tee-Object -FilePath (Join-Path $PSScriptRoot 'suite-summary.log')
$code = $LASTEXITCODE
$summaryPath = Join-Path $PSScriptRoot 'suite-summary.log'
$summaryText = [IO.File]::ReadAllText($summaryPath).Replace("`r`n", "`n")
[IO.File]::WriteAllText($summaryPath, $summaryText, [Text.UTF8Encoding]::new($false))
@{ exit = $code; seconds = $watch.Elapsed.TotalSeconds } | ConvertTo-Json | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'suite-meta.json')
exit $code
