$ErrorActionPreference = 'Stop'

$paths = @(
  'art/bakeoff/rio/rio_female-low_sweep-v2.png',
  'art/bakeoff/rio/rio_female-low_sweep-v2.json',
  'art/bakeoff/rio/rio_female-dimension_slash-v2.png',
  'art/bakeoff/rio/rio_female-dimension_slash-v2.json',
  'art/bakeoff/rio/rio_female-attack-v2.png',
  'art/bakeoff/rio/rio_female-attack-v2.json',
  'art/bakeoff/rio/rio_male-attack-v2.png',
  'art/bakeoff/rio/rio_male-attack-v2.json',
  'reports/codex-art-68/README.md',
  'reports/codex-art-68/prompts.txt',
  'reports/codex-art-68/face-manual.json',
  'reports/codex-art-68/make_face_boards.py',
  'reports/codex-art-68/make_face_grid.py',
  'reports/codex-art-68/inspect_face_pixels.py',
  'reports/codex-art-68/low_sweep',
  'reports/codex-art-68/dimension_slash',
  'reports/codex-art-68/attack_female',
  'reports/codex-art-68/attack_male',
  'reports/codex-art-68/low_sweep-face.png',
  'reports/codex-art-68/low_sweep-face-grid.png',
  'reports/codex-art-68/low_sweep-face-centres.txt',
  'reports/codex-art-68/low_sweep-face-measurements.json',
  'reports/codex-art-68/dimension_slash-face.png',
  'reports/codex-art-68/dimension_slash-face-grid.png',
  'reports/codex-art-68/dimension_slash-face-centres.txt',
  'reports/codex-art-68/dimension_slash-face-measurements.json',
  'reports/codex-art-68/rio_female-attack-face.png',
  'reports/codex-art-68/rio_female-attack-face-grid.png',
  'reports/codex-art-68/rio_female-attack-face-centres.txt',
  'reports/codex-art-68/rio_female-attack-face-measurements.json',
  'reports/codex-art-68/rio_male-attack-face.png',
  'reports/codex-art-68/rio_male-attack-face-grid.png',
  'reports/codex-art-68/rio_male-attack-face-centres.txt',
  'reports/codex-art-68/rio_male-attack-face-measurements.json',
  'reports/codex-art-68/commit.ps1'
)

git add -- $paths
git commit -m "art: redraw compact Rio rows at idle face scale

Co-Authored-By: Codex <noreply@openai.com>"
