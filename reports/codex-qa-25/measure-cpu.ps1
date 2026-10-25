Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class QA25Cpu {
 [DllImport("kernel32.dll", SetLastError=true)]
 public static extern bool GetSystemTimes(out long idle, out long kernel, out long user);
}
'@
function Snapshot {
 [long]$idle=0;[long]$kernel=0;[long]$user=0
 if(-not [QA25Cpu]::GetSystemTimes([ref]$idle,[ref]$kernel,[ref]$user)){throw 'GetSystemTimes failed'}
 $workers=@()
 foreach($slot in 1..2){
  $n=[int][IO.File]::ReadAllText((Join-Path $PSScriptRoot "worker-$slot.pid"))
  $p=[Diagnostics.Process]::GetProcessById($n)
  $workers+=@{pid=$n;cpu_seconds=$p.TotalProcessorTime.TotalSeconds}
 }
 return @{utc=[DateTime]::UtcNow;idle=$idle;kernel=$kernel;user=$user;workers=$workers}
}
$rows=@()
for($i=0;$i -lt 5;$i++){
 $a=Snapshot
 Start-Sleep -Seconds 5
 $b=Snapshot
 $wall=($b.utc-$a.utc).TotalSeconds
 $total=($b.kernel-$a.kernel)+($b.user-$a.user)
 $busy=$total-($b.idle-$a.idle)
 $cpu=0.0;$same=$true
 for($j=0;$j -lt 2;$j++){if($a.workers[$j].pid -ne $b.workers[$j].pid){$same=$false};$cpu+=$b.workers[$j].cpu_seconds-$a.workers[$j].cpu_seconds}
 $rows+=@{start=$a.utc.ToString('o');end=$b.utc.ToString('o');wall_seconds=$wall;logical_processors=[Environment]::ProcessorCount;system_busy_percent=100.0*$busy/$total;raw_unaligned_core_ratio=($busy/10000000.0)/$wall;system_busy_core_equivalent=([double]$busy/$total)*[Environment]::ProcessorCount;two_soak_core_equivalent=if($same){$cpu/$wall}else{$null};worker_pids=@($b.workers.pid)}
}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'cpu-samples.json'),($rows|ConvertTo-Json -Depth 6))
$rows|Format-Table -AutoSize
