$ErrorActionPreference = 'Stop'

git add -- `
  tools/sprite_pipeline/README.md `
  tools/sprite_pipeline/normalize.py `
  tools/sprite_pipeline/test_normalize.py `
  art/bakeoff/frey/frey-shield-v1.png `
  art/bakeoff/frey/frey-shield-v1.json `
  art/bakeoff/frey/frey-attack_up-v1.png `
  art/bakeoff/frey/frey-attack_up-v1.json `
  art/bakeoff/frey/frey-tumble-v3.png `
  art/bakeoff/frey/frey-tumble-v3.json `
  reports/codex-art-39/README.md `
  reports/codex-art-39/commit.ps1 `
  reports/codex-art-39/idle `
  reports/codex-art-39/walk `
  reports/codex-art-39/jump `
  reports/codex-art-39/fall `
  reports/codex-art-39/hurt `
  reports/codex-art-39/shield `
  reports/codex-art-39/attack `
  reports/codex-art-39/attack_up `
  reports/codex-art-39/attack_down `
  reports/codex-art-39/attack_air_side `
  reports/codex-art-39/dash_strike `
  reports/codex-art-39/rising_cleave `
  reports/codex-art-39/spike_followup `
  reports/codex-art-39/descent `
  reports/codex-art-39/tumble


git commit -m 'art: match Frey head scale where poses fit' -m 'Co-Authored-By: Codex <noreply@openai.com>'
