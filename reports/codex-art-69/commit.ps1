$ErrorActionPreference = 'Stop'

$candidateFiles = @(
	'art/bakeoff/frey/frey-defeat-v1.png',
	'art/bakeoff/frey/frey-defeat-v1.json',
	'art/bakeoff/luna/luna-defeat-v1.png',
	'art/bakeoff/luna/luna-defeat-v1.json',
	'art/bakeoff/luna/luna_brave-defeat-v1.png',
	'art/bakeoff/luna/luna_brave-defeat-v1.json',
	'art/bakeoff/yuki/yuki-defeat-v1.png',
	'art/bakeoff/yuki/yuki-defeat-v1.json',
	'art/bakeoff/nova/nova_male-defeat-v1.png',
	'art/bakeoff/nova/nova_male-defeat-v1.json',
	'art/bakeoff/nova/nova_female-defeat-v1.png',
	'art/bakeoff/nova/nova_female-defeat-v1.json',
	'art/bakeoff/rio/rio_male-defeat-v1.png',
	'art/bakeoff/rio/rio_male-defeat-v1.json',
	'art/bakeoff/rio/rio_female-defeat-v1.png',
	'art/bakeoff/rio/rio_female-defeat-v1.json'
)

$reportFiles = @(
	'reports/codex-art-69/README.md',
	'reports/codex-art-69/prompts.txt',
	'reports/codex-art-69/commit.ps1',
	'reports/codex-art-69/qa_faces.py',
	'reports/codex-art-69/face-crops.json',
	'reports/codex-art-69/face-measurements.json',
	'reports/codex-art-69/frey-defeat.png',
	'reports/codex-art-69/luna-defeat.png',
	'reports/codex-art-69/luna_brave-defeat.png',
	'reports/codex-art-69/yuki-defeat.png',
	'reports/codex-art-69/nova_male-defeat.png',
	'reports/codex-art-69/nova_female-defeat.png',
	'reports/codex-art-69/rio_male-defeat.png',
	'reports/codex-art-69/rio_female-defeat.png',
	'reports/codex-art-69/frey-faces-grid.png',
	'reports/codex-art-69/luna-faces-grid.png',
	'reports/codex-art-69/luna_brave-faces-grid.png',
	'reports/codex-art-69/yuki-faces-grid.png',
	'reports/codex-art-69/nova_male-faces-grid.png',
	'reports/codex-art-69/nova_female-faces-grid.png',
	'reports/codex-art-69/rio_male-faces-grid.png',
	'reports/codex-art-69/rio_female-faces-grid.png',
	'reports/codex-art-69/frey/final/metrics.json',
	'reports/codex-art-69/frey/final/head-scale.json',
	'reports/codex-art-69/luna/final/metrics.json',
	'reports/codex-art-69/luna/final/head-scale.json',
	'reports/codex-art-69/luna_brave/final/metrics.json',
	'reports/codex-art-69/luna_brave/final/head-scale.json',
	'reports/codex-art-69/yuki/final/metrics.json',
	'reports/codex-art-69/yuki/final/head-scale.json',
	'reports/codex-art-69/nova_male/final/metrics.json',
	'reports/codex-art-69/nova_male/final/head-scale.json',
	'reports/codex-art-69/nova_female/final/metrics.json',
	'reports/codex-art-69/nova_female/final/head-scale.json',
	'reports/codex-art-69/rio_male/final/metrics.json',
	'reports/codex-art-69/rio_male/final/head-scale.json',
	'reports/codex-art-69/rio_female/final/metrics.json',
	'reports/codex-art-69/rio_female/final/head-scale.json'
)

git add -- $candidateFiles $reportFiles
git commit -m "art: add defeat candidates for all fighter forms`n`nCo-Authored-By: Codex <noreply@openai.com>"
