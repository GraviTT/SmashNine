$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/luna/luna_brave-idle-v3.png' `
  'art/bakeoff/luna/luna_brave-idle-v3.json' `
  'art/bakeoff/luna/luna_brave-idle-v4.png' `
  'art/bakeoff/luna/luna_brave-idle-v4.json' `
  'art/bakeoff/luna/luna_brave-idle-v5.png' `
  'art/bakeoff/luna/luna_brave-idle-v5.json' `
  'reports/codex-art-44'

git commit -m 'art: add three Brave Luna design proposals' -m 'Co-Authored-By: Codex <noreply@openai.com>'
