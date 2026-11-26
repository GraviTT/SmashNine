"""Brave Luna's star beam, per variant: python beam_summary.py <dir>

<dir> holds one file per run, "<variant>-<seed>.txt": the output of
tests/analysis/lead/luna_beam_probe.gd (LUNA_BEAM lines and one SOAK_RESULT line).
Prints one block per variant, a per-seed table, each character's credited ring-outs and
knock-outs, and what the recorded hits of the "current" variant would come to under other
beam numbers (arithmetic on the recorded hits, not replayed matches).
"""
import json, os, re, statistics, sys
from collections import defaultdict

TICK = 2.2      # Luna.BEAM_TICK_DAMAGE
FINAL = 14.0    # Luna.BEAM_FINAL_DAMAGE
BEAM_TIME = 3.0
TICK_TIME = 0.15  # Luna.BEAM_TICK
FLOOR = 1.0     # PlayerBase._calculate_incoming_damage: no hit does less

src = sys.argv[1]
runs = defaultdict(dict)   # variant -> seed -> {"result": {...}, "beams": [...]}
for name in sorted(os.listdir(src)):
    m = re.fullmatch(r"([a-z0-9]+)-(\d+)\.txt", name)
    if not m:
        continue
    variant, seed = m.group(1), int(m.group(2))
    run = {"result": None, "beams": []}
    for line in open(os.path.join(src, name), encoding="utf-8", errors="ignore"):
        if line.startswith("LUNA_BEAM "):
            run["beams"].append(json.loads(line[len("LUNA_BEAM "):]))
        elif line.startswith("SOAK_RESULT "):
            run["result"] = json.loads(line[len("SOAK_RESULT "):])
    if run["result"] is None:
        print(f"!! {name}: no SOAK_RESULT line")
        continue
    runs[variant][seed] = run


def placements(result):
    order = [e.split()[0] for e in result["eliminations"]]
    n = len(order) + 1
    out = [(name, n - i) for i, name in enumerate(order)]
    out.append((result["winner"], 1))
    return out


def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0


def direct(beam):
    return beam["tick_damage"] + beam["final_damage"]


def ring(beam):
    return sum(r[2] for r in beam["ringouts"])


