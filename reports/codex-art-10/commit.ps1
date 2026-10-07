$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Push-Location $repoRoot
try {
	git add -- 'smash-nine-prototype/assets/art/vfx' 'smash-nine-prototype/tests/art_preview/ult_vfx_b' 'reports/codex-art-10'
	$message = @'
Add ultimate VFX art for five fighters

Co-Authored-By: Codex <noreply@openai.com>
'@
	git commit -m $message
}
finally {
	Pop-Location
}
