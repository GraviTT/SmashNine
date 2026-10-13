$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/frey/frey-descent-v4.png' `
  'art/bakeoff/frey/frey-descent-v4.json' `
  'reports/codex-art-41/prompt.txt' `
  'reports/codex-art-41/compare.png' `
  'reports/codex-art-41/metrics.json' `
  'reports/codex-art-41/README.md' `
  'reports/codex-art-41/commit.ps1'

git commit -m "art: rebuild Frey descent as sword-first slam`n`nCo-Authored-By: Codex <noreply@openai.com>"
