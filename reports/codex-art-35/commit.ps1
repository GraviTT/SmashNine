$ErrorActionPreference = 'Stop'

$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Set-Location $repo

$allowed = @(
	'tools/sprite_pipeline',
	'tools/motion_viewer/build.mjs',
	'tools/motion_viewer/index.html',
	'tools/motion_viewer/README.md',
	'art/bakeoff',
	'reports/codex-art-35'
)

$alreadyStaged = @(git diff --cached --name-only)
$outside = @($alreadyStaged | Where-Object {
	$name = $_
	-not ($allowed | Where-Object { $name -eq $_ -or $name.StartsWith("$_/") })
})
if ($outside.Count -gt 0) {
	throw "Refusing to commit pre-staged paths outside CODEX-ART-35: $($outside -join ', ')"
}

git -c core.autocrlf=false add -- $allowed
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }

$message = @"
Add shared sprite normalization and bakeoff viewer

Co-Authored-By: Codex <noreply@openai.com>
"@
git -c core.autocrlf=false commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
