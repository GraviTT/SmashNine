"""Original AUD-01a candidates. DSP: numpy only; plots: Pillow; WAV: stdlib."""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import wave

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art/audio_bakeoff"
REPORT = ROOT / "reports/codex-aud-01a"
SR = 44100
PEAK = 10 ** (-1 / 20)
# id, Korean label, duration, target full-file RMS dBFS, valid duration range
SOUNDS = [
    ("hit_light", "약한 타격 · J", .18, -13.5, (.12, .25)),
    ("hit_heavy", "강한 타격 · 마무리", .34, -13.5, (.25, .45)),
    ("swing", "휘두르기", .21, -15.0, (.15, .25)),
    ("jump", "점프", .17, -14.0, (.12, .20)),
    ("land", "착지", .12, -14.0, (.08, .15)),
    ("guard", "가드 적중", .21, -14.0, (.15, .25)),
    ("parry", "완벽한 패링", .34, -14.0, (.25, .40)),
    ("hurt", "피격 몸통음", .23, -13.5, (.15, .30)),
    ("ko", "탈락 · KO", .78, -16.0, (.60, .90)),
    ("portal", "차원문 · Q", 1.02, -16.0, (.80, 1.20)),
    ("ui_select", "메뉴 확인", .10, -14.0, (.05, .12)),
    ("ui_cancel", "메뉴 뒤로", .10, -14.0, (.05, .12)),
]
STYLE_NOTES = {
    "a": "사각파·삼각파와 계단 잡음으로 짧고 또렷한 8비트 질감",
    "b": "완만한 음정 변화와 FM 배음으로 둥글고 따뜻한 16비트 울림",
    "c": "짧은 잡음 타격·음정 몸통·저음 펄스를 겹친 아케이드 무게감",
}


def clock(duration):
    return np.arange(round(duration * SR), dtype=np.float64) / SR


def phase(t, start, end=None, bend=.04):
    """Continuous exponential frequency glide, analytically integrated."""
    if end is None:
        end = start
    return 2 * np.pi * (end * t + (start - end) * bend * (1 - np.exp(-t / bend)))


