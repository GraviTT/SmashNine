$ErrorActionPreference = 'Stop'
$repo = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $repo
$paths = @(
    'design/tasks/CODEX-SKM-01b.md'
    'reports/codex-skm-01b/README.md'
    'reports/codex-skm-01b/frey-hover_dash.png'
    'reports/codex-skm-01b/frey-launch_chase.png'
)
git add -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git add failed' }
git commit --only -m 'Add Frey hover dash and launch chase review (SKM-01b)' -m 'Co-Authored-By: Codex <noreply@openai.com>' -- $paths
if ($LASTEXITCODE -ne 0) { throw 'git commit failed' }
