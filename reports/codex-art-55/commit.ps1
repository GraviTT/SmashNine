$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/frey/frey-walk-v4.png' `
  'art/bakeoff/frey/frey-walk-v4.json' `
  'art/bakeoff/luna/luna-walk-v3.png' `
  'art/bakeoff/luna/luna-walk-v3.json' `
  'reports/codex-art-55'

git commit -m 'art: add pose-guided Frey and Luna walks' -m 'Co-Authored-By: Codex <noreply@openai.com>'
