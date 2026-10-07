$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location -LiteralPath $repoRoot

$existingStaged = @(git diff --cached --name-only)
if ($existingStaged.Count -gt 0) {
	throw "The index already contains staged files. Commit or unstage them before running this script."
}

$allowedPaths = @(
	"smash-nine-prototype/assets/art/luna/luna_brave_generated_source.png",
	"smash-nine-prototype/assets/art/luna/luna_brave_sheet.png",
	"smash-nine-prototype/assets/art/luna/luna_brave_README.md",
	"smash-nine-prototype/assets/art/ui/title_logo.png",
	"smash-nine-prototype/assets/art/ui/title_logo_generated_source.png",
	"smash-nine-prototype/tests/art_preview/luna_brave_a",
	"reports/codex-art-06"
)

git add -- $allowedPaths
if ($LASTEXITCODE -ne 0) {
	throw "git add failed"
}

$staged = @(git diff --cached --name-only)
if ($staged.Count -eq 0) {
	throw "No CODEX-ART-06 changes were staged."
}

foreach ($path in $staged) {
	$normalized = $path.Replace("\", "/")
	$allowed = $normalized -in @(
		"smash-nine-prototype/assets/art/luna/luna_brave_generated_source.png",
		"smash-nine-prototype/assets/art/luna/luna_brave_sheet.png",
		"smash-nine-prototype/assets/art/luna/luna_brave_README.md",
		"smash-nine-prototype/assets/art/ui/title_logo.png",
		"smash-nine-prototype/assets/art/ui/title_logo_generated_source.png"
	) -or $normalized.StartsWith("smash-nine-prototype/tests/art_preview/luna_brave_a/") -or $normalized.StartsWith("reports/codex-art-06/")
	if (-not $allowed) {
		git restore --staged -- $allowedPaths
		throw "Refusing to commit staged path outside CODEX-ART-06 scope: $path"
	}
}

git commit -m "art: add Brave Luna sheet and title logo" -m "Co-Authored-By: Codex <noreply@openai.com>"
if ($LASTEXITCODE -ne 0) {
	throw "git commit failed"
}
