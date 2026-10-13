$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  'art/bakeoff/frey' `
  'reports/codex-art-36a' `
  'tools/sprite_pipeline/normalize.py' `
  'tools/sprite_pipeline/README.md' `
  'tools/sprite_pipeline/test_normalize.py'

$message = "art: refine Frey redraw candidates and add priority rows`n`nCo-Authored-By: Codex <noreply@openai.com>"
git -c core.autocrlf=false commit -m $message
