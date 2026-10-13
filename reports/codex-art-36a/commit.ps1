$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  'art/bakeoff/frey/frey-idle-v1.png' `
  'art/bakeoff/frey/frey-idle-v1.json' `
  'art/bakeoff/frey/frey-spike_followup-v1.png' `
  'art/bakeoff/frey/frey-spike_followup-v1.json' `
  'art/bakeoff/frey/frey-descent-v1.png' `
  'art/bakeoff/frey/frey-descent-v1.json' `
  'art/bakeoff/frey/frey-tumble-v1.png' `
  'art/bakeoff/frey/frey-tumble-v1.json' `
  'reports/codex-art-36a'

$message = "art: add Frey one-sheet redraw candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
git -c core.autocrlf=false commit -m $message
