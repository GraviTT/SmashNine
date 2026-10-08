param(
	[int]$Seed = 101,
	[int]$Count = 12,
	[int]$Seconds = 480,
	[int]$Players = 8
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$repo = (Resolve-Path (Join-Path $project '..')).Path
$godot = if ($env:GODOT_BIN) { $env:GODOT_BIN } else { 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' }
$runtime = Join-Path $env:TEMP 'codex-qa-14-godot'
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
$env:LOCALAPPDATA = $runtime
$env:APPDATA = $runtime

& $godot --headless --fixed-fps 60 --path $project -s 'tests/analysis/codex_qa_14/bot_behavior_probe.gd' -- "--seed=$Seed" "--count=$Count" "--seconds=$Seconds" "--players=$Players"
if ($LASTEXITCODE -ne 0) {
	exit $LASTEXITCODE
}

$result = Join-Path $repo 'reports/codex-qa-14/results.json'
Write-Host "Probe JSON: $result"
