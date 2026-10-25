$ErrorActionPreference='Stop'
$report=(Resolve-Path -LiteralPath $PSScriptRoot).Path
$root=(Resolve-Path -LiteralPath (Join-Path $report '../..')).Path
$utf8=New-Object Text.UTF8Encoding($false)
$readme=Join-Path $report 'README.md'
$text=[IO.File]::ReadAllText($readme)
$text=$text.Replace('{{TEST_TABLE}}',[IO.File]::ReadAllText((Join-Path $report 'test-table.md')).Trim())
$text=$text.Replace('08:36:59.649~08:49:46.791','08:36:59.670~08:49:46.812')
[IO.File]::WriteAllText($readme,$text,$utf8)
$suite=Join-Path $report 'suite.log'
[IO.File]::WriteAllText($suite,[IO.File]::ReadAllText($suite),$utf8)
if((Get-Item -LiteralPath $suite).Length -ge 1MB){throw 'suite.log exceeds 1 MB'}
$runtime=(Resolve-Path -LiteralPath (Join-Path $report 'runtime')).Path
$expected=[IO.Path]::GetFullPath((Join-Path $report 'runtime'))
if($runtime -ne $expected -or -not $runtime.StartsWith($report+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw "Unsafe cleanup target: $runtime"}
$files=@(Get-ChildItem -LiteralPath $runtime -Recurse -Force -File)
$inventory=@($files|ForEach-Object{$_.FullName.Substring($root.Length+1).Replace('\','/')})
[IO.File]::WriteAllText((Join-Path $report 'runtime-files.txt'),($inventory -join "`n")+"`n",$utf8)
$bytes=($files|Measure-Object Length -Sum).Sum
Remove-Item -LiteralPath $runtime -Recurse -Force
$record=@{target=$runtime;verified_inside_report=$true;removed=(-not (Test-Path -LiteralPath $runtime));file_count=$files.Count;bytes=$bytes;utc=[DateTime]::UtcNow.ToString('o')}
[IO.File]::WriteAllText((Join-Path $report 'runtime-cleanup.json'),($record|ConvertTo-Json),$utf8)
$manifest=Join-Path $report 'files.txt'
[IO.File]::WriteAllText($manifest,'',$utf8)
$kept=@(Get-ChildItem -LiteralPath $report -Recurse -File -Force|ForEach-Object{$_.FullName.Substring($root.Length+1).Replace('\','/')}|Sort-Object)
[IO.File]::WriteAllText($manifest,("# Retained files`n"+($kept -join "`n")+"`n`n# Transient runtime files written then removed (also runtime-files.txt)`n"+($inventory -join "`n")+"`n"),$utf8)
Write-Output "retained=$($kept.Count) removed_runtime_files=$($files.Count) removed_runtime_bytes=$bytes suite_bytes=$((Get-Item -LiteralPath $suite).Length)"
