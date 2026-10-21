$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $repo
try {
    if ((git branch --show-current).Trim() -ne 'codex/sys-01') { throw 'Expected branch codex/sys-01.' }
    $paths = @(
        'smash-nine-prototype/scripts/RealmMonster.gd',
        'smash-nine-prototype/scripts/RealmMonsterSpawner.gd',
        'smash-nine-prototype/scripts/monsters',
        'smash-nine-prototype/scripts/Main.gd',
        'smash-nine-prototype/tests/test_monster_ecology.gd',
        'smash-nine-prototype/tests/run_all.ps1',
        'reports/codex-sys-01'
    )
    foreach ($staged in @(git diff --cached --name-only)) {
        $permitted = $staged -in $paths -or $staged.StartsWith('smash-nine-prototype/scripts/monsters/') -or $staged.StartsWith('reports/codex-sys-01/')
        if (-not $permitted) { throw "Unrelated staged path: $staged. Resolve it before committing this unit." }
    }
    & git add -- @paths
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit attempted.' }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
    $message = @'
Give realm monsters readable archetypes, elites and paced spawns

Assign all 18 skins to 10 telegraphed archetypes. Add realm guardians,
phase-aware regular populations, delayed slot refills and defeat feedback.
Preserve the bot API and regular D7 damage/knockback caps.

Validation and paired soak measurements: reports/codex-sys-01/README.md.

Co-Authored-By: Codex <noreply@openai.com>
'@
    $messagePath = Join-Path $env:TEMP 'SmashNine-sys01-commit-message.txt'
    [IO.File]::WriteAllText($messagePath, $message, [Text.UTF8Encoding]::new($false))
    & git commit --file $messagePath
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally { Pop-Location }
