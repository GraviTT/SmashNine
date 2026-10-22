"""Read delivered PCM independently; check score, metrics and exact regeneration."""
import hashlib
import json
import wave
import numpy as np
import music

def main():
    records = json.loads((music.REPORT / "measurements.json").read_text(encoding="utf-8"))["records"]
    expected = {f"music_{t}-{s}.wav" for t in music.SPECS for s in "abc"}
    assert {p.name for p in music.OUT.glob("music_*.wav")} == expected
    assert len(records) == len(expected) and {music.Path(r["file"]).name for r in records} == expected
    details = []
    for r in records:
        path = music.ROOT / r["file"]
        with wave.open(str(path), "rb") as w:
            assert w.getframerate() == 44100 and w.getsampwidth() == 2 and w.getcomptype() == "NONE"
            channels, frames = w.getnchannels(), w.getnframes()
            raw = w.readframes(frames)
        assert channels == (1 if r["style"] == "a" else 2)
        x = np.frombuffer(raw, "<i2").reshape(-1, channels).astype(np.float64) / 32768
        peak = 20 * np.log10(abs(x).max())
        rms = 20 * np.log10(np.sqrt(np.mean(x ** 2)))
        assert peak <= -1 and abs(rms + 18) < .01
        assert abs(peak - r["peak_dbfs"]) < 1e-9 and abs(rms - r["rms_dbfs"]) < 1e-9
        assert 32 <= frames / 44100 <= 48 and path.stat().st_size <= 8_000_000
        assert abs(frames / 44100 - r["bars"] * 4 * 60 / r["bpm"]) < 1e-9
        assert (90 <= r["bpm"] <= 110) if r["track"] == "title" else (150 <= r["bpm"] <= 170)
        assert np.max(abs(x)) < 1 and r["clipped_samples"] == 0
        n = 441
        jump = np.max(abs(x[0] - x[-1]))
        delta = 20 * np.log10(np.sqrt(np.mean(x[:n] ** 2)) / np.sqrt(np.mean(x[-n:] ** 2)))
        context = np.concatenate([x[-8820:], x[:8820]])
        join = np.concatenate([x[-n:], x[:n]])
        dip = 20 * np.log10(np.sqrt(np.mean(join ** 2)) / np.sqrt(np.mean(context ** 2)))
        assert jump < .01 and abs(delta) < 6 and dip > -12, (path.name, jump, delta, dip)
        assert r["seam"]["pass_check"]
        assert abs(jump - r["seam"]["boundary_step_fs"]) < 1e-12
        assert abs(delta - r["seam"]["side_level_delta_db"]) < 1e-9
        assert abs(dip - r["seam"]["seam_vs_context_db"]) < 1e-9
        assert hashlib.sha256(path.read_bytes()).hexdigest() == r["sha256"]
        regenerated, score = music.render(r["track"], r["style"])
        assert regenerated.tobytes() == raw
        saved_score = json.loads((music.REPORT / f"{path.stem}-score.json").read_text(encoding="utf-8"))
        assert score == saved_score
        assert (music.REPORT / f"{path.stem}-score.txt").read_text(encoding="utf-8") == music.score_text(score)
        assert (music.REPORT / f"{path.stem}.png").is_file()
        # Every pitched part stays in D dorian; motif is actually in the melody.
        for bar in score["bars"]:
            for part in ["lead", "bass", "harmony"]:
                for e in bar[part]:
                    ns = e["note"] if isinstance(e["note"], list) else [e["note"]]
                    for note in ns:
                        if note != "-": assert music.midi(note) % 12 in [0, 2, 4, 5, 7, 9, 11]
        motif_bars = [bar["bar"] for bar in score["bars"] if ' '.join(e["note"] for e in bar["lead"]) == music.MOTIF]
        assert len(motif_bars) >= 2
        details.append(dict(file=path.name, deterministic_pcm=True, motif_bars=motif_bars,
                            peak_dbfs=float(peak), rms_dbfs=float(rms), join_step_fs=float(jump),
                            join_side_delta_db=float(delta), join_vs_context_db=float(dip)))
        print("PASS " + path.name, flush=True)
    for track in music.SPECS:
        scores = [music.score(track, style) for style in "abc"]
        for part in ["lead", "bass", "drums"]:
            assert all([b[part] for b in s["bars"]] == [b[part] for b in scores[0]["bars"]] for s in scores)
    result = dict(status="PASS", wav_count=len(records), details=details,
                  checks=["44.1kHz PCM16, mono A / stereo B,C", "32-48s, bar-aligned length, tempo ranges", "RMS -18dBFS and peak <= -1dBFS, no clipping", "Each WAV <=8 decimal MB", "6 independent boundary/10ms energy/context seam checks", "6 SHA256 and byte-identical deterministic PCM replays", "Text and JSON scores match the rendering data", "D dorian only, common six-note motif occurs at least twice per track", "Same lead/bass/drum score across all styles", "All six analysis figures present"],
                  limitations=["RMS fallback used; integrated LUFS and oversampled true peak not measured", "Numerical seam and spectral evidence do not replace human listening", "Godot, in-game SFX masking and hosted Artifact DB not exercised"])
    (music.REPORT / "verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
    print("PASS: six music candidates, six exact PCM regenerations, scores and joins")

if __name__ == "__main__": main()