def block(variant):
    seeds = sorted(runs[variant])
    results = [runs[variant][s]["result"] for s in seeds]
    beams = [b for s in seeds for b in runs[variant][s]["beams"]]
    fired = [b for b in beams if b["fired"]]
    hit = [b for b in fired if b["ticks"] + b["finals"] > 0]
    seats = sum(r["luna"]["seats"] for r in results)
    luna_matches = sum(1 for r in results if r["luna"]["seats"] > 0)
    forms = sum(r["luna"]["forms"] for r in results)
    no_beam = sum(r["luna"]["forms_without_beam"] for r in results)
    lengths = [r["seconds_simulated"] for r in results]
    places = [p for r in results for name, p in placements(r) if name == "Luna"]
    wins = sum(1 for p in places if p == 1)
    luna_damage = sum(r["moves"].get("luna", {}).get("damage", 0.0) for r in results)
    beam_damage = sum(direct(b) for b in fired)
    ticks = [b["ticks"] for b in fired]
    print(f"== {variant}: {len(seeds)} matches (seeds {seeds[0]}-{seeds[-1]}), {luna_matches} with Luna, {seats} Luna seats")
    print(f"   match length median {statistics.median(lengths):.0f} s (min {min(lengths):.0f}, max {max(lengths):.0f}); ring-outs {sum(r['ringouts'] for r in results)}")
    print(f"   Luna: average place {mean(places):.2f} over {len(places)} seats ({sorted(places)}), wins {wins}; damage dealt per seat {luna_damage / max(seats, 1):.0f}")
    print(f"   forms {forms} ({forms / max(seats, 1):.1f} per seat); beams pressed {len(beams)}, fired {len(fired)}, forms that ended with no beam {no_beam}")
    if not fired:
        return
    print(f"   beams that hit a fighter: {len(hit)} of {len(fired)} ({100 * len(hit) / len(fired):.0f}%)")
    print(f"   ticks per beam: mean {mean(ticks):.1f}, median {statistics.median(ticks):.0f} (beams that hit: mean {mean([b['ticks'] for b in hit]):.1f}); last blast hits per beam {mean([b['finals'] for b in fired]):.2f}")
    tick_amounts = [h[3] for b in fired for h in b["hits"] if h[2] == "t"]
    final_amounts = [h[3] for b in fired for h in b["hits"] if h[2] == "f"]
    if tick_amounts:
        at_floor = sum(1 for a in tick_amounts if a <= FLOOR + 1e-6)
        print(f"   one tick took {mean(tick_amounts):.2f} HP on average ({at_floor} of {len(tick_amounts)} ticks at the 1.0 floor, largest {max(tick_amounts):.2f}); one last blast {mean(final_amounts) if final_amounts else 0:.2f} HP")
    held = []
    for b in hit:
        per_victim = defaultdict(int)
        for h in b["hits"]:
            if h[2] == "t":
                per_victim[h[1]] += 1
        if per_victim:
            held.append(max(per_victim.values()) * TICK_TIME)
    if held:
        print(f"   the fighter a beam held longest: {mean(held):.1f} s on average, median {statistics.median(held):.1f} s, 2.85 s or more in {sum(1 for x in held if x >= 2.85)} of {len(held)} beams that hit")
    print(f"   HP taken by the beam itself: {beam_damage / len(fired):.1f} per beam (beams that hit: {beam_damage / max(len(hit), 1):.1f}); per seat per match {beam_damage / max(seats, 1):.0f} = {100 * beam_damage / max(luna_damage, 1):.0f}% of her damage")
    rings = [r for b in fired for r in b["ringouts"]]
    after_final = [r for r in rings if r[3] == "f"]
    with_ring = sum(1 for b in fired if b["ringouts"])
    blasted = sum(1 for b in fired if b["finals"] > 0)
    print(f"   ring-outs within 3 s of a beam hit, credited to her: {len(rings)} ({len(after_final)} after the last blast, {len(rings) - len(after_final)} after ticks only), {sum(r[2] for r in rings):.0f} HP; beams followed by one: {with_ring} of {len(fired)} ({100 * with_ring / len(fired):.0f}%); beams whose last blast hit: {blasted}")
    if rings:
        print(f"   those ring-outs came {statistics.median([r[1] for r in rings]):.1f} s after the beam's last hit (median; max {max(r[1] for r in rings):.1f} s); mean {mean([r[2] for r in rings]):.1f} HP each")
    credited = sum(r["luna"]["ringouts_credited"] for r in results)
    print(f"   all ring-outs credited to Luna: {credited} ({credited / max(seats, 1):.1f} per seat); the beam's share {100 * len(rings) / max(credited, 1):.0f}%")
    print(f"   a beam is worth (its own HP + the ring-out's HP): {(beam_damage + sum(r[2] for r in rings)) / len(fired):.1f} per beam, {(beam_damage + sum(r[2] for r in rings)) / max(seats, 1):.0f} per seat per match")
    buckets = [(0, 0), (1, 5), (6, 10), (11, 15), (16, 20), (21, 99)]
    print("   beams by ticks: " + ", ".join(f"{lo}-{hi}: {sum(1 for t in ticks if lo <= t <= hi)}" if lo != hi else f"{lo}: {sum(1 for t in ticks if t == lo)}" for lo, hi in buckets))
    into = [b["into"] for b in beams]
    print(f"   pressed {statistics.median(into):.1f} s into the form (median; min {min(into):.1f}, max {max(into):.1f})")
    other = sum(b["other_hits"] for b in beams)
    counted = sum(r["moves"].get("luna", {}).get("beam_ticks", 0) for r in results)
    print(f"   check: ticks recorded {sum(b['ticks'] for b in beams)} vs the game's own count {counted:.0f}; hits by her during a beam that were not the beam: {other}")


