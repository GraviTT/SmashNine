# Prepared for lead review. Codex does not run this script.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repo
$files = @(
    'art/bakeoff/nova/nova_female-field_fly-v1.json'
    'art/bakeoff/nova/nova_female-field_fly-v1.png'
    'art/bakeoff/nova/nova_female-orb_throw-v1.json'
    'art/bakeoff/nova/nova_female-orb_throw-v1.png'
    'art/bakeoff/nova/nova_male-field_fly-v1.json'
    'art/bakeoff/nova/nova_male-field_fly-v1.png'
    'art/bakeoff/nova/nova_male-orb_throw-v1.json'
    'art/bakeoff/nova/nova_male-orb_throw-v1.png'
    'design/tasks/CODEX-SKM-05.md'
    'reports/codex-skm-05/README.md'
    'reports/codex-skm-05/audit.json'
    'reports/codex-skm-05/board.py'
    'reports/codex-skm-05/commit.ps1'
    'reports/codex-skm-05/deliver.py'
    'reports/codex-skm-05/face_check.py'
    'reports/codex-skm-05/face_grid.py'
    'reports/codex-skm-05/files-to-stage.json'
    'reports/codex-skm-05/generation-ledger.json'
    'reports/codex-skm-05/ingest.py'
    'reports/codex-skm-05/nova_female-field_fly-checks.json'
    'reports/codex-skm-05/nova_female-field_fly-faces4x.png'
    'reports/codex-skm-05/nova_female-field_fly.png'
    'reports/codex-skm-05/nova_female-gravity_beam-checks.json'
    'reports/codex-skm-05/nova_female-gravity_beam-faces4x.png'
    'reports/codex-skm-05/nova_female-gravity_beam.png'
    'reports/codex-skm-05/nova_female-orb_throw-checks.json'
    'reports/codex-skm-05/nova_female-orb_throw-faces4x.png'
    'reports/codex-skm-05/nova_female-orb_throw.png'
    'reports/codex-skm-05/nova_male-field_fly-checks.json'
    'reports/codex-skm-05/nova_male-field_fly-faces4x.png'
    'reports/codex-skm-05/nova_male-field_fly.png'
    'reports/codex-skm-05/nova_male-gravity_beam-checks.json'
    'reports/codex-skm-05/nova_male-gravity_beam-faces4x.png'
    'reports/codex-skm-05/nova_male-gravity_beam.png'
    'reports/codex-skm-05/nova_male-orb_throw-checks.json'
    'reports/codex-skm-05/nova_male-orb_throw-faces4x.png'
    'reports/codex-skm-05/nova_male-orb_throw.png'
    'reports/codex-skm-05/process.py'
    'reports/codex-skm-05/prompts.txt'
    'reports/codex-skm-05/review_faces.py'
    'reports/codex-skm-05/selection.json'
    'reports/codex-skm-05/verify_skm.py'
)
git add -- @files
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
$message = @'
art: add Nova SKM-05 body motion candidates and review

Co-Authored-By: Codex <noreply@openai.com>
'@
git commit -m $message
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
