$root=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$suite=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'suite.log'))
$tests=@()
foreach($line in ($suite -split "`n")){
 if($line -match '^(PASS|FAIL) (test_\S+|visual_preview)\s*(.*)$'){
  $tests+=@{test=$Matches[2];status=$Matches[1];detail=$Matches[3].Trim()}
 }
}
$errors=@();$certificate=0
foreach($file in (Get-ChildItem (Join-Path $PSScriptRoot 'logs') -File -Filter '*.log')){
 foreach($line in ([IO.File]::ReadAllText($file.FullName) -split "`n")){
  if($line.Trim() -eq 'ERROR: Failed to read the root certificate store.'){$certificate++;continue}
  if($line -match '^\s*(SCRIPT ERROR|ERROR|Parse Error)'){$errors+=@{log=$file.Name;line=$line.Trim()}}
 }
}
$soaks=@()
foreach($entry in @(@('QA-22','reports/codex-qa-22/suite-summary.log'),@('SYS-09','reports/codex-sys-09/full-suite.log'),@('QA-26','reports/codex-qa-26/suite.log'))){
 $text=[IO.File]::ReadAllText((Join-Path $root $entry[1]))
 $matchesSoak=[regex]::Matches($text,'SOAK_RESULT (\{[^\r\n]+\})')
 if($matchesSoak.Count){$data=$matchesSoak[$matchesSoak.Count-1].Groups[1].Value|ConvertFrom-Json;$soaks+=@{run=$entry[0];source=$entry[1];result=$data}}
}
$run=Get-Content -Raw (Join-Path $PSScriptRoot 'run.json')|ConvertFrom-Json
$summary=@{tests=$tests;passed=@($tests|Where-Object{$_.status -eq 'PASS'}).Count;failed=@($tests|Where-Object{$_.status -eq 'FAIL'}).Count;engine_errors=$errors;certificate_noise=$certificate;soaks=$soaks;run=$run}
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'summary.json'),($summary|ConvertTo-Json -Depth 12))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'test-table.md'),("| Test | Result |`n|---|---|`n"+(($tests|ForEach-Object{'| '+$_.test+' | '+$_.status+' |'}) -join "`n")+"`n"))
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'engine-errors.txt'),($(if($errors.Count){($errors|ForEach-Object{$_.log+': '+$_.line}) -join "`n"}else{'No engine errors other than the known certificate-store noise.'})+"`n"))
Write-Output "tests=$($tests.Count) passed=$($summary.passed) failed=$($summary.failed) errors=$($errors.Count) certificate=$certificate"
$soaks|ForEach-Object{Write-Output ($_.run+' '+($_.result|ConvertTo-Json -Compress))}
