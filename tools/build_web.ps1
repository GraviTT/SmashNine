# Exports the Godot project with the "Web" preset and zips it for upload (itch.io HTML5,
# or any static host). Output: build/web/ and build/SmashNine-web.zip
# Usage (from the repo root): powershell -ExecutionPolicy Bypass -File tools/build_web.ps1 [-PartMB 5]
# Needs the 4.7.stable web export templates in %APPDATA%\Godot\export_templates\4.7.stable.
# Files bigger than -PartMB MiB (the engine wasm, the game pck) are split into <name>.partN and
# joined in the browser by tools/web_part_loader.js: ChatGPT Sites rejected the 37.7 MiB wasm
# ("artifacts_git_receive_pack_object_too_large", 2026-10-07) and its largest accepted file we
# know of is 6.4 MB (CuRun). -PartMB 0 keeps whole files.
param([int]$PartMB = 5)
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

if ($PartMB -gt 0) {
	$partBytes = [long]$PartMB * 1MB
	$parts = [ordered]@{}
	foreach ($name in @("index.wasm", "index.pck")) {
		$file = Join-Path $webDir $name
		$size = (Get-Item $file).Length
		if ($size -le $partBytes) { continue }
		$bytes = [IO.File]::ReadAllBytes($file)
		$count = [int][Math]::Ceiling($size / $partBytes)
		for ($i = 0; $i -lt $count; $i++) {
			$offset = $i * $partBytes
			$length = [int][Math]::Min($partBytes, $size - $offset)
			$chunk = New-Object byte[] $length
			[Array]::Copy($bytes, $offset, $chunk, 0, $length)
			[IO.File]::WriteAllBytes((Join-Path $webDir "$name.part$i"), $chunk)
		}
		Remove-Item $file
		$parts[$name] = $count
	}
	if ($parts.Count -gt 0) {
		$map = ($parts.GetEnumerator() | ForEach-Object { "`"$($_.Key)`": $($_.Value)" }) -join ", "
		$loader = [IO.File]::ReadAllText((Join-Path $PSScriptRoot "web_part_loader.js")).Replace("/*PARTS*/{}", "{$map}")
		$html = Join-Path $webDir "index.html"
		$text = [IO.File]::ReadAllText($html)
		$engineTag = '<script src="index.js"></script>'
		if (-not $text.Contains($engineTag)) {
			Write-Output "index.html has no $engineTag to put the part loader before"
			exit 1
		}
		$text = $text.Replace($engineTag, "<script>`n$loader</script>`n`t`t$engineTag")
		[IO.File]::WriteAllText($html, $text, (New-Object Text.UTF8Encoding $false))
		Write-Output "Split into $PartMB MiB parts: $map"
	}
}

if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path (Join-Path $webDir "*") -DestinationPath $zip
$size = [Math]::Round((Get-Item $zip).Length / 1MB, 1)
$largest = Get-ChildItem $webDir -File | Sort-Object Length -Descending | Select-Object -First 1
Write-Output "Largest file: $($largest.Name) ($([Math]::Round($largest.Length / 1MB, 2)) MiB)"
Write-Output "Web build: $webDir"
Write-Output "Upload zip: $zip ($size MB). Local check: node tools/serve_web.js build/web 8060"
