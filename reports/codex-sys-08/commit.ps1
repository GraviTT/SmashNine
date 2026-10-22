$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/sys-08') { throw "Expected codex/sys-08, got $branch" }
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'files.txt') -Encoding UTF8 | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
$singleFiles = @('design/AUDIO.md','smash-nine-prototype/scripts/realms/RealmHazards.gd','smash-nine-prototype/scripts/story/StorySession.gd','smash-nine-prototype/scripts/ui/StoryDialogue.gd','smash-nine-prototype/scripts/ui/StoryScreens.gd','smash-nine-prototype/tests/test_audio.gd','smash-nine-prototype/tests/test_realm_gimmicks.gd')
foreach ($file in $files) {
    if ($file -match '(^|/)__pycache__(/|$)|\.pyc$|(^|/)\.\.(/|$)' -or [IO.Path]::IsPathRooted($file)) { throw "Forbidden path: $file" }
    if ($file -notin $singleFiles -and $file -notmatch '^(smash-nine-prototype/scripts/audio/|smash-nine-prototype/tests/analysis/codex_sys_08/|reports/codex-sys-08/)') { throw "Outside card: $file" }
    $absolute = [IO.Path]::GetFullPath((Join-Path $repo $file))
    if (-not $absolute.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Outside clone: $file" }
    $item = Get-Item -LiteralPath $absolute
    if ($item.PSIsContainer -or $item.Attributes.HasFlag([IO.FileAttributes]::ReparsePoint)) { throw "Expected ordinary file: $file" }
    if ($item.Extension -eq '.log' -and $item.Length -gt 1MB) { throw "Log exceeds 1 MB: $file" }
}
$staged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index' }
foreach ($file in $staged) { if ($file -notin $files) { throw "Unrelated staged file: $file" } }
& node (Join-Path $PSScriptRoot 'verify.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Verification failed' }
& git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed (no force-add attempted)' }
$staged = @(& git diff --cached --name-only)
foreach ($file in $staged) { if ($file -notin $files) { throw "Unexpected staged file: $file" } }
$message = "fix: limit moon gate re-crossing and audio request rates; wire story sound hooks`n`nCo-Authored-By: Codex <noreply@openai.com>"
$bodyFile = [IO.Path]::GetTempFileName()
try {
    [IO.File]::WriteAllText($bodyFile, $message, [Text.UTF8Encoding]::new($false))
    & git commit --file $bodyFile
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed' }
} finally { Remove-Item -LiteralPath $bodyFile -ErrorAction SilentlyContinue }
