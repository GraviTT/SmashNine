# CODEX-AUD-02a · Music, trial: a title theme and a battle loop in the three styles

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 1 (music).
- The sound effects trial (AUD-01a, merged `c43851e`) is with the user now. This trial does the same for music, so one direction can be picked for both.
- Unit: Builder (sound). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/aud-02a` (from the latest main). Your AUD-01a synth code is in `tools/audio_synth/`; build on it.
- Running at the same time:
  - ART-71 (monsters), ART-72 (character motions), SYS-06 (wiring) in other clones
  - You share no files. SYS-06 is the only unit running Godot.
- **Original music only.** Compose and synthesize everything yourself with Python and numpy. No samples, no downloads, no installs.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes.
- The lead cannot hear. Leave the numbers and pictures named below; the user judges the music.

## The two tracks
- **`title`**: the start screen. 90–110 BPM, 32–48 s, a seamless loop.
  - Mood: the nine realms of Yggdrasil, wonder with a little danger.
  - Introduce a short **motif** (4–8 notes) that the battle track reuses.
- **`battle`**: a realm fight. 150–170 BPM, 32–48 s, a seamless loop.
  - Mood: driving and bright, not grim. The motif returns in the melody.
  - Leave room for the sound effects: no constant high noise, and a melody that is not too dense.
- Both: a Norse-fantasy colour (a minor mode: dorian or aeolian), a clear melody, bass, drums, a short harmony part.

## The three styles (the same A/B/C as the effects)
- **A, chiptune**: two pulse waves, a triangle and noise drums (NES-like).
- **B, 16-bit**: FM lead and bass, a pad, synthesized drums, a short room reverb (SNES/Genesis-like).
- **C, layered**: a chiptune lead over a soft synth pad and punchy layered drums.

## Format and checks
- WAV, 44.1 kHz, 16-bit, stereo or mono (your choice per style; say why). Each file ≤ 8 MB.
- Loudness about −16 LUFS (measure it, or RMS about −18 dBFS if LUFS cannot be measured), peak ≤ −1 dBFS, no clipping.
- **Seamless loop**: the loop point on a bar line. Check that the last and first 10 ms join with no step, and that the level does not drop at the seam.
- Files: `art/audio_bakeoff/music_<track>-<style>.wav`.
- Per file, in `reports/codex-aud-02a/`:
  - a picture: waveform, spectrogram, and the loop seam zoomed
  - the score as text (the notes per part per bar)

## The listening page
Extend `tools/sound_viewer/` with a **음악** section: a card per track, with its three styles.

- The page:
  - play / stop, and a loop toggle
  - a Korean one-line note per style
  - the effects section stays as it is
- **Adopt**: the same `sound_picks` collection, with document ids `music_title` and `music_battle`.
- **Music files are not embedded.** Reference them as sidecar files (`audio/music_*.wav`) and list them in `dist/files.json`, so the lead publishes them with the page. The effects stay embedded.
  - Update `build.mjs` and `verify.mjs`, which hard-code 36 files today.
- `tools/sound_viewer/README.md`: the music section and how to republish with the sidecar files.

## Output
- the WAVs, the scores, the pictures
- `reports/codex-aud-02a/measurements.json`
- `reports/codex-aud-02a/README.md` (Korean): per style, the instruments and the measured loudness
- the page changes
- `commit.ps1` (only your files, no `git add -f`, no `__pycache__`)

## Writable
`tools/audio_synth/**`, `tools/sound_viewer/**`, `art/audio_bakeoff/music_*`, `reports/codex-aud-02a/**`.

Hard stop: 150 minutes.
