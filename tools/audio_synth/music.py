"""AUD-02a/AUD-02: original, data-scored D-dorian music; numpy DSP + Pillow only.

Uses AUD-01a oscillators, filtered seeded noise, fonts and WAV conventions.
All releases and room taps wrap onto the beginning: no fade-to-silence loop.
"""
from __future__ import annotations
import hashlib
import json
import argparse
import wave
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
import synth

ROOT = synth.ROOT
OUT = ROOT / "art/audio_bakeoff"
REPORT = ROOT / "reports/codex-aud-02a"
SR = synth.SR
MOTIF = "D5 A5 G5 E5 F5 D5"
SPECS = {"title": (100, 16, "이그드라실의 아침"), "battle": (160, 24, "아홉 세계의 질주")}
EXTRA_SPECS = {"select": (120, 16, "영웅들의 발걸음"), "story": (90, 16, "뿌리가 기억하는 약속"),
               "results": (100, 12, "다시 만날 아홉 세계")}
EXTRA_REPORT = ROOT / "reports/codex-aud-02"
COLLECTIONS = {"aud02": (EXTRA_SPECS, EXTRA_REPORT), "aud02a": (SPECS, REPORT)}
NOTES = {"a": "두 펄스의 맑은 룬 선율과 삼각파 베이스, 짧은 잡음 북의 칩튠",
         "b": "종 같은 FM 선율·탄력 있는 FM 베이스와 패드, 작은 방의 16비트 울림",
         "c": "또렷한 칩 선율에 부드러운 패드와 겹친 킥·스네어를 더한 추진력"}

# Each string is one complete bar. onset/duration are quarter-note beats.
# '-' means a rest, retained in the exported score. No algorithmic melody.
P = [
    "0:D5:0.65 0.75:A5:0.4 1.25:G5:0.6 2:E5:0.4 2.5:F5:0.4 3:D5:0.8",
    "0:-:1 1:E5:0.65 2:G5:0.65 3:A5:0.75",
    "0:B5:0.8 1:A5:0.65 2:G5:0.65 3:E5:0.6",
    "0:F5:1.25 1.5:E5:0.75 2.5:D5:1.1",
    "0:A4:0.65 1:D5:0.65 2:F5:0.65 3:E5:0.65",
    "0:G5:1.1 1.5:E5:0.65 2.5:C5:0.8",
    "0:D5:0.65 1:F5:0.65 2:A5:1.25 3.5:G5:0.3",
    "0:E5:0.8 1:F5:0.65 2:E5:0.65 3:D5:0.65",
    "0:D5:0.65 0.75:A5:0.4 1.25:G5:0.6 2:E5:0.4 2.5:F5:0.4 3:D5:0.8",
    "0:-:0.5 0.5:E5:0.65 1.5:G5:0.65 2.5:A5:1.0",
    "0:B5:0.65 1:D6:0.65 2:A5:0.8 3:G5:0.65",
    "0:F5:0.8 1:E5:0.65 2:D5:1.4",
    "0:F5:0.65 1:A5:0.65 2:G5:0.65 3:F5:0.65",
    "0:E5:0.65 1:G5:0.65 2:B5:0.8 3:A5:0.65",
    "0:A5:0.65 1:G5:0.65 2:F5:0.65 3:E5:0.65",
    "0:F5:0.8 1:E5:0.65 2:D5:1.4",
]
# B section opens out with fewer attacks; final A restates the six-note hook.
BATTLE = P[:8] + [
    P[0], P[1], P[10], P[11],
    "0:F5:1.2 1.5:A5:0.8 3:C6:0.65",
    "0:B5:1.2 1.5:A5:0.8 3:G5:0.65",
    "0:E5:1.2 1.5:G5:0.8 3:E5:0.65",
    "0:F5:1.0 1.5:E5:0.8 3:D5:0.65",
] + P[8:]
CHORDS = {
    "Dm": ("D2", ["D4", "F4", "A4"]), "C": ("C2", ["C4", "E4", "G4"]),
    "G": ("G2", ["B3", "D4", "G4"]), "Am": ("A2", ["A3", "C4", "E4"]),
    "F": ("F2", ["A3", "C4", "F4"]),
}
TITLE_CHORDS = ["Dm", "C", "G", "Dm", "Dm", "C", "G", "Dm", "Dm", "C", "G", "Dm", "F", "G", "Am", "Dm"]
BATTLE_CHORDS = TITLE_CHORDS[:8] + ["Dm", "C", "G", "Dm", "F", "G", "C", "Dm"] + TITLE_CHORDS[8:]

