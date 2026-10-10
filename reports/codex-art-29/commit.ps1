$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repo

$allowed = @(
	'smash-nine-prototype/characters/nova/Nova.gd',
	'smash-nine-prototype/characters/yuki/Yuki.gd',
	'smash-nine-prototype/characters/rio/Rio.gd',
	'smash-nine-prototype/tests/test_moves_sheet.gd',
	'reports/codex-art-29'
)

$alreadyStaged = @(git diff --cached --name-only)
$outside = @($alreadyStaged | Where-Object {
	$name = $_
	-not ($allowed | Where-Object { $name -eq $_ -or $name.StartsWith("$_/") })
})
if ($outside.Count -gt 0) {
	throw "Refusing to commit pre-staged paths outside CODEX-ART-29: $($outside -join ', ')"
}

git add -- $allowed
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }

$message = @"
Wire Nova Yuki and Rio move rows

Co-Authored-By: Codex <noreply@openai.com>
"@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
