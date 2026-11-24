"""Write a literal allowlist commit script. Does not touch the git index."""
from pathlib import Path
import json

ROOT = Path('reports/codex-skm-07')
FILES = [
    'design/tasks/CODEX-SKM-07.md',
    'art/bakeoff/xion/b/xion-shot_air_down-v2.png',
    'art/bakeoff/xion/b/xion-shot_air_down-v2.json',
    'art/bakeoff/xion/b/xion-shot_air_down-v3.png',
    'art/bakeoff/xion/b/xion-shot_air_down-v3.json',
] + [str(ROOT/name).replace('\\','/') for name in [
    'README.md','prompts.txt','xion-shot_air_down-v2.png','xion-shot_air_down-v3.png','comparison.png',
    'config.py','ingest.py','process.py','face_check.py','face_grid.py','review_faces.py','body_grid.py',
    'finalize.py','prepare_handoff.py','verify_skm.py','commit.ps1',
]]

if __name__ == '__main__':
    lines = [
        "$ErrorActionPreference = 'Stop'",
        "Set-Location (Resolve-Path (Join-Path $PSScriptRoot '../..'))",
        "if ((git branch --show-current).Trim() -ne 'codex/skm-07') { throw 'Wrong branch' }",
        "$alreadyStaged = @(git diff --cached --name-only)",
        "if ($LASTEXITCODE -ne 0) { throw 'Cannot read the index' }",
        "if ($alreadyStaged.Count -gt 0) { throw 'Index is not empty; review the existing staged work first.' }",
        '# Literal string array avoids the PowerShell 5.1 ConvertFrom-Json array issue.',
        '# Includes requested prompts; excludes QA JSON, attempts, raws, caches and logs.',
        '$files = @(',
        *["    '" + p + "'" for p in FILES],
        ')',
        "foreach ($path in $files) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Missing: ' + $path) } }",
        '& git add -- $files',
        "if ($LASTEXITCODE -ne 0) { throw 'git add failed' }",
        '$staged = @(git diff --cached --name-only)',
        "if ($LASTEXITCODE -ne 0) { throw 'Cannot read staged paths' }",
        "$outside = @($staged | Where-Object { $files -notcontains $_ })",
        "if ($outside.Count -gt 0) { throw ('Out-of-scope paths: ' + ($outside -join ', ')) }",
        'git diff --cached --check',
        "if ($LASTEXITCODE -ne 0) { throw 'Staged whitespace check failed' }",
        "git commit -m 'art: redraw Xion airborne down-shot candidates (SKM-07)' -m 'Co-Authored-By: Codex <noreply@openai.com>'",
        "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }",
    ]
    (ROOT/'commit.ps1').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
    (ROOT/'files-to-stage.json').write_text(json.dumps(FILES,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'Updated commit.ps1: {len(FILES)} explicit files, no git mutation.')