def midi(note):
    return 12 * (int(note[-1]) + 1) + {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}[note[0]]

def hz(note):
    return 440 * 2 ** ((midi(note) - 69) / 12)

def event(beat, note, duration, velocity=1.):
    return dict(beat=beat, note=note, duration=duration, velocity=velocity)

def score(track, style):
    if track in EXTRA_SPECS:
        return extra_score(track, style)
    bpm, count, label = SPECS[track]
    melodies = P if track == "title" else BATTLE
    chords = TITLE_CHORDS if track == "title" else BATTLE_CHORDS
    bars = []
    for i in range(count):
        lead = [event(float(a), n, float(d)) for a, n, d in (s.split(":") for s in melodies[i].split())]
        # Hold the final tonic across the bar line: the loop is a continuation,
        # not a quiet release followed by a fresh downbeat every 36-38 seconds.
        if i == count - 1:
            lead[-1]["duration"] = 2.65
            lead[-1]["tie_to_start"] = True
            lead[-1]["velocity"] = 1.15
        if i == 0:
            lead[0]["tie_from_end"] = True
        root, chord = CHORDS[chords[i]]
        fifth = {"D2": "A2", "C2": "G2", "G2": "D3", "A2": "E3", "F2": "C3"}[root]
        if track == "title":
            bass = [event(0, root, 1.7), event(2, fifth, .8), event(3, root, 1.18, .8)]
            drums = [event(0, "kick", .23, .5), event(2, "snare", .19, .65)]
            hats = [0.5, 1.5, 2.5, 3.5]
        else:
            bass = [event(b, root if j % 2 == 0 else fifth, .38 if b != 3.5 else .7, .82 if j % 2 else 1.) for j, b in enumerate([0, .75, 1.5, 2, 2.75, 3.5])]
            drums = [event(b, "kick", .24, 1 if b in (0, 2) else .65) for b in [0, 1.5, 2, 3.5]]
            drums += [event(b, "snare", .2, .85) for b in [1, 3]]
            hats = list(np.arange(0, 4, .5))
        drums += [event(float(b), "hat", .05, .30 if j % 2 else .42) for j, b in enumerate(hats)]
        if i % 8 == 7:
            drums += [event(3.25, "snare", .12, .3), event(3.75, "snare", .12, .4)]
        if style == "a":
            # Exactly two monophonic pulse parts + one triangle; no chord polyphony.
            harmony = [event(.25 + j, chord[j % 3], .48, .65) for j in range(3)]
        else:
            # Brief chord answer, not an uninterrupted orchestral wash.
            harmony = [event(.25, chord, 2.45, .7), event(3, chord, 1.35, .44)]
        bars.append(dict(bar=i + 1, chord=chords[i], lead=lead, bass=bass, harmony=harmony, drums=drums))
    return dict(track=track, style=style, label=label, bpm=bpm, meter="4/4", mode="D dorian (D E F G A B C)", motif=MOTIF, bars=bars)


