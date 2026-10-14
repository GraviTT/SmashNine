$ErrorActionPreference = 'Stop'

git add -- `
  reports/codex-art-59/nova_male `
  reports/codex-art-59/nova_female `
  reports/codex-art-59/commit-b.ps1

git commit -m 'art: report Nova walk attempts' -m 'Co-Authored-By: Codex <noreply@openai.com>'
