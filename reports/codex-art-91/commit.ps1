param()
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($branch -ne 'codex/art-91') { throw "Wrong branch: $branch" }
$manifest = Join-Path $PSScriptRoot 'commit-paths.txt'
$paths = @([IO.File]::ReadAllLines($manifest, [Text.Encoding]::UTF8) | Where-Object { $_.Trim() })
$paths += @('reports/codex-art-91/inventory.md', 'reports/codex-art-91/inventory.json', 'design/tasks/CODEX-ART-91.md', 'design/tasks/CODEX-ART-91.prompt.md')
$paths = @($paths | Sort-Object -Unique)
foreach ($path in $paths) {
    if ($path -match '(^|/)(raw|__pycache__)(/|$)|run\.log$' -or $path -match '\.\.') { throw "Forbidden path: $path" }
    if ($path -notmatch '^(art/bakeoff/monsters/[^/]+-(appear|rage|sleep|flee)-v1\.(png|json)|reports/codex-art-91/[^/]+|design/tasks/CODEX-ART-91(\.prompt)?\.md)$') { throw "Outside task scope: $path" }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $path) -PathType Leaf)) { throw "Missing file: $path" }
}
# Stage only explicit delivery paths. Never force-add raw images or unrelated files.
$pathspec = Join-Path $env:TEMP ('art91-pathspec-' + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllLines($pathspec, $paths, (New-Object Text.UTF8Encoding($false)))
    & git add --pathspec-from-file=$pathspec
    if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
    Write-Host "Staged $($paths.Count) explicit ART-91 paths. Review and commit as lead. No commit executed."
} finally {
    if (Test-Path -LiteralPath $pathspec) { Remove-Item -LiteralPath $pathspec }
}
