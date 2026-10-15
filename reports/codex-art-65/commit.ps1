$ErrorActionPreference = 'Stop'

git add -- `
  art/bakeoff/rio/rio_male-fall-v1.png `
  art/bakeoff/rio/rio_male-fall-v1.json `
  art/bakeoff/rio/rio_male-shield-v1.png `
  art/bakeoff/rio/rio_male-shield-v1.json `
  art/bakeoff/rio/rio_male-infinity_overdrive-v1.png `
  art/bakeoff/rio/rio_male-infinity_overdrive-v1.json `
  reports/codex-art-65

$message = "art: complete compact Rio male missing rows`n`nCo-Authored-By: Codex <noreply@openai.com>"
git commit -m $message
