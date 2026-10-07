$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $repoRoot

$allowedRoots = @(
	"smash-nine-prototype/assets/art/frey/",
	"smash-nine-prototype/tests/art_preview/frey/",
	"reports/codex-art-02/"
)

git add -- `
	"smash-nine-prototype/assets/art/frey" `
	"smash-nine-prototype/tests/art_preview/frey" `
	"reports/codex-art-02"

$staged = @(git diff --cached --name-only)
if ($staged.Count -eq 0) {
	throw "No writable-path changes were staged."
}

foreach ($path in $staged) {
	$allowed = $false
	foreach ($root in $allowedRoots) {
		if ($path.Replace("\", "/").StartsWith($root)) {
			$allowed = $true
			break
		}
	}
	if (-not $allowed) {
		throw "Refusing to commit staged path outside CODEX-ART-02 scope: $path"
	}
}

git commit -m "art: add original Frey sprite sheet candidate" -m "Co-Authored-By: Codex <noreply@openai.com>"
