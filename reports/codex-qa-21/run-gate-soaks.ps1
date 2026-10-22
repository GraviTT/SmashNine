$ErrorActionPreference = 'Stop'
foreach ($matchSeed in @(2105, 2106)) {
    & (Join-Path $PSScriptRoot 'run.ps1') -Script 'tests/analysis/codex_qa_21/gate_soak.gd' -Name "gate-soak-$matchSeed" -Extra @('--seconds=480', "--seed=$matchSeed", '--players=16')
}
