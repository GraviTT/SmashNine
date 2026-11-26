"""Soul cards before and after: python cards_summary.py <before file> <after file> [first N seeds]

Reads SOAK_RESULT lines ("seed N SOAK_RESULT {...}", one match a line) and prints the matches, every
character's place, wins and damage, and for the side with cards: which cards the bots took and how
often each card's effect came (PlayerBase.move_counts: card_<id>, air_dash, meteor, riposte,
soul_drain, last_flame, chaser, twin_stars). With a third argument only the first N seeds are read.
"""
import json, re, statistics, sys
from collections import defaultdict

CARDS = [
    ("power", "stat"), ("vitality", "stat"), ("swiftness", "stat"), ("anchor", "stat"), ("last_stand", "stat"),
    ("sky_step", "action"), ("air_dash", "action"), ("meteor_landing", "action"), ("riposte", "action"),
    ("soul_drain", "action"), ("last_flame", "action"), ("chaser", "action"), ("hunter", "action"), ("overcharge", "action"),
    ("second_wingbeat", "character"), ("twin_stars", "character"), ("deep_gravity", "character"),
    ("second_decoy", "character"), ("extended_magazine", "character"),
]
OWN = {"frey": "second_wingbeat", "luna": "twin_stars", "nova": "deep_gravity", "rio": "second_decoy", "xion": "extended_magazine"}
EFFECTS = [("air_dash", "air_dash"), ("meteor_landing", "meteor"), ("riposte", "riposte"), ("soul_drain", "soul_drain"),
           ("last_flame", "last_flame"), ("chaser", "chaser"), ("twin_stars", "twin_stars")]


def load(path, limit=None):
    rows = []
    for line in open(path, encoding="utf-8", errors="ignore"):
        if "SOAK_RESULT" not in line:
            continue
        d = json.loads(line[line.index("{"):])
        d["seed"] = line.split()[1]
        rows.append(d)
    rows.sort(key=lambda d: d["seed"])
    return rows[:limit] if limit else rows


def places(d):
    order = [e.split()[0] for e in d["eliminations"]]
    out = [(name, len(order) + 1 - i) for i, name in enumerate(order)]
    out.append((d["winner"], 1))
    return out


def totals(rows):
    tot = defaultdict(lambda: defaultdict(float))
    for d in rows:
        for cid, m in d.get("moves", {}).items():
            for k, v in m.items():
                tot[cid][k] += v
    return tot


def side(rows, label):
    L = [d["seconds_simulated"] for d in rows]
    causes = defaultdict(int)
    for d in rows:
        for k, v in d["defeats_by_cause"].items():
            causes[k] += v
    picks = []
    for d in rows:
        picks += [int(s.split("/")[1]) for s in d["souls"]]
    print(f"== {label}: {len(rows)} matches")
    print(f"length median {statistics.median(L):.0f} s (min {min(L):.0f}, max {max(L):.0f}); ring-outs {sum(d['ringouts'] for d in rows)}; hits between fighters {sum(d['pvp_hits'] for d in rows)}; monster hits {sum(d['monster_hits'] for d in rows)}")
    print(f"defeats by cause {dict(sorted(causes.items()))}; cards taken per seat {statistics.mean(picks):.2f} (seats with 3: {sum(1 for p in picks if p == 3)} of {len(picks)})")
    place = defaultdict(list)
    for d in rows:
        for name, p in places(d):
            place[name].append(p)
    tot = totals(rows)
    print("character: place (wins, seats), damage per seat, ultimates per seat")
    for name in sorted(place):
        v = place[name]
        t = tot[name.lower()]
        seats = t["seats"] or 1
        print(f"  {name:5s} {sum(v)/len(v):.2f} ({sum(1 for x in v if x == 1)}, {len(v)})  damage {t['damage']/seats:6.1f}  ult {t['i']/seats:.1f}")
    return tot


limit = int(sys.argv[3]) if len(sys.argv) > 3 else None
before = load(sys.argv[1], limit)
after = load(sys.argv[2], limit)
side(before, "before")
tot = side(after, "after")

taken = {card: sum(t.get("card_" + card, 0.0) for t in tot.values()) for card, _ in CARDS}
all_taken = sum(taken.values())
seats = sum(t["seats"] for t in tot.values())
if all_taken:
    print(f"== cards taken (after): {all_taken:.0f} by {seats:.0f} seats")
    by_kind = defaultdict(float)
    for card, kind in CARDS:
        by_kind[kind] += taken[card]
    print("by kind: " + ", ".join(f"{k} {v:.0f} ({100 * v / all_taken:.0f}%)" for k, v in by_kind.items()))
    for card, kind in CARDS:
        print(f"  {card:18s} {kind:9s} {taken[card]:4.0f}  ({100 * taken[card] / all_taken:4.1f}% of picks)")
    print("== own cards: taken by seats of that fighter")
    for cid, card in OWN.items():
        t = tot[cid]
        print(f"  {cid:5s} {card:18s} {t.get('card_' + card, 0.0):.0f} of {t['seats']:.0f} seats")
    print("== effects (after): times in all matches, and per fighter that took the card")
    for card, key in EFFECTS:
        times = sum(t.get(key, 0.0) for t in tot.values())
        holders = taken[card]
        print(f"  {card:18s} {times:5.0f}" + (f"  ({times / holders:.1f} per holder)" if holders else "  (nobody took it)"))
    wings = tot["frey"]
    print(f"  frey wings per seat {wings.get('wings', 0.0) / (wings['seats'] or 1):.1f}; rio swaps per seat {tot['rio'].get('u2', 0.0) / (tot['rio']['seats'] or 1):.1f}; nova fields per seat {tot['nova'].get('l', 0.0) / (tot['nova']['seats'] or 1):.1f}; xion shots per seat {tot['xion'].get('j', 0.0) / (tot['xion']['seats'] or 1):.1f}")
