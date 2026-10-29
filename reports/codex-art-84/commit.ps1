# Prepared for the lead. ART-84 builder does not execute this script.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$listPath = Join-Path $PSScriptRoot 'commit-files.txt'
$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
Push-Location -LiteralPath $repoRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-84') {
        throw 'Run only in the ART-84 clone on codex/art-84.'
    }
    $paths = @(Get-Content -LiteralPath $listPath -Encoding UTF8)
    if ($paths.Count -eq 0 -or ($paths | Select-Object -Unique).Count -ne $paths.Count) {
        throw 'Empty or duplicate path list.'
    }
    foreach ($p in $paths) {
        $allowed = $p -match '^art/bakeoff/(frey|luna|yuki|nova|rio)/[a-z_]+_face-(hurt|shadow)-v2\.(png|json)$' -or
                   $p -match '^reports/codex-art-84/[A-Za-z0-9_.-]+\.(png|json|py|md|ps1|txt)$' -or
                   $p -in @('design/tasks/CODEX-ART-84.md','design/tasks/CODEX-ART-84.prompt.md')
        if (-not $allowed -or $p -match '(art/raw/|__pycache__|run\.log|(^|/)\.\.(/|$)|attempt)') {
            throw "Disallowed path: $p"
        }
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $p) -PathType Leaf)) {
            throw "Missing file: $p"
        }
    }
    $message = [IO.File]::ReadAllText($messagePath)
    if (-not $message.TrimEnd().EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) {
        throw 'Missing required co-author trailer.'
    }
    & git -c core.autocrlf=false add "--pathspec-from-file=$listPath"
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    # --only prevents unrelated pre-existing staged changes entering the commit.
    & git -c core.autocrlf=false commit --only "--pathspec-from-file=$listPath" --file $messagePath
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally {
    Pop-Location
}
