# Prepared only; the AUD-02 unit does not execute this script.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/aud-02') { throw 'Expected codex/aud-02' }
$files = @(
    'tools/audio_synth/music.py'
    'tools/audio_synth/verify_music.py'
    'art/audio_bakeoff/music_select-a.wav'
    'art/audio_bakeoff/music_select-b.wav'
    'art/audio_bakeoff/music_select-c.wav'
    'art/audio_bakeoff/music_story-a.wav'
    'art/audio_bakeoff/music_story-b.wav'
    'art/audio_bakeoff/music_story-c.wav'
    'art/audio_bakeoff/music_results-a.wav'
    'art/audio_bakeoff/music_results-b.wav'
    'art/audio_bakeoff/music_results-c.wav'
    'reports/codex-aud-02/baseline.json'
    'reports/codex-aud-02/build_report.py'
    'reports/codex-aud-02/handoff-checks.json'
    'reports/codex-aud-02/measurements.json'
    'reports/codex-aud-02/music_results-a-score.json'
    'reports/codex-aud-02/music_results-a-score.txt'
    'reports/codex-aud-02/music_results-a.png'
    'reports/codex-aud-02/music_results-b-score.json'
    'reports/codex-aud-02/music_results-b-score.txt'
    'reports/codex-aud-02/music_results-b.png'
    'reports/codex-aud-02/music_results-c-score.json'
    'reports/codex-aud-02/music_results-c-score.txt'
    'reports/codex-aud-02/music_results-c.png'
    'reports/codex-aud-02/music_select-a-score.json'
    'reports/codex-aud-02/music_select-a-score.txt'
    'reports/codex-aud-02/music_select-a.png'
    'reports/codex-aud-02/music_select-b-score.json'
    'reports/codex-aud-02/music_select-b-score.txt'
    'reports/codex-aud-02/music_select-b.png'
    'reports/codex-aud-02/music_select-c-score.json'
    'reports/codex-aud-02/music_select-c-score.txt'
    'reports/codex-aud-02/music_select-c.png'
    'reports/codex-aud-02/music_story-a-score.json'
    'reports/codex-aud-02/music_story-a-score.txt'
    'reports/codex-aud-02/music_story-a.png'
    'reports/codex-aud-02/music_story-b-score.json'
    'reports/codex-aud-02/music_story-b-score.txt'
    'reports/codex-aud-02/music_story-b.png'
    'reports/codex-aud-02/music_story-c-score.json'
    'reports/codex-aud-02/music_story-c-score.txt'
    'reports/codex-aud-02/music_story-c.png'
    'reports/codex-aud-02/overview.png'
    'reports/codex-aud-02/README.md'
    'reports/codex-aud-02/supplemental.json'
    'reports/codex-aud-02/verification.json'
    'reports/codex-aud-02/visual-review.md'
    'reports/codex-aud-02/commit.ps1'
)
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw ('Missing: ' + $file) }
}
# Existing staged changes must be reviewed separately; never include them here.
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read index' }
if ($staged.Count -gt 0) { throw 'Index is not empty; review existing staged files first' }
git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files' }
foreach ($file in $staged) {
    if ($file -notin $files -or $file -match '(^|/)__pycache__(/|$)|(^|/)run\.log$') { throw ('Unexpected staged file: ' + $file) }
}
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed' }
$message = @'
Compose select, story and results music candidates in three styles

Add nine original PCM loops with scores, analysis images and reproducibility checks.
Preserve the six AUD-02a music WAVs byte-for-byte.

Co-Authored-By: Codex <noreply@openai.com>
'@
$messagePath = Join-Path ([IO.Path]::GetTempPath()) ('smashnine-aud02-' + [Guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllText($messagePath, $message, (New-Object Text.UTF8Encoding($false)))
    git commit --file $messagePath
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
} finally {
    Remove-Item -LiteralPath $messagePath -ErrorAction SilentlyContinue
}
