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
$runtime = Join-Path $env:TEMP 'codex-qa-14-godot-r9'
$reportDir = Join-Path $repo 'reports/codex-qa-14'
New-Item -ItemType Directory -Force -Path $runtime | Out-Null
$env:LOCALAPPDATA = $runtime
$env:APPDATA = $runtime

for ($offset = 0; $offset -lt $Count; $offset++) {
	$currentSeed = $Seed + $offset
	$log = Join-Path $reportDir "probe-round9-seed-$currentSeed.log"
	& $godot --headless --fixed-fps 60 --log-file $log --path $project -s 'tests/analysis/codex_qa_14/bot_behavior_probe_round9.gd' -- "--seed=$currentSeed" '--count=1' "--seconds=$Seconds" "--players=$Players"
	Write-Host "Seed $currentSeed exit code: $LASTEXITCODE"
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
	$source = Join-Path $reportDir 'round9-results.json'
	$destination = Join-Path $reportDir "round9-seed-$currentSeed.json"
	Copy-Item -LiteralPath $source -Destination $destination -Force
}

if ($Seed -eq 101 -and $Count -eq 12) {
	& (Join-Path $PSScriptRoot 'merge_round9.ps1') -ReportDir $reportDir
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
	& node (Join-Path $PSScriptRoot 'summarize_round4.js') 'round9'
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
	& node (Join-Path $PSScriptRoot 'summarize_round9_recovery.js')
	if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Probe JSON: $(Join-Path $reportDir 'round9-results.json')"
