$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
Push-Location -LiteralPath $Repo
try {
	$branch = (& git branch --show-current).Trim()
	if ($LASTEXITCODE -ne 0 -or $branch -ne 'codex/aud-01') {
		throw 'Expected branch codex/aud-01; no files staged.'
	}
	$files = @(
		'tools/audio_synth/sfx_all.py',
		'tools/audio_synth/verify_sfx_all.py',
		'tools/audio_synth/README.md',
		'tools/sound_viewer/build.mjs',
		'tools/sound_viewer/index.html',
		'tools/sound_viewer/verify.mjs',
		'tools/sound_viewer/README.md',
		'reports/codex-aud-01/README.md',
		'reports/codex-aud-01/measurements.json',
		'reports/codex-aud-01/measurements.md',
		'reports/codex-aud-01/verification.json',
		'reports/codex-aud-01/viewer-checks.json',
		'reports/codex-aud-01/visual-review.md',
		'reports/codex-aud-01/loudness-overview.png',
		'reports/codex-aud-01/commit.ps1'
	)
	$measurements = Get-Content -LiteralPath 'reports/codex-aud-01/measurements.json' -Raw -Encoding UTF8 | ConvertFrom-Json
	if ($measurements.records.Count -ne 216) { throw 'Expected 216 measured candidates.' }
	foreach ($row in $measurements.records) {
		if ($row.sound -notmatch '^[a-z_0-9]+$' -or $row.sound -like 'music_*' -or $row.style -notin @('a','b','c')) {
			throw 'Unexpected sound manifest entry.'
		}
		$expected = 'art/audio_bakeoff/{0}-{1}.wav' -f $row.sound, $row.style
		if ($row.file -cne $expected) { throw "Unexpected WAV path: $($row.file)" }
		if (-not $row.preserved_trial) { $files += $expected }
		$files += ('reports/codex-aud-01/{0}.png' -f $row.sound)
	}
	$files = @($files | Sort-Object -Unique)
	if ($files.Count -ne 267) { throw "Expected 267 own deliverables, got $($files.Count)." }
	foreach ($file in $files) {
		if ($file -match '(^|/)(__pycache__|run\.log)(/|$)|tools/sound_viewer/dist/|/preview/|/music_') {
			throw "Forbidden staging path: $file"
		}
		if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing deliverable: $file" }
	}
	$staged = @(& git diff --cached --name-only)
	if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect staged files.' }
	$foreign = @($staged | Where-Object { $_ -notin $files })
	if ($foreign.Count -gt 0) { throw "Unrelated staged files exist: $($foreign -join ', '). No files staged by this script." }
	# Small explicit batches stay below Windows command-line limits. No recursive add.
	for ($i = 0; $i -lt $files.Count; $i += 40) {
		$last = [Math]::Min($i + 39, $files.Count - 1)
		$batch = $files[$i..$last]
		& git -c core.autocrlf=false add -- $batch
		if ($LASTEXITCODE -ne 0) { throw 'Staging failed; no commit attempted. Inspect the index before retrying.' }
	}
	$after = @(& git diff --cached --name-only)
	if ($LASTEXITCODE -ne 0 -or @($after | Where-Object { $_ -notin $files }).Count -gt 0) {
		throw 'Unexpected staged paths; no commit attempted.'
	}
	$message = @'
Add complete three-style original SFX candidates and grouped sound viewer

Generate 60 new effect IDs in A/B/C while preserving 36 trial WAVs.
Add full-catalog PCM measurements, comparison plots and deterministic checks.
Move SFX to sidecars, add global style adoption and dynamic music discovery.

Co-Authored-By: Codex <noreply@openai.com>
'@
	& git commit -m $message
	if ($LASTEXITCODE -ne 0) { throw 'Commit failed. The explicit staged files remain for inspection.' }
} finally {
	Pop-Location
}
