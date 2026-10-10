$ErrorActionPreference = 'Continue'
$Repo = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$Project = Join-Path $Repo 'smash-nine-prototype'
$Godot = 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$Tests = @(
	'test_character_architecture', 'test_frey_sprite', 'test_luna_prototype', 'test_nova_prototype',
	'test_rio_prototype', 'test_ultimates', 'test_match_rules', 'test_hazards', 'test_soul_crystals',
	'test_art', 'test_sprite_frames', 'test_offscreen_markers', 'test_relocation_active', 'test_bot_panel',
	'test_skill_bar', 'test_bot_brain', 'test_talisman_burst', 'test_flash_art', 'test_ultimate_armor',
	'test_sprite_pose', 'test_frey_kit', 'test_luna_kit', 'test_skill_fx_art', 'test_realm_monsters',
	'test_moves_sheet', 'test_hit_sparks', 'test_hud_frames', 'test_restart', 'visual_preview'
)
$Failed = @()
$Summary = @()
foreach ($Test in $Tests) {
	$Script = Join-Path $Project "tests/$Test.gd"
	if (-not (Test-Path $Script)) { continue }
	$Log = Join-Path $PSScriptRoot "$Test.log"
	$Output = & $Godot --headless --path $Project --log-file $Log -s "tests/$Test.gd" 2>&1 | Out-String
	$Code = $LASTEXITCODE
	$Errors = @($Output -split "`r?`n" | Where-Object {
		$_ -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)' -and
		$_ -notmatch 'Failed to read the root certificate store'
	})
	if ($Code -ne 0 -or $Errors.Count -gt 0) {
		$Failed += $Test
		$Summary += "FAIL $Test exit=$Code errors=$($Errors.Count)"
		$Summary += $Errors
	} else {
		$Summary += "PASS $Test"
	}
}
$Summary | Set-Content -Encoding UTF8 (Join-Path $PSScriptRoot 'filtered-tests.txt')
$Summary | Write-Output
if ($Failed.Count -gt 0) {
	Write-Output "FAILED: $($Failed -join ', ')"
	exit 1
}
Write-Output 'ALL PASSED (known root-certificate sandbox noise excluded)'
exit 0
