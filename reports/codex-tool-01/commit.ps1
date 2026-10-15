$ErrorActionPreference = 'Stop'

git add -- `
	'smash-nine-prototype/tests/capture_move_clips.gd' `
	'art/clips' `
	'tools/motion_viewer/build.mjs' `
	'tools/motion_viewer/index.html' `
	'tools/motion_viewer/README.md' `
	'reports/codex-tool-01'

git commit -m "feat: add real attack clips to motion viewer`n`nCo-Authored-By: Codex <noreply@openai.com>"
