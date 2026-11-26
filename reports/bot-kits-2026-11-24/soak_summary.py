"""Summarise SOAK_RESULT lines: python soak_summary.py <dir or file> [label]"""
import json, os, re, statistics, sys
from collections import defaultdict
src = sys.argv[1]
files = [os.path.join(src, f) for f in sorted(os.listdir(src)) if f.endswith(".txt")] if os.path.isdir(src) else [src]
rows = []
for f in files:
    for line in open(f, encoding="utf-8", errors="ignore"):
        if "SOAK_RESULT" not in line: continue
        seed = line.split()[1]
        d = json.loads(line[line.index("{"):])
        d["seed"] = seed
        rows.append(d)
rows.sort(key=lambda d: d["seed"])
L = [d["seconds_simulated"] for d in rows]
def alive(d, t):
    times = [float(re.search(r"t=(\d+)", e).group(1)) for e in d["eliminations"]]
    return d["players"] - sum(1 for x in times if x <= t)
print("seed  len  winner ringouts pvp alive@210/240")
for d in rows:
    print(f"{d['seed']} {d['seconds_simulated']:6.1f} {d['winner']:5s} {d['ringouts']:3d} {d['pvp_hits']:4d}  {alive(d,210)}/{alive(d,240)}")
print(f"length median {statistics.median(L):.0f} (min {min(L):.0f}, max {max(L):.0f}); ringouts total {sum(d['ringouts'] for d in rows)}; pvp hits {sum(d['pvp_hits'] for d in rows)}")
# average placement
place = defaultdict(list)
for d in rows:
    order = [e.split()[0] for e in d["eliminations"]]
    n = len(order) + 1
    for i, name in enumerate(order): place[name].append(n - i)
    place[d["winner"]].append(1)
print("avg place:", {k: round(sum(v)/len(v), 1) for k, v in sorted(place.items())}, "wins:", {k: sum(1 for x in v if x == 1) for k, v in sorted(place.items())})
# moves per seat
tot = defaultdict(lambda: defaultdict(float))
for d in rows:
    for cid, m in d.get("moves", {}).items():
        for k, v in m.items(): tot[cid][k] += v
keys = ["damage", "j", "k", "k2", "l", "l2", "u", "u2", "i", "i2", "wings", "wing_hits", "u_hits", "flight", "back_hits", "beam_ticks", "decoy_burst", "seal_torn", "talisman_stopped", "talisman_burst_on_platform"]
print("moves per seat (8 matches):")
print("char  seats " + " ".join(f"{k[:9]:>9s}" if len(k) > 6 else f"{k:>6s}" for k in keys))
for cid in sorted(tot):
    seats = tot[cid]["seats"]
    print(f"{cid:5s} {int(seats):5d} " + " ".join((f"{tot[cid].get(k, 0)/seats:9.1f}" if len(k) > 6 else f"{tot[cid].get(k, 0)/seats:6.1f}") for k in keys))
