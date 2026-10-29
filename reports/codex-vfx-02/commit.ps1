# Review and run manually; Codex did not execute this file.
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location -LiteralPath $repoRoot
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/vfx-02') { throw 'Expected branch codex/vfx-02.' }
    $alreadyStaged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the index.' }
    if ($alreadyStaged.Count -gt 0) { throw 'Index is not empty; review existing staged work first.' }
    $files = @(
        'art/bakeoff/skill_icons/luna_brave/luna_brave_j-a-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_j-a-v1.png',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_j-b-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_j-b-v1.png',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_k-a-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_k-a-v1.png',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_k-b-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_k-b-v1.png',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_l-a-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_l-a-v1.png',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_l-b-v1.json',
        'art/bakeoff/skill_icons/luna_brave/luna_brave_l-b-v1.png',
        'design/tasks/CODEX-VFX-02.md',
        'reports/codex-vfx-02/README.md',
        'reports/codex-vfx-02/board.png',
        'reports/codex-vfx-02/brave_rows_1x.png',
        'reports/codex-vfx-02/brave_rows_4x.png',
        'reports/codex-vfx-02/build_icons.py',
        'reports/codex-vfx-02/commit.ps1',
        'reports/codex-vfx-02/measurements.json',
        'reports/codex-vfx-02/set_a_1x.png',
        'reports/codex-vfx-02/set_a_4x.png',
        'reports/codex-vfx-02/set_b_1x.png',
        'reports/codex-vfx-02/set_b_4x.png',
        'reports/codex-vfx-02/set_current_1x.png',
        'reports/codex-vfx-02/set_current_4x.png',
        'reports/codex-vfx-02/verification.json',
        'reports/codex-vfx-02/verify_icons.py'
    )
    foreach ($file in $files) {
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing deliverable: $file" }
    }
    & git add -- @files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    $staged = @(& git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
    foreach ($file in $staged) {
        if ($file -notin $files) { throw "Unexpected staged path: $file" }
    }
    & git commit -m 'art: add Brave Luna J K L pixel icon candidates (VFX-02)' -m 'Co-Authored-By: Codex <noreply@openai.com>'
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally { Pop-Location }
