"""Sound apply (10-29): the picked WAVs -> OGG Vorbis at the paths AudioManager loads.

usage: python -I convert_audio.py <repo root> <ffmpeg.exe> [--check-only]

Reads picks-snapshot.json next to this file: the `style` document is the default for every
sound effect, a per-sound document overrides it, and every music id has its own document.
Writes smash-nine-prototype/assets/audio/{sfx,music}/<id>.ogg (design/AUDIO.md) and
manifest.json next to this file. --check-only re-measures the OGGs already written.

Checks here: the last Ogg page's granule position (the stream's sample count) must equal the
WAV's frame count. Levels and SNR come from an ffmpeg decode, which is only approximate for the
short effects: ffmpeg's native decoder misreads streams whose only audio page is also the last
one (it trims or pads up to ~1000 frames), so frames_ffmpeg_decode differs there although the
granule is exact. The decode that counts is Godot's own: verify_decode.py.
Music also gets the loop seam test of reports/codex-aud-02 (last -> first sample step
< 0.01 FS, 10 ms RMS on the two sides within 6 dB, the 20 ms around the seam not more than
12 dB below the 400 ms around it), on the WAV and on the ffmpeg-decoded OGG.
"""
import hashlib
import json
import os
import re
import subprocess
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
Q_SFX = 6
Q_MUSIC = 6
RATE = 44100


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def read_wav(path):
    import wave
    with wave.open(path) as w:
        assert w.getsampwidth() == 2 and w.getframerate() == RATE, path
        channels = w.getnchannels()
        data = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    return data.reshape(-1, channels).astype(np.float64) / 32768.0


def decode(ffmpeg, path, channels):
    raw = subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-i", path, "-f", "s16le", "-acodec", "pcm_s16le", "-ac", str(channels), "-ar", str(RATE), "-"], capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype="<i2").reshape(-1, channels).astype(np.float64) / 32768.0


def db(value):
    return round(float(20.0 * np.log10(max(value, 1e-12))), 2)


def rms(x):
    return float(np.sqrt(np.mean(np.square(x)))) if x.size else 0.0


