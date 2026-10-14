$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/rio/rio_female-walk-v3.png' `
  'art/bakeoff/rio/rio_female-walk-v3.json' `
  'reports/codex-art-64'

git commit -m 'art: redraw Rio female passing frames' -m 'Co-Authored-By: Codex <noreply@openai.com>'
