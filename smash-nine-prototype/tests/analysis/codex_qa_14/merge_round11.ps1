param(
	[string]$ReportDir = (Join-Path $PSScriptRoot '..\..\..\..\reports\codex-qa-14')
)

$ErrorActionPreference = 'Stop'

function Merge-Value($Left, $Right) {
	if ($null -eq $Left) { return $Right }
	if ($null -eq $Right) { return $Left }
	if ($Left -is [System.Collections.IList] -and -not ($Left -is [string])) {
		return ,([object[]](@($Left) + @($Right)))
	}
	if ($Left -is [pscustomobject]) {
		$merged = [ordered]@{}
		foreach ($property in $Left.psobject.Properties) { $merged[$property.Name] = $property.Value }
		foreach ($property in $Right.psobject.Properties) {
			if ($merged.Contains($property.Name)) { $merged[$property.Name] = Merge-Value $merged[$property.Name] $property.Value }
			else { $merged[$property.Name] = $property.Value }
		}
		return [pscustomobject]$merged
	}
	if (($Left -is [ValueType]) -and ($Right -is [ValueType])) { return [double]$Left + [double]$Right }
	return $Left
}

$parts = @(Get-ChildItem -LiteralPath $ReportDir -Filter 'round11-seed-*.json' | Sort-Object Name)
if ($parts.Count -ne 12) { throw "Expected 12 seed files, found $($parts.Count)" }
$rows = @($parts | ForEach-Object { Get-Content -Raw -Encoding UTF8 $_.FullName | ConvertFrom-Json })
$first = $rows[0]
$totals = $null
$matches = @(); $ringouts = @(); $lowHp = @(); $relocations = @(); $drops = @(); $escapes = @()
$recoverySkills = @(); $recoverySkillAsks = @(); $progressExtensions = @(); $wallSeconds = 0.0
$standoffTraces = @(); $deadBands = @()
$recoveryEntries = @()
$savedFalls = @()
$r10OnlyFalls = @()

foreach ($row in $rows) {
	$totals = Merge-Value $totals $row.totals
	$matches += @($row.matches); $ringouts += @($row.ringouts); $lowHp += @($row.low_hp_portals)
	$relocations += @($row.relocations); $drops += @($row.target_drop_events); $escapes += @($row.corner_escape_events)
	$recoverySkills += @($row.recovery_skill_events); $recoverySkillAsks += @($row.recovery_skill_ask_events)
	$progressExtensions += @($row.progress_extension_events); $wallSeconds += [double]$row.wall_seconds
	$standoffTraces += @($row.standoff_trace_events); $deadBands += @($row.dead_band_events)
	$recoveryEntries += @($row.recovery_entry_events)
	$savedFalls += @($row.saved_fall_events)
	$r10OnlyFalls += @($row.r10_only_fall_events)
}

$result = [ordered]@{
	schema = 11; seeds = @(101..112); players = $first.players; sample_interval = $first.sample_interval
	hit_window = $first.hit_window; no_progress_definition = $first.no_progress_definition
	wall_seconds = [math]::Round($wallSeconds, 3); matches = $matches; totals = $totals; ringouts = $ringouts
	low_hp_portals = $lowHp; relocations = $relocations; target_drop_events = $drops; corner_escape_events = $escapes
	recovery_skill_events = $recoverySkills; recovery_skill_ask_events = $recoverySkillAsks
	progress_extension_events = $progressExtensions; standoff_trace_events = $standoffTraces; dead_band_events = $deadBands
	recovery_entry_events = $recoveryEntries
	saved_fall_events = $savedFalls
	r10_only_fall_events = $r10OnlyFalls
	round2_definitions = $first.round2_definitions; round3_definitions = $first.round3_definitions
	round4_definitions = $first.round4_definitions; round5_definitions = $first.round5_definitions
	round6_definitions = $first.round6_definitions; round7_definitions = $first.round7_definitions
	round8_definitions = $first.round8_definitions; round9_definitions = $first.round9_definitions
	round10_definitions = $first.round10_definitions
	round11_definitions = $first.round11_definitions
}

$output = Join-Path $ReportDir 'round11-results.json'
$result | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $output
Write-Host "Merged $($parts.Count) seeds into $output"
Write-Host "matches=$($matches.Count) ringouts=$($ringouts.Count) wall_seconds=$wallSeconds dead_bands=$($deadBands.Count) recovery_entries=$($recoveryEntries.Count) saved_falls=$($savedFalls.Count) r10_only_falls=$($r10OnlyFalls.Count)"
