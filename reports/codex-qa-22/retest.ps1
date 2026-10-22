$ErrorActionPreference = 'Stop'
foreach ($name in @('gate_geometry', 'story_cutin', 'gimmick_actors')) {
    & (Join-Path $PSScriptRoot 'run.ps1') -Script "tests/analysis/codex_qa_22/$name.gd" -Name $name
}
foreach ($matchSeed in @(2105, 2106)) {
    & (Join-Path $PSScriptRoot 'run.ps1') -Script 'tests/analysis/codex_qa_22/gate_soak.gd' -Name "gate-soak-$matchSeed" -Extra @('--seconds=480', "--seed=$matchSeed", '--players=16')
}