# AUD-02: written melodies, not generated variations of the old P/BATTLE score.
# Select: a dotted/offbeat hook; story: the hook stretches across two bars,
# then receives a lower answer. Results: two-bar salute then a gentler return.
SELECT = [
    "0:D5:0.4 0.5:A5:0.55 1.25:G5:0.55 2:E5:0.55 2.75:F5:0.4 3.5:D5:0.35",
    "0:-:0.5 0.5:F5:0.7 1.5:A5:0.55 2.5:G5:0.55 3.5:E5:0.35",
    "0:G5:0.65 1:B5:0.65 2:A5:0.45 2.75:G5:0.85",
    "0:F5:0.6 1:E5:0.55 2:D5:1.5",
    "0:-:0.5 0.5:A4:0.6 1.5:D5:0.6 2.5:F5:1.0",
    "0:E5:0.65 1:G5:0.65 2.5:E5:1.0",
    "0:B4:0.6 1:D5:0.6 2:G5:0.65 3:A5:0.6",
    "0:G5:0.6 1:E5:0.6 2:F5:0.6 3:D5:0.65",
    "0:D5:0.4 0.5:A5:0.55 1.25:G5:0.55 2:E5:0.55 2.75:F5:0.4 3.5:D5:0.35",
    "0:-:0.5 0.5:E5:0.6 1.5:G5:0.6 2.5:A5:1.0",
    "0:B5:0.65 1:A5:0.65 2:G5:0.65 3:E5:0.65",
    "0:F5:0.8 1.5:E5:0.65 2.5:D5:1.0",
    "0:A4:0.8 1.5:C5:0.8 3:F5:0.6",
    "0:G5:0.8 1.5:B5:0.8 3:A5:0.6",
    "0:A5:0.6 1:G5:0.6 2:E5:0.6 3:F5:0.6",
    "0:F5:0.65 1:E5:0.65 2:D5:2.4",
]
STORY = [
    "0:D5:1.7 2:A5:1.7",
    "0:G5:0.8 1:E5:0.8 2:F5:0.8 3:D5:0.8",
    "0:B4:1.6 2:D5:1.6",
    "0:E5:1.3 1.5:C5:0.8 2.5:D5:1.1",
    "0:A4:1.6 2:C5:1.6",
    "0:E5:1.1 1.5:G5:1.8",
    "0:F5:1.6 2:E5:1.6",
    "0:D5:2.6 3:-:1",
    "0:D5:1.7 2:A5:1.7",
    "0:G5:0.8 1:E5:0.8 2:F5:0.8 3:D5:0.8",
    "0:B4:1.6 2:G5:1.6",
    "0:E5:1.3 1.5:D5:0.8 2.5:C5:1.1",
    "0:A4:1.6 2:C5:1.6",
    "0:B4:1.6 2:D5:1.6",
    "0:E5:1.4 2:F5:1.2",
    "0:E5:1.4 2:D5:3.7",
]
RESULTS = [
    "0:D5:0.75 1:A5:0.75 2:G5:0.45 2.5:E5:0.45 3:F5:0.45 3.5:D5:0.4",
    "0:F5:0.7 1:A5:0.7 2:B5:0.7 3:A5:0.75",
    "0:G5:1.3 2:E5:1.2",
    "0:F5:1.3 2:D5:1.5",
    "0:A4:1.2 2:C5:1.2",
    "0:E5:1.2 2:G5:1.2",
    "0:B4:1.2 2:D5:1.2",
    "0:F5:1.2 2:E5:1.2",
    "0:D5:0.75 1:A5:0.75 2:G5:0.45 2.5:E5:0.45 3:F5:0.45 3.5:D5:0.4",
    "0:C5:1.2 2:E5:1.2",
    "0:B4:1.2 2:G5:1.2",
    "0:F5:0.7 1:E5:0.7 2:D5:2.75",
]
EXTRA_CHORDS = {
    "select": TITLE_CHORDS,
    "story": ["Dm", "Dm", "G", "C", "F", "C", "G", "Dm", "Dm", "Dm", "G", "C", "F", "G", "Am", "Dm"],
    "results": ["Dm", "Dm", "C", "Dm", "F", "C", "G", "Am", "Dm", "C", "G", "Dm"],
}
EXTRA_NOTES = {
    "select": {"a": "엇박 펄스 훅·삼각파 베이스·작은 잡음 북: 가벼운 영웅 선택",
               "b": "FM 훅·베이스와 짧은 패드 응답: 둥근 16비트 선택곡",
               "c": "칩 훅·넓은 패드·절제한 겹친 드럼: 산뜻한 선택곡"},
    "story": {"a": "고역을 줄인 펄스의 느린 모티프·삼각파·드문 잡음 북",
              "b": "부드러운 FM 선율·긴 패드·낮은 북: 대사 아래의 여정",
              "c": "낮춘 칩 선율·넓은 패드·작은 겹친 북: 신비와 다짐"},
    "results": {"a": "두 마디 펄스 팡파르에서 여유로운 칩 선율로",
                "b": "FM 팡파르 뒤 둥근 저음·따뜻한 패드로 쉬어가는 결과곡",
                "c": "칩 팡파르·겹친 북 뒤 패드와 긴 음으로 마무리"},
}


