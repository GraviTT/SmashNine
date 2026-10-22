"""Independent verification of delivered PCM, plus deterministic regeneration in RAM."""
import hashlib
import json
from pathlib import Path
import wave

import numpy as np
import synth

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "reports/codex-aud-01a"


def level(value):
    return 20 * np.log10(max(float(value), 1e-12))


def main():
    manifest = json.loads((REPORT / "measurements.json").read_text(encoding="utf-8"))
    expected = {f"{sound}-{style}.wav" for sound, *_ in synth.SOUNDS for style in "abc"}
    actual = {p.name for p in (ROOT / "art/audio_bakeoff").glob("*.wav")}
    assert actual == expected, (actual - expected, expected - actual)
    details = []
    for m in manifest["records"]:
        path = ROOT / m["file"]
        with wave.open(str(path), "rb") as w:
            assert (w.getframerate(), w.getsampwidth(), w.getnchannels(), w.getcomptype()) == (44100, 2, 1, "NONE")
            raw = w.readframes(w.getnframes())
        pcm = np.frombuffer(raw, "<i2")
        y = pcm.astype(np.float64) / 32768
        peak, rms = level(max(abs(y))), level(np.sqrt(np.mean(y ** 2)))
        duration = len(y) / 44100
        assert abs(peak + 1) < .002 and not np.any((pcm == 32767) | (pcm == -32768))
        assert abs(peak - m["peak_dbfs"]) < 1e-8
        assert abs(rms - m["rms_dbfs"]) < 1e-8 and abs(duration - m["length_s"]) < 1e-8
        assert m["duration_range_s"][0] <= duration <= m["duration_range_s"][1]
        lead = np.flatnonzero(abs(y) > .001)[0] / 44100 * 1000
        assert lead <= 5 and pcm[0] == pcm[-1] == 0
        end_peak = level(max(abs(y[-44:])))
        end_step = max(abs(np.diff(y[-45:])))
        assert end_peak < -45 and end_step < .001
        # Compare PCM bytes from a fresh function invocation, without writing files.
        target_rms = next(spec[3] for spec in synth.SOUNDS if spec[0] == m["sound"])
        regenerated, _ = synth.master(getattr(synth, f"{m['sound']}_{m['style']}")(duration=duration), target_rms)
        assert regenerated.tobytes() == raw, f"non-deterministic PCM: {path.name}"
        assert hashlib.sha256(path.read_bytes()).hexdigest() == m["sha256"]
        # Broad spectral descriptors: indicators of timbre, not perceived quality.
        power = abs(np.fft.rfft(y)) ** 2
        hz = np.fft.rfftfreq(len(y), 1 / 44100)
        centroid = float(np.sum(power * hz) / np.sum(power))
        sub = float(np.sum(power[(hz >= 30) & (hz < 120)]) / np.sum(power))
        high = float(np.sum(power[hz >= 4000]) / np.sum(power))
        details.append({"file": path.name, "peak_dbfs": peak, "rms_dbfs": rms,
                        "length_s": duration, "lead_in_ms_at_minus60": float(lead),
                        "last_1ms_peak_dbfs": end_peak, "last_1ms_max_step": float(end_step),
                        "power_centroid_hz": centroid, "energy_30_120hz_fraction": sub,
                        "energy_above_4khz_fraction": high, "deterministic_pcm": True})
        assert (REPORT / f"{path.stem}.png").is_file()
    spreads = {}
    for sound, *_ in synth.SOUNDS:
        rows = [d for d in details if d["file"].startswith(sound + "-")]
        assert len(rows) == 3
        spread = max(d["rms_dbfs"] for d in rows) - min(d["rms_dbfs"] for d in rows)
        assert spread <= 3, (sound, spread)  # Stricter than a +/-3 dB window.
        spreads[sound] = spread
    result = {"status": "PASS", "wav_count": len(details), "figure_count": 36,
              "checks": ["PCM16 mono 44100 Hz", "duration ranges", "peak -1 dBFS", "zero clipped samples",
                         "lead-in <= 5 ms at -60 dBFS", "zero endpoints", "last 1 ms < -45 dBFS",
                         "last 1 ms sample steps < .001 full-scale", "36 exact deterministic PCM replays",
                         "reported values and SHA256 match written WAVs", "same-sound RMS spread <= 3 dB"],
              "rms_spread_db_by_sound": spreads, "details": details,
              "limitations": ["No human listening test", "Sample peak, not oversampled true peak",
                              "Spectral metrics do not establish perceived warmth or punch",
                              "No real browser or hosted Artifact database was available"]}
    (REPORT / "verification.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: {len(details)} WAVs, 36 plots, 36 exact deterministic PCM replays")
    print(f"Maximum A/B/C RMS spread: {max(spreads.values()):.6f} dB")
    print(f"Maximum onset delay: {max(d['lead_in_ms_at_minus60'] for d in details):.3f} ms")
    print(f"Loudest final 1 ms peak: {max(d['last_1ms_peak_dbfs'] for d in details):.3f} dBFS")
    print(f"Largest final 1 ms sample step: {max(d['last_1ms_max_step'] for d in details):.6f} full-scale")


if __name__ == "__main__":
    main()
