$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$listFile = Join-Path $PSScriptRoot 'commit-paths.txt'
$messageFile = Join-Path $PSScriptRoot 'commit-message.txt'
if ((& git -C $repo branch --show-current).Trim() -ne 'codex/art-86') { throw 'Wrong branch; expected codex/art-86.' }
if ($LASTEXITCODE -ne 0) { throw 'Cannot read branch.' }
$paths = @(Get-Content -LiteralPath $listFile -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
if ($paths.Count -eq 0) { throw 'Empty path list.' }
foreach ($entry in $paths) {
    if ($entry -match '(^|/)(art/raw|qa23|__pycache__)(/|$)' -or $entry -match '(^|/)run\.log$') { throw "Excluded path: $entry" }
    $allowed = $entry -match '^art/bakeoff/(frey|nova|rio)/[^/]+\.(png|json)$' -or $entry -match '^reports/codex-art-86/[^/]+$' -or $entry -in @('design/tasks/CODEX-ART-86.md', 'design/tasks/CODEX-ART-86.prompt.md')
    if (-not $allowed -or $entry.Contains('..')) { throw "Path outside task: $entry" }
    $absolute = [IO.Path]::GetFullPath((Join-Path $repo $entry))
    if (-not $absolute.StartsWith($repo + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Path escapes clone: $entry" }
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) { throw "Missing file: $entry" }
}
$staged = @(& git -C $repo diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staging area.' }
foreach ($entry in $staged) { if ($entry -notin $paths) { throw "Unrelated file already staged: $entry" } }
$msg = [IO.File]::ReadAllText($messageFile).TrimEnd()
if (-not $msg.EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) { throw 'Missing final coauthor line.' }
& git -C $repo --literal-pathspecs add "--pathspec-from-file=$listFile"
if ($LASTEXITCODE -ne 0) { throw 'git add failed. No forced add was attempted.' }
& git -C $repo commit "--file=$messageFile"
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
