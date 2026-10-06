param(
	[int]$Players = 8,
	[int]$FirstSeed = 1,
	[int]$SeedCount = 30,
	[int]$Seconds = 480,
	[string]$GodotBin = "C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe",
	[string]$OutputJsonl = "../reports/codex-analyst-01/raw/results.jsonl",
	[string]$OutputLog = "../reports/codex-analyst-01/raw/sweep.log"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$jsonPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputJsonl))
$logPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputLog))
New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($jsonPath)) | Out-Null
Set-Content -LiteralPath $jsonPath -Value "" -NoNewline
Set-Content -LiteralPath $logPath -Value "" -NoNewline
$failedRuns = @()

for ($offset = 0; $offset -lt $SeedCount; $offset++) {
	$seed = $FirstSeed + $offset
	$arguments = @(
		"--headless", "--path", $projectRoot, "--fixed-fps", "60",
		"-s", "tests/analysis/analysis_soak.gd", "--",
		"--seconds=$Seconds", "--seed=$seed", "--players=$Players"
	)
	$processInfo = New-Object System.Diagnostics.ProcessStartInfo
	$processInfo.FileName = $GodotBin
	$processInfo.Arguments = ($arguments | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
	$processInfo.WorkingDirectory = $projectRoot
	$processInfo.RedirectStandardOutput = $true
	$processInfo.RedirectStandardError = $true
	$processInfo.UseShellExecute = $false
	$process = [System.Diagnostics.Process]::Start($processInfo)
	$stdoutTask = $process.StandardOutput.ReadToEndAsync()
	$stderr = $process.StandardError.ReadToEnd()
	$process.WaitForExit()
	$output = $stdoutTask.Result + "`n" + $stderr
	$exitCode = $process.ExitCode
	Add-Content -LiteralPath $logPath -Value ("===== players={0} seed={1} exit={2} =====`n{3}" -f $Players, $seed, $exitCode, $output)
	$engineErrors = @($output -split "`r?`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|Parse Error|ERROR)' })
	$resultLine = ($output -split "`r?`n" | Where-Object { $_ -like "ANALYSIS_RESULT *" } | Select-Object -Last 1)
	if (-not $resultLine) {
		throw "Missing ANALYSIS_RESULT for players=$Players seed=$seed; see $logPath"
	}
	$result = $resultLine.Substring("ANALYSIS_RESULT ".Length) | ConvertFrom-Json
	$result | Add-Member -NotePropertyName exit_code -NotePropertyValue $exitCode
	$result | Add-Member -NotePropertyName engine_errors -NotePropertyValue $engineErrors
	$result | Add-Member -NotePropertyName run_pass -NotePropertyValue ($exitCode -eq 0 -and $engineErrors.Count -eq 0)
	Add-Content -LiteralPath $jsonPath -Value ($result | ConvertTo-Json -Compress -Depth 20)
	if ($exitCode -ne 0 -or $engineErrors.Count -gt 0) {
		$failedRuns += "p${Players}s${seed}"
	}
	Write-Host ("[analysis] players={0} seed={1} complete pass={2} errors={3}" -f $Players, $seed, $result.run_pass, $engineErrors.Count)
}

if ($failedRuns.Count -gt 0) {
	Write-Host ("[analysis] failed runs: {0}; see {1}" -f ($failedRuns -join ","), $logPath)
	exit 1
}
