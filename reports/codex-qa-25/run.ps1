param([ValidateSet('baseline','fps10','load','trace')][string]$Condition='baseline',[int]$Count=20,[string]$TraceMode='physics',[string]$Poll='idle',[int]$Fps=0,[int]$StallMs=0,[string]$RunTag='')
$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$project=Join-Path $root 'smash-nine-prototype'
$godot='C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
[IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot 'logs'))|Out-Null
$results=New-Object System.Collections.Generic.List[object]
$loads=New-Object System.Collections.Generic.List[object]
$loadRecords=New-Object System.Collections.Generic.List[object]
$deadline=[DateTime]::UtcNow.AddMinutes(30)
$prefix=if($RunTag){"$RunTag-"}else{''}
function Start-Godot([string]$Arguments,[string]$Label){
 $psi=New-Object Diagnostics.ProcessStartInfo
 $psi.FileName=$godot; $psi.Arguments=$Arguments; $psi.WorkingDirectory=$project
 $psi.UseShellExecute=$false; $psi.CreateNoWindow=$true
 $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::Start($psi)
 return @{process=$p;stdout=$p.StandardOutput.ReadToEndAsync();stderr=$p.StandardError.ReadToEndAsync();label=$Label;start=[DateTime]::UtcNow;args=$Arguments}
}
function Finish-Godot($job,[bool]$stopped=$false){
 $p=$job.process
 $p.WaitForExit()
 $out=$job.stdout.Result+"`n"+$job.stderr.Result
 [IO.File]::WriteAllText((Join-Path $PSScriptRoot ('logs/'+$job.label+'.log')),$out)
 $errors=@($out -split "`n"|Where-Object{$_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and $_.Trim() -ne 'ERROR: Failed to read the root certificate store.'})
 return @{label=$job.label;exit=$p.ExitCode;errors=$errors;certificate=@($out -split "`n"|Where-Object{$_.Trim() -eq 'ERROR: Failed to read the root certificate store.'}).Count;seconds=([DateTime]::UtcNow-$job.start).TotalSeconds;console_wrapper_cpu_seconds=$p.TotalProcessorTime.TotalSeconds;stopped=$stopped;args=$job.args}
}
try {
 if($Condition -eq 'load'){
  if(Test-Path (Join-Path $PSScriptRoot 'stop-workers.txt')){Remove-Item -LiteralPath (Join-Path $PSScriptRoot 'stop-workers.txt')}
  1..2|ForEach-Object{$loads.Add((Start-Godot "--headless --path . --fixed-fps 60 -s tests/analysis/codex_qa_25/load_soak.gd -- --seconds=480 --seed=$(2500+$_) --players=8 --worker=$_" "${prefix}load-soak-$_"))}
 }
 for($i=1;$i -le $Count -and [DateTime]::UtcNow -lt $deadline;$i++){
  for($j=0;$j -lt $loads.Count;$j++){
   if($loads[$j].process.HasExited){
    $loadRecords.Add((Finish-Godot $loads[$j]))
    $loads[$j]=Start-Godot "--headless --path . --fixed-fps 60 -s tests/analysis/codex_qa_25/load_soak.gd -- --seconds=480 --seed=$(2500+$j+1) --players=8 --worker=$($j+1)" "${prefix}load-soak-$($j+1)-restart-$i"
   }
  }
  $engines=@();$before=@()
  for($j=0;$j -lt $loads.Count;$j++){
   $pidPath=Join-Path $PSScriptRoot "worker-$($j+1).pid"
   $limit=[DateTime]::UtcNow.AddSeconds(30)
   $engine=$null
   while($null -eq $engine -and [DateTime]::UtcNow -lt $limit){
    if(Test-Path $pidPath){try{$engine=[Diagnostics.Process]::GetProcessById([int][IO.File]::ReadAllText($pidPath));if($engine.HasExited){$engine=$null}}catch{$engine=$null}}
    if($null -eq $engine){Start-Sleep -Milliseconds 200}
   }
   if($null -eq $engine){throw 'Load engine PID unavailable'}
   $engines+=,$engine;$before+=$engine.TotalProcessorTime.TotalSeconds
  }
  $flags=if($Condition -eq 'fps10'){' --max-fps 10'}elseif($Condition -eq 'trace' -and $Fps -gt 0){" --max-fps $Fps"}else{''}
  $label=if($Condition -eq 'trace'){"${prefix}trace-$TraceMode-$Poll-fps$Fps-stall$StallMs-$i"}else{"$prefix$Condition-$i"}
  $script=if($Condition -eq 'trace'){'tests/analysis/codex_qa_25/timeline.gd'}else{'tests/test_nova_prototype.gd'}
  $tail=if($Condition -eq 'trace'){" -- --startup=$TraceMode --poll=$Poll --stall-ms=$StallMs --out=$label"}else{''}
  $job=Start-Godot "--headless --path .$flags -s $script$tail" $label
  $timedout=-not $job.process.WaitForExit(120000)
  if($timedout){$job.process.Kill();$job.process.WaitForExit()}
  $row=Finish-Godot $job $timedout
  $row.condition=$Condition;$row.iteration=$i
  $row.load_running_end=@($loads|Where-Object{-not $_.process.HasExited}).Count
  $cpu=0.0
  for($j=0;$j -lt $engines.Count;$j++){$engines[$j].Refresh();$cpu += [Math]::Max(0,$engines[$j].TotalProcessorTime.TotalSeconds-$before[$j])}
  $row.load_core_equivalent=$cpu/[Math]::Max(0.001,$row.seconds)
  $row.load_engine_pids=@($engines|ForEach-Object{$_.Id})
  $results.Add($row)
  [IO.File]::WriteAllText((Join-Path $PSScriptRoot "$prefix$Condition-results$(if($Condition -eq 'trace'){"-$TraceMode-$Poll-fps$Fps-stall$StallMs"}).json"),(@{logical_processors=[Environment]::ProcessorCount;rows=$results.ToArray()}|ConvertTo-Json -Depth 8))
  Write-Output "$label exit=$($row.exit) errors=$($row.errors.Count) seconds=$([Math]::Round($row.seconds,2)) loads=$($row.load_running_end)"
 }
} finally {
 if($loads.Count -gt 0){[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'stop-workers.txt'),'QA-25 load condition finished')}
 foreach($job in $loads){$stopped=-not $job.process.HasExited;if($stopped -and -not $job.process.WaitForExit(15000)){throw 'Load worker did not acknowledge stop file'};$loadRecords.Add((Finish-Godot $job $stopped))}
 if($loads.Count -gt 0){[IO.File]::WriteAllText((Join-Path $PSScriptRoot "${prefix}load-workers.json"),($loadRecords.ToArray()|ConvertTo-Json -Depth 8))}
}