def osc(t, start, end=None, bend=.04, kind="sine"):
    p = phase(t, start, end, bend)
    if kind == "square":
        # Harmonic-limited square (no raw discontinuous aliased oscillator).
        top = start if end is None else max(start, end)
        harmonics = range(1, min(65, int((SR * .44) / top) + 1), 2)
        return sum(np.sin(h * p) / h for h in harmonics) * (4 / np.pi)
    if kind == "triangle":
        return sum((-1) ** ((h - 1) // 2) * np.sin(h * p) / h ** 2
                   for h in range(1, 30, 2) if h * max(start, end or start) < SR * .44) * 8 / np.pi ** 2
    return np.sin(p)


def env(t, decay, attack=.0008):
    return (1 - np.exp(-t / attack)) * np.exp(-t / decay)


def noise(t, seed, low=200, high=9000, step=1):
    """Seeded noise; a frequency mask supplies reproducible soft band edges."""
    rng = np.random.default_rng(seed)
    x = np.repeat(rng.uniform(-1, 1, math.ceil(len(t) / step)), step)[:len(t)]
    f = np.fft.rfftfreq(len(t), 1 / SR)
    mask = (1 - np.exp(-(f / low) ** 4)) * np.exp(-(f / high) ** 6)
    y = np.fft.irfft(np.fft.rfft(x) * mask, n=len(t))
    return y / (np.sqrt(np.mean(y * y)) + 1e-15) * .35


def fm(t, start, end, ratio=2.0, index=1.2, decay=.08, bend=.04):
    p = phase(t, start, end, bend)
    return np.sin(p + index * np.exp(-t / decay) * np.sin(ratio * p))


def chip_hit(t, seed, hz, decay, noise_mix=.7):
    return (.65 * osc(t, hz, hz * .32, .025, "triangle") * env(t, decay)
            + noise_mix * noise(t, seed, 800, 12000, 4) * env(t, decay * .35))


def arcade(t, seed, hz, decay, grit=.6, sub=.35):
    return (grit * noise(t, seed, 950, 10500) * env(t, min(decay * .25, .028))
            + .65 * fm(t, hz, hz * .48, 1.7, .7) * env(t, decay)
            + sub * osc(t, 112, 48, .018) * env(t, min(decay * .7, .065)))


# One named entry point per sound/style: all timbre parameters and seeds are explicit.
def hit_light_a(duration=.18, seed=101):
    return chip_hit(clock(duration), seed, 310, .036, .8)


def hit_light_b(duration=.18, seed=102):
    t = clock(duration)
    return fm(t, 280, 155, 2.7, 2.1, .025, .018) * env(t, .038) + .25 * noise(t, seed, 1200, 6500) * env(t, .012)


def hit_light_c(duration=.18, seed=103):
    return arcade(clock(duration), seed, 265, .038, .95, .32)


def hit_heavy_a(duration=.34, seed=201):
    t = clock(duration)
    return chip_hit(t, seed, 185, .070, .95) + .24 * osc(t, 80, 45, .035, "square") * env(t, .045)


def hit_heavy_b(duration=.34, seed=202):
    t = clock(duration)
    return .8 * fm(t, 170, 65, 1.45, 2.9, .045, .030) * env(t, .075) + .3 * noise(t, seed, 500, 6400) * env(t, .019)


def hit_heavy_c(duration=.34, seed=203):
    t = clock(duration)
    return arcade(t, seed, 190, .080, 1.05, .85) + .10 * noise(t, seed + 1, 90, 1800) * env(t, .08)


def swing_a(duration=.21, seed=301):
    t = clock(duration)
    return noise(t, seed, 1000, 12500, 3) * env(t, .042, .004) + .13 * osc(t, 1000, 230, .06, "triangle") * env(t, .04)


def swing_b(duration=.21, seed=302):
    t = clock(duration)
    return .7 * noise(t, seed, 500, 6500) * env(t, .045, .004) + .24 * fm(t, 850, 190, 1.3, 1.2, .06, .05) * env(t, .047, .004)


def swing_c(duration=.21, seed=303):
    t = clock(duration)
    return .9 * noise(t, seed, 1800, 10500) * env(t, .037, .003) + .19 * osc(t, 650, 120, .045) * env(t, .047) + .08 * osc(t, 88, 55) * env(t, .025)


def jump_a(duration=.17, seed=401):
    t = clock(duration)
    return osc(t, 280, 1000, .055, "square") * env(t, .043) + .08 * noise(t, seed, 1600, 10000, 4) * env(t, .007)


def jump_b(duration=.17, seed=402):
    t = clock(duration)
    return fm(t, 260, 740, 2, 1.2, .06, .045) * env(t, .043) + .07 * noise(t, seed, 1700, 6000) * env(t, .009)


def jump_c(duration=.17, seed=403):
    t = clock(duration)
    return .25 * noise(t, seed, 1400, 8500) * env(t, .014) + .6 * fm(t, 300, 780, 1.5, .5, .04, .05) * env(t, .039) + .2 * osc(t, 110, 65) * env(t, .021)


def land_a(duration=.12, seed=501):
    return chip_hit(clock(duration), seed, 110, .025, .55)


def land_b(duration=.12, seed=502):
    t = clock(duration)
    return fm(t, 125, 58, 1.4, 1.1, .02, .015) * env(t, .026) + .18 * noise(t, seed, 300, 5000) * env(t, .012)


def land_c(duration=.12, seed=503):
    return arcade(clock(duration), seed, 150, .024, .4, .65)


def guard_a(duration=.21, seed=601):
    t = clock(duration)
    return (.65 * osc(t, 590, 520, .02, "square") + .25 * osc(t, 920, kind="triangle")) * env(t, .042) + .2 * noise(t, seed, 2000, 12000, 3) * env(t, .010)


def guard_b(duration=.21, seed=602):
    t = clock(duration)
    return fm(t, 420, 390, 2.76, 2.0, .05, .022) * env(t, .049) + .2 * noise(t, seed, 2000, 8000) * env(t, .009)


def guard_c(duration=.21, seed=603):
    t = clock(duration)
    return arcade(t, seed, 470, .047, .7, .23) + .28 * osc(t, 1470) * env(t, .044)


def parry_a(duration=.34, seed=701):
    t = clock(duration)
    return (.6 * osc(t, 1320, kind="square") + .3 * osc(t, 1980, kind="triangle")) * env(t, .073) + .18 * noise(t, seed, 3000, 14000, 2) * env(t, .008)


def parry_b(duration=.34, seed=702):
    t = clock(duration)
    return (fm(t, 980, 1046, 3.5, 1.25, .045, .018) + .25 * osc(t, 2093)) * env(t, .078) + .10 * noise(t, seed, 3500, 10000) * env(t, .009)


def parry_c(duration=.34, seed=703):
    t = clock(duration)
    return arcade(t, seed, 1046, .070, .65, .18) + .48 * osc(t, 2093) * env(t, .080) + .20 * osc(t, 3139) * env(t, .055)


def hurt_a(duration=.23, seed=801):
    return chip_hit(clock(duration), seed, 145, .048, .8)


def hurt_b(duration=.23, seed=802):
    t = clock(duration)
    return fm(t, 155, 70, 1.37, 2.7, .035, .03) * env(t, .048) + .28 * noise(t, seed, 400, 4600) * env(t, .024)


def hurt_c(duration=.23, seed=803):
    return arcade(clock(duration), seed, 165, .050, .55, .50)


def ko_a(duration=.78, seed=901):
    t = clock(duration)
    # Continuous descending carrier plus stepped third-channel accompaniment.
    steps = np.select([t < .15, t < .30, t < .48], [659.25, 523.25, 392.0], 196.0)
    p = 2 * np.pi * np.cumsum(steps) / SR
    return .65 * osc(t, 780, 85, .20, "triangle") * env(t, .17) + .23 * np.sin(p) * env(t, .16) + .4 * noise(t, seed, 600, 11000, 5) * env(t, .035)


def ko_b(duration=.78, seed=902):
    t = clock(duration)
    return .7 * fm(t, 570, 85, 2.01, 2.0, .15, .20) * env(t, .18) + .18 * osc(t, 285, 42, .22) * env(t, .21) + .3 * noise(t, seed, 700, 6800) * env(t, .024)


def ko_c(duration=.78, seed=903):
    t = clock(duration)
    return arcade(t, seed, 260, .17, .9, .8) + .28 * fm(t, 720, 55, 1.5, .8, .12, .20) * env(t, .17) + .12 * noise(t, seed + 1, 400, 9000) * env(t, .13)


def portal_a(duration=1.02, seed=1001):
    t = clock(duration)
    return (.6 * osc(t, 210, 840, .28, "triangle") + .21 * osc(t, 420, 1680, .28, "square")) * env(t, .24, .002) * (.8 + .2 * np.cos(2 * np.pi * 13 * t)) + .16 * noise(t, seed, 1500, 11000, 5) * env(t, .16)


def portal_b(duration=1.02, seed=1002):
    t = clock(duration)
    return (fm(t, 195, 620, 2.005, 1.9, .25, .25) + .25 * fm(t, 293, 930, 1.5, .8, .30, .25)) * env(t, .24, .002) + .08 * noise(t, seed, 2200, 6500) * env(t, .20)


def portal_c(duration=1.02, seed=1003):
    t = clock(duration)
    return (.65 * fm(t, 220, 880, 1.5, 1.5, .23, .28) + .2 * osc(t, 330, 1320, .28)) * env(t, .23, .002) + .25 * noise(t, seed, 1200, 10000) * env(t, .14) + .30 * osc(t, 100, 45, .04) * env(t, .055)


def ui_select_a(duration=.10, seed=1101):
    t = clock(duration)
    return osc(t, 880, 1760, .025, "square") * env(t, .025)


def ui_select_b(duration=.10, seed=1102):
    t = clock(duration)
    return fm(t, 740, 1480, 2, .65, .025, .02) * env(t, .025)


def ui_select_c(duration=.10, seed=1103):
    t = clock(duration)
    return .65 * osc(t, 900, 1800, .02) * env(t, .025) + .15 * noise(t, seed, 3000, 10000) * env(t, .004) + .12 * osc(t, 140, 90) * env(t, .012)


def ui_cancel_a(duration=.10, seed=1201):
    t = clock(duration)
    return osc(t, 660, 290, .024, "square") * env(t, .026)


def ui_cancel_b(duration=.10, seed=1202):
    t = clock(duration)
    return fm(t, 620, 260, 1.5, .65, .025, .025) * env(t, .026)


def ui_cancel_c(duration=.10, seed=1203):
    t = clock(duration)
    return .65 * osc(t, 660, 280, .025) * env(t, .025) + .15 * noise(t, seed, 2000, 8000) * env(t, .004) + .12 * osc(t, 120, 70) * env(t, .012)


def db(value):
    return 20 * np.log10(max(float(value), 1e-12))


def master(x, target):
    """Match RMS/peak by gentle crest shaping, then impose zero-ended fades.

    Gamma is recorded. No sampled material, stochastic dithering or hard clipping.
    """
    x = x - np.mean(x)
    x /= np.max(np.abs(x))
    fade = np.ones(len(x))
    a, b = round(.0007 * SR), round(.010 * SR)
    fade[:a] = np.sin(np.linspace(0, np.pi / 2, a)) ** 2
    fade[-b:] = np.sin(np.linspace(np.pi / 2, 0, b)) ** 2
    fade[0] = fade[-1] = 0

    def shape(gamma):
        y = np.sign(x) * np.abs(x) ** gamma * fade
        return y * PEAK / np.max(np.abs(y))

    lo, hi = .30, 3.0
    for _ in range(45):
        mid = (lo + hi) / 2
        y = shape(mid)
        if db(np.sqrt(np.mean(y * y))) > target:
            lo = mid
        else:
            hi = mid
    gamma = (lo + hi) / 2
    y = shape(gamma)
    return np.rint(y * 32768).astype("<i2"), gamma


def measure(path, gamma=None):
    with wave.open(str(path), "rb") as w:
        fmt = {"sample_rate": w.getframerate(), "channels": w.getnchannels(), "bits": w.getsampwidth() * 8}
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    x = pcm.astype(np.float64) / 32768
    active = np.flatnonzero(np.abs(x) > 10 ** (-60 / 20))
    return {
        "file": path.relative_to(ROOT).as_posix(), **fmt,
        "length_s": len(x) / SR,
        "peak_dbfs": db(np.max(np.abs(x))),
        "rms_dbfs": db(np.sqrt(np.mean(x * x))),
        "clipped_samples": int(np.sum((pcm == -32768) | (pcm == 32767))),
        "lead_in_ms_at_minus60": float(active[0] / SR * 1000) if len(active) else None,
        "tail_ms_at_minus60": float((len(x) - 1 - active[-1]) / SR * 1000) if len(active) else None,
        "first_sample": int(pcm[0]), "last_sample": int(pcm[-1]),
        "first_1ms_peak_dbfs": db(np.max(np.abs(x[:44]))),
        "last_1ms_peak_dbfs": db(np.max(np.abs(x[-44:]))),
        "last_1ms_max_step": float(np.max(np.abs(np.diff(x[-45:])))),
        "dc_dbfs": db(abs(np.mean(x))),
        "crest_shape_gamma": gamma,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }, x


def font(size):
    for path in ["C:/Windows/Fonts/consola.ttf", "C:/Windows/Fonts/arial.ttf"]:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def picture(name, x, m, path):
    """Fixed absolute axes and dBFS colors; compare pictures without autoscaling."""
    im = Image.new("RGB", (1100, 690), "#0e1523")
    draw = ImageDraw.Draw(im)
    fg, grid = "#cbd7ed", "#2e3a51"
    draw.text((28, 15), name, font=font(24), fill="#ffffff")
    draw.text((28, 48), f"44.1 kHz / PCM16 mono   {m['length_s']:.3f}s   peak {m['peak_dbfs']:.2f} dBFS   RMS {m['rms_dbfs']:.2f} dBFS", font=font(17), fill=fg)
    left, right, top, bottom = 88, 1000, 102, 278
    for value in [-1, -.5, 0, .5, 1]:
        y = (top + bottom) / 2 - value * (bottom - top) / 2
        draw.line((left, y, right, y), fill=grid)
        draw.text((30, y - 9), f"{value:+.1f}", font=font(15), fill=fg)
    bins = np.linspace(0, len(x), right - left + 1).astype(int)
    for i, (a, b) in enumerate(zip(bins[:-1], bins[1:])):
        v = x[a:max(a + 1, b)]
        draw.line((left + i, (top + bottom) / 2 - max(v) * 88,
                   left + i, (top + bottom) / 2 - min(v) * 88), fill="#70d8c2")
    draw.text((left, 78), "WAVEFORM / full scale", font=font(15), fill=fg)
    # Hann STFT 1024 samples, hop 128. Coherent-gain calibrated magnitude.
    nfft, hop = 1024, 128
    padded = np.pad(x, (nfft // 2, nfft // 2))
    frames = np.lib.stride_tricks.sliding_window_view(padded, nfft)[::hop]
    win = np.hanning(nfft)
    magnitude = abs(np.fft.rfft(frames * win, axis=1)) * 2 / win.sum()
    levels = 20 * np.log10(np.maximum(magnitude, 1e-6))
    st, sb = 348, 604
    freq = np.geomspace(SR / 2, 60, sb - st)
    rows = np.clip(np.rint(freq / SR * nfft).astype(int), 0, nfft // 2)
    cols = np.clip(np.rint(np.linspace(0, len(x) / hop, right - left)).astype(int), 0, len(frames) - 1)
    values = np.clip((levels[cols[None, :], rows[:, None]] + 80) / 80, 0, 1)
    stops = np.array([[10, 16, 30], [36, 52, 106], [104, 65, 153], [220, 97, 105], [255, 222, 144]])
    loc = values * 4
    k = np.minimum(loc.astype(int), 3)
    rgb = stops[k] * (1 - (loc - k)[..., None]) + stops[k + 1] * (loc - k)[..., None]
    im.paste(Image.fromarray(rgb.astype(np.uint8)), (left, st))
    draw.text((left, 316), "SPECTROGRAM / log Hz / Hann 1024, hop 128", font=font(15), fill=fg)
    for hz in [60, 250, 1000, 4000, 16000, 22050]:
        y = st + np.log((SR / 2) / hz) / np.log((SR / 2) / 60) * (sb - st)
        draw.text((17, y - 8), str(hz), font=font(14), fill=fg)
    for tick in np.linspace(0, m["length_s"], 5):
        xx = left + tick / m["length_s"] * (right - left)
        draw.text((xx - 22, 613), f"{tick:.2f}", font=font(14), fill=fg)
    for y in range(st, sb):
        level = (sb - y) / (sb - st)
        at = min(int(level * 4), 3)
        mix = level * 4 - at
        color = tuple((stops[at] * (1 - mix) + stops[at + 1] * mix).astype(int))
        draw.line((1021, y, 1035, y), fill=color)
    for v in [0, -20, -40, -60, -80]:
        draw.text((1040, st + (-v / 80) * (sb - st) - 8), str(v), font=font(14), fill=fg)
    draw.text((28, 651), "Time (s). Color: dBFS, fixed -80..0. Endpoints: 0; last 1 ms peak " + f"{m['last_1ms_peak_dbfs']:.1f} dBFS", font=font(15), fill=fg)
    im.save(path)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    records = []
    for sound, label, duration, rms, limits in SOUNDS:
        for style in "abc":
            name = f"{sound}-{style}"
            pcm, gamma = master(globals()[f"{sound}_{style}"](duration=duration), rms)
            path = OUT / f"{name}.wav"
            with wave.open(str(path), "wb") as w:
                w.setnchannels(1)
                w.setsampwidth(2)
                w.setframerate(SR)
                w.writeframes(pcm.tobytes())
            m, x = measure(path, gamma)
            m.update(sound=sound, style=style, label=label, note=STYLE_NOTES[style], duration_range_s=limits)
            assert limits[0] <= m["length_s"] <= limits[1], name
            assert abs(m["peak_dbfs"] + 1) < .002, name
            assert abs(m["rms_dbfs"] - rms) < .02, name
            assert m["clipped_samples"] == 0, name
            assert m["lead_in_ms_at_minus60"] <= 5, name
            assert m["first_sample"] == m["last_sample"] == 0, name
            assert m["last_1ms_peak_dbfs"] < -45, name
            picture(name, x, m, REPORT / f"{name}.png")
            records.append(m)
            print(f"{name:15s} {duration:.3f}s peak={m['peak_dbfs']:.3f} RMS={m['rms_dbfs']:.3f} gamma={gamma:.3f}")
    summary = {"method": "numpy synthesis, deterministic fixed seeds, RMS/peak crest shaping; measured from written PCM16",
               "sample_rate": SR, "peak_target_dbfs": -1, "records": records}
    (REPORT / "measurements.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["| 파일 | Peak dBFS | RMS dBFS | 길이 s | 클리핑 |", "|---|---:|---:|---:|---:|"]
    lines += [f"| `{Path(m['file']).name}` | {m['peak_dbfs']:.2f} | {m['rms_dbfs']:.2f} | {m['length_s']:.3f} | {m['clipped_samples']} |" for m in records]
    (REPORT / "measurements.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    # Three contact sheets keep every result visible for inspection, at readable scale.
    for style in "abc":
        sheet = Image.new("RGB", (1650, 2070), "#0e1523")
        for i, (sound, *_) in enumerate(SOUNDS):
            with Image.open(REPORT / f"{sound}-{style}.png") as pic:
                sheet.paste(pic.resize((550, 345), Image.Resampling.LANCZOS), ((i % 3) * 550, (i // 3) * 345))
        sheet.crop((0, 0, 1650, 1380)).save(REPORT / f"overview-{style}.png")
    print("36 WAV + 36 figures + 3 overviews written; generation checks passed.")


if __name__ == "__main__":
    main()
