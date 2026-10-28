# Lead handoff. Not executed by the Builder. Default: stage only; -Commit opts in.
[CmdletBinding()]
param([switch]$Commit)

$ErrorActionPreference = 'Stop'
$taskRepo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$taskPathspec = Join-Path $PSScriptRoot 'commit-paths.txt'
$taskPaths = @(Get-Content -Encoding UTF8 -LiteralPath $taskPathspec | Where-Object { $_.Length -gt 0 })

Push-Location -LiteralPath $taskRepo
try {
    $taskTop = (& git rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Not a Git repository.' }
    if ((Resolve-Path -LiteralPath $taskTop).Path -ne $taskRepo) { throw 'Unexpected repository root.' }
    $taskBranch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $taskBranch -ne 'codex/tool-04') { throw 'Run on codex/tool-04 only.' }

    $taskAllowed = @(
        'design/tasks/CODEX-TOOL-04.md',
        'design/tasks/CODEX-TOOL-04.prompt.md',
        'tools/compare_viewer/.gitignore',
        'tools/compare_viewer/build.mjs',
        'tools/compare_viewer/index.html',
        'tools/compare_viewer/verify.mjs',
        'tools/compare_viewer/changes.json',
        'tools/compare_viewer/README.md',
        'reports/codex-tool-04/README.md',
        'reports/codex-tool-04/checks.json',
        'reports/codex-tool-04/commit.ps1',
        'reports/codex-tool-04/commit-paths.txt'
    )
    if (@(Compare-Object $taskAllowed $taskPaths).Count -ne 0 -or $taskPaths.Count -ne $taskAllowed.Count) {
        throw 'Pathspec must contain exactly the twelve reviewed task files.'
    }
    foreach ($taskPath in $taskPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $taskRepo $taskPath) -PathType Leaf)) {
            throw "Missing task file: $taskPath"
        }
    }
    $taskStaged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect staging area.' }
    foreach ($taskPath in $taskStaged) {
        if ($taskPaths -notcontains $taskPath) { throw "Unrelated staged file: $taskPath. Review it separately first." }
    }

    & git -c core.autocrlf=false add ('--pathspec-from-file=' + $taskPathspec)
    if ($LASTEXITCODE -ne 0) { throw 'Staging failed; no commit was attempted.' }
    & git diff --cached --stat
    if ($LASTEXITCODE -ne 0) { throw 'Unable to display staged diff.' }
    if ($Commit) {
        & git -c core.autocrlf=false commit -m 'Build separate candidate comparison viewer (TOOL-04)'
        if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
    } else {
        Write-Host 'Task files staged only. Review the diff; rerun with -Commit when ready.'
    }
} finally {
    Pop-Location
}
