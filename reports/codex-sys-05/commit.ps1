# Review and run from this clone only. SYS-05 never executes this script itself.
$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
if ((git branch --show-current).Trim() -ne 'codex/sys-05') {
	throw 'Expected branch codex/sys-05.'
}
$files = @(
	'design/AUDIO.md',
	'smash-nine-prototype/scripts/audio/AudioCatalog.gd',
	'smash-nine-prototype/scripts/audio/AudioCatalog.gd.uid',
	'smash-nine-prototype/scripts/audio/AudioManager.gd',
	'smash-nine-prototype/scripts/audio/AudioManager.gd.uid',
	'smash-nine-prototype/scripts/audio/AudioSettings.gd',
	'smash-nine-prototype/scripts/audio/AudioSettings.gd.uid',
	'smash-nine-prototype/characters/common/PlayerBase.gd',
	'smash-nine-prototype/scripts/RealmMonster.gd',
	'smash-nine-prototype/scripts/RealmMonsterSpawner.gd',
	'smash-nine-prototype/scripts/realms/RealmHazards.gd',
	'smash-nine-prototype/scripts/ui/MatchHud.gd',
	'smash-nine-prototype/scripts/ui/FrontendMenu.gd',
	'smash-nine-prototype/scripts/Main.gd',
	'smash-nine-prototype/assets/i18n/strings.csv',
	'smash-nine-prototype/tests/test_audio.gd',
	'smash-nine-prototype/tests/run_all.ps1',
	'reports/codex-sys-05/README.md',
	'reports/codex-sys-05/probe.json',
	'reports/codex-sys-05/source-audit.json',
	'reports/codex-sys-05/build_catalog.cjs',
	'reports/codex-sys-05/audit.cjs',
	'reports/codex-sys-05/write_report.cjs',
	'reports/codex-sys-05/verification.json',
	'reports/codex-sys-05/wiring.svg',
	'reports/codex-sys-05/fix-1.prompt.md',
	'reports/codex-sys-05/commit.ps1'
)
# Refuse to commit an unrelated pre-staged change from another session.
$staged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the index.' }
foreach ($path in $staged) {
	if ($files -notcontains $path) { throw "Unrelated staged file: $path" }
}
foreach ($path in $files) {
	if ($path -match '(__pycache__|\.log$)') { throw "Forbidden artifact: $path" }
	if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing deliverable: $path" }
}
& git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed (no force-add is permitted).' }
$message = @'
Wire audio with watched-realm filtering and human progress cues

Add silent fallbacks, pooled playback, music crossfades and persisted volume options. Filter world audio against Main's watched realm, restrict progress cues to is_human and sound only user focus navigation. Cover realm switches, story reloads, UI focus and the full headless suite without changing gameplay rules.

Co-Authored-By: Codex <noreply@openai.com>
'@
& git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
