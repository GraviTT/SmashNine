$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location $repo
try {
    if ((git branch --show-current).Trim() -ne 'codex/qa-22') { throw 'Use the analyst clone on codex/qa-22.' }
    $allowed = @('reports/codex-qa-22/', 'smash-nine-prototype/tests/analysis/codex_qa_22/')
    function Test-Allowed([string]$file) {
        if (!($allowed | Where-Object { $file.StartsWith($_) })) { return $false }
        if ($file -match '(^|/)__pycache__(/|$)' -or $file -match '(^|/)run.log$' -or $file -match '\.uid$') { return $false }
        return $true
    }
    foreach ($file in @(git diff --cached --name-only)) {
        if (!(Test-Allowed $file)) { throw "Unrelated or excluded staged file: $file" }
        if ($file -like '*.log' -and [long](git cat-file -s ":$file") -gt 1000000) { throw "Staged log exceeds 1 MB: $file" }
    }
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
    $files = @(git ls-files --cached --modified --others --exclude-standard -- 'reports/codex-qa-22' 'smash-nine-prototype/tests/analysis/codex_qa_22') | Sort-Object -Unique
    $files = @($files | Where-Object {
        (Test-Allowed $_) -and !($_ -like '*.log' -and (Get-Item -LiteralPath $_).Length -gt 1000000)
    })
    if (!$files.Count) { throw 'No QA-22 files to stage.' }
    git -c core.autocrlf=false add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    $checkFiles = @($files | Where-Object { $_ -notlike '*.log' })
    git diff --cached --check -- $checkFiles
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
    git commit --file (Join-Path $PSScriptRoot 'commit-message.txt')
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally { Pop-Location }
