$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $repoRoot
try {
    foreach ($name in @('cg_forest-v1','cg_forest-v2','cg_beast-v3','cg_beast-v4','cg_heart-v1','cg_heart-v2')) {
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot ('art/bakeoff/story/' + $name + '.png')))) {
            throw 'Processed candidates are incomplete. Run the authorized finishing workflow before committing.'
        }
    }
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/sart-01') {
        throw 'Expected branch codex/sart-01. No files were staged.'
    }
    $allowed = @('art/bakeoff/story/', 'reports/codex-sart-01/')
    $staged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect the index.' }
    foreach ($path in $staged) {
        if (-not ($path.StartsWith($allowed[0]) -or $path.StartsWith($allowed[1]))) {
            throw "An unrelated path is already staged: $path. No files were staged."
        }
    }
    & git -c core.autocrlf=false add -- art/bakeoff/story reports/codex-sart-01
    if ($LASTEXITCODE -ne 0) { throw 'Staging failed.' }
    $staged = @(& git diff --cached --name-only)
    foreach ($path in $staged) {
        if (-not ($path.StartsWith($allowed[0]) -or $path.StartsWith($allowed[1]))) {
            throw "Unexpected staged path: $path. Commit stopped."
        }
    }
    & git -c core.autocrlf=false commit --file (Join-Path $PSScriptRoot 'commit-message.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
}
finally {
    Pop-Location
}
