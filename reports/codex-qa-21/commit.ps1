$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location $repo
try {
    if ((git branch --show-current).Trim() -ne 'codex/qa-21') { throw 'Run this in the analyst clone on codex/qa-21.' }
    $allowed = @('reports/codex-qa-21/', 'smash-nine-prototype/tests/analysis/codex_qa_21/')
    $staged = @(git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
    foreach ($file in $staged) {
        if (!($allowed | Where-Object { $file.StartsWith($_) }) -or $file -match '(^|/)__pycache__(/|$)' -or $file -match '^reports/codex-qa-21/(web/|run.log$|story-save-test.cfg$)') {
            throw "Unrelated or excluded staged file; leave it untouched: $file"
        }
    }
    $files = @(git ls-files --cached --modified --others --exclude-standard -- 'reports/codex-qa-21' 'smash-nine-prototype/tests/analysis/codex_qa_21') | Sort-Object -Unique
    $files = @($files | Where-Object { $_ -notmatch '(^|/)__pycache__(/|$)' -and $_ -notmatch '^reports/codex-qa-21/(web/|run.log$|story-save-test.cfg$)' })
    if (!$files.Count) { throw 'No QA-21 files to stage.' }
    git -c core.autocrlf=false add -- $files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed; no commit attempted.' }
    # Keep whitespace in engine logs as evidence; validate authored source/report files.
    $checkFiles = @($files | Where-Object { $_ -notlike '*.log' })
    git diff --cached --check -- $checkFiles
    if ($LASTEXITCODE -ne 0) { throw 'Staged source/report whitespace check failed.' }
    git commit --file (Join-Path $PSScriptRoot 'commit-message.txt')
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally { Pop-Location }
