# One-screen summary of a run_sweep.ps1 JSONL file: match length, finish reasons,
# winner share and damage per character, elimination causes, first PvP hit.
# Usage: powershell -File tests/analysis/sweep_summary.ps1 -Jsonl ../reports/lead-sweep/raw/fix1-8p.jsonl
param([Parameter(Mandatory = $true)][string]$Jsonl)

$rows = @(Get-Content -LiteralPath $Jsonl | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_ | ConvertFrom-Json })
function Get-Quantile([double[]]$values, [double]$q) {
	$sorted = @($values | Sort-Object)
	if ($sorted.Count -eq 0) { return 0 }
	$index = [Math]::Min($sorted.Count - 1, [Math]::Max(0, [int][Math]::Round($q * ($sorted.Count - 1))))
	return $sorted[$index]
}
$lengths = @($rows | ForEach-Object { [double]$_.seconds_simulated })
$pvp = @($rows | Where-Object { [double]$_.first_pvp_hit -ge 0 } | ForEach-Object { [double]$_.first_pvp_hit })
"matches: $($rows.Count)   engine-error runs: $(@($rows | Where-Object { $_.engine_errors.Count -gt 0 }).Count)"
"length s  P10 {0:N0}  median {1:N0}  P90 {2:N0}   under 300 s: {3}/{4}" -f (Get-Quantile $lengths 0.1), (Get-Quantile $lengths 0.5), (Get-Quantile $lengths 0.9), @($lengths | Where-Object { $_ -lt 300 }).Count, $rows.Count
"first PvP hit median: {0:N1} s" -f (Get-Quantile $pvp 0.5)
"finish reasons: " + (($rows | Group-Object finish_reason | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "  ")
$eliminations = @($rows | ForEach-Object { $_.eliminations })
"elimination causes: " + (($eliminations | Group-Object cause | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join "  ")
$results = @($rows | ForEach-Object { $_.player_results })
"character   wins  share  avg dmg  avg souls  avg picks"
foreach ($character in @("frey", "yuki", "luna", "nova")) {
	$wins = @($rows | Where-Object { $_.winner_character -eq $character }).Count
	$mine = @($results | Where-Object { $_.character -eq $character })
	$damage = ($mine | Measure-Object -Property damage_dealt -Average).Average
	$souls = ($mine | Measure-Object -Property souls -Average).Average
	$picks = ($mine | Measure-Object -Property soul_picks -Average).Average
	"{0,-10} {1,5} {2,6:P0} {3,8:N1} {4,10:N1} {5,10:N2}" -f $character, $wins, ($wins / [Math]::Max($rows.Count, 1)), $damage, $souls, $picks
}
