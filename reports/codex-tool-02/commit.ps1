$files = @(
	'smash-nine-prototype/tests/capture_move_clips.gd',
	'reports/codex-tool-01/encode_clips.py',
	'art/clips/manifest.json',
	'tools/motion_viewer/index.html',
	'tools/motion_viewer/README.md',
	'reports/codex-tool-02/README.md',
	'reports/codex-tool-02/commit.ps1',
	'reports/codex-tool-02/verify_clips.py',
	'reports/codex-tool-02/middle-frames.json',
	'reports/codex-tool-02/middle-frames-fx.png',
	'reports/codex-tool-02/middle-frames-nofx.png',
	'reports/codex-tool-02/event-frames-fx.png',
	'reports/codex-tool-02/inspection-details.png'
)

$forms = @('frey', 'luna', 'luna_brave', 'yuki', 'nova', 'rio')
foreach ($form in $forms) {
	$files += Get-ChildItem "art/clips/$form" -Filter '*.webp' |
		Where-Object { $_.BaseName -match '^(guard|pursuit|spike|status|ultimate|star-charge|transform|aura|seals|momentum|rune)-(fx|nofx)$' } |
		ForEach-Object { $_.FullName }
}

git add -- $files
git commit -m 'Add around-character effect clips to motion viewer' -m 'Co-Authored-By: Codex <noreply@openai.com>'
