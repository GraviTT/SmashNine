$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  'art/bakeoff/frey' `
  'art/bakeoff/yuki' `
  'reports/codex-art-36a'

$message = "art: add Frey attack v2 and Yuki redraw candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
git -c core.autocrlf=false commit -m $message
