"""Sound apply (10-29): compare Godot's own decode of every adopted OGG with its picked WAV.

usage: python -I verify_decode.py <repo root> <decode dir>
<decode dir> comes from smash-nine-prototype/tests/analysis/lead/sound_apply_decode.gd (raw
float32 stereo, rendered by AudioStreamPlayback.mix_audio at the mixer's rate). Writes
decode-check.json next to this file.

Per sound: offset against the WAV (Godot's resampler keeps 2 frames of history, so every stream
should show the same small offset), SNR over the aligned part, how many WAV frames the decode
did not reach and how loud the WAV is there. Per music track: the full first pass, and the 2 s
rendered across the loop wrap against WAV tail + WAV head, with the offset measured separately
before and after the wrap (equal offsets = no gap and no overlap) and the reports/codex-aud-02
seam criteria on the rendered wrap.
"""
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from convert_audio import RATE, db, read_wav, rms, seam  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))


def load_f32(path):
    return np.fromfile(path, dtype="<f4").astype(np.float64).reshape(-1, 2)


def lag_between(ref, sig, span=64):
    """Offset of sig against ref (positive: sig is late), searched in +-span frames."""
    n = min(ref.shape[0], sig.shape[0])
    a, b = ref[:n].mean(axis=1), sig[:n].mean(axis=1)
    if rms(a) < 1e-4:
        return None
    size = 1 << (2 * n).bit_length()
    corr = np.fft.irfft(np.fft.rfft(b, size) * np.conj(np.fft.rfft(a, size)), size)
    return max(range(-span, span + 1), key=lambda lag: corr[lag % size])


def bands(x):
    """Energy per third-octave band (63 Hz - 16 kHz) of the mono sum, in dB."""
    mono = x.mean(axis=1)
    power = np.abs(np.fft.rfft(mono)) ** 2
    freqs = np.fft.rfftfreq(mono.size, 1.0 / RATE)
    centres = [1000.0 * 2.0 ** (k / 3.0) for k in range(-12, 13)]
    return np.array([10.0 * np.log10(max(power[(freqs >= c / 2 ** (1 / 6)) & (freqs < c * 2 ** (1 / 6))].sum(), 1e-12)) for c in centres])


def band_difference(ref, sig):
    """Largest |decode - WAV| over the bands within 40 dB of the WAV's loudest band."""
    a, b = bands(ref), bands(sig)
    keep = a > a.max() - 40.0
    return round(float(np.max(np.abs(a[keep] - b[keep]))), 2)


def compare(ref, sig, lag):
    aligned = sig[lag:] if lag >= 0 else np.concatenate([np.zeros((-lag, 2)), sig])
    n = min(ref.shape[0], aligned.shape[0])
    noise = rms(ref[:n] - aligned[:n])
    missing = ref[n:]
    return {
        "aligned_frames": int(aligned.shape[0]),
        "snr_db": db(rms(ref[:n]) / max(noise, 1e-12)),
        "rms_difference_db": round(db(rms(aligned[:n])) - db(rms(ref[:n])), 2),
        "max_third_octave_difference_db": band_difference(ref[:n], aligned[:n]),
        "wav_frames_not_reached": int(missing.shape[0]),
        "wav_rms_in_not_reached_dbfs": db(rms(missing)) if missing.size else None,
        "wav_peak_in_not_reached_dbfs": db(float(np.max(np.abs(missing)))) if missing.size else None,
        "decode_beyond_wav_peak_dbfs": db(float(np.max(np.abs(aligned[n:])))) if aligned.shape[0] > n else None,
    }


def main():
    repo, decode_dir = sys.argv[1], sys.argv[2]
    manifest = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))
    info = json.load(open(os.path.join(decode_dir, "decode.json"), encoding="utf-8"))
    assert int(info["mix_rate"]) == RATE, info["mix_rate"]
    result = {"mix_rate": info["mix_rate"], "sounds": {}, "failures": []}
    for entry in manifest["sounds"]:
        sound = entry["id"]
        x = read_wav(os.path.join(repo, entry["source"]))
        if x.shape[1] == 1:
            x = np.repeat(x, 2, axis=1)
        y = load_f32(os.path.join(decode_dir, sound + ".f32"))
        godot = info[sound]
        lag = lag_between(x, y)
        row = {"godot_length_frames": godot["frames_by_length"], "wav_frames": int(x.shape[0]), "rendered_frames": int(y.shape[0]),
               "loop": godot["loop"], "loop_offset": godot["loop_offset"], "lag_frames": lag}
        row.update(compare(x, y, lag or 0))
        if godot["frames_by_length"] != x.shape[0]:
            result["failures"].append(f"{sound}: Godot length {godot['frames_by_length']} != WAV {x.shape[0]}")
        if entry["folder"] == "music":
            if not godot["loop"] or godot["loop_offset"] != 0:
                result["failures"].append(sound + ": music must import with loop on from 0")
            wrap = load_f32(os.path.join(decode_dir, sound + "-seam.f32"))
            expected = np.concatenate([x[-RATE:], x[:RATE]])
            half = RATE // 2
            before = lag_between(expected[:RATE], wrap[:RATE])
            after_lag = lag_between(expected[RATE + 2048:RATE + 2048 + half], wrap[RATE + 2048:RATE + 2048 + half])
            noise_before = rms(expected[RATE - half:RATE] - wrap[RATE - half + (before or 0):RATE + (before or 0)])
            noise_after = rms(expected[RATE:RATE + half] - wrap[RATE + (before or 0):RATE + half + (before or 0)])
            row["wrap"] = {
                "lag_before_wrap": before, "lag_after_wrap": after_lag,
                "snr_last_0.5s_db": db(rms(expected[RATE - half:RATE]) / max(noise_before, 1e-12)),
                "snr_first_0.5s_after_wrap_db": db(rms(expected[RATE:RATE + half]) / max(noise_after, 1e-12)),
                "aud02_seam_on_render": seam(np.concatenate([wrap[(before or 0) + RATE:], wrap[:(before or 0) + RATE]])),
                "still_playing": godot.get("seam_still_playing"),
            }
            if before != after_lag or not godot.get("seam_still_playing") or not row["wrap"]["aud02_seam_on_render"]["pass"]:
                result["failures"].append(sound + ": loop wrap")
        elif lag is None or lag != 2:
            result["failures"].append(f"{sound}: offset {lag}")
        result["sounds"][sound] = row
        print(f"{sound:20s} lag {lag} snr {row['snr_db']:5.1f} rmsdiff {row['rms_difference_db']:+.2f} band {row['max_third_octave_difference_db']:.2f}  not reached {row['wav_frames_not_reached']:4d} (rms {row['wav_rms_in_not_reached_dbfs']}, peak {row['wav_peak_in_not_reached_dbfs']})" + (f"  wrap {row['wrap']['lag_before_wrap']}/{row['wrap']['lag_after_wrap']} snr {row['wrap']['snr_last_0.5s_db']}/{row['wrap']['snr_first_0.5s_after_wrap_db']} seam {row['wrap']['aud02_seam_on_render']['pass']}" if 'wrap' in row else ""))
    with open(os.path.join(HERE, "decode-check.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("failures:", result["failures"])
    sys.exit(1 if result["failures"] else 0)


if __name__ == "__main__":
    main()
