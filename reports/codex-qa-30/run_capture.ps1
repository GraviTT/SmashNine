$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$cache = Join-Path $PSScriptRoot 'runtime/capture-user'
New-Item -ItemType Directory -Force "$cache/local", "$cache/roaming" | Out-Null
$env:LOCALAPPDATA = "$cache/local"
$env:APPDATA = "$cache/roaming"
$info = New-Object Diagnostics.ProcessStartInfo
$info.FileName = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$info.Arguments = '--path smash-nine-prototype -s tests/analysis/codex_qa_30/capture_apply.gd -- --out=../reports/codex-qa-30'
$info.WorkingDirectory = $repo
$info.UseShellExecute = $false
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$process = [Diagnostics.Process]::Start($info)
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(180000)) {
    $process.Kill()
    $process.WaitForExit()
    [IO.File]::WriteAllText((Join-Path $PSScriptRoot 'capture.log'), $stdout.Result + "`n" + $stderr.Result)
    throw 'Capture process exceeded 180 seconds; this process only was stopped.'
}
$output = $stdout.Result + "`n" + $stderr.Result
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'capture.log'), $output)
Write-Output $output
Write-Output "Godot exit: $($process.ExitCode)"
$errors = @($output -split "`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and $_.Trim() -ne 'ERROR: Failed to read the root certificate store.' })
if ($process.ExitCode -ne 0 -or $errors.Count -gt 0) { exit 1 }
