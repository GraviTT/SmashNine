$ErrorActionPreference = 'Stop'
$repo09 = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$project09 = Join-Path $repo09 'smash-nine-prototype'
$profile09 = Join-Path $env:TEMP 'smashnine-sys09-profile'
New-Item -ItemType Directory -Force -Path $profile09 | Out-Null
$env:APPDATA = $profile09
$env:LOCALAPPDATA = $profile09
$env:STORY_FACE_REPORT = Join-Path $PSScriptRoot 'face-results.json'
$godot09 = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$tests09 = @('test_story_faces') + @(Get-ChildItem -LiteralPath (Join-Path $project09 'tests') -Filter 'test_story_*.gd' | Where-Object { $_.BaseName -ne 'test_story_faces' } | Sort-Object Name | ForEach-Object { $_.BaseName })
$failed09 = @()
foreach ($test09 in $tests09) {
	$psi09 = New-Object System.Diagnostics.ProcessStartInfo
	$psi09.FileName = $godot09
	$psi09.Arguments = "--headless --path `"$project09`" -s tests/$test09.gd"
	$psi09.WorkingDirectory = $project09
	$psi09.UseShellExecute = $false
	$psi09.CreateNoWindow = $true
	$psi09.RedirectStandardOutput = $true
	$psi09.RedirectStandardError = $true
	$process09 = [Diagnostics.Process]::Start($psi09)
	$stdout09 = $process09.StandardOutput.ReadToEndAsync()
	$stderr09 = $process09.StandardError.ReadToEnd()
	$process09.WaitForExit()
	$output09 = $stdout09.Result + "`n" + $stderr09
	if ([Text.Encoding]::UTF8.GetByteCount($output09) -gt 1MB) { throw "Log exceeds 1 MB: $test09" }
	[IO.File]::WriteAllText((Join-Path $PSScriptRoot "$test09.log"), $output09)
	$errors09 = @($output09 -split "`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and $_.Trim() -ne 'ERROR: Failed to read the root certificate store.' })
	if ($process09.ExitCode -ne 0 -or $errors09.Count -gt 0) {
		$failed09 += $test09
		Write-Output "FAIL $test09 exit=$($process09.ExitCode)"
		$output09 -split "`n" | Select-Object -Last 16 | Write-Output
	} else {
		Write-Output "PASS $test09"
		$output09 -split "`n" | Where-Object { $_ -match '^STORY_FACES_RESULT' } | Write-Output
	}
}
Remove-Item Env:STORY_FACE_REPORT
if ($failed09.Count -gt 0) { throw "Failed: $($failed09 -join ', ')" }
Write-Output "FOCUSED ALL PASSED ($($tests09.Count) tests)"
