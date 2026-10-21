# Runs the unchanged error gate with only the documented certificate-store noise removed.
# Raw logs retain that noise and every other line. No packages are installed.
param([switch]$SkipSoak, [switch]$Capture)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$temporary = Join-Path $env:TEMP 'smashnine-sys02-checks'
New-Item -ItemType Directory -Force $temporary | Out-Null
$env:APPDATA = Join-Path $temporary 'AppData'
$env:LOCALAPPDATA = Join-Path $temporary 'LocalAppData'
New-Item -ItemType Directory -Force $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$env:SYS02_REAL_GODOT = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$env:SYS02_RAW_LOGS = Join-Path $PSScriptRoot 'raw-logs'
$wrapper = Join-Path $temporary ('GodotNoiseFilter-' + [Guid]::NewGuid().ToString('N') + '.exe')
Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'GodotNoiseFilter.cs'))) -Language CSharp -OutputAssembly $wrapper -OutputType ConsoleApplication
$previousGodot = $env:GODOT_BIN
try {
    $env:GODOT_BIN = $wrapper
    Set-Location $repo
    if ($Capture) {
        & $wrapper --path smash-nine-prototype --resolution 1280x720 -s tests/test_frontend_flow.gd -- --capture | Tee-Object (Join-Path $PSScriptRoot 'capture-run.log')
    } elseif ($SkipSoak) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File smash-nine-prototype/tests/run_all.ps1 -SkipSoak | Tee-Object (Join-Path $PSScriptRoot 'all-tests.log')
    } else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File smash-nine-prototype/tests/run_all.ps1 | Tee-Object (Join-Path $PSScriptRoot 'all-tests.log')
    }
    $result = $LASTEXITCODE
} finally {
    $env:GODOT_BIN = $previousGodot
}
exit $result
