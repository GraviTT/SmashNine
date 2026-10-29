# Prepared for the lead. ART-88 does not execute this script.
$ErrorActionPreference = 'Stop'
$repo88 = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$list88 = Join-Path $PSScriptRoot 'delivery-files.txt'
$message88 = Join-Path $PSScriptRoot 'commit-message.txt'
$delivery88 = Get-Content -Raw -Encoding UTF8 (Join-Path $PSScriptRoot 'delivery.json') | ConvertFrom-Json
$paths88 = @(Get-Content -Encoding UTF8 $list88 | Where-Object { $_.Length -gt 0 })
$allowedArt88 = @($delivery88.rows) + @($delivery88.metadata | ForEach-Object { $_.path }) + @($delivery88.sheets | ForEach-Object { $_.path })
$cards88 = @('design/tasks/CODEX-ART-88.md', 'design/tasks/CODEX-ART-88.prompt.md')
if ($paths88.Count -eq 0 -or (@($paths88 | Select-Object -Unique)).Count -ne $paths88.Count) {
    throw 'Empty or duplicate delivery path list.'
}
foreach ($path88 in $paths88) {
    if ([IO.Path]::IsPathRooted($path88) -or $path88.Contains('\') -or $path88 -match '(^|/)\.\.(/|$)' -or
        $path88 -match '(^|/)(qa23|ref81|__pycache__|review-rows)(/|$)|(^|/)run\.log$|^art/raw/') {
        throw "Forbidden delivery path: $path88"
    }
    $report88 = $path88 -match '^reports/codex-art-88/[^/]+$' -or $path88 -match '^reports/codex-art-88/before/[^/]+\.png$'
    if ($path88 -notin $allowedArt88 -and $path88 -notin $cards88 -and -not $report88) {
        throw "Not an ART-88 delivery path: $path88"
    }
    $full88 = [IO.Path]::GetFullPath((Join-Path $repo88 $path88))
    if (-not $full88.StartsWith($repo88 + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes this clone: $path88"
    }
    if (-not (Test-Path -LiteralPath $full88 -PathType Leaf)) { throw "Missing delivery file: $path88" }
}
foreach ($card88 in $cards88) {
    if ($card88 -notin $paths88) { throw "Required card/prompt missing: $card88" }
}
$coauthor88 = 'Co-Authored-By: Codex <noreply@openai.com>'
if (-not ([IO.File]::ReadAllText($message88).TrimEnd().EndsWith($coauthor88))) {
    throw 'Commit message must end with the Codex co-author line.'
}
Push-Location -LiteralPath $repo88
$oldLiteral88 = $env:GIT_LITERAL_PATHSPECS
try {
    $branch88 = & git branch --show-current
    if ($LASTEXITCODE -ne 0 -or $branch88 -ne 'codex/art-88') { throw 'Run only in the codex/art-88 clone.' }
    $staged88 = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect the git index.' }
    if ($staged88.Count -ne 0) { throw 'Index is not empty; preserve other staged work and inspect it before running this script.' }
    $env:GIT_LITERAL_PATHSPECS = '1'
    & git add "--pathspec-from-file=$list88"
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit attempted.' }
    $staged88 = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to check staged paths.' }
    foreach ($path88 in $staged88) {
        if ($path88 -notin $paths88) { throw "Unexpected staged path: $path88" }
    }
    & git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed.' }
    & git commit --file $message88
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally {
    $env:GIT_LITERAL_PATHSPECS = $oldLiteral88
    Pop-Location
}
