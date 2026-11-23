from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];REPORT=ROOT/'reports/codex-art-97a'
paths=['design/tasks/CODEX-ART-97.md']
for row in ('attack','shield','victory'):
    paths.extend(f'art/bakeoff/xion/b/xion-{row}-b2.{suffix}' for suffix in ('png','json'))
paths.extend(p.relative_to(ROOT).as_posix() for p in sorted(REPORT.rglob('*')) if p.is_file() and p.name not in ('baseline-status.txt','commit.ps1') and '__pycache__' not in p.parts)
paths.append('reports/codex-art-97a/commit.ps1')
assert all('art/raw/' not in p and not p.startswith('smash-nine-prototype/') for p in paths)
lines=["$ErrorActionPreference = 'Stop'","$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\\..')).Path","Set-Location -LiteralPath $repo","$branch = git branch --show-current","if ($branch -ne 'codex/xion-97a') { throw 'Wrong branch; expected codex/xion-97a' }","$paths = @("]
lines.extend("    '"+p.replace("'","''")+"'" for p in paths)
lines.extend([
 ')',
 'foreach ($path in $paths) { if (-not (Test-Path -LiteralPath $path)) { throw "Missing file: $path" } }',
 'git add -- $paths',
 "if ($LASTEXITCODE -ne 0) { throw 'git add failed' }",
 "$message = @'",
 'art(xion): add B shield candidate and held attack/victory studies',
 '',
 'Record the rejected defeat attempts, measurements and 4x review.',
 'Attack and victory remain on hold; no game assets are installed.',
 '',
 'Co-Authored-By: Codex <noreply@openai.com>',
 "'@",
 'git commit --only -m $message -- $paths',
 "if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }",
 ])
(REPORT/'commit.ps1').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Wrote commit.ps1 with',len(paths),'literal paths; NOT EXECUTED')
