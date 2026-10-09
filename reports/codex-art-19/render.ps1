$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
node (Join-Path $repo 'reports\codex-art-19\render.js')
