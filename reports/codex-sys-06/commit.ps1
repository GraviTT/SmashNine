$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$files = @(
    'smash-nine-prototype/characters/common/PlayerBase.gd',
    'smash-nine-prototype/scripts/RealmMonster.gd',
    'smash-nine-prototype/scripts/ui/FrontendMenu.gd',
    'smash-nine-prototype/scripts/ui/StoryScreens.gd',
    'smash-nine-prototype/tests/run_all.ps1',
    'smash-nine-prototype/tests/test_fighter_motion.gd',
    'smash-nine-prototype/tests/test_monster_motion.gd',
    'smash-nine-prototype/tests/test_victory_screens.gd',
    'reports/codex-sys-06/README.md',
    'reports/codex-sys-06/validation.txt',
    'reports/codex-sys-06/results-existing.png',
    'reports/codex-sys-06/results-stand-in.png',
    'reports/codex-sys-06/ending-stand-in.png',
    'reports/codex-sys-06/commit.ps1'
)
$branch = git -C $repo branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/sys-06') { throw 'Expected branch codex/sys-06.' }
foreach ($file in $files) {
    if ($file -match '__pycache__' -or -not (Test-Path -LiteralPath (Join-Path $repo $file))) {
        throw "Invalid or missing task file: $file"
    }
}
$staged = @(git -C $repo diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the index.' }
foreach ($file in $staged) {
    if ($files -notcontains $file) { throw "Unrelated staged file: $file" }
}
git -C $repo -c core.autocrlf=false add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
$message = @'
Wire optional fighter motions, six-row monsters and victory screens

Preserve existing art fallbacks and combat rules; add stand-in motion regressions.

Co-Authored-By: Codex <noreply@openai.com>
'@
$messagePath = Join-Path ([IO.Path]::GetTempPath()) ('smashnine-sys06-' + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllText($messagePath, $message, (New-Object Text.UTF8Encoding($false)))
    git -C $repo commit --file $messagePath
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
} finally {
    Remove-Item -LiteralPath $messagePath -ErrorAction SilentlyContinue
}
