# CODEX-AUD-02 · Music: the select, story and results tracks, in all three styles

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 1 (AUD-02). The trial (AUD-02a) made `music_title` and `music_battle` in A/B/C; the game also asks for `music_select`, `music_story` and `music_results` (`smash-nine-prototype/scripts/audio/AudioCatalog.gd`, `design/AUDIO.md`). The user has not picked a style yet; the lead runs all three styles now so the pick is ready at once.
- Read first: `design/tasks/CODEX-AUD-02a.md`, `reports/codex-aud-02a/README.md`, `tools/audio_synth/README.md`, `tools/audio_synth/music.py`.
- Unit: Builder (sound). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-motion/SmashNine`, branch `codex/aud-02` (from the latest main).
- Running at the same time: AUD-01 (all effects, and the listening page) in auditor. **Do not touch `tools/sound_viewer/`**: AUD-01 makes the page read every `reports/codex-aud-02*/measurements.json`, so your tracks appear when you write that file in the AUD-02a format.
- **Original music only** (Python and numpy, no samples, no downloads, no installs). **Candidates only**: nothing under `smash-nine-prototype/` changes. The lead cannot hear; the user judges.

## The three tracks
All reuse the AUD-02a motif (D5 A5 G5 E5 F5 D5, D dorian) so the soundtrack hangs together, and the three styles exactly as AUD-02a defined them (A chiptune mono, B 16-bit FM stereo, C layered stereo).
- **`music_select`** (character select): 112–124 BPM, 24–32 s, a seamless loop. Eager, light, a little swagger; the motif in a new rhythm. Less dense than battle.
- **`music_story`** (story scenes and stage fights): 84–96 BPM, 40–48 s, a seamless loop. Wonder and resolve; the motif slow, then answered. It plays under dialogue: no busy high parts, a clear but soft lead.
- **`music_results`** (results and endings): 96–108 BPM, 20–32 s, a seamless loop that opens with a 2–4 bar fanfare on the motif and settles into a warm loop.
- Same checks as AUD-02a: about RMS −18 dBFS, peak ≤ −1 dBFS, no clipping; the loop point on a bar line, no step at the seam (last and first 10 ms), no level drop at the seam; each file ≤ 8 MB.

## Output
- `art/audio_bakeoff/music_<track>-<a|b|c>.wav`
- `reports/codex-aud-02/measurements.json` (**the AUD-02a format**, so the page reads it), per file a picture (waveform, spectrogram, the seam zoomed) and the score as text
- `reports/codex-aud-02/README.md` (Korean): per track and style the instruments, the tempo, the loudness, what to listen for
- extend `tools/audio_synth/music.py` (keep the AUD-02a files byte-identical) and `verify_music.py`; describe the commands in your report (AUD-01 owns `tools/audio_synth/README.md`)
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no `run.log`

## Writable
`tools/audio_synth/music.py`, `tools/audio_synth/verify_music.py`, `art/audio_bakeoff/music_{select,story,results}-*.wav`, `reports/codex-aud-02/**`.

Hard stop: 150 minutes. Tracks in the order above.
