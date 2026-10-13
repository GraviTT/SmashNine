$ErrorActionPreference = 'Stop'

git -c core.autocrlf=false add -- `
  art/bakeoff/rio/rio_female-idle-v1.png `
  art/bakeoff/rio/rio_female-idle-v1.json `
  art/bakeoff/rio/rio_female-walk-v1.png `
  art/bakeoff/rio/rio_female-walk-v1.json `
  art/bakeoff/rio/rio_female-plunge-v1.png `
  art/bakeoff/rio/rio_female-plunge-v1.json `
  art/bakeoff/nova/nova_male-idle-v1.png `
  art/bakeoff/nova/nova_male-idle-v1.json `
  art/bakeoff/nova/nova_male-vector_side-v1.png `
  art/bakeoff/nova/nova_male-vector_side-v1.json `
  art/bakeoff/nova/nova_female-idle-v1.png `
  art/bakeoff/nova/nova_female-idle-v1.json `
  art/bakeoff/nova/nova_female-vector_side-v1.png `
  art/bakeoff/nova/nova_female-vector_side-v1.json `
  art/bakeoff/luna/luna_brave-idle-v1.png `
  art/bakeoff/luna/luna_brave-idle-v1.json `
  art/bakeoff/luna/luna_brave-brave_combo-v1.png `
  art/bakeoff/luna/luna_brave-brave_combo-v1.json `
  reports/codex-art-36b

git -c core.autocrlf=false commit `
  -m "art: add redraw bakeoff candidates for rio nova and brave luna" `
  -m "Co-Authored-By: Codex <noreply@openai.com>"
