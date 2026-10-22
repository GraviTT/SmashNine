# CODEX-AUD-01 · Every sound effect, in all three styles, and the listening page for them

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 1 (AUD-01). The plan made the full set after the user's style pick; the user has not picked yet and the Codex quota resets soon, so the lead runs it now **in all three styles**. Whatever the user picks is then ready at once.
- The trial (AUD-01a, `reports/codex-aud-01a/README.md`, `tools/audio_synth/synth.py`) made 12 effects × A/B/C. The game asks for the ids in `smash-nine-prototype/scripts/audio/AudioCatalog.gd` (and `design/AUDIO.md`: when each one plays, its group, its gap).
- Unit: Builder (sound). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/aud-01` (from the latest main).
- Running at the same time: AUD-02 (music, other tracks) in builder-motion. It writes only `art/audio_bakeoff/music_*` and `reports/codex-aud-02/`; it does not touch the listening page. You own `tools/sound_viewer/`.
- **Original sound only:** Python and numpy synthesis, no samples, no downloads, no installs. **Candidates only:** nothing under `smash-nine-prototype/` changes.
- The lead cannot hear. Leave the numbers and pictures; the user judges.

## 1. The effects
Every non-music id in `AudioCatalog.gd` that has no trial file yet, in styles A (chiptune), B (16-bit FM) and C (layered arcade), exactly as AUD-01a defined the styles. Keep the 12 trial ids as they are.
- **Fighters:** the remaining fighter ids (swing_light/heavy, hit_launch, dash, tumble, respawn, …).
- **Skills:** each character's own colour, so the five sound different: Frey (valkyrie: steel, wings, a bright ring), Luna (stars, sparkles, a soft chime), Brave Luna (punches, a heavier star burst), Yuki (paper talismans, a bell, a fan snap), Nova (tech: charge, servo, energy pulse), Rio (runes, a dimension tear, a blade hum). `ult_*` bigger and longer (0.6–1.2 s) than `skill_*` (0.15–0.4 s). The fallbacks `skill_cast`, `ult_start` neutral.
- **Monsters:** `monster_windup` (a short telegraph that reads before an attack), one per archetype (bite, charge, leap, slam, shell, bolt, lob, swoop, blink, homing; fallback `monster_attack`), `monster_hurt`, `monster_defeat`, `elite_appear` (a short horn or roar sting).
- **Realms:** `hazard_warning`, `eruption`, `quake`, `beam`, `vines`, `belt_reverse`, `gate_open`, `gate_travel`, `bush_rustle`, `collapse_warning` (urgent, but not shrill), `portal`.
- **Progress, menus, story:** `soul_pickup`, `card_offer`, `card_pick`, `match_start`, `results`, `victory` (a short fanfare 1–2 s), `ui_move` (very short, quiet), `ui_select`, `ui_cancel`, `story_text` (a tiny tick: it plays on every line), `story_advance`.
- Loudness as AUD-01a: the three styles of one id at the same RMS; classes at the AUD-01a levels (hits and hurt loudest; UI, text and ambience quieter); peak ≤ −1 dBFS; no clipping; start within 5 ms; a clean tail (no click).
- Files: `art/audio_bakeoff/<id>-<a|b|c>.wav` (44.1 kHz, 16-bit, mono like the trial). A picture per id (waveform and spectrogram of the three styles) and `reports/codex-aud-01/measurements.json` (the AUD-01a format).

## 2. The listening page
The page embeds every effect today; about 200 effects will not fit in one page. Rework `tools/sound_viewer/`:
- Effects become sidecar files (`audio/<id>-<style>.wav`) like the music; `dist/files.json` lists them. If the list passes 250 files or 60 MB, also write `files-1.json`, `files-2.json`, … each within that (the Artifact takes 255 files / 64 MB per publish).
- Group the effects by the catalog's groups (Fighters, Skills, Monsters, Realms, Progress, Menus and story). A Korean one-line note per id: when it plays in the game (from `design/AUDIO.md`).
- **A style switch at the top** (A / B / C) that plays every effect in that style, and a **style pick** stored as the document `sound_picks/style` (`{"style": "a"|"b"|"c", "note"}`), next to the existing per-sound picks (`sound_picks/<id>`, unchanged for the 12 trial ids).
- Music: read the music records of every `reports/codex-aud-02*/measurements.json` (AUD-02a now, AUD-02 when it lands) instead of the fixed two tracks; the music picks stay `music_<track>`.
- Update `build.mjs`, `verify.mjs` (mock DOM and db, as now) and `README.md` (how to republish in parts).

## Output
- the WAVs, the pictures, `reports/codex-aud-01/measurements.json`, `reports/codex-aud-01/README.md` (Korean: per group what you made, the loudness table, what to listen to first)
- the synth code in `tools/audio_synth/` (extend it; keep AUD-01a's results byte-identical) and its verify script
- the page changes
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no `run.log`, nothing in `tools/sound_viewer/dist/`

## Writable
`tools/audio_synth/**` except `music.py` and `verify_music.py` (AUD-02 owns them), `tools/sound_viewer/**` (not `dist/`), `art/audio_bakeoff/<non-music ids>-*.wav`, `reports/codex-aud-01/**`.

Hard stop: 150 minutes. Groups in the order above; list what is left.