def extra_score(track, style):
    bpm, count, label = EXTRA_SPECS[track]
    melodies = {"select": SELECT, "story": STORY, "results": RESULTS}[track]
    bars = []
    for i, melody in enumerate(melodies):
        lead = [event(float(a), n, float(d)) for a, n, d in (token.split(":") for token in melody.split())]
        if i == 0:
            lead[0]["tie_from_end"] = True
        if i == count - 1:
            lead[-1]["tie_to_start"] = True
            # Carry enough tonic energy into the next downbeat's bass attack.
            lead[-1]["velocity"] = 1.1 if track == "story" else 1.4
        fanfare = track == "results" and i < 2
        if track == "results":
            for e in lead:
                e["velocity"] *= 1.12 if fanfare else .78
        root, chord = CHORDS[EXTRA_CHORDS[track][i]]
        fifth = {"D2": "A2", "C2": "G2", "G2": "D3", "A2": "E3", "F2": "C3"}[root]
        if track == "select":
            bass = [event(0, root, .8), event(1.5, fifth, .4, .8), event(2.5, root, .65), event(3.5, fifth, .4, .7)]
            drums = [event(0, "kick", .2, .7), event(2.5, "kick", .2, .4), event(1, "snare", .2, .5), event(3, "snare", .2, .5)]
            drums += [event(b, "hat", .05, .22) for b in [.5, 1.5, 2.5, 3.5]]
            harmony = ([event(.75 + j, chord[j], .42, .6) for j in range(3)] if style == "a"
                       else [event(.75, chord, 1.3, .6), event(2.75, chord, .8, .45)])
        elif track == "story":
            bass = [event(0, root, 2.6, .8), event(3, fifth, .85, .6)]
            drums = [event(.5, "kick", .2, .32), event(2.5, "snare", .2, .25)]
            if i % 2:
                drums += [event(3.5, "hat", .05, .12)]
            harmony = ([event(.5, chord[0], 1.15, .65), event(2.25, chord[1 if i % 2 else 2], 1.25, .6)] if style == "a"
                       else [event(.25, chord, 3.25, .72)])
        else:
            bass = [event(0, root, 1.65, .9), event(2, fifth, 1.65, .75)]
            drums = [event(.5, "kick", .2, .6 if fanfare else .35), event(2.5, "snare", .2, .65 if fanfare else .3)]
            if fanfare:
                drums += [event(1.5, "snare", .15, .3), event(3.25, "snare", .15, .3), event(3.75, "snare", .15, .4)]
            else:
                drums += [event(1.5, "hat", .05, .16)]
            harmony = ([event(.25 + j * 1.25, chord[j], .8, .7) for j in range(3)] if style == "a"
                       else [event(.25, chord, 3.25, .72)])
        bars.append(dict(bar=i + 1, chord=EXTRA_CHORDS[track][i], lead=lead, bass=bass, harmony=harmony, drums=drums))
    return dict(track=track, style=style, label=label, bpm=bpm, meter="4/4", mode="D dorian (D E F G A B C)", motif=MOTIF, bars=bars)

def envelope(t, gate, attack, release, decay=0.):
    e = np.minimum(t / attack, 1.) * np.minimum(np.maximum((gate + release - t) / release, 0.), 1.)
    if decay:
        e *= .62 + .38 * np.exp(-t / decay)
    return e

def pulse(t, f, duty=.5, ceiling=7500):
    # Band-limited pulse (DC removed); A's pulse 2 uses the 25% duty voice.
    p = 2 * np.pi * f * t
    return sum(4 * np.sin(np.pi * h * duty) / (np.pi * h) * np.cos(h * p - np.pi * h * duty)
               for h in range(1, min(40, int(ceiling / f)) + 1))

