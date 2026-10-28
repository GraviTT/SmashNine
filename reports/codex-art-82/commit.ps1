$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/art-82') {
    throw 'Run this script only in the ART-82 clone on codex/art-82.'
}
& git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { throw 'The index must be empty before staging ART-82 files.' }
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'commit-files.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
if ($files.Count -eq 0) { throw 'Empty ART-82 manifest.' }
foreach ($file in $files) {
    if ($file -match '(^art/raw/|__pycache__|(^|/)run\.log$)' -or $file -match '\.\.') {
        throw "Forbidden file in manifest: $file"
    }
    $allowed = $file.StartsWith('reports/codex-art-82/') -or
        $file -in @('design/tasks/CODEX-ART-82.md', 'design/tasks/CODEX-ART-82.prompt.md') -or
        $file -match '^art/bakeoff/(luna/(luna-victory-v2|luna_brave-victory-v2|luna-jump-v4)|nova/nova_female-victory-v2|rio/(rio_female-victory-v2|rio_male-victory-v2)|yuki/yuki-fall-v3)\.(png|json)$'
    if (-not $allowed) { throw "Out-of-scope file: $file" }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
}
# Small batches avoid the Windows command-line length limit.
for ($offset = 0; $offset -lt $files.Count; $offset += 40) {
    $last = [Math]::Min($offset + 39, $files.Count - 1)
    $batch = @($files[$offset..$last])
    & git -c core.autocrlf=false add -- $batch
    if ($LASTEXITCODE -ne 0) { throw 'ART-82 staging failed. No commit was attempted.' }
}
$staged = @(& git -c core.quotepath=false diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the staged paths.' }
$unexpected = @($staged | Where-Object { $_ -notin $files })
if ($unexpected.Count -ne 0) { throw "Unexpected staged paths: $unexpected" }
$message = @'
art: add seven character motion repair candidates for ART-82

Preserve existing candidates and document six withheld rows plus three partial repairs.
Include strict face measurements, 4x comparisons, generation provenance and asset checks.

Co-Authored-By: Codex <noreply@openai.com>
'@
$message | & git -c core.autocrlf=false commit --file -
if ($LASTEXITCODE -ne 0) { throw 'ART-82 commit failed.' }
