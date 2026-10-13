$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  art/bakeoff/rio `
  art/bakeoff/nova `
  art/bakeoff/luna `
  reports/codex-art-36b

git -c core.autocrlf=false commit `
  -m "art: refine redraw bakeoff candidates and add base luna" `
  -m "Co-Authored-By: Codex <noreply@openai.com>"
