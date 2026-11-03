$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $repoRoot
try {
    $staged = @(git diff --cached --name-only)
    if ($LASTEXITCODE -ne 0) { throw 'Could not inspect index.' }
    if ($staged.Count -gt 0) { throw 'Existing staged files found. Review them before running this script.' }
    $files = @('design/tasks/CODEX-VFX-06.md')
    foreach ($kind in @('head', 'split', 'bind', 'tile')) {
        foreach ($variant in @('a', 'b')) {
            foreach ($extension in @('png', 'json')) {
                $files += "art/bakeoff/effects/nova/nova_beam_$kind-$variant-v2.$extension"
            }
        }
    }
    $reportRoot = Join-Path $repoRoot 'reports/codex-vfx-06'
    foreach ($entry in (Get-ChildItem -LiteralPath $reportRoot -File)) {
        $files += 'reports/codex-vfx-06/' + $entry.Name
    }
    foreach ($file in $files) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing: $file" }
        if ($file -match '(^art/raw/|^smash-nine-prototype/|__pycache__)') { throw "Forbidden: $file" }
    }
    git add -- @files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    git diff --cached --check
    if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
    $message = "art: add Nova wrapping gravity beam A/B candidates (VFX-06)`n`nCo-Authored-By: Codex <noreply@openai.com>"
    git commit -m $message
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
}
finally {
    Pop-Location
}
