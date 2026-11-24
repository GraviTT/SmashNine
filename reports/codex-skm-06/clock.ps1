param([ValidateSet('check','start','end')][string]$Action='check', [string]$Row='', [int]$Attempt=0)
$ErrorActionPreference = 'Stop'
$now = Get-Date
$path = Join-Path $PSScriptRoot 'time-limit.json'
$state = Get-Content -Raw -Encoding UTF8 $path | ConvertFrom-Json
$state.observations += $now.ToString('o')
if ($Action -eq 'start') {
    if ([datetimeoffset]$now -ge [datetimeoffset]::Parse($state.deadline_local)) { throw 'Hard stop passed; no more rows' }
    $state.calls += [pscustomobject]@{row=$Row; attempt=$Attempt; start=$now.ToString('o'); status='generating'}
}
if ($Action -eq 'end') {
    $call = $state.calls[-1]
    $call | Add-Member -Force end $now.ToString('o')
    $call | Add-Member -Force elapsed_minutes (([datetimeoffset]$now - [datetimeoffset]::Parse($call.start)).TotalMinutes)
    $call.status = 'returned'
}
[IO.File]::WriteAllText($path, ($state | ConvertTo-Json -Depth 12) + "`n", (New-Object Text.UTF8Encoding($false)))
$now.ToString('o')
if ([datetimeoffset]$now -ge [datetimeoffset]::Parse($state.deadline_local)) { Write-Output 'HARD STOP PASSED'; exit 2 }
