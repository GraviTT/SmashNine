$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  'art/bakeoff/frey' `
  'art/bakeoff/yuki' `
  'reports/codex-art-36a' `
  'tools/sprite_pipeline/normalize.py' `
  'tools/sprite_pipeline/test_normalize.py' `
  'tools/sprite_pipeline/README.md'

$message = "art: fix Frey and Yuki redraw scale and borders`n`nCo-Authored-By: Codex <noreply@openai.com>"
git -c core.autocrlf=false commit -m $message
