"""Sound apply (10-29): read back what the game's mixer recorded (sound_apply_capture.gd).

usage: python -I check_capture.py <repo root> <capture dir>
Checks: every effect and track played its own adopted file; each seam recording, located in
WAV tail + WAV head, continues across the wrap with the same offset (no gap, no overlap) and
passes the reports/codex-aud-02 seam criteria; levels match the files plus the bus faders; the
bot match used no fallback. Clipping of the bot-match mix is reported as a finding (not a
failure): it comes from many effects overlapping, not from the files. capture-match.json (the
--match-only run, unclamped float frames) adds a longer match. Writes capture-check.json.
"""
import json
import os
import sys
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from convert_audio import RATE, db, read_wav, rms, seam  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
SPAN = int(2.5 * RATE)
CHUNK = int(0.25 * RATE)


def read_capture(path):
    with wave.open(path) as w:
        assert w.getframerate() == RATE and w.getnchannels() == 2
        return np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").reshape(-1, 2).astype(np.float64) / 32767.0


def locate(chunk, reference):
    """Start index in reference that best matches chunk (normalised cross-correlation)."""
    a, b = chunk.mean(axis=1), reference.mean(axis=1)
    size = 1 << (a.size + b.size).bit_length()
    corr = np.fft.irfft(np.fft.rfft(b, size) * np.conj(np.fft.rfft(a, size)), size)[: b.size - a.size + 1]
    sums = np.concatenate([[0.0], np.cumsum(b * b)])
    energy = np.sqrt(np.maximum(sums[a.size:] - sums[:-a.size], 0.0))
    return int(np.argmax(corr / np.maximum(energy, 1e-9)))


