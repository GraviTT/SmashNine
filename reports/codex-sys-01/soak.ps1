param([ValidateSet('before', 'after')][string]$Stage = 'after')
$ErrorActionPreference = 'Continue'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$taskAppData = Join-Path $env:TEMP 'SmashNine-sys01-appdata'
New-Item -ItemType Directory -Force $taskAppData | Out-Null
$env:APPDATA = $taskAppData
$env:LOCALAPPDATA = $taskAppData
$godot = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
Set-Location -LiteralPath $repo
foreach ($soakSeed in 1001..1003) {
    & $godot --headless --path smash-nine-prototype --fixed-fps 60 -s tests/soak_match.gd -- --seconds=480 --seed=$soakSeed --players=8 *> (Join-Path $PSScriptRoot "$Stage-$soakSeed.log")
    Write-Output "Finished $Stage $soakSeed (exit $LASTEXITCODE)"
}
