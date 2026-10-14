$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/frey/frey-walk-v3.png' `
  'art/bakeoff/frey/frey-walk-v3.json' `
  'art/bakeoff/luna/luna-walk-v2.png' `
  'art/bakeoff/luna/luna-walk-v2.json' `
  'reports/codex-art-54'

git commit `
  -m 'Art: add Frey and Luna 8-frame walk candidates' `
  -m 'Co-Authored-By: Codex <noreply@openai.com>'