def levels(x):
    mono = x.mean(axis=1)
    window = int(0.05 * RATE)
    short = [rms(mono[i:i + window]) for i in range(0, max(1, mono.size - window + 1), window // 2)]
    return {"rms_dbfs": db(rms(x)), "peak_dbfs": db(float(np.max(np.abs(x)))), "max_50ms_rms_dbfs": db(max(short))}


def best_lag(x, y, span=2048):
    """Offset of y against x over the first 0.5 s (positive: y starts late)."""
    n = min(x.shape[0], y.shape[0], RATE // 2)
    a, b = x[:n].mean(axis=1), y[:n].mean(axis=1)
    if rms(a) < 1e-4:
        return None
    span = min(span, n // 4)
    size = 1 << (2 * n).bit_length()
    corr = np.fft.irfft(np.fft.rfft(b, size) * np.conj(np.fft.rfft(a, size)), size)
    return max(range(-span, span + 1), key=lambda lag: corr[lag % size])


def seam(x):
    """reports/codex-aud-02 seam criteria on a loop that plays x[-1] then x[0]."""
    joined = np.concatenate([x[-int(0.2 * RATE):], x[: int(0.2 * RATE)]]).mean(axis=1)
    mid = joined.size // 2
    ten = int(0.01 * RATE)
    step = float(np.max(np.abs(x[0] - x[-1])))
    before, after = rms(joined[mid - ten:mid]), rms(joined[mid:mid + ten])
    around = rms(joined)
    near = rms(joined[mid - ten:mid + ten])
    result = {
        "step_fs": round(step, 5),
        "rms10_before_db": db(before),
        "rms10_after_db": db(after),
        "rms10_diff_db": round(abs(db(before) - db(after)), 2),
        "rms20_vs_400_db": round(db(near) - db(around), 2),
    }
    result["pass"] = step < 0.01 and result["rms10_diff_db"] < 6.0 and result["rms20_vs_400_db"] > -12.0
    return result


def ogg_pages(path):
    """(header type, granule position) of every Ogg page."""
    data = open(path, "rb").read()
    pos, pages = 0, []
    while pos < len(data):
        assert data[pos:pos + 4] == b"OggS", (path, pos)
        segments = data[pos + 27:pos + 27 + data[pos + 26]]
        pages.append((data[pos + 5], int.from_bytes(data[pos + 6:pos + 14], "little", signed=True)))
        pos += 27 + len(segments) + sum(segments)
    return pages


def catalog_ids(repo):
    text = open(os.path.join(repo, "smash-nine-prototype/scripts/audio/AudioCatalog.gd"), encoding="utf-8").read()
    return re.findall(r'^\t"([a-z0-9_]+)": \{', text, re.M)


def main():
    repo, ffmpeg = sys.argv[1], sys.argv[2]
    check_only = "--check-only" in sys.argv
    snapshot = json.load(open(os.path.join(HERE, "picks-snapshot.json"), encoding="utf-8"))
    docs = {d["id"]: d["data"] for d in snapshot["documents"]}
    default_style = docs["style"]["style"]
    ids = catalog_ids(repo)
    music = [i for i in ids if i.startswith("music_")]
    assert len(ids) == 77 and len(music) == 5, (len(ids), len(music))
    for i in music:
        assert i in docs, "no pick for " + i
    version = subprocess.run([ffmpeg, "-version"], capture_output=True, text=True, check=True).stdout.splitlines()[0]
    manifest = {"snapshot_read_at": snapshot["read_at"], "default_sfx_style": default_style, "ffmpeg": version,
                "encoder": {"codec": "libvorbis", "sfx_quality": Q_SFX, "music_quality": Q_MUSIC,
                            "flags": "-map_metadata -1 -fflags +bitexact -flags:a +bitexact"}, "sounds": []}
    failures = []
    for sound in ids:
        folder = "music" if sound.startswith("music_") else "sfx"
        style = docs[sound]["style"] if sound in docs else default_style
        src = os.path.join(repo, "art/audio_bakeoff", f"{sound}-{style}.wav")
        rel = f"smash-nine-prototype/assets/audio/{folder}/{sound}.ogg"
        dst = os.path.join(repo, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        if not check_only:
            quality = Q_MUSIC if folder == "music" else Q_SFX
            subprocess.run([ffmpeg, "-y", "-hide_banner", "-loglevel", "error", "-i", src, "-map_metadata", "-1", "-fflags", "+bitexact",
                            "-flags:a", "+bitexact", "-c:a", "libvorbis", "-q:a", str(quality), dst], check=True)
        x = read_wav(src)
        y = decode(ffmpeg, dst, x.shape[1])
        pages = ogg_pages(dst)
        lag = best_lag(x, y)
        n = min(x.shape[0], y.shape[0])
        noise = rms(x[:n] - y[:n])
        entry = {
            "id": sound, "folder": folder, "style": style, "picked_by": "per-sound document" if sound in docs else "style document",
            "source": os.path.relpath(src, repo).replace("\\", "/"), "source_sha256": sha256(src),
            "ogg": rel, "ogg_bytes": os.path.getsize(dst), "ogg_sha256": sha256(dst), "wav_bytes": os.path.getsize(src),
            "channels": int(x.shape[1]), "frames_wav": int(x.shape[0]), "end_granule": pages[-1][1], "audio_pages": len(pages) - 2,
            "frames_ffmpeg_decode": int(y.shape[0]), "seconds": round(x.shape[0] / RATE, 4),
            "ffmpeg_lag_samples": lag, "ffmpeg_snr_db": db(rms(x) / max(noise, 1e-12)),
            "wav_levels": levels(x), "ogg_levels_ffmpeg": levels(y),
        }
        if folder == "music":
            entry["seam_wav"] = seam(x)
            entry["seam_ogg"] = seam(y)
            if not entry["seam_ogg"]["pass"] or not entry["seam_wav"]["pass"] or y.shape[0] != x.shape[0]:
                failures.append(sound + " seam")
        if pages[-1] != (4, x.shape[0]):
            failures.append(f"{sound} end page {pages[-1]} != (EOS, {x.shape[0]})")
        manifest["sounds"].append(entry)
        print(f"{sound:20s} {style} {entry['ogg_bytes']:>8d} B  granule {'ok' if pages[-1][1] == x.shape[0] else 'DIFF'} pages {len(pages) - 2} ffmpeg frames {y.shape[0] - x.shape[0]:+d}")
    manifest["totals"] = {
        "sfx_ogg_bytes": sum(s["ogg_bytes"] for s in manifest["sounds"] if s["folder"] == "sfx"),
        "music_ogg_bytes": sum(s["ogg_bytes"] for s in manifest["sounds"] if s["folder"] == "music"),
        "wav_bytes": sum(s["wav_bytes"] for s in manifest["sounds"]),
        "count": len(manifest["sounds"]),
        "failures": failures,
    }
    with open(os.path.join(HERE, "manifest.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(json.dumps(manifest["totals"]))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
