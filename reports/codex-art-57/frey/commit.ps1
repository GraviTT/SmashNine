$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/frey/frey-walk-v5.png' `
  'art/bakeoff/frey/frey-walk-v5.json' `
  'reports/codex-art-57/frey/make_walk_reference.py' `
  'reports/codex-art-57/frey/walk_reference_frey.png' `
  'reports/codex-art-57/frey/build_report.py' `
  'reports/codex-art-57/frey/costume.png' `
  'reports/codex-art-57/frey/feet.png' `
  'reports/codex-art-57/frey/bob.png' `
  'reports/codex-art-57/frey/bob.json' `
  'reports/codex-art-57/frey/walk.gif' `
  'reports/codex-art-57/frey/compare.png' `
  'reports/codex-art-57/frey/metrics.json' `
  'reports/codex-art-57/frey/prompts.txt' `
  'reports/codex-art-57/frey/README.md' `
  'reports/codex-art-57/frey/commit.ps1'

git commit -m 'art: add Frey eight-frame walk v5' -m 'Co-Authored-By: Codex <noreply@openai.com>'
