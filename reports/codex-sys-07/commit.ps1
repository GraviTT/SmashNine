$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = git branch --show-current
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/sys-07') { throw 'Expected codex/sys-07.' }
$files = @(
    'smash-nine-prototype/scripts/Projectile.gd',
    'smash-nine-prototype/scripts/RealmMonster.gd',
    'smash-nine-prototype/tests/test_projectile_art.gd',
    'smash-nine-prototype/tests/run_all.ps1',
    'smash-nine-prototype/assets/art/monsters/README.md',
    'reports/codex-sys-07/README.md',
    'reports/codex-sys-07/validation.txt',
    'reports/codex-sys-07/commit.ps1'
)
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
$unrelated = @($staged | Where-Object { $_ -notin $files })
if ($unrelated.Count) { throw "Unrelated files already staged: $($unrelated -join ', ')" }
git diff --check -- @files
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
$body = @'
Wire monster projectile strips and optional slam shockwave art

Keep fighter art and combat unchanged; support file-copy adoption with crest fallback.
Add procedural-image regression coverage and document adoption paths.

Co-Authored-By: Codex <noreply@openai.com>
'@
$messageFile = New-TemporaryFile
try {
    [IO.File]::WriteAllText($messageFile.FullName, $body, (New-Object Text.UTF8Encoding($false)))
    git commit --file $messageFile.FullName
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
} finally {
    Remove-Item -LiteralPath $messageFile.FullName
}
