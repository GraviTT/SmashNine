param([string]$Mode = 'a')
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$p = New-Object System.Diagnostics.ProcessStartInfo
$p.FileName = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$p.WorkingDirectory = Join-Path $root 'smash-nine-prototype'
$p.Arguments = "--headless --path . --fixed-fps 60 -s tests/analysis/codex_qa_24/probe.gd -- --mode=$Mode"
$p.UseShellExecute = $false
$p.CreateNoWindow = $true
$p.RedirectStandardOutput = $true
$p.RedirectStandardError = $true
$started = [DateTime]::UtcNow
$process = [Diagnostics.Process]::Start($p)
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(600000)) { $process.Kill(); $process.WaitForExit() }
$output = $stdout.Result + "`n" + $stderr.Result
[IO.File]::WriteAllText((Join-Path $PSScriptRoot "logs/$Mode.log"), $output)
$errors = @($output -split "`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and $_.Trim() -ne 'ERROR: Failed to read the root certificate store.' })
$result = @{mode=$Mode; exit=$process.ExitCode; seconds=([DateTime]::UtcNow-$started).TotalSeconds; errors=$errors}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot "run-$Mode.json"), ($result | ConvertTo-Json -Depth 5))
$result | ConvertTo-Json -Depth 5
