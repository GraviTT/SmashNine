$ErrorActionPreference = 'Stop'
foreach ($matchSeed in @(1001, 2105, 2106)) {
    & (Join-Path $PSScriptRoot 'run.ps1') -Script 'tests/analysis/codex_qa_22/sound_soak.gd' -Name "sound-br-$matchSeed" -Extra @('--seconds=480', "--seed=$matchSeed", '--players=8')
    if ($LASTEXITCODE -ne 0) { throw "Sound BR $matchSeed failed" }
}
foreach ($stage in @(1, 5, 9)) {
    & (Join-Path $PSScriptRoot 'run.ps1') -Script 'tests/analysis/codex_qa_22/sound_story.gd' -Name "sound-story-$stage" -Extra @("--stage=$stage")
    if ($LASTEXITCODE -ne 0) { throw "Sound story $stage failed" }
}
& (Join-Path $PSScriptRoot 'run.ps1') -Script 'tests/analysis/codex_qa_22/music_screens.gd' -Name 'music-screens'
if ($LASTEXITCODE -ne 0) { throw 'Music screens failed' }
