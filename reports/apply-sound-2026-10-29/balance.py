"""Sound apply (10-29): rough loudness balance of effects against music at the default settings.

usage: python -I balance.py <repo root> [<capture dir>]
File levels come from manifest.json (the picked WAVs). The game applies the bus faders of
AudioSettings.DEFAULTS: SFX 80 % and Music 60 % (linear_to_db), Master 80 % on both, so Master
does not change the balance. Effects are compared by their loudest 50 ms RMS, music by its
whole-file RMS: "margin" is how far an effect's loudest moment sits above the music bed.
With a capture dir (tests/analysis/lead/sound_apply_capture.gd output) the same numbers are
read back from the game's own mixer. Writes balance.json next to this file.
"""
import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def fader_db(percent):
    return round(20.0 * math.log10(percent / 100.0), 2)


def main():
    repo = sys.argv[1]
    capture_dir = sys.argv[2] if len(sys.argv) > 2 else ""
    settings = open(os.path.join(repo, "smash-nine-prototype/scripts/audio/AudioSettings.gd"), encoding="utf-8").read()
    defaults = {k: int(v) for k, v in re.findall(r'"(master|music|effects)": (\d+)', settings.split("DEFAULTS", 1)[1].split("\n", 1)[0])}
    catalog = open(os.path.join(repo, "smash-nine-prototype/scripts/audio/AudioCatalog.gd"), encoding="utf-8").read()
    groups = dict(re.findall(r'^\t"([a-z0-9_]+)": \{.*"group": "([^"]+)"', catalog, re.M))
    manifest = json.load(open(os.path.join(HERE, "manifest.json"), encoding="utf-8"))
    sfx_bus, music_bus = fader_db(defaults["effects"]), fader_db(defaults["music"])
    music = {s["id"]: s["wav_levels"]["rms_dbfs"] + music_bus for s in manifest["sounds"] if s["folder"] == "music"}
    bed = sum(music.values()) / len(music)
    rows = {}
    for s in manifest["sounds"]:
        if s["folder"] == "music":
            continue
        level = s["wav_levels"]["max_50ms_rms_dbfs"] + sfx_bus
        rows[s["id"]] = {"group": groups[s["id"]], "file_max_50ms_rms_dbfs": s["wav_levels"]["max_50ms_rms_dbfs"],
                         "file_peak_dbfs": s["wav_levels"]["peak_dbfs"], "in_game_max_50ms_dbfs": round(level, 2),
                         "margin_over_music_db": round(level - bed, 2)}
    by_group = {}
    for sound, row in rows.items():
        by_group.setdefault(row["group"], []).append(row["margin_over_music_db"])
    result = {
        "defaults": defaults, "fader_db": {"sfx": sfx_bus, "music": music_bus, "master": fader_db(defaults["master"])},
        "music_in_game_rms_dbfs": {k: round(v, 2) for k, v in music.items()}, "music_bed_mean_dbfs": round(bed, 2),
        "groups": {g: {"min": min(v), "max": max(v), "count": len(v)} for g, v in sorted(by_group.items())},
        "sounds": rows,
    }
    if capture_dir:
        capture = json.load(open(os.path.join(capture_dir, "capture.json"), encoding="utf-8"))
        cap_bed = sum(m["rms_dbfs"] for m in capture["music"].values()) / len(capture["music"])
        result["capture"] = {
            "music_rms_dbfs": {k: v["rms_dbfs"] for k, v in capture["music"].items()}, "music_bed_mean_dbfs": round(cap_bed, 2),
            "sfx_margin_over_music_db": {k: round(v["max_50ms_rms_dbfs"] - cap_bed, 2) for k, v in capture["sfx"].items()},
            "match": {k: capture["match"][k] for k in ("rms_dbfs", "peak_dbfs", "max_50ms_rms_dbfs")},
        }
        diffs = [result["capture"]["sfx_margin_over_music_db"][k] - rows[k]["margin_over_music_db"] for k in rows]
        result["capture"]["margin_capture_minus_files_db"] = {"min": round(min(diffs), 2), "max": round(max(diffs), 2)}
    with open(os.path.join(HERE, "balance.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print("faders", result["fader_db"], "music bed", result["music_bed_mean_dbfs"], result["music_in_game_rms_dbfs"])
    for group, span in result["groups"].items():
        print(f"{group:12s} margin {span['min']:+6.1f} .. {span['max']:+6.1f} dB ({span['count']})")
    if capture_dir:
        print("capture bed", result["capture"]["music_bed_mean_dbfs"], "margin capture-files", result["capture"]["margin_capture_minus_files_db"], "match", result["capture"]["match"])


if __name__ == "__main__":
    main()