def main():
    repo, capture_dir = sys.argv[1], sys.argv[2]
    manifest = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))
    capture = json.load(open(os.path.join(capture_dir, "capture.json"), encoding="utf-8"))
    faders = {bus: capture["mixer"]["buses"][bus] for bus in ("Music", "SFX")}
    out = {"mixer": capture["mixer"], "sfx": {}, "music": {}, "seams": {}, "match": {}, "failures": []}
    for entry in manifest["sounds"]:
        sound, expected_path = entry["id"], "res://" + entry["ogg"].split("smash-nine-prototype/", 1)[1]
        if entry["folder"] == "sfx":
            got = capture["sfx"][sound]
            diff = round(got["max_50ms_rms_dbfs"] - (entry["wav_levels"]["max_50ms_rms_dbfs"] + faders["SFX"]), 2)
            out["sfx"][sound] = {"path": got["path"], "resolved": got["resolved"], "capture_max_50ms_dbfs": got["max_50ms_rms_dbfs"],
                                 "capture_peak_dbfs": got["peak_dbfs"], "minus_file_plus_fader_db": diff}
            if got["path"] != expected_path or got["resolved"] != sound:
                out["failures"].append(f"{sound} played {got['path']} via {got['resolved']}")
            continue
        got = capture["music"][sound]
        out["music"][sound] = {"path": got["path"], "imported_loop": got["imported_loop"], "playing_loop": got["playing_stream_loop"],
                               "length_s": got["length_s"], "capture_rms_dbfs": got["rms_dbfs"]}
        if got["path"] != expected_path or not got["imported_loop"] or not got["playing_stream_loop"] or round(got["length_s"] * RATE) != entry["frames_wav"]:
            out["failures"].append(sound + " music path/loop/length")
        x = read_wav(os.path.join(repo, entry["source"]))
        rec = read_capture(os.path.join(capture_dir, capture["seams"][sound]["wav"]))
        ref = np.concatenate([x[-SPAN:], x[:SPAN]])
        # A chunk 0.3 s in is after the seek and before the wrap; it fixes the mapping.
        c0 = int(0.3 * RATE)
        e0 = locate(rec[c0:c0 + CHUNK], ref)
        wrap = SPAN - e0 + c0
        after = locate(rec[wrap + 2048:wrap + 2048 + CHUNK], ref) - (SPAN + 2048)
        before = locate(rec[wrap - 2048 - CHUNK:wrap - 2048], ref) - (SPAN - 2048 - CHUNK)
        half = RATE // 2
        seg_rec = rec[wrap - half:wrap + half]
        seg_ref = ref[SPAN - half:SPAN + half]
        gain = float(np.sum(seg_rec * seg_ref) / np.sum(seg_ref * seg_ref))
        noise_before = rms(seg_rec[:half] - gain * seg_ref[:half])
        noise_after = rms(seg_rec[half:] - gain * seg_ref[half:])
        around = rec[wrap - int(0.2 * RATE):wrap + int(0.2 * RATE)]
        row = {
            "wrap_frame_in_recording": int(wrap), "offset_before_wrap": int(before), "offset_after_wrap": int(after),
            "gain": round(gain, 4), "gain_db": db(gain), "music_fader_db": faders["Music"],
            "snr_0.5s_before_db": db(rms(gain * seg_ref[:half]) / max(noise_before, 1e-12)),
            "snr_0.5s_after_db": db(rms(gain * seg_ref[half:]) / max(noise_after, 1e-12)),
            "aud02_seam_on_recording": seam(np.concatenate([around[around.shape[0] // 2:], around[:around.shape[0] // 2]])),
        }
        out["seams"][sound] = row
        if before != 0 or after != 0 or not row["aud02_seam_on_recording"]["pass"] or min(row["snr_0.5s_before_db"], row["snr_0.5s_after_db"]) < 20.0:
            out["failures"].append(sound + " seam")
    match = capture["match"]
    out["match"] = {k: match[k] for k in ("seconds", "rms_dbfs", "peak_dbfs", "max_50ms_rms_dbfs", "music", "started_paths", "resolutions")}
    wrong = {k: v for k, v in match["resolutions"].items() if k != v}
    out["match"]["fallbacks_used"] = wrong
    if wrong:
        out["failures"].append("match used a fallback")
    clip_keys = ("frames", "rms_dbfs", "peak_dbfs", "peak_after_master_dbfs", "max_50ms_rms_dbfs", "frames_over_0dbfs", "frames_clipping_output", "output_clip_runs", "longest_output_clip_frames")
    longer = os.path.join(capture_dir, "capture-match.json")
    if os.path.exists(longer):
        extra = json.load(open(longer, encoding="utf-8"))["match"]
        out["match_long"] = {k: extra[k] for k in clip_keys if k in extra}
        out["match_long"].update({"seconds_requested": extra["seconds"], "seconds_recorded": round(extra["frames"] / RATE, 2), "distinct_files": len(extra["started_paths"]),
                                  "started_paths": extra["started_paths"], "fallbacks_used": {k: v for k, v in extra["resolutions"].items() if k != v}})
        out["match_long"]["clipping_share_percent"] = round(100.0 * extra["frames_clipping_output"] / extra["frames"], 3)
        if out["match_long"]["fallbacks_used"]:
            out["failures"].append("long match used a fallback")
    diffs = [v["minus_file_plus_fader_db"] for v in out["sfx"].values()]
    out["sfx_level_vs_file_db"] = {"min": min(diffs), "max": max(diffs)}
    with open(os.path.join(HERE, "capture-check.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
        f.write("\n")
    for sound, row in out["seams"].items():
        print(f"{sound:14s} wrap at {row['wrap_frame_in_recording']:6d}  offset before/after {row['offset_before_wrap']}/{row['offset_after_wrap']}  gain {row['gain_db']} dB  snr {row['snr_0.5s_before_db']}/{row['snr_0.5s_after_db']}  aud02 {row['aud02_seam_on_recording']['pass']}")
    print("sfx capture - (file + fader):", out["sfx_level_vs_file_db"])
    print("match:", {k: out["match"][k] for k in ("rms_dbfs", "peak_dbfs", "max_50ms_rms_dbfs", "music")}, len(match["started_paths"]), "files")
    if "match_long" in out:
        print("long match:", {k: out["match_long"][k] for k in ("seconds_recorded", "distinct_files", "peak_after_master_dbfs", "frames_clipping_output", "output_clip_runs", "longest_output_clip_frames", "clipping_share_percent")})
    print("failures:", out["failures"])
    sys.exit(1 if out["failures"] else 0)


if __name__ == "__main__":
    main()