def pitched(note, seconds, part, style, phase_offset=0., soft=False):
    release = .085 if part == "lead" else (.19 if part == "harmony" else .07)
    if style != "a" and part == "harmony": release = .24
    t = synth.clock(seconds + release)
    f = hz(note)
    tone_t = t + phase_offset / f
    if part == "lead":
        if style == "b":
            x = synth.fm(tone_t, f, f, ratio=2, index=.7 if soft else 1.45, decay=.18 if soft else .10) + (.04 if soft else .12) * synth.osc(tone_t, f * 2)
        else:
            x = pulse(tone_t, f, .5, 2400 if soft else 6000) * .64 + (.12 * synth.osc(tone_t, f) if style == "c" else 0)
        return x * envelope(t, seconds, .025 if soft else .005, release, .12)
    if part == "bass":
        if style == "a": x = synth.osc(t, f, kind="triangle")
        else: x = synth.fm(t, f, f, ratio=1, index=.95, decay=.075) + .16 * synth.osc(t, f / 2)
        return x * envelope(t, seconds, .004, release, .14)
    if style == "a": x = .65 * pulse(t, f, .25, 2200 if soft else 4500)
    else:
        x = .55 * synth.osc(t, f) + .20 * synth.osc(t, f * 1.002) + .13 * synth.osc(t, f * 2) + .05 * synth.osc(t, f * 3)
    return x * envelope(t, seconds, .018 if style == "a" else .065, release)

def drum(kind, style, seed):
    t = synth.clock({"kick": .3, "snare": .24, "hat": .065}[kind])
    if style == "a":
        low, high, decay, step = {"kick": (35, 650, .052, 18), "snare": (350, 5500, .038, 4), "hat": (2800, 6500, .012, 2)}[kind]
        return synth.noise(t, seed, low, high, step) * synth.env(t, decay, .001)
    if kind == "kick":
        x = synth.osc(t, 136, 48, .022) * synth.env(t, .065, .001)
        if style == "c": x += .32 * synth.osc(t, 75, 44, .024) * synth.env(t, .09, .002) + .2 * synth.noise(t, seed, 900, 3200) * synth.env(t, .008)
        return x
    if kind == "snare":
        x = .55 * synth.noise(t, seed, 700, 6800) * synth.env(t, .035, .001)
        x += .24 * synth.fm(t, 190, 140, 1.7, .9, .025) * synth.env(t, .034)
        if style == "c": x += .25 * synth.noise(t, seed + 1, 1800, 4200) * synth.env(t, .018, .003)
        return x
    return .55 * synth.noise(t, seed, 3000, 7200) * synth.env(t, .011, .0008)

def add_wrap(dst, x, start, pan=0.):
    start %= len(dst)
    gains = np.array([1.]) if dst.shape[1] == 1 else np.sqrt(np.array([1 - pan, 1 + pan]) / 2)
    x = x[:, None] * gains
    end = min(len(x), len(dst) - start)
    dst[start:start + end] += x[:end]
    if end < len(x): dst[:len(x) - end] += x[end:]

def render(track, style):
    s = score(track, style)
    beat = 60 / s["bpm"]
    length = round(len(s["bars"]) * 4 * beat * SR)
    channels = 1 if style == "a" else 2
    mix = np.zeros((length, channels), dtype=np.float64)
    gains = {"lead": .17 if track == "title" else .15, "bass": .20, "harmony": .072, "drums": .23 if track == "title" else .27}
    if track in EXTRA_SPECS:
        gains = {"select": dict(lead=.14, bass=.19, harmony=.07, drums=.20),
                 "story": dict(lead=.085, bass=.12, harmony=.105, drums=.10),
                 "results": dict(lead=.13, bass=.17, harmony=.095, drums=.18)}[track]
    for bar in s["bars"]:
        for part in ["lead", "bass", "harmony", "drums"]:
            for j, e in enumerate(bar[part]):
                if e["note"] == "-": continue
                if e.get("tie_from_end"): continue
                start = round(((bar["bar"] - 1) * 4 + e["beat"]) * beat * SR)
                if part == "drums":
                    x = drum(e["note"], style, 2000 + bar["bar"] * 101 + j)
                    add_wrap(mix, x * gains[part] * e["velocity"], start, -.17 if e["note"] == "hat" else 0.)
                else:
                    ns = e["note"] if isinstance(e["note"], list) else [e["note"]]
                    for k, n in enumerate(ns):
                        # Place the tied tonic near a smooth oscillator maximum at
                        # the bar line, avoiding a steep pulse edge at the loop.
                        offset = (.25 - hz(n) * (4 - e["beat"]) * beat) % 1 if e.get("tie_to_start") else 0.
                        x = pitched(n, e["duration"] * beat, part, style, offset, soft=track == "story")
                        pan = [-.4, .05, .4][k] if len(ns) > 1 else (-.12 if part == "harmony" else 0.)
                        add_wrap(mix, x * gains[part] * e["velocity"] / np.sqrt(len(ns)), start, pan)
    if style != "a":
        dry = mix.copy()
        for delay, gain in [(.023, .10), (.041, .075), (.067, .05), (.089, .035)]:
            mix += np.roll(dry[:, ::-1], round(delay * SR), axis=0) * gain
    mix -= mix.mean(axis=0)
    # Constant gain only. Preserve attacks and the circular waveform, no limiter.
    mix *= 10 ** (-18 / 20) / np.sqrt(np.mean(mix ** 2))
    assert np.max(abs(mix)) < 10 ** (-1 / 20), "Crest factor needs arrangement adjustment"
    return np.rint(mix * 32768).astype("<i2"), s

