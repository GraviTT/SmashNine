"""Read delivered PCM independently; check score, metrics and exact regeneration."""
import argparse
import hashlib
import json
import wave
import numpy as np
import music

LIMITS = {"title": (90, 110, 32, 48), "battle": (150, 170, 32, 48),
          "select": (112, 124, 24, 32), "story": (84, 96, 40, 48), "results": (96, 108, 20, 32)}


def main(collection="all"):
    groups = list(music.COLLECTIONS) if collection == "all" else [collection]
    records, reports = [], {}
    for group in groups:
        specs, report = music.COLLECTIONS[group]
        rows = json.loads((report / "measurements.json").read_text(encoding="utf-8"))["records"]
        expected = {f"music_{t}-{s}.wav" for t in specs for s in "abc"}
        assert len(rows) == len(expected) and {music.Path(r["file"]).name for r in rows} == expected
        records.extend(rows)
        reports.update({t: report for t in specs})
    # Other candidate groups may coexist in the output directory.
    all_expected = {f"music_{t}-{s}.wav" for specs, _ in music.COLLECTIONS.values() for t in specs for s in "abc"}
    assert {p.name for p in music.OUT.glob("music_*.wav")} == all_expected
    details = []
    for r in records:
        path = music.ROOT / r["file"]
        report = reports[r["track"]]
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
        min_bpm, max_bpm, min_seconds, max_seconds = LIMITS[r["track"]]
        assert min_seconds <= frames / 44100 <= max_seconds and path.stat().st_size <= 8_000_000
        assert abs(frames / 44100 - r["bars"] * 4 * 60 / r["bpm"]) < 1e-9
        assert min_bpm <= r["bpm"] <= max_bpm
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
        saved_score = json.loads((report / f"{path.stem}-score.json").read_text(encoding="utf-8"))
        assert score == saved_score
        assert (report / f"{path.stem}-score.txt").read_text(encoding="utf-8") == music.score_text(score)
        assert (report / f"{path.stem}.png").is_file()
        # Every pitched part stays in D dorian; motif is actually in the melody.
        for bar in score["bars"]:
            for part in ["lead", "bass", "harmony"]:
                for e in bar[part]:
                    ns = e["note"] if isinstance(e["note"], list) else [e["note"]]
                    for note in ns:
                        if note != "-": assert music.midi(note) % 12 in [0, 2, 4, 5, 7, 9, 11]
        # The story hook spans two bars; detect contiguous pitched events,
        # preserving the actual notes rather than assuming one-bar motifs.
        melody = [(bar["bar"], e["note"]) for bar in score["bars"] for e in bar["lead"] if e["note"] != "-"]
        hook = music.MOTIF.split()
        motif_bars = [melody[i][0] for i in range(len(melody) - len(hook) + 1)
                      if [n for _, n in melody[i:i + len(hook)]] == hook]
        assert len(motif_bars) >= 2
        # The wrapping tonic must cover exactly the omitted first attack.
        first, last = score["bars"][0]["lead"][0], score["bars"][-1]["lead"][-1]
        assert first["tie_from_end"] and last["tie_to_start"] and first["note"] == last["note"] == "D5"
        assert abs(last["beat"] + last["duration"] - 4 - first["duration"]) < 1e-9
        details.append(dict(file=path.name, deterministic_pcm=True, motif_bars=motif_bars,
                            peak_dbfs=float(peak), rms_dbfs=float(rms), join_step_fs=float(jump),
                            join_side_delta_db=float(delta), join_vs_context_db=float(dip)))
        print("PASS " + path.name, flush=True)
    for track in reports:
        scores = [music.score(track, style) for style in "abc"]
        for part in ["lead", "bass", "drums"]:
            assert all([b[part] for b in s["bars"]] == [b[part] for b in scores[0]["bars"]] for s in scores)
    baseline = json.loads((music.EXTRA_REPORT / "baseline.json").read_text(encoding="utf-8"))
    for relative, sha in baseline["sha256"].items():
        assert hashlib.sha256((music.ROOT / relative).read_bytes()).hexdigest() == sha, relative
    arrangement = {}
    for track in reports:
        score = music.score(track, "a")
        part_counts = {p: sum(e["note"] != "-" and not e.get("tie_from_end", False)
                            for b in score["bars"] for e in b[p]) for p in ["lead", "bass", "harmony", "drums"]}
        seconds = len(score["bars"]) * 4 * 60 / score["bpm"]
        arrangement[track] = dict(scored_attacks=part_counts,
                                  lead_attacks_per_second=part_counts["lead"] / seconds,
                                  drum_attacks_per_second=part_counts["drums"] / seconds,
                                  highest_lead_note=max((e["note"] for b in score["bars"] for e in b["lead"] if e["note"] != "-"), key=music.midi))
    if "story" in reports and "battle" in reports:
        assert arrangement["story"]["lead_attacks_per_second"] < arrangement["battle"]["lead_attacks_per_second"]
        assert arrangement["select"]["drum_attacks_per_second"] < arrangement["battle"]["drum_attacks_per_second"]
    result = dict(status="PASS", wav_count=len(records), details=details, arrangement=arrangement,
                  legacy_wav_count=6, baseline_files_unchanged=True,
                  checks=["44.1kHz PCM16, mono A / stereo B,C", "Per-track duration and BPM ranges, exact whole-bar sample count",
                          "RMS -18dBFS and sample peak <= -1dBFS, no clipping", "Each WAV <=8 decimal MB",
                          "Independent boundary/10ms energy/context seam checks", "SHA256 and byte-identical deterministic PCM replays",
                          "Text and JSON scores match the rendering data", "D dorian only, six-note hook occurs at least twice (story crosses bars)",
                          "Loop tonic covers exactly the omitted first attack", "Same lead/bass/drum score across all styles",
                          "All analysis figures present", "All six legacy WAV hashes and synth.py match the pre-edit baseline"],
                  limitations=["RMS fallback used; integrated LUFS and oversampled true peak not measured",
                               "Numerical seam and spectral evidence do not replace human listening",
                               "Godot, in-game SFX masking, listening page and hosted Artifact DB not exercised"])
    # AUD-02 owns only this report; legacy trial documents stay untouched.
    (music.EXTRA_REPORT / "verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
    print(f"PASS: {len(records)} music candidates, exact PCM regenerations, scores and joins; six legacy WAVs unchanged")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--collection", choices=["all", *music.COLLECTIONS], default="all")
    main(parser.parse_args().collection)
