param(
	[string]$EightPlayerJsonl = "../reports/codex-analyst-01/raw/results-8p.jsonl",
	[string]$SixteenPlayerJsonl = "../reports/codex-analyst-01/raw/results-16p.jsonl",
	[string]$OutputDirectory = "../reports/codex-analyst-01/data"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$eightPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $EightPlayerJsonl))
$sixteenPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $SixteenPlayerJsonl))
$outputPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDirectory))
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

$eight = @(Get-Content -LiteralPath $eightPath | ForEach-Object { $_ | ConvertFrom-Json })
$sixteen = @(Get-Content -LiteralPath $sixteenPath | ForEach-Object { $_ | ConvertFrom-Json })

function Export-Matches($rows, [string]$name) {
	$rows | Select-Object seed, players, seconds_simulated, finish_reason, winner_character, winner_id, first_pvp_hit, ringouts, wall_seconds, wall_per_sim_second, maximum_nodes, final_nodes, nan_positions, run_pass, @{Name="engine_error_count"; Expression={$_.engine_errors.Count}} |
		Export-Csv -LiteralPath (Join-Path $outputPath $name) -NoTypeInformation -Encoding utf8
}

Export-Matches $eight "matches-8p.csv"
Export-Matches $sixteen "matches-16p.csv"

$characterRows = foreach ($group in ($eight.player_results | Group-Object character)) {
	$players = @($group.Group)
	$wins = @($players | Where-Object alive).Count
	[pscustomobject]@{
		character = $group.Name
		exposures = $players.Count
		wins = $wins
		winner_share_percent = [math]::Round(100.0 * $wins / $eight.Count, 1)
		average_damage = [math]::Round(($players.damage_dealt | Measure-Object -Average).Average, 1)
		average_souls = [math]::Round(($players.souls | Measure-Object -Average).Average, 1)
		average_soul_picks = [math]::Round(($players.soul_picks | Measure-Object -Average).Average, 2)
		full_builds = @($players | Where-Object soul_picks -eq 3).Count
		zero_pick_lives = @($players | Where-Object soul_picks -eq 0).Count
		average_ringouts = [math]::Round(($players.ringouts | Measure-Object -Average).Average, 2)
		average_knockouts = [math]::Round(($players.score | Measure-Object -Average).Average, 2)
	}
}
$characterRows | Sort-Object character | Export-Csv -LiteralPath (Join-Path $outputPath "character-balance-8p.csv") -NoTypeInformation -Encoding utf8

$cardRows = foreach ($group in ($eight.card_picks | Group-Object card)) {
	$picks = @($group.Group)
	$times = @($picks.time | Sort-Object)
	[pscustomobject]@{
		card = $group.Name
		picks = $picks.Count
		median_pick_time = $times[[math]::Ceiling(0.5 * $times.Count) - 1]
		p10_pick_time = $times[[math]::Ceiling(0.1 * $times.Count) - 1]
		p90_pick_time = $times[[math]::Ceiling(0.9 * $times.Count) - 1]
	}
}
$cardRows | Sort-Object card | Export-Csv -LiteralPath (Join-Path $outputPath "card-picks-8p.csv") -NoTypeInformation -Encoding utf8

$causeRows = foreach ($group in ($eight.eliminations | Group-Object cause)) {
	[pscustomobject]@{cause=$group.Name; eliminations=$group.Count; percent=[math]::Round(100.0 * $group.Count / $eight.eliminations.Count, 1)}
}
$causeRows | Sort-Object cause | Export-Csv -LiteralPath (Join-Path $outputPath "elimination-causes-8p.csv") -NoTypeInformation -Encoding utf8

Write-Output "Wrote analysis CSV files to $outputPath"
