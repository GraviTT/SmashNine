$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
Set-Location -LiteralPath $repoRoot
if ((& git branch --show-current).Trim() -ne 'codex/art-80') {
    throw 'Expected branch codex/art-80.'
}
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'commit-files.txt') -Encoding UTF8 | Where-Object { $_.Trim() })
foreach ($file in $files) {
    if ($file -match '(^|/)(art/raw|__pycache__)(/|$)|(^|/)run\.log$|\.\.') {
        throw "Excluded path: $file"
    }
    if ($file -notmatch '^art/bakeoff/(frey|luna|yuki|nova|rio)/[a-z_]+_face-shadow-v1\.(png|json)$' -and $file -notmatch '^reports/codex-art-80/[^/]+$') {
        throw "Outside ART-80 scope: $file"
    }
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing file: $file" }
}
$message = @'
art: add eight candidate shadow boss dialogue portraits

Edit current neutral faces, preserve their alpha and supply comparison boards.
Candidates only; no game integration.

Co-Authored-By: Codex <noreply@openai.com>
'@
$messagePath = Join-Path ([IO.Path]::GetTempPath()) ('codex-art-80-' + [guid]::NewGuid().ToString('N') + '.txt')
try {
    [IO.File]::WriteAllText($messagePath, $message, [Text.UTF8Encoding]::new($false))
    & git add -- @files
    if ($LASTEXITCODE -ne 0) { throw 'git add failed.' }
    & git commit --only --file $messagePath -- @files
    if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally {
    if (Test-Path -LiteralPath $messagePath) { Remove-Item -LiteralPath $messagePath }
}
