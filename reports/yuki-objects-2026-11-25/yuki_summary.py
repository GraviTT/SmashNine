"""Yuki before and after: python yuki_summary.py <before file or dir> <after file or dir>

Reads SOAK_RESULT lines (one per match, "seed N SOAK_RESULT {...}" in a file, or one match per
.txt file in a directory) and prints, for each side: the matches, every character's average place
and wins, and Yuki's own numbers per seat. Then, seed by seed, Yuki's damage per seat on both sides.
"""
import json, os, re, statistics, sys
from collections import defaultdict


def load(src):
    rows = []
    files = [os.path.join(src, f) for f in sorted(os.listdir(src)) if f.endswith(".txt")] if os.path.isdir(src) else [src]
    for path in files:
        for line in open(path, encoding="utf-8", errors="ignore"):
            if "SOAK_RESULT" not in line:
                continue
            d = json.loads(line[line.index("{"):])
            head = line[:line.index("SOAK_RESULT")].split()
            seed = head[1] if len(head) >= 2 else re.search(r"(\d{4})", os.path.basename(path)).group(1)
            d["seed"] = seed
            rows.append(d)
    rows.sort(key=lambda d: d["seed"])
    return rows


def places(d):
    """[(name, place, damage dealt or None for the winner)] for the eight seats of one match."""
    out = []
    order = d["eliminations"]
    n = len(order) + 1
    for i, e in enumerate(order):
        name = e.split()[0]
        dmg = float(re.search(r"dmg_dealt=(\d+)", e).group(1))
        out.append((name, n - i, dmg))
    out.append((d["winner"], 1, None))
    return out


def side(rows, label):
    L = [d["seconds_simulated"] for d in rows]
    print(f"== {label}: {len(rows)} matches")
    print(f"length median {statistics.median(L):.0f} s (min {min(L):.0f}, max {max(L):.0f}); ring-outs {sum(d['ringouts'] for d in rows)}; hits between fighters {sum(d['pvp_hits'] for d in rows)}")
    place = defaultdict(list)
    for d in rows:
        for name, p, _ in places(d):
            place[name].append(p)
    print("average place (wins, seats): " + ", ".join(f"{k} {sum(v)/len(v):.1f} ({sum(1 for x in v if x == 1)}, {len(v)})" for k, v in sorted(place.items())))
    tot = defaultdict(float)
    for d in rows:
        for k, v in d.get("moves", {}).get("yuki", {}).items():
            tot[k] += v
    seats = tot["seats"]
    if seats:
        keys = ["damage", "j", "k", "l", "i", "seal_torn", "talisman_stopped", "talisman_burst_on_platform"]
        print(f"Yuki, {int(seats)} seats, per seat per match: " + ", ".join(f"{k} {tot.get(k, 0.0)/seats:.1f}" for k in keys))
        if tot.get("k"):
            print(f"  seals torn of seals placed: {tot.get('seal_torn', 0.0):.0f} of {tot['k']:.0f} ({100.0 * tot.get('seal_torn', 0.0) / tot['k']:.0f}%)")
        if tot.get("j"):
            met = tot.get("talisman_stopped", 0.0) + tot.get("talisman_burst_on_platform", 0.0)
            print(f"  talismans that met a platform of J presses: {met:.0f} of {tot['j']:.0f} ({100.0 * met / tot['j']:.0f}%)")
    return place, tot


def yuki_by_seed(rows):
    out = {}
    for d in rows:
        m = d.get("moves", {}).get("yuki")
        if m:
            out[d["seed"]] = (m["damage"] / m["seats"], [p for name, p, _ in places(d) if name == "Yuki"])
    return out


before = load(sys.argv[1])
after = load(sys.argv[2])
side(before, "before")
side(after, "after")
b = yuki_by_seed(before)
a = yuki_by_seed(after)
print("== Yuki seed by seed: damage per seat (places), before -> after")
up = down = 0
for seed in sorted(set(b) & set(a)):
    diff = a[seed][0] - b[seed][0]
    up += diff > 0
    down += diff < 0
    print(f"{seed}  {b[seed][0]:6.1f} {b[seed][1]} -> {a[seed][0]:6.1f} {a[seed][1]}  {diff:+.1f}")
print(f"matches with Yuki: {len(set(b) & set(a))}; damage per seat up in {up}, down in {down}")
