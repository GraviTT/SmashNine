# Exports the Godot project with the "Web" preset and zips it for upload (itch.io HTML5,
# or any static host). Output: build/web/ and build/SmashNine-web.zip
# Usage (from the repo root): powershell -ExecutionPolicy Bypass -File tools/build_web.ps1
# Needs the 4.7.stable web export templates in %APPDATA%\Godot\export_templates\4.7.stable.
$ErrorActionPreference = "Stop"
$godot = $env:GODOT_BIN
if (-not $godot) {
	$godot = Join-Path $env:USERPROFILE "Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
}
$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo "smash-nine-prototype"
$webDir = Join-Path $repo "build\web"
$zip = Join-Path $repo "build\SmashNine-web.zip"
if (Test-Path $webDir) { Remove-Item -Recurse -Force $webDir }
New-Item -ItemType Directory -Force -Path $webDir | Out-Null

$process = Start-Process -FilePath $godot -ArgumentList @("--headless", "--path", "`"$project`"", "--export-release", "Web", "`"$webDir\index.html`"") -NoNewWindow -Wait -PassThru
if ($process.ExitCode -ne 0 -or -not (Test-Path (Join-Path $webDir "index.wasm"))) {
	Write-Output "Web export failed (exit $($process.ExitCode))"
	exit 1
}
if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path (Join-Path $webDir "*") -DestinationPath $zip
$size = [Math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Output "Web build: $webDir"
Write-Output "Upload zip: $zip ($size MB). Local check: node tools/serve_web.js build/web 8060"
