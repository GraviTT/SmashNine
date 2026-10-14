$ErrorActionPreference = 'Stop'

git add -- `
  'art/bakeoff/yuki/main/yuki_illustration-v1.png' `
  'art/bakeoff/yuki/main/yuki_illustration-v2.png' `
  'art/bakeoff/yuki/main/yuki_face-v1.png' `
  'art/bakeoff/yuki/main/yuki_face-v2.png' `
  'reports/codex-art-50'

git commit -m "Add Yuki main art candidates`n`nCo-Authored-By: Codex <noreply@openai.com>"
