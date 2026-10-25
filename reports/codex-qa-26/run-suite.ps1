$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source=Join-Path $root 'smash-nine-prototype'
$runtime=Join-Path $PSScriptRoot 'runtime'
$project=Join-Path $runtime 'smash-nine-prototype'
$utf8=New-Object Text.UTF8Encoding($false)
function Processes([string]$label){
 $psi=New-Object Diagnostics.ProcessStartInfo
 $psi.FileName='C:/Windows/System32/tasklist.exe';$psi.Arguments='/FO CSV'
 $psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
 $p=[Diagnostics.Process]::Start($psi);$o=$p.StandardOutput.ReadToEndAsync();$e=$p.StandardError.ReadToEndAsync();$p.WaitForExit()
 $raw=$o.Result+"`n"+$e.Result
 $filtered=@($raw -split "`n"|Where-Object{$_ -match '(?i)godot|codex|error|access|denied|Image Name'}) -join "`n"
 $fallback=@([Diagnostics.Process]::GetProcesses()|Where-Object{$_.ProcessName -match '(?i)godot|codex'}|ForEach-Object{[pscustomobject]@{name=$_.ProcessName;pid=$_.Id}})
 [IO.File]::WriteAllText((Join-Path $PSScriptRoot "processes-$label.txt"),('UTC '+[DateTime]::UtcNow.ToString('o')+"`nTASKLIST exit="+$p.ExitCode+"`n"+$filtered+"`nFALLBACK GetProcesses`n"+($fallback|ConvertTo-Json)), $utf8)
}
[IO.Directory]::CreateDirectory($project)|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $runtime 'reports/codex-sys-08'))|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $runtime 'design'))|Out-Null
[IO.Directory]::CreateDirectory((Join-Path $PSScriptRoot 'tmp'))|Out-Null
# Exact file copies keep res://../reports writes inside this card. No test string is patched.
& C:/Windows/System32/robocopy.exe $source $project /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP /XD (Join-Path $source '.godot/shader_cache') (Join-Path $source '.godot/editor') > (Join-Path $PSScriptRoot 'copy.log')
if($LASTEXITCODE -ge 8){throw "Runtime copy failed: robocopy exit $LASTEXITCODE"}
Copy-Item -LiteralPath (Join-Path $root 'design/AUDIO.md') -Destination (Join-Path $runtime 'design/AUDIO.md')
$inventory=@(Get-ChildItem -LiteralPath $project -Recurse -File -Force|ForEach-Object{$_.FullName.Substring($PSScriptRoot.Length+1).Replace('\','/')})
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'runtime-files.txt'),($inventory -join "`n")+"`n",$utf8)
$hashes=@(Get-ChildItem -LiteralPath $source -Recurse -File -Force|Where-Object{$_.Extension -in @('.gd','.gdshader','.tscn','.tres','.godot','.ps1','.csv') -and $_.FullName -notlike '*\.godot\*'}|ForEach-Object{
 $rel=$_.FullName.Substring($source.Length+1)
 $a=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
 $b=(Get-FileHash -LiteralPath (Join-Path $project $rel) -Algorithm SHA256).Hash
 if($a -ne $b){throw "Copy hash mismatch: $rel"}
 @{path=$rel.Replace('\','/');sha256=$a}
})
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'source-hashes.json'),($hashes|ConvertTo-Json -Depth 4),$utf8)
Processes 'start'
$env:GODOT_BIN='C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe'
$env:GODOT_TEST_LOG_DIR=Join-Path $PSScriptRoot 'logs'
$env:TEMP=Join-Path $PSScriptRoot 'tmp'
$env:TMP=$env:TEMP
$env:STORY_FACE_REPORT=Join-Path $PSScriptRoot 'story-faces.json'
$start=[DateTime]::UtcNow
Push-Location $project
try {
 & powershell -NoProfile -ExecutionPolicy Bypass -File tests/run_all.ps1 2>&1 | Tee-Object -FilePath (Join-Path $PSScriptRoot 'suite.log')
 $code=$LASTEXITCODE
} finally {Pop-Location}
$end=[DateTime]::UtcNow
Processes 'end'
$changes=@()
foreach($h in $hashes){$actual=(Get-FileHash -LiteralPath (Join-Path $source $h.path) -Algorithm SHA256).Hash;if($actual -ne $h.sha256){$changes+=$h.path}}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'run.json'),(@{start_utc=$start.ToString('o');end_utc=$end.ToString('o');wall_seconds=($end-$start).TotalSeconds;exit=$code;execution_project=$project;source_files_verified=$hashes.Count;source_changes=$changes;runtime_file_count=$inventory.Count}|ConvertTo-Json -Depth 5),$utf8)
Write-Output "QA26_DONE exit=$code wall_seconds=$(($end-$start).TotalSeconds) source_changes=$($changes.Count)"
exit $code
