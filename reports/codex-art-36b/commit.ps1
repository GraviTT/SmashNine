$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  art/bakeoff/nova `
  reports/codex-art-36b

git -c core.autocrlf=false commit `
  -m "art: add effect-free Nova male base rows" `
  -m "Co-Authored-By: Codex <noreply@openai.com>"
