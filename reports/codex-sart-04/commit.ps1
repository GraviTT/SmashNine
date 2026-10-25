$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path

function Assert-GitOk([string] $action) {
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $action (exit $LASTEXITCODE)" }
}

$branch = & git -C $repoRoot branch --show-current
Assert-GitOk 'read branch'
if ($branch.Trim() -ne 'codex/sart-04') {
    throw "Expected codex/sart-04, found $branch. No files staged."
}

$allowed = '^(art/bakeoff/story/(map_[^/]+|shadow_dissolve[^/]+)\.(png|json)|reports/codex-sart-04/[^/]+\.(md|json|py|png|gif|ps1|txt))$'
$stagedBefore = @(& git -C $repoRoot diff --cached --name-only)
Assert-GitOk 'inspect existing index'
foreach ($entry in $stagedBefore) {
    if ($entry -notmatch $allowed) { throw "Unrelated staged path: $entry. No files staged by this script." }
}

# Explicit candidate list: never stage raw generations or another card's output.
$candidateStems = @(
    'map_path_tile-v1', 'map_path_tile-v2',
    'map_marker_next-v1', 'map_marker_next-v2',
    'map_seal_clear-v1', 'map_seal_clear-v2', 'map_seal_clear-v3',
    'map_seal_locked-v1', 'map_seal_locked-v2', 'map_seal_locked-v3',
    'shadow_dissolve-v1', 'shadow_dissolve-v2'
)
$stagePaths = @()
foreach ($stem in $candidateStems) {
    foreach ($extension in @('png', 'json')) {
        $relative = "art/bakeoff/story/$stem.$extension"
        if (-not (Test-Path -LiteralPath (Join-Path $repoRoot $relative) -PathType Leaf)) {
            throw "Missing expected candidate: $relative"
        }
        $stagePaths += $relative
    }
}
foreach ($file in Get-ChildItem -LiteralPath $PSScriptRoot -File) {
    $relative = "reports/codex-sart-04/$($file.Name)"
    if ($relative -match $allowed) { $stagePaths += $relative }
}

& git -C $repoRoot add -- $stagePaths
Assert-GitOk 'stage only card paths'
$stagedAfter = @(& git -C $repoRoot diff --cached --name-only)
Assert-GitOk 'verify staged paths'
foreach ($entry in $stagedAfter) {
    if ($entry -notmatch $allowed) { throw "Unexpected staged path: $entry. Commit aborted." }
}
& git -C $repoRoot diff --cached --check
Assert-GitOk 'whitespace check'

$messagePath = Join-Path $PSScriptRoot 'commit-message.txt'
$message = Get-Content -LiteralPath $messagePath -Raw -Encoding UTF8
if (-not $message.TrimEnd().EndsWith('Co-Authored-By: Codex <noreply@openai.com>')) {
    throw 'Missing required Codex co-author trailer.'
}
& git -C $repoRoot commit --file $messagePath
Assert-GitOk 'commit'
Write-Host 'Committed SART-04 candidates and report only. No merge or push performed.'
