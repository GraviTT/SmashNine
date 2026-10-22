$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$encoding = [Text.UTF8Encoding]::new($false)
$rows = @()
function Save-Text([string]$Path, [string]$Text) { [IO.File]::WriteAllText($Path, $Text, $encoding) }
function Expect-Failure([string]$Script, [string]$Name, [string]$Extra = '') {
    $arguments = @('-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'run.ps1'), '-Script', $Script, '-Name', $Name, '-Realtime')
    if ($Extra) { $arguments += @('-Extra', $Extra) }
    & powershell @arguments
    $code = $LASTEXITCODE
    if ($code -eq 0) { throw "Regression did not fail without the fix: $Name" }
    return @{ name = $Name; expected_nonzero = $true; exit = $code }
}
$gate = Join-Path $repo 'smash-nine-prototype/scripts/realms/RealmHazards.gd'
$finalGate = [IO.File]::ReadAllText($gate)
try {
    Save-Text $gate ($finalGate.Replace('GATE_COOLDOWN := 2.5', 'GATE_COOLDOWN := 1.0'))
    $result = Expect-Failure 'tests/test_realm_gimmicks.gd' 'gate-no-fix'
    $rows += $result[-1]
} finally { Save-Text $gate $finalGate }
$audio = Join-Path $repo 'smash-nine-prototype/scripts/audio/AudioManager.gd'
$finalAudio = [IO.File]::ReadAllText($audio)
try {
    $old = [regex]::Replace($finalAudio, '(?ms)^func gap_usec\(id: String\) -> int:.*?(?=^## Both)', "func gap_usec(_id: String) -> int:`n`treturn 40000`n`n")
    $old = [regex]::Replace($old, '(?ms)^static func landing\(source: Node, landed: bool\) -> void:.*?(?=^func _forget_landing)', "static func landing(source: Node, landed: bool) -> void:`n`tif landed:`n`t`tsound(source, `"land`")`n`n")
    Save-Text $audio $old
    $result = Expect-Failure 'tests/test_audio.gd' 'audio-no-fix' '--sys08-audio-only'
    $rows += $result[-1]
} finally { Save-Text $audio $finalAudio }
$storyPaths = @('scripts/story/StorySession.gd', 'scripts/ui/StoryDialogue.gd', 'scripts/ui/StoryScreens.gd')
$snapshots = @{}
$capturePath = Join-Path $PSScriptRoot 'sound-story-1.json'
$finalCapture = [IO.File]::ReadAllText($capturePath)
try {
    foreach ($relative in $storyPaths) {
        $path = Join-Path $repo "smash-nine-prototype/$relative"
        $snapshots[$path] = [IO.File]::ReadAllText($path)
        $lines = $snapshots[$path] -split "`n" | Where-Object {
            $_ -notmatch 'AUDIO\.sound\(self, "story_text"\)|AUDIO\.story_advance\(self, action\)|AUDIO\.story_result\(self, bool\(result.clear\)\)|AUDIO\.story_ending\(self\)|preload\("res://scripts/audio/AudioManager.gd"\)\.sound\(hero, "portal"\)'
        }
        Save-Text $path ($lines -join "`n")
    }
    $result = Expect-Failure 'tests/analysis/codex_sys_08/sound_story.gd' 'story-no-fix' '--stage=1'
    $rows += $result[-1]
    Copy-Item -LiteralPath $capturePath -Destination (Join-Path $PSScriptRoot 'story-no-fix.json')
} finally {
    foreach ($path in $snapshots.Keys) { Save-Text $path $snapshots[$path] }
    Save-Text $capturePath $finalCapture
}
Save-Text (Join-Path $PSScriptRoot 'regression-checks.json') ($rows | ConvertTo-Json -Depth 8)
Write-Output 'SYS08 all three regressions fail without their fixes; final sources restored.'
