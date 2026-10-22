$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $Repo
try {
	$branch = (& git branch --show-current).Trim()
	if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/aud-01a') {
		throw 'Expected branch codex/aud-01a; no files staged.'
	}
	$files = @(
		'.gitignore',
		'tools/audio_synth/synth.py',
		'tools/audio_synth/verify.py',
		'tools/audio_synth/README.md',
		'tools/sound_viewer/index.html',
		'tools/sound_viewer/build.mjs',
		'tools/sound_viewer/verify.mjs',
		'tools/sound_viewer/README.md',
		'reports/codex-aud-01a/README.md',
		'reports/codex-aud-01a/measurements.json',
		'reports/codex-aud-01a/measurements.md',
		'reports/codex-aud-01a/verification.json',
		'reports/codex-aud-01a/viewer-checks.json',
		'reports/codex-aud-01a/visual-review.md',
		'reports/codex-aud-01a/commit.ps1'
	)
	$sounds = @('hit_light', 'hit_heavy', 'swing', 'jump', 'land', 'guard', 'parry', 'hurt', 'ko', 'portal', 'ui_select', 'ui_cancel')
	foreach ($sound in $sounds) {
		foreach ($style in @('a', 'b', 'c')) {
			$files += "art/audio_bakeoff/$sound-$style.wav"
			$files += "reports/codex-aud-01a/$sound-$style.png"
		}
	}
	foreach ($style in @('a', 'b', 'c')) { $files += "reports/codex-aud-01a/overview-$style.png" }
	foreach ($file in $files) {
		if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing deliverable: $file" }
	}
	$staged = @(& git diff --cached --name-only)
	if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
	$foreign = @($staged | Where-Object { $_ -notin $files })
	if ($foreign.Count -gt 0) { throw "Unrelated staged files exist: $($foreign -join ', '). No files staged by this script." }
	# Refuse to include unrelated changes in the one shared allowed file.
	$ignoreStat = @(& git diff HEAD --numstat -- .gitignore)
	if ($LASTEXITCODE -ne 0 -or $ignoreStat.Count -ne 1 -or $ignoreStat[0] -ne "1`t0`t.gitignore") {
		throw '.gitignore must have exactly the one allowed added line.'
	}
	$ignoreDiff = (& git diff HEAD -- .gitignore) -join "`n"
	if (-not $ignoreDiff.Contains("+tools/sound_viewer/dist/")) { throw 'Unexpected .gitignore edit.' }
	& git add -- $files
	if ($LASTEXITCODE -ne 0) { throw 'git add failed; commit not attempted.' }
	$stagedAfter = @(& git diff --cached --name-only)
	if ($LASTEXITCODE -ne 0 -or @($stagedAfter | Where-Object { $_ -notin $files }).Count -gt 0) {
		throw 'Unexpected staged path; commit not attempted.'
	}
	$message = @'
Add 36 original synthesized sound candidates and listening viewer

Provide three styles for twelve core effects, deterministic numpy synthesis,
PCM measurements, waveform/spectrogram review, and Artifact sound picks.

Co-Authored-By: Codex <noreply@openai.com>
'@
	& git commit -m $message
	if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
} finally {
	Pop-Location
}