def db(v): return float(20 * np.log10(max(float(v), 1e-12)))

def measure(path, s):
    with wave.open(str(path), "rb") as w:
        channels = w.getnchannels()
        pcm = np.frombuffer(w.readframes(w.getnframes()), "<i2").reshape(-1, channels)
    x = pcm.astype(np.float64) / 32768
    n = round(.01 * SR)
    seam = np.concatenate([x[-n:], x[:n]])
    before, after = db(np.sqrt(np.mean(x[-n:] ** 2))), db(np.sqrt(np.mean(x[:n] ** 2)))
    context = np.concatenate([x[-SR // 5:], x[:SR // 5]])
    seam_rms = db(np.sqrt(np.mean(seam ** 2)))
    context_rms = db(np.sqrt(np.mean(context ** 2)))
    jump = float(np.max(abs(x[0] - x[-1])))
    local_steps = abs(np.diff(seam, axis=0))
    seam_ok = jump < .01 and abs(after - before) < 6 and seam_rms - context_rms > -12
    mono = x.mean(axis=1)
    f = np.fft.rfftfreq(len(mono), 1 / SR)
    power = abs(np.fft.rfft(mono)) ** 2
    r = dict(file=path.relative_to(ROOT).as_posix(), sound="music_" + s["track"], track=s["track"], style=s["style"],
             label=s["label"], note=EXTRA_NOTES.get(s["track"], NOTES)[s["style"]], bpm=s["bpm"], mode=s["mode"], bars=len(s["bars"]),
             sample_rate=SR, bits=16, channels=channels, length_s=len(x) / SR, bytes=path.stat().st_size,
             rms_dbfs=db(np.sqrt(np.mean(x ** 2))), peak_dbfs=db(np.max(abs(x))),
             clipped_samples=int(np.sum((pcm == 32767) | (pcm == -32768))), dc_dbfs=db(np.max(abs(x.mean(axis=0)))),
             loudness_method="Full-file RMS dBFS (per-channel energy mean), permitted LUFS fallback; LUFS not measured",
             energy_above_4khz_fraction=float(power[f >= 4000].sum() / power.sum()),
             seam=dict(pass_check=seam_ok, window_ms_each_side=10, boundary_step_fs=jump, boundary_step_dbfs=db(jump),
                       local_max_sample_step_fs=float(local_steps.max()), before_rms_dbfs=before, after_rms_dbfs=after,
                       side_level_delta_db=after - before, seam_rms_dbfs=seam_rms, surrounding_400ms_rms_dbfs=context_rms,
                       seam_vs_context_db=seam_rms - context_rms, method="Circular note releases + circular room taps; no end fade, no splice crossfade",
                       criteria="boundary step < 0.01 FS; 10ms side RMS difference < 6dB; seam RMS no lower than context -12dB"),
             sha256=hashlib.sha256(path.read_bytes()).hexdigest())
    return r, x

def picture(path, r, x):
    im = Image.new("RGB", (1400, 1020), "#0e1523")
    d = ImageDraw.Draw(im)
    fg, grid, green = "#cbd7ed", "#2e3a51", "#70d8c2"
    def txt(x, y, t, size=18, color=fg): d.text((x, y), t, font=synth.font(size), fill=color)
    txt(32, 18, path.stem + " / ORIGINAL D DORIAN", 26, "white")
    txt(32, 56, f"{r['bpm']} BPM | {r['bars']} bars | {r['length_s']:.2f}s | PCM16 {SR}Hz | {r['channels']}ch | RMS {r['rms_dbfs']:.2f} / peak {r['peak_dbfs']:.2f} dBFS")
    txt(32, 84, "Hook: D5 A5 G5 E5 F5 D5 | same melody/rhythm across styles | linear gain, no fade-out loop", 16)
    l, rr, top, bottom = 100, 1300, 140, 330
    for v in [-1, -.5, 0, .5, 1]:
        yy = (top + bottom) / 2 - v * 95
        d.line((l, yy, rr, yy), fill=grid); txt(34, yy - 9, f"{v:+.1f}", 15)
    bins = np.linspace(0, len(x), rr - l + 1).astype(int)
    for i, (a, b) in enumerate(zip(bins[:-1], bins[1:])):
        v = x[a:b]
        d.line((l + i, 235 - v.max() * 95, l + i, 235 - v.min() * 95), fill=green)
    for bar in range(r["bars"] + 1):
        xx = l + bar / r["bars"] * (rr - l)
        d.line((xx, top, xx, bottom), fill=grid)
        if bar % 2 == 0: txt(xx - 5, 335, str(bar + 1) if bar < r["bars"] else "loop", 13)
    txt(l, 115, "WAVEFORM (both channels), fixed +/-1 FS; vertical grid: bars", 16)
    nfft, hop = 2048, 512
    mono = x.mean(axis=1)
    frames = np.lib.stride_tricks.sliding_window_view(np.pad(mono, (nfft // 2, nfft // 2), mode="wrap"), nfft)[::hop]
    win = np.hanning(nfft)
    levels = 20 * np.log10(np.maximum(abs(np.fft.rfft(frames * win, axis=1)) * 2 / win.sum(), 1e-6))
    st, sb = 414, 680
    freq = np.geomspace(SR / 2, 40, sb - st)
    rows = np.clip(np.rint(freq / SR * nfft).astype(int), 0, nfft // 2)
    cols = np.rint(np.linspace(0, len(frames) - 1, rr - l)).astype(int)
    value = np.clip((levels[cols[None, :], rows[:, None]] + 80) / 80, 0, 1)
    stops = np.array([[10, 16, 30], [36, 52, 106], [104, 65, 153], [220, 97, 105], [255, 222, 144]])
    loc = value * 4; k = np.minimum(loc.astype(int), 3)
    rgb = stops[k] * (1 - (loc - k)[..., None]) + stops[k + 1] * (loc - k)[..., None]
    im.paste(Image.fromarray(rgb.astype(np.uint8)), (l, st))
    txt(l, 385, "SPECTROGRAM / mono sum / log Hz / Hann 2048, hop 512 / fixed -80..0 dBFS", 16)
    for f in [40, 100, 500, 2000, 8000, 22050]:
        yy = st + np.log((SR / 2) / f) / np.log((SR / 2) / 40) * (sb - st)
        txt(24, yy - 8, str(f), 14)
    for value, color in zip([-80, -60, -40, -20, 0], stops):
        xx = 690 + (value + 80) * 7
        d.rectangle((xx, 692, xx + 18, 704), fill=tuple(color)); txt(xx + 24, 688, str(value), 13)
    txt(l, 688, f"0 to {r['length_s']:.2f} seconds (same horizontal scale)", 14)
    seam = np.concatenate([x[-441:], x[:441]])
    txt(l, 735, "LOOP JOIN / last 10ms -> first 10ms / fixed +/-0.5 FS / L green, R violet", 16)
    mid, scale = 848, 160
    for v in [-.5, 0, .5]:
        yy = mid - v * scale
        d.line((l, yy, rr, yy), fill=grid); txt(35, yy - 8, f"{v:+.1f}", 14)
    for c in range(x.shape[1]):
        points = [(l + i / (len(seam) - 1) * (rr - l), mid - float(v) * scale) for i, v in enumerate(seam[:, c])]
        d.line(points, fill=green if c == 0 else "#bcadff", width=1)
    d.line((700, 760, 700, 935), fill="#ffc38c", width=2)
    for ms in [-10, -5, 0, 5, 10]: txt(700 + ms * 60 - 14, 932, str(ms) + "ms", 14)
    s = r["seam"]
    txt(32, 967, f"JOIN {'PASS' if s['pass_check'] else 'FAIL'} | step {s['boundary_step_fs']:.6f} FS | sides {s['side_level_delta_db']:+.2f}dB | seam/context {s['seam_vs_context_db']:+.2f}dB", 18)
    txt(32, 995, "Numerical/visual review only: listening and game SFX mix approval remain with the user.", 14)
    im.save(path)

def score_text(s):
    lines = [f"{s['track']} / {s['style'].upper()} / {s['label']}", f"{s['bpm']} BPM | 4/4 | {s['mode']} | {len(s['bars'])} bars", f"Shared six-note hook: {MOTIF}",
             "Notation: beat (0-based quarter notes):note:duration-in-beats@velocity; '-' is a rest.",
             "Drum durations describe score articulation; synthesis one-shot release lengths are fixed in music.py.",
             "Harmony: A monophonic pulse 2 arpeggio; B/C short chord pad. Rendered releases may cross bar/loop.", ""]
    for b in s["bars"]:
        lines.append(f"BAR {b['bar']:02d} | {b['chord']}")
        for part in ["lead", "bass", "harmony", "drums"]:
            values = []
            for e in b[part]:
                note = '+'.join(e['note']) if isinstance(e['note'], list) else e['note']
                tie = "~FROM-END" if e.get("tie_from_end") else ("~TO-START" if e.get("tie_to_start") else "")
                values.append(f"{e['beat']:g}:{note}:{e['duration']:g}@{e['velocity']:g}{tie}")
            lines.append(f"  {part:8s} " + "  ".join(values))
    return '\n'.join(lines) + '\n'

def main(plots_only=False, collection="aud02"):
    specs, report = COLLECTIONS[collection]
    OUT.mkdir(exist_ok=True, parents=True); report.mkdir(exist_ok=True, parents=True)
    records = []
    for track in specs:
        for style in "abc":
            name = f"music_{track}-{style}"
            path = OUT / (name + ".wav")
            s = score(track, style)
            if not plots_only:
                pcm, s = render(track, style)
                with wave.open(str(path), "wb") as w:
                    w.setparams((pcm.shape[1], 2, SR, 0, "NONE", "not compressed")); w.writeframes(pcm.tobytes())
            r, x = measure(path, s); records.append(r)
            (report / (name + "-score.txt")).write_text(score_text(s), encoding="utf-8")
            (report / (name + "-score.json")).write_text(json.dumps(s, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
            picture(report / (name + ".png"), r, x)
            print(f"{name}: {r['length_s']:.2f}s RMS {r['rms_dbfs']:.2f} peak {r['peak_dbfs']:.2f}, seam={r['seam']}", flush=True)
    (report / "measurements.json").write_text(json.dumps(dict(motif=MOTIF, records=records), ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
    sheet = Image.new("RGB", (2100, 510 * len(specs)), "#0e1523")
    for i, r in enumerate(records):
        with Image.open(report / (Path(r["file"]).stem + ".png")) as pic:
            sheet.paste(pic.resize((700, 510), Image.Resampling.LANCZOS), ((i % 3) * 700, (i // 3) * 510))
    sheet.save(report / "overview.png")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--plots-only", action="store_true", help="Read existing WAVs; refresh measurement/score/figure documents without rendering audio")
    parser.add_argument("--collection", choices=COLLECTIONS, default="aud02", help="Default writes only new AUD-02 candidates; aud02a explicitly regenerates the legacy trial")
    args = parser.parse_args()
    main(args.plots_only, args.collection)
