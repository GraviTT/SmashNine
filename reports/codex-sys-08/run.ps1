param([string]$Script = '', [string]$Name = '', [string[]]$Extra = @(), [switch]$Import, [switch]$ExportWeb, [int]$Seed = -1, [int]$Players = 0, [int]$Seconds = 480, [switch]$Realtime)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$project = Join-Path $repo 'smash-nine-prototype'
$cache = Join-Path $env:TEMP 'SmashNine-SYS08-cache'
[IO.Directory]::CreateDirectory($cache) | Out-Null
$psi = New-Object Diagnostics.ProcessStartInfo
$psi.FileName = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$argsList = @('--headless', '--path', $project)
if ($Import) { $argsList += '--import'; if (!$Name) { $Name = 'import' } }
elseif ($ExportWeb) {
    $web = Join-Path $PSScriptRoot 'web'
    [IO.Directory]::CreateDirectory($web) | Out-Null
    $templates = Join-Path $cache 'Godot/export_templates/4.7.stable'
    [IO.Directory]::CreateDirectory($templates) | Out-Null
    Copy-Item -LiteralPath (Join-Path $env:APPDATA 'Godot/export_templates/4.7.stable/web_nothreads_release.zip') -Destination $templates -Force
    $argsList += @('--export-release', 'Web', (Join-Path $web 'index.html'))
    if (!$Name) { $Name = 'web-export' }
}
else { if (!$Realtime) { $argsList += @('--fixed-fps', '60') }; $argsList += @('-s', $Script) }
if ($Seed -ge 0) { $Extra += "--seed=$Seed"; $Extra += "--seconds=$Seconds" }
if ($Players -gt 0) { $Extra += "--players=$Players" }
if ($Extra.Count) { $argsList += '--'; $argsList += $Extra }
$psi.Arguments = ($argsList | ForEach-Object { '"' + $_ + '"' }) -join ' '
$psi.WorkingDirectory = $project
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.EnvironmentVariables['APPDATA'] = $cache
$psi.EnvironmentVariables['LOCALAPPDATA'] = $cache
$watch = [Diagnostics.Stopwatch]::StartNew()
$p = [Diagnostics.Process]::Start($psi)
$errTask = $p.StandardError.ReadToEndAsync()
if (!$Name) { $Name = [IO.Path]::GetFileNameWithoutExtension($Script) }
$log = Join-Path $PSScriptRoot "logs/$Name.log"
$writer = [IO.StreamWriter]::new($log, $false, [Text.UTF8Encoding]::new($false))
$stdout = [Text.StringBuilder]::new()
while (!$p.StandardOutput.EndOfStream) {
    $line = $p.StandardOutput.ReadLine()
    [void]$stdout.AppendLine($line)
    $writer.WriteLine($line)
    $writer.Flush()
    if ($line -match 'SYS08|passed|failed|FAIL|RESULT') { Write-Output $line }
}
$p.WaitForExit()
$writer.WriteLine($errTask.Result)
$writer.Dispose()
$output = $stdout.ToString() + "`n" + $errTask.Result
$errors = @($output -split "`n" | Where-Object { $_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and $_.Trim() -ne 'ERROR: Failed to read the root certificate store.' })
Write-Output "SYS08 RUN $Name exit=$($p.ExitCode) errors=$($errors.Count) wall=$([Math]::Round($watch.Elapsed.TotalSeconds,2))s"
$output -split "`n" | Where-Object { $_ -match 'SYS08|passed|failed|FAIL|RESULT|SCRIPT ERROR|Parse Error' } | Select-Object -Last 25
if ($errors.Count) { $errors | Select-Object -First 15 }
if ($p.ExitCode -ne 0 -or $errors.Count) { exit 1 }
exit 0
