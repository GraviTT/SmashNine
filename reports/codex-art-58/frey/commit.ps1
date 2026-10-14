$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/frey/frey-walk-v6.png' `
  'art/bakeoff/frey/frey-walk-v6.json' `
  'reports/codex-art-58/frey/build_report.py' `
  'reports/codex-art-58/frey/onion.png' `
  'reports/codex-art-58/frey/feet.json' `
  'reports/codex-art-58/frey/costume.png' `
  'reports/codex-art-58/frey/bob.png' `
  'reports/codex-art-58/frey/bob.json' `
  'reports/codex-art-58/frey/walk.gif' `
  'reports/codex-art-58/frey/measurements.json' `
  'reports/codex-art-58/frey/prompts.txt' `
  'reports/codex-art-58/frey/README.md' `
  'reports/codex-art-58/frey/commit.ps1'

git commit -m 'art: redraw Frey walk passing frames' -m 'Co-Authored-By: Codex <noreply@openai.com>'
