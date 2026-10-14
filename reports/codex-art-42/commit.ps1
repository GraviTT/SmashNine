$ErrorActionPreference = 'Stop'

git add -- `
  art/bakeoff/luna/luna-idle-v2.png `
  art/bakeoff/luna/luna-idle-v2.json `
  art/bakeoff/luna/luna_brave-idle-v2.png `
  art/bakeoff/luna/luna_brave-idle-v2.json `
  reports/codex-art-42/README.md `
  reports/codex-art-42/idle/prompt.txt `
  reports/codex-art-42/idle/compare.png `
  reports/codex-art-42/idle/metrics.json `
  reports/codex-art-42/brave-idle/prompt.txt `
  reports/codex-art-42/brave-idle/compare.png `
  reports/codex-art-42/brave-idle/metrics.json `
  reports/codex-art-42/commit.ps1

git commit -m 'art: add Luna phase-one idle anchors' -m 'Co-Authored-By: Codex <noreply@openai.com>'
