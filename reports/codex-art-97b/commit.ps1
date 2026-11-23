# Prepared for the lead. Not executed by this unit.
$ErrorActionPreference = 'Stop'
$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $Root
$Branch = (& git branch --show-current).Trim()
if ($Branch -ne 'codex/xion-97b') { throw "Unexpected branch: $Branch" }
$Paths = @(
    'design/tasks/CODEX-ART-97.md',
    'art/bakeoff/xion/b/xion-walk-b2.png',
    'art/bakeoff/xion/b/xion-walk-b2.json',
    'art/bakeoff/xion/b/xion-jump-b2.png',
    'art/bakeoff/xion/b/xion-jump-b2.json',
    'art/bakeoff/xion/b/xion-fall-b2.png',
    'art/bakeoff/xion/b/xion-fall-b2.json',
    'art/bakeoff/xion/b/xion-hurt-b2.png',
    'art/bakeoff/xion/b/xion-hurt-b2.json',
    'art/bakeoff/xion/b/xion-land-b2.png',
    'art/bakeoff/xion/b/xion-land-b2.json',
    'reports/codex-art-97b/README.md',
    'reports/codex-art-97b/metrics.json',
    'reports/codex-art-97b/verification.json',
    'reports/codex-art-97b/reproducibility.json',
    'reports/codex-art-97b/workspace-size.json',
    'reports/codex-art-97b/provenance.json',
    'reports/codex-art-97b/prompts.txt',
    'reports/codex-art-97b/overview.png',
    'reports/codex-art-97b/walk.png',
    'reports/codex-art-97b/jump.png',
    'reports/codex-art-97b/fall.png',
    'reports/codex-art-97b/hurt.png',
    'reports/codex-art-97b/land.png',
    'reports/codex-art-97b/walk-4x.gif',
    'reports/codex-art-97b/jump-4x.gif',
    'reports/codex-art-97b/fall-4x.gif',
    'reports/codex-art-97b/hurt-4x.gif',
    'reports/codex-art-97b/land-4x.gif',
    'reports/codex-art-97b/feet.json',
    'reports/codex-art-97b/feet-motion.json',
    'reports/codex-art-97b/onion.png',
    'reports/codex-art-97b/bob.json',
    'reports/codex-art-97b/bob.png',
    'reports/codex-art-97b/scarf.json',
    'reports/codex-art-97b/scarf-landmarks-1.png',
    'reports/codex-art-97b/scarf-landmarks-2.png',
    'reports/codex-art-97b/scarf-landmarks-3.png',
    'reports/codex-art-97b/scarf-landmarks-4.png',
    'reports/codex-art-97b/heads-4x-1.png',
    'reports/codex-art-97b/heads-4x-2.png',
    'reports/codex-art-97b/heads-4x-3.png',
    'reports/codex-art-97b/walk-reference.png',
    'reports/codex-art-97b/current-feet.json',
    'reports/codex-art-97b/prepare.py',
    'reports/codex-art-97b/make_walk_reference.py',
    'reports/codex-art-97b/normalize_trial.py',
    'reports/codex-art-97b/check_walk.py',
    'reports/codex-art-97b/review_assets.py',
    'reports/codex-art-97b/audit.py',
    'reports/codex-art-97b/publish.py',
    'reports/codex-art-97b/rebuild.ps1',
    'reports/codex-art-97b/commit.ps1'
)
foreach ($Path in $Paths) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file: $Path" }
}
$AlreadyStaged = @(& git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staging area' }
foreach ($Path in $AlreadyStaged) {
    if ($Path -and $Paths -notcontains $Path) { throw "Out-of-scope staged file: $Path" }
}
& git add -- $Paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$MessagePath = Join-Path $PSScriptRoot 'commit-message.txt'
$Message = @'
art: add Xion B2 walk and jump fall hurt land candidates

Deliver five candidate strips with anchor comparisons and measured checks.
Leave product files unchanged.

Co-Authored-By: Codex <noreply@openai.com>
'@
[System.IO.File]::WriteAllText($MessagePath, $Message + "`n", [System.Text.UTF8Encoding]::new($false))
& git commit --file $MessagePath
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
