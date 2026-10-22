$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$branch = & git -C $repoRoot branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch.Trim() -ne 'codex/sys-04') { throw 'Run this handoff only on codex/sys-04.' }
$staged = & git -C $repoRoot diff --cached --name-only
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the Git index.' }
if ($staged) { throw 'The index already contains changes. Review them before running this task-only handoff.' }
$paths = @(
    'smash-nine-prototype/scripts/story/StoryCatalog.gd',
    'smash-nine-prototype/scripts/story/StoryDirector.gd',
    'smash-nine-prototype/scripts/story/StorySession.gd',
    'smash-nine-prototype/scripts/ui/StoryDialogue.gd',
    'smash-nine-prototype/scripts/ui/StoryScreens.gd',
    'smash-nine-prototype/scripts/Main.gd',
    'smash-nine-prototype/scripts/RealmMonster.gd',
    'smash-nine-prototype/scripts/Vfx.gd',
    'smash-nine-prototype/assets/i18n/strings.csv',
    'smash-nine-prototype/tests/test_story_data.gd',
    'smash-nine-prototype/tests/test_story_flow.gd',
    'smash-nine-prototype/tests/test_story_late_flow.gd',
    'smash-nine-prototype/tests/test_story_rewards.gd',
    'smash-nine-prototype/tests/test_story_exit_reload.gd',
    'smash-nine-prototype/tests/test_story_presentation.gd',
    'smash-nine-prototype/tests/test_story_text_fit.gd',
    'smash-nine-prototype/tests/test_story_atomic_reload.gd',
    'smash-nine-prototype/tests/test_monster_options.gd',
    'smash-nine-prototype/tests/test_language.gd',
    'smash-nine-prototype/tests/run_all.ps1',
    'reports/codex-sys-04/'
)
& git -C $repoRoot add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed. The sandbox may not permit writing .git.' }
$message = @'
Implement story stages 5-9 and hero endings

Add collapse crystals, opt-in hostile/boss monsters, boss reinforcements,
later duels/home stages, rival/self shadows, hero-only shrinking band and
ending/CLEAR flow. Preserve root-card rewards and stopped exit enemies
across art reloads; include tests and Korean capture evidence.

Co-Authored-By: Codex <noreply@openai.com>
'@
$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
[IO.File]::WriteAllText($messagePath, $message.Trim() + "`n", [Text.UTF8Encoding]::new($false))
& git -C $repoRoot add -- 'reports/codex-sys-04/commit-message.txt'
if ($LASTEXITCODE -ne 0) { throw 'Cannot stage the commit message.' }
& git -C $repoRoot commit --file $messagePath
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
