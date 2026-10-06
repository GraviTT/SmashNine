# Runs every headless test and a bot-only match soak, and fails on any engine error.
# Usage (from smash-nine-prototype/):  powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 [-SoakSeconds 480] [-SoakRuns 1] [-SkipSoak]
# Set $env:GODOT_BIN to override the Godot console executable.
param(
	[int]$SoakSeconds = 480,
	[int]$SoakRuns = 1,
	[switch]$SkipSoak
)

$ErrorActionPreference = "Stop"
$godot = $env:GODOT_BIN
if (-not $godot) {
	$godot = Join-Path $env:USERPROFILE "Downloads\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe"
}
if (-not (Test-Path $godot)) {
	Write-Output "Godot console executable not found: $godot (set GODOT_BIN)"
	exit 2
}
$project = Split-Path -Parent $PSScriptRoot
$tests = @("test_character_architecture", "test_frey_sprite", "test_luna_prototype", "test_nova_prototype", "test_match_rules")
$failed = @()

function Invoke-Godot([string[]]$GodotArgs) {
	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.FileName = $godot
	$psi.Arguments = ($GodotArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
	$psi.WorkingDirectory = $project
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.UseShellExecute = $false
	$process = [System.Diagnostics.Process]::Start($psi)
	$stdoutTask = $process.StandardOutput.ReadToEndAsync()
	$stderr = $process.StandardError.ReadToEnd()
	$process.WaitForExit()
	return @{ Code = $process.ExitCode; Output = ($stdoutTask.Result + "`n" + $stderr) }
}

function Get-EngineErrors([string]$Text) {
	return @($Text -split "`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' })
}

foreach ($test in $tests) {
	if (-not (Test-Path (Join-Path $project "tests\$test.gd"))) { continue }
	$result = Invoke-Godot @("--headless", "--path", ".", "-s", "tests/$test.gd")
	$errors = Get-EngineErrors $result.Output
	if ($result.Code -ne 0 -or $errors.Count -gt 0) {
		$failed += $test
		Write-Output "FAIL $test (exit $($result.Code))"
		$result.Output -split "`n" | Select-Object -Last 25 | ForEach-Object { Write-Output "    $_" }
	} else {
		$last = ($result.Output -split "`n" | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^Godot Engine' } | Select-Object -Last 1)
		Write-Output "PASS $test  $last"
	}
}

if (-not $SkipSoak) {
	for ($run = 1; $run -le $SoakRuns; $run++) {
		$seed = 1000 + $run
		$result = Invoke-Godot @("--headless", "--path", ".", "--fixed-fps", "60", "-s", "tests/soak_match.gd", "--", "--seconds=$SoakSeconds", "--seed=$seed")
		$errors = Get-EngineErrors $result.Output
		$summary = ($result.Output -split "`n" | Where-Object { $_ -match '^SOAK_RESULT' } | Select-Object -Last 1)
		if ($result.Code -ne 0 -or $errors.Count -gt 0 -or -not $summary) {
			$failed += "soak#$run"
			Write-Output "FAIL soak run $run seed $seed (exit $($result.Code), $($errors.Count) engine errors)"
			$errors | Select-Object -First 10 | ForEach-Object { Write-Output "    $_" }
		} else {
			Write-Output "PASS soak run $run seed $seed  $summary"
		}
	}
}

if ($failed.Count -gt 0) {
	Write-Output "FAILED: $($failed -join ', ')"
	exit 1
}
Write-Output "ALL PASSED"
exit 0
