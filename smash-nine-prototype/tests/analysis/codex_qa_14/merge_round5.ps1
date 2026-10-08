param(
	[string]$ReportDir = (Join-Path $PSScriptRoot '..\..\..\..\reports\codex-qa-14')
)

$ErrorActionPreference = 'Stop'

function Merge-Value($Left, $Right) {
	if ($null -eq $Left) { return $Right }
	if ($null -eq $Right) { return $Left }
	if ($Left -is [System.Collections.IList] -and -not ($Left -is [string])) {
		return [object[]](@($Left) + @($Right))
	}
	if ($Left -is [pscustomobject]) {
		$merged = [ordered]@{}
		foreach ($property in $Left.psobject.Properties) { $merged[$property.Name] = $property.Value }
		foreach ($property in $Right.psobject.Properties) {
			if ($merged.Contains($property.Name)) {
				$merged[$property.Name] = Merge-Value $merged[$property.Name] $property.Value
			} else {
				$merged[$property.Name] = $property.Value
			}
		}
		return [pscustomobject]$merged
	}
	if (($Left -is [ValueType]) -and ($Right -is [ValueType])) {
		return [double]$Left + [double]$Right
	}
	return $Left
}

$parts = @(Get-ChildItem -LiteralPath $ReportDir -Filter 'round5-seed-*.json' | Sort-Object Name)
if ($parts.Count -ne 12) { throw "Expected 12 seed files, found $($parts.Count)" }
$rows = @($parts | ForEach-Object { Get-Content -Raw -Encoding UTF8 $_.FullName | ConvertFrom-Json })
$first = $rows[0]
$totals = $null
$matches = @()
$ringouts = @()
$lowHp = @()
$relocations = @()
$drops = @()
$escapes = @()
$recoverySkills = @()
$recoverySkillAsks = @()
$progressExtensions = @()
$wallSeconds = 0.0

foreach ($row in $rows) {
	$totals = Merge-Value $totals $row.totals
	$matches += @($row.matches)
	$ringouts += @($row.ringouts)
	$lowHp += @($row.low_hp_portals)
	$relocations += @($row.relocations)
	$drops += @($row.target_drop_events)
	$escapes += @($row.corner_escape_events)
	$recoverySkills += @($row.recovery_skill_events)
	$recoverySkillAsks += @($row.recovery_skill_ask_events)
	$progressExtensions += @($row.progress_extension_events)
	$wallSeconds += [double]$row.wall_seconds
}

$result = [ordered]@{
	schema = 5
	seeds = @(101..112)
	players = $first.players
	sample_interval = $first.sample_interval
	hit_window = $first.hit_window
	no_progress_definition = $first.no_progress_definition
	wall_seconds = [math]::Round($wallSeconds, 3)
	matches = $matches
	totals = $totals
	ringouts = $ringouts
	low_hp_portals = $lowHp
	relocations = $relocations
	target_drop_events = $drops
	corner_escape_events = $escapes
	recovery_skill_events = $recoverySkills
	recovery_skill_ask_events = $recoverySkillAsks
	progress_extension_events = $progressExtensions
	round2_definitions = $first.round2_definitions
	round3_definitions = $first.round3_definitions
	round4_definitions = $first.round4_definitions
	round5_definitions = $first.round5_definitions
}

$output = Join-Path $ReportDir 'round5-results.json'
$result | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $output
Write-Host "Merged $($parts.Count) seeds into $output"
Write-Host "matches=$($matches.Count) ringouts=$($ringouts.Count) wall_seconds=$wallSeconds"