for variant in sorted(runs):
    block(variant)

# Each character's credited ring-outs and knock-outs per seat.
print("\ncredited per seat (ring-outs / knock-outs), by variant:")
for variant in sorted(runs):
    seats, rings, kos = defaultdict(int), defaultdict(int), defaultdict(int)
    for run in runs[variant].values():
        r = run["result"]
        for cid, moves in r["moves"].items():
            seats[cid] += moves["seats"]
        for cid, n in r.get("ringouts_by", {}).items():
            rings[cid] += n
        for cid, n in r.get("kos_by", {}).items():
            kos[cid] += n
    print(f"   {variant:8s} " + "  ".join(f"{cid} {rings[cid] / seats[cid]:.2f}/{kos[cid] / seats[cid]:.2f} ({seats[cid]})" for cid in sorted(seats)))

# Per-seed side by side.
if "current" in runs and "fixed" in runs:
    print("\nseed | fixed: len winner Luna-places beams ticks own-HP ring-outs | current: the same")
    for seed in sorted(set(runs["current"]) & set(runs["fixed"])):
        cells = []
        for variant in ("fixed", "current"):
            run = runs[variant][seed]
            r = run["result"]
            fired = [b for b in run["beams"] if b["fired"]]
            places = [p for name, p in placements(r) if name == "Luna"]
            cells.append(f"{r['seconds_simulated']:5.0f} {r['winner']:5s} {str(places):8s} {len(fired):2d} {sum(b['ticks'] for b in fired):3d} {sum(direct(b) for b in fired):5.0f} {sum(len(b['ringouts']) for b in fired):2d}")
        print(f"{seed} | {cells[0]} | {cells[1]}")

# What the recorded hits of the current rule come to under other numbers.
if "current" in runs:
    fired = [b for s in runs["current"] for b in runs["current"][s]["beams"] if b["fired"]]
    hit = [b for b in fired if b["ticks"] + b["finals"] > 0]

    def projected(beam, tick, time, final):
        """HP one recorded beam takes with another tick damage, last blast or a shorter beam.

        Each recorded hit keeps the share a guard took off it: recorded / what the hit would
        take unguarded at the game's numbers."""
        total = 0.0
        late = {}
        for at, victim, kind, amount, multiplier in beam["hits"]:
            if kind == "t":
                guard = amount / max(TICK * multiplier, FLOOR)
                if at <= time + 1e-6:
                    total += max(tick * multiplier, FLOOR) * guard
                    if at > time - 0.2:
                        late[victim] = multiplier
            elif kind == "f" and time >= BEAM_TIME:
                guard = amount / max(FINAL * multiplier, FLOOR)
                total += max(final * multiplier, FLOOR) * guard
        if time < BEAM_TIME:
            # The last blast reaches whoever the beam still held just before it ends.
            total += sum(max(final * multiplier, FLOOR) for multiplier in late.values())
        return total

    print("\nprojection from the current rule's recorded beams (HP per beam that hit / per fired beam; ring-outs not included):")
    for label, tick, time, final in [
            ("as it is: tick 2.2, 3.0 s, blast 14", 2.2, 3.0, 14.0), ("tick 1.5", 1.5, 3.0, 14.0), ("tick 1.0", 1.0, 3.0, 14.0),
            ("2.5 s", 2.2, 2.5, 14.0), ("2.0 s", 2.2, 2.0, 14.0), ("1.5 s", 2.2, 1.5, 14.0),
            ("blast 10", 2.2, 3.0, 10.0), ("blast 7", 2.2, 3.0, 7.0)]:
        values = [projected(b, tick, time, final) for b in fired]
        values_hit = [projected(b, tick, time, final) for b in hit]
        print(f"   {label:36s} {mean(values_hit):5.1f} / {mean(values):5.1f}   (largest {max(values):.0f})")
    check = [abs(projected(b, TICK, BEAM_TIME, FINAL) - direct(b)) for b in fired]
    print(f"   check: the 'as it is' line against the recorded HP, largest difference per beam {max(check):.2f}")
