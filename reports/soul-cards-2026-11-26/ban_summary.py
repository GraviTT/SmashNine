"""Card ablation: python ban_summary.py <label>=<file or dir> [<label>=<file or dir> ...]

Each source is a file of "seed N SOAK_RESULT {...}" lines or a directory of probe outputs
(tests/analysis/lead/card_ban_probe.gd, one match a file). Prints one row per character and source:
average place (wins) and damage per seat, over the seeds every source has.
"""
import json, os, re, statistics, sys
from collections import defaultdict


def load(src):
    rows = {}
    if os.path.isdir(src):
        for name in sorted(os.listdir(src)):
            m = re.search(r"(\d{4})\.txt$", name)
            if not m:
                continue
            for line in open(os.path.join(src, name), encoding="utf-8", errors="ignore"):
                if line.startswith("SOAK_RESULT"):
                    rows[m.group(1)] = json.loads(line[line.index("{"):])
    else:
        for line in open(src, encoding="utf-8", errors="ignore"):
            if "SOAK_RESULT" in line:
                rows[line.split()[1]] = json.loads(line[line.index("{"):])
    return rows


sources = []
for arg in sys.argv[1:]:
    label, path = arg.split("=", 1)
    sources.append((label, load(path)))
seeds = sorted(set.intersection(*[set(rows) for _, rows in sources]))
print(f"{len(seeds)} matches in every source ({seeds[0]}-{seeds[-1]})")
names = ["Frey", "Luna", "Nova", "Rio", "Xion", "Yuki"]
table = {}
for label, rows in sources:
    place = defaultdict(list)
    tot = defaultdict(lambda: defaultdict(float))
    L = []
    ringouts = 0
    for seed in seeds:
        d = rows[seed]
        L.append(d["seconds_simulated"])
        ringouts += d["ringouts"]
        order = [e.split()[0] for e in d["eliminations"]]
        for i, name in enumerate(order):
            place[name].append(len(order) + 1 - i)
        place[d["winner"]].append(1)
        for cid, m in d["moves"].items():
            for k, v in m.items():
                tot[cid][k] += v
    table[label] = {n: (statistics.mean(place[n]), sum(1 for x in place[n] if x == 1), tot[n.lower()]["damage"] / (tot[n.lower()]["seats"] or 1)) for n in names}
    print(f"{label:14s} length median {statistics.median(L):.0f} s, ring-outs {ringouts}")
print("place (wins) damage per seat")
print(" " * 6 + "".join(f"{label:>22s}" for label, _ in sources))
for n in names:
    print(f"{n:6s}" + "".join(f"{table[label][n][0]:10.2f} ({table[label][n][1]:2d}) {table[label][n][2]:6.1f}" for label, _ in sources))
