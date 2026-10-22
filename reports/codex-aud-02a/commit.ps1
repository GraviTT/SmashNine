# Prepared for the lead; this unit did NOT execute this script.
$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location -LiteralPath $repo
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/aud-02a') {
        throw 'Run only in the codex/aud-02a clone.'
    }
    $alreadyStaged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect the Git index.' }
    if ($alreadyStaged.Count -gt 0) { throw 'Index is not empty. Review existing staged changes first.' }
    $files = @(
        'tools/audio_synth/README.md'
        'tools/audio_synth/music.py'
        'tools/audio_synth/verify.py'
        'tools/audio_synth/verify_music.py'
        'tools/sound_viewer/README.md'
        'tools/sound_viewer/build.mjs'
        'tools/sound_viewer/index.html'
        'tools/sound_viewer/verify.mjs'
        'art/audio_bakeoff/music_title-a.wav'
        'art/audio_bakeoff/music_title-b.wav'
        'art/audio_bakeoff/music_title-c.wav'
        'art/audio_bakeoff/music_battle-a.wav'
        'art/audio_bakeoff/music_battle-b.wav'
        'art/audio_bakeoff/music_battle-c.wav'
        'reports/codex-aud-02a/README.md'
        'reports/codex-aud-02a/commit.ps1'
        'reports/codex-aud-02a/measurements.json'
        'reports/codex-aud-02a/verification.json'
        'reports/codex-aud-02a/viewer-checks.json'
        'reports/codex-aud-02a/visual-review.md'
        'reports/codex-aud-02a/overview.png'
        'reports/codex-aud-02a/music_title-a.png'
        'reports/codex-aud-02a/music_title-b.png'
        'reports/codex-aud-02a/music_title-c.png'
        'reports/codex-aud-02a/music_battle-a.png'
        'reports/codex-aud-02a/music_battle-b.png'
        'reports/codex-aud-02a/music_battle-c.png'
        'reports/codex-aud-02a/music_title-a-score.txt'
        'reports/codex-aud-02a/music_title-b-score.txt'
        'reports/codex-aud-02a/music_title-c-score.txt'
        'reports/codex-aud-02a/music_battle-a-score.txt'
        'reports/codex-aud-02a/music_battle-b-score.txt'
        'reports/codex-aud-02a/music_battle-c-score.txt'
        'reports/codex-aud-02a/music_title-a-score.json'
        'reports/codex-aud-02a/music_title-b-score.json'
        'reports/codex-aud-02a/music_title-c-score.json'
        'reports/codex-aud-02a/music_battle-a-score.json'
        'reports/codex-aud-02a/music_battle-b-score.json'
        'reports/codex-aud-02a/music_battle-c-score.json'
    )
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing deliverable: $file" }
    }
    & git -c core.autocrlf=false add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
    $staged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to recheck the Git index.' }
    $unexpected = @($staged | Where-Object { $_ -notin $files })
    if ($unexpected.Count -gt 0) { throw "Unexpected staged file: $($unexpected -join ', ')" }
    $message = @(
        'Compose title and battle music in three styles and extend the sound viewer'
        ''
        'Add original D-dorian scores, six measured PCM loops, visual QA, and music sidecars.'
        'Preserve embedded effects and sound_picks; add music_title and music_battle adoption.'
        ''
        'Co-Authored-By: Codex <noreply@openai.com>'
    ) -join "`n"
    $messageFile = Join-Path ([IO.Path]::GetTempPath()) ('smashnine-aud02a-' + [Guid]::NewGuid().ToString('N') + '.txt')
    try {
        [IO.File]::WriteAllText($messageFile, $message, [Text.UTF8Encoding]::new($false))
        & git commit --file $messageFile
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed; review the staged files.' }
    } finally {
        if (Test-Path -LiteralPath $messageFile) { Remove-Item -LiteralPath $messageFile }
    }
} finally {
    Pop-Location
}
