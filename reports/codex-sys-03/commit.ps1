# Run from the normal workspace after review if this sandbox cannot write .git.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = (& git branch --show-current).Trim()
if ($branch -ne 'codex/sys-03') { throw "Expected codex/sys-03, got $branch" }
$paths = @(
    'smash-nine-prototype/scripts/story',
    'smash-nine-prototype/scripts/ui/FrontendMenu.gd',
    'smash-nine-prototype/scripts/ui/MatchHud.gd',
    'smash-nine-prototype/scripts/ui/StoryScreens.gd',
    'smash-nine-prototype/scripts/ui/StoryScreens.gd.uid',
    'smash-nine-prototype/scripts/ui/StoryDialogue.gd',
    'smash-nine-prototype/scripts/ui/StoryDialogue.gd.uid',
    'smash-nine-prototype/scripts/Main.gd',
    'smash-nine-prototype/assets/i18n/strings.csv',
    'smash-nine-prototype/assets/i18n/strings.csv.import',
    'smash-nine-prototype/assets/i18n/story.csv',
    'smash-nine-prototype/assets/i18n/story.csv.import',
    'smash-nine-prototype/project.godot',
    'tools/font_subset/make_ui_font.py',
    'smash-nine-prototype/tests/test_story_data.gd',
    'smash-nine-prototype/tests/test_story_flow.gd',
    'smash-nine-prototype/tests/test_language.gd',
    'smash-nine-prototype/tests/test_font_coverage.gd',
    'smash-nine-prototype/tests/test_frontend_flow.gd',
    'smash-nine-prototype/tests/run_all.ps1',
    'reports/codex-sys-03'
)
& git -c core.autocrlf=false add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit was attempted.' }
# A pre-existing index can contain unrelated work. Never include it in this unit's commit.
$staged = @(& git diff --cached --name-only)
foreach ($file in $staged) {
    $allowed = $false
    foreach ($item in $paths) {
        if ($file -eq $item -or $file.StartsWith($item.TrimEnd('/') + '/')) { $allowed = $true; break }
    }
    if (-not $allowed) { throw "Unrelated staged path: $file. Review the index before committing." }
}
# Preserve raw engine logs byte-for-byte; their blank lines are not source whitespace.
& git diff --cached --check -- . ':(glob,exclude)reports/codex-sys-03/**/*.log'
if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
& git commit --file (Join-Path $PSScriptRoot 'commit-message.txt')
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
