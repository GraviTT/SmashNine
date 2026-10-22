$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$env:PYTHONDONTWRITEBYTECODE = '1'
$python = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
function Run-Python([string[]] $Arguments) {
    & $python @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Python failed: $Arguments" }
}
$ids = @('muspelheim_magma_boar','niflheim_glacier_wolf','niflheim_frost_owl','jotunheim_storm_wisp','yggdrasil_root_guardian','yggdrasil_root_oracle')
$rows = @('idle','walk','windup','attack','hurt','defeat')
$factors = @(
    @(0.19,0.19,0.14,0.18,0.11,0.16),
    @(0.175,0.17,0.13,0.21,0.105,0.14),
    @(0.17,0.17,0.16,0.2,0.11,0.15),
    @(0.18,0.175,0.14,0.18,0.11,0.15),
    @(0.15,0.15,0.185,0.17,0.1,0.14),
    @(0.19,0.175,0.18,0.2,0.095,0.16)
)
$eyes = @{
    idle = '379,297;358,297;338,299;379,255;352,254;336,254'
    walk = '406,319;384,320;368,323;414,260;385,261;370,267'
    windup = '525,293;379,270;500,181;392,182'
    attack = '373,300;347,298;334,300;374,245;347,247;336,248'
    hurt = '678,476;610,575'
}
for ($i=0; $i -lt $ids.Count; $i++) {
    $mid=$ids[$i]
    for ($j=0; $j -lt $rows.Count; $j++) {
        $row=$rows[$j]
        $factor=([double]$factors[$i][$j]).ToString('0.########', [Globalization.CultureInfo]::InvariantCulture)
        $rowArgs=@('reports/codex-art-76/process.py',$mid,$row,$factor)
        $ground=$i -in @(0,1,2,4) -and -not ($i -eq 1 -and $row -eq 'attack')
        if ($i -eq 5 -and $row -in @('walk','windup','attack','hurt')) { $ground=$true }
        if ($ground) { $rowArgs+='--ground' }
        if ($i -eq 1) { $rowArgs+=@('--offset','2') }
        if ($i -eq 4 -and $row -eq 'defeat') { $rowArgs+=@('--offset','3') }
        Run-Python -Arguments $rowArgs
        if ($i -eq 3 -and $row -ne 'defeat') { Run-Python -Arguments @('reports/codex-art-76/wisp_core.py',$row,'--align') }
        if ($i -eq 5 -and $row -ne 'defeat') { Run-Python -Arguments @('reports/codex-art-76/process.py','align',$mid,$row,$eyes[$row]) }
        if ($i -eq 1 -and $row -eq 'attack') { Run-Python -Arguments @('reports/codex-art-76/process.py','contacts',$mid,$row,'0,4,5') }
        if ($i -in @(3,5) -and $row -eq 'defeat') { Run-Python -Arguments @('reports/codex-art-76/process.py','contacts',$mid,$row,'2,3') }
    }
    Run-Python -Arguments @('reports/codex-art-76/process.py','board',$mid)
}
foreach ($script in @('verify.py','ruler_boards.py','annotate_evidence.py','finish_motion_evidence.py','build_report.py')) {
    Run-Python -Arguments @("reports/codex-art-76/$script")
}
node tools/motion_viewer/build.mjs
if ($LASTEXITCODE -ne 0) { throw 'Viewer build failed.' }
node reports/codex-art-76/verify_viewer.mjs
if ($LASTEXITCODE -ne 0) { throw 'Viewer check failed.' }
