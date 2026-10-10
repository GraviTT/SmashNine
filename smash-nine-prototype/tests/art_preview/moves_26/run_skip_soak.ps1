param(
	[string]$GodotBin = "C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$repo = Split-Path -Parent $project
$logDir = Join-Path $repo "reports/codex-art-26/test-logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$tests = @(
	"test_character_architecture", "test_frey_sprite", "test_luna_prototype",
	"test_nova_prototype", "test_rio_prototype", "test_ultimates", "test_match_rules",
	"test_hazards", "test_soul_crystals", "test_art", "test_sprite_frames",
	"test_offscreen_markers", "test_relocation_active", "test_bot_panel", "test_skill_bar",
	"test_bot_brain", "test_talisman_burst", "test_flash_art", "test_ultimate_armor",
	"test_sprite_pose", "test_frey_kit", "test_luna_kit", "test_restart", "visual_preview"
)

$failed = @()

function Invoke-Godot([string[]]$GodotArgs) {
	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.FileName = $GodotBin
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

foreach ($test in $tests) {
	$script = Join-Path $project "tests/$test.gd"
	if (-not (Test-Path -LiteralPath $script)) { continue }
	$log = Join-Path $logDir "$test.log"
	$result = Invoke-Godot @("--headless", "--path", $project, "--log-file", $log, "-s", "tests/$test.gd")
	$output = $result.Output
	$code = $result.Code
	$errors = @($output -split "`n" | Where-Object {
		$_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and
		$_ -notmatch 'Failed to read the root certificate store'
	})
	if ($code -ne 0 -or $errors.Count -gt 0) {
		$failed += $test
		Write-Output "FAIL $test (exit $code, $($errors.Count) non-certificate engine errors)"
		$output -split "`n" | Select-Object -Last 25 | ForEach-Object { Write-Output "    $_" }
	} else {
		$last = ($output -split "`n" | Where-Object {
			$_.Trim() -ne "" -and
			$_ -notmatch '^Godot Engine' -and
			$_ -notmatch 'Failed to read the root certificate store' -and
			$_ -notmatch '^\s+at: get_system_ca_certificates'
		} | Select-Object -Last 1)
		Write-Output "PASS $test  $last"
	}
}

if ($failed.Count -gt 0) {
	Write-Output "FAILED: $($failed -join ', ')"
	exit 1
}
Write-Output "ALL PASSED (certificate-store sandbox noise excluded; soak skipped)"
exit 0
