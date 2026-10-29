$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo

# Prepared only. Do not mix unrelated staged changes into this candidate commit.
$alreadyStaged = @(git diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect index.' }
if ($alreadyStaged.Count -gt 0) { throw 'Index is not empty. Preserve and handle existing staged work separately.' }

$files = @(
    'design/tasks/CODEX-VFX-01.md',
    'art/bakeoff/effects/rio/rio_air_step-a-1-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-a-1-v1.json',
    'art/bakeoff/effects/rio/rio_air_step-a-2-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-a-2-v1.json',
    'art/bakeoff/effects/rio/rio_air_step-b-1-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-b-1-v1.json',
    'art/bakeoff/effects/rio/rio_air_step-b-2-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-b-2-v1.json',
    'art/bakeoff/effects/rio/rio_air_step-c-1-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-c-1-v1.json',
    'art/bakeoff/effects/rio/rio_air_step-c-2-v1.png',
    'art/bakeoff/effects/rio/rio_air_step-c-2-v1.json',
    'reports/codex-vfx-01/README.md',
    'reports/codex-vfx-01/build.py',
    'reports/codex-vfx-01/commit.ps1',
    'reports/codex-vfx-01/measurements.json',
    'reports/codex-vfx-01/verification.json',
    'reports/codex-vfx-01/prompts.txt',
    'reports/codex-vfx-01/references.png',
    'reports/codex-vfx-01/overview.png',
    'reports/codex-vfx-01/board.png',
    'reports/codex-vfx-01/board-a.png',
    'reports/codex-vfx-01/board-b.png',
    'reports/codex-vfx-01/board-c.png',
    'reports/codex-vfx-01/board-a-1.png',
    'reports/codex-vfx-01/board-a-2.png',
    'reports/codex-vfx-01/board-b-1.png',
    'reports/codex-vfx-01/board-b-2.png',
    'reports/codex-vfx-01/board-c-1.png',
    'reports/codex-vfx-01/board-c-2.png'
)
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing deliverable: $file" }
}
git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'Staging failed. No force-add will be attempted.' }
$message = @'
Add Rio extra-air-jump VFX candidates and measured review boards

Three ideas with first/last jump states; document the unresolved anchor contract.

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'Commit failed.' }
