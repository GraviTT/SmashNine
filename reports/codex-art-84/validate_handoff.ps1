# Read-only Git checks and PowerShell parsing. Never invokes commit.ps1.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$outPath = Join-Path $PSScriptRoot 'commit-validation.json'
if (Test-Path -LiteralPath $outPath) { throw 'Existing result; never overwrite.' }
$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'commit.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw ($parseErrors | Out-String) }
$paths = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'commit-files.txt') -Encoding UTF8)
$invalid = @()
foreach ($p in $paths) {
    $allowed = $p -match '^art/bakeoff/(frey|luna|yuki|nova|rio)/[a-z_]+_face-(hurt|shadow)-v2\.(png|json)$' -or
               $p -match '^reports/codex-art-84/[A-Za-z0-9_.-]+\.(png|json|py|md|ps1|txt)$' -or
               $p -in @('design/tasks/CODEX-ART-84.md','design/tasks/CODEX-ART-84.prompt.md')
    if (-not $allowed -or $p -match '(art/raw/|__pycache__|run\.log|(^|/)\.\.(/|$)|attempt)') { $invalid += $p }
    if ($p -ne 'reports/codex-art-84/commit-validation.json' -and -not (Test-Path -LiteralPath (Join-Path $repoRoot $p) -PathType Leaf)) { $invalid += "Missing: $p" }
}
Push-Location -LiteralPath $repoRoot
try {
    $protectedChanges = @(& git status --porcelain --untracked-files=all -- smash-nine-prototype tools)
    $staged = @(& git diff --cached --name-only)
    $ignored = @(& git check-ignore art/raw/faces-84/yuki-neutral.png)
    $message = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'commit-message.txt'))
    $result = [ordered]@{
        syntax_errors = $parseErrors.Count
        list_count = $paths.Count
        duplicate_count = $paths.Count - @($paths | Select-Object -Unique).Count
        invalid_paths = $invalid
        card_included = $paths -contains 'design/tasks/CODEX-ART-84.md'
        prompt_included = $paths -contains 'design/tasks/CODEX-ART-84.prompt.md'
        coauthor_trailer_valid = $message.TrimEnd().EndsWith('Co-Authored-By: Codex <noreply@openai.com>')
        protected_path_changes = $protectedChanges
        staged_paths = $staged
        raw_is_ignored = $ignored.Count -eq 1
        commit_script_executed = $false
        staging_executed = $false
    }
    if ($invalid.Count -gt 0 -or $result.duplicate_count -gt 0 -or $protectedChanges.Count -gt 0 -or -not $result.coauthor_trailer_valid) { throw 'Handoff validation failed.' }
    $json = $result | ConvertTo-Json -Depth 5
    $stream = [IO.File]::Open($outPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write)
    try {
        $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json + "`n")
        $stream.Write($bytes,0,$bytes.Length)
    }
    finally { $stream.Dispose() }
    Write-Output $json
}
finally { Pop-Location }
