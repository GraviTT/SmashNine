"""Apply the 2026-10-29 candidate picks to the game's art.

usage: python apply_picks.py <repo root> <picks-snapshot.json> [<overrides.json>]

The snapshot is the comparison viewer's `candidate_picks` collection read once at the start
(222 rows, every one picked). Rows whose choice is "none" keep the game's picture.
overrides.json maps a snapshot doc id to the candidate file that replaces its pick (the user's
2026-10-29 size match: monster windup/defeat rows rebuilt at the kept pictures' size, ART-93).
Writes reports/apply-2026-10-29/applied.json (every file written, with hashes and checks).
"""
import hashlib
import json
import math
import os
import re
import shutil
import sys

from PIL import Image

ROOT = os.path.abspath(sys.argv[1])
SNAP = json.load(open(sys.argv[2], encoding="utf-8"))
OVERRIDES = json.load(open(sys.argv[3], encoding="utf-8"))["rows"] if len(sys.argv) > 3 else {}
GAME = os.path.join(ROOT, "smash-nine-prototype")
ART = os.path.join(GAME, "assets", "art")
TODAY = "2026-10-29"

# Strips the fighter loader reads beside the main sheet (PlayerBase.OPTIONAL_MOTION_ROWS; defeat is
# added by this change): frames and cell size.
STRIP_ROWS = {"jump": (3, 128), "fall": (2, 128), "hurt": (3, 128), "land": (2, 128), "victory": (6, 192), "defeat": (6, 192)}
# Rows that live inside a sheet: (character script, table constant, sheet file).
SHEET_REPAIRS = {
    ("frey", "attack"): ("characters/frey/Frey.gd", "SHEET_ROWS", "frey/frey_sheet.png"),
    ("rio_male", "walk"): ("characters/rio/Rio.gd", "SHEET_ROWS", "rio/rio_male_sheet.png"),
    ("rio_female", "walk"): ("characters/rio/Rio.gd", "SHEET_ROWS", "rio/rio_female_sheet.png"),
    ("rio_female", "mana_combo"): ("characters/rio/Rio.gd", "MOVE_SHEET_ROWS", "rio/rio_female_moves_sheet.png"),
}
MONSTER_CELL = 96

applied, notes = [], []


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def folder_of(stem):
    return stem.split("_")[0]


def src_path(rel):
    path = os.path.join(ROOT, rel)
    if not os.path.isfile(path):
        sys.exit(f"missing candidate: {rel}")
    return path


def copy(doc, src_rel, dst_rel, size=None):
    src, dst = src_path(src_rel), os.path.join(ART, dst_rel)
    if size is not None:
        got = Image.open(src).size
        if got != size:
            sys.exit(f"{doc}: {src_rel} is {got}, expected {size}")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    existed = os.path.exists(dst)
    before = sha(dst) if existed else None
    shutil.copyfile(src, dst)
    applied.append({"doc": doc, "from": src_rel, "to": f"smash-nine-prototype/assets/art/{dst_rel}", "replaced": existed,
                    "before_sha256": before, "sha256": sha(dst)})
    mark_adopted(src_rel)


def exact_strip(doc, src_rel, frames, cell):
    """Candidates are drawn on a six-cell canvas; the game wants exactly frames x cell.
    Cells past the last frame must be empty."""
    img = Image.open(src_path(src_rel)).convert("RGBA")
    if img.height != cell or img.width % cell or img.width // cell < frames:
        sys.exit(f"{doc}: {src_rel} is {img.size}, cannot hold {frames} x {cell}")
    for i in range(frames, img.width // cell):
        if img.crop((i * cell, 0, (i + 1) * cell, cell)).getbbox() is not None:
            sys.exit(f"{doc}: {src_rel} has a drawing in cell {i + 1} past its {frames} frames")
    return img.crop((0, 0, frames * cell, cell))


def copy_strip(doc, src_rel, dst_rel, frames, cell):
    dst = os.path.join(ART, dst_rel)
    existed = os.path.exists(dst)
    before = sha(dst) if existed else None
    exact_strip(doc, src_rel, frames, cell).save(dst)
    applied.append({"doc": doc, "from": src_rel, "to": f"smash-nine-prototype/assets/art/{dst_rel}", "replaced": existed,
                    "size": [frames * cell, cell], "before_sha256": before, "sha256": sha(dst)})
    mark_adopted(src_rel)


def mark_adopted(src_rel):
    meta = src_path(src_rel)[:-4] + ".json"
    if not os.path.exists(meta):
        return
    data = json.load(open(meta, encoding="utf-8"))
    if data.get("adopted") != TODAY:
        data["adopted"] = TODAY
        with open(meta, "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
            f.write("\n")


def supersede(picked_rel, new_rel):
    """The pick stays a candidate the user chose, but the game now uses its size-matched version."""
    meta = src_path(picked_rel)[:-4] + ".json"
    data = json.load(open(meta, encoding="utf-8"))
    data.pop("adopted", None)
    data["superseded_by"] = os.path.basename(new_rel)
    with open(meta, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def row_table(script, const):
    src = open(os.path.join(GAME, script), encoding="utf-8").read()
    start = src.index(f"const {const} := [")
    end = src.index("]\n", src.index("[", start))
    body = src[start:end + 1] if const == "SHEET_ROWS" else src[start:src.index("\n]", start) + 2]
    return [(m[1], int(m[2])) for m in re.finditer(r'\["([a-z0-9_]+)",\s*(\d+),\s*[\d.]+,\s*(?:true|false)\]', body)]


def cells(img, cell, count, start=0):
    """Frames of a sheet laid out six to a row (a row longer than six continues below)."""
    return [img.crop((((start + i) % 6) * cell, ((start + i) // 6) * cell, ((start + i) % 6 + 1) * cell, ((start + i) // 6 + 1) * cell)) for i in range(count)]


def strip_cells(img, cell, count):
    """Frames of a candidate strip: one row, frame i at x = i * cell (an 8-frame walk is 1024 wide)."""
    if img.height != cell or img.width < count * cell:
        sys.exit(f"strip {img.size} cannot hold {count} x {cell}")
    return [img.crop((i * cell, 0, (i + 1) * cell, cell)) for i in range(count)]


def repair_sheet(doc, form, row, src_rel):
    script, const, sheet_rel = SHEET_REPAIRS[(form, row)]
    table = row_table(script, const)
    names = [name for name, _ in table]
    if row not in names:
        sys.exit(f"{doc}: {row} not in {const}")
    index = names.index(row)
    frames = table[index][1]
    start_row = sum(math.ceil(n / 6) for _, n in table[:index])
    sheet_path = os.path.join(ART, sheet_rel)
    sheet = Image.open(sheet_path).convert("RGBA")
    cell = sheet.width // 6
    strip = Image.open(src_path(src_rel)).convert("RGBA")
    if strip.size != (frames * cell, cell):
        sys.exit(f"{doc}: strip {strip.size} != {frames}x{cell}")
    # The cells being replaced must be today's adopted version (the file the repair replaces).
    meta = json.load(open(src_path(src_rel)[:-4] + ".json", encoding="utf-8"))
    old_rel = os.path.join(os.path.dirname(src_rel), os.path.basename(meta["replaces"]))
    old = Image.open(src_path(old_rel)).convert("RGBA")
    current = cells(sheet, cell, frames, start_row * 6)
    if old.height == cell:
        old_frames = strip_cells(old, cell, frames)
        differing = [i + 1 for i, (c, o) in enumerate(zip(current, old_frames)) if c.tobytes() != o.tobytes()]
        same = not differing
        notes.append(f"{doc}: cells being replaced {'equal' if same else 'DIFFER (frames ' + str(differing) + ') from'} {old_rel}")
    else:
        # Frey attack-v5: its `replaces` names the 192-px attack_chain strip, but ART-86 redrew the
        # base sheet's own spare row (F1-F2 kept). Compare the sheet with the repair instead.
        changed = [i + 1 for i, (c, n) in enumerate(zip(current, strip_cells(strip, cell, frames))) if c.tobytes() != n.tobytes()]
        same = None
        notes.append(f"{doc}: {old_rel} is a {old.height}-px strip, not this {cell}-px row; the repair changes frames {changed} of the sheet row")
    before = sha(sheet_path)
    for i, frame in enumerate(strip_cells(strip, cell, frames)):
        x, y = ((start_row * 6 + i) % 6) * cell, ((start_row * 6 + i) // 6) * cell
        sheet.paste(Image.new("RGBA", (cell, cell), (0, 0, 0, 0)), (x, y))
        sheet.paste(frame, (x, y))
    sheet.save(sheet_path)
    applied.append({"doc": doc, "from": src_rel, "to": f"smash-nine-prototype/assets/art/{sheet_rel}", "replaced": True,
                    "sheet_rows": [start_row, start_row + math.ceil(frames / 6) - 1], "frames": frames,
                    "old_cells_equal_replaced_candidate": same, "before_sha256": before, "sha256": sha(sheet_path)})
    mark_adopted(src_rel)


def alpha_rows(cell_img):
    a = cell_img.getchannel("A").point(lambda v: 255 if v else 0)
    box = a.getbbox()
    return box


def monster_sheet(mid, legacy_rel, windup_rel, defeat_rel, docs):
    legacy = Image.open(legacy_rel if os.path.isabs(legacy_rel) else src_path(legacy_rel)).convert("RGBA")
    if legacy.size != (576, 384):
        sys.exit(f"{mid}: legacy sheet {legacy.size}")
    strips = {}
    for row, rel in (("windup", windup_rel), ("defeat", defeat_rel)):
        frames = json.load(open(src_path(rel)[:-4] + ".json", encoding="utf-8")).get("frames", 4)
        if frames != 4:
            sys.exit(f"{mid} {row}: {frames} frames (RealmMonster plays 4)")
        strips[row] = exact_strip(f"{mid} {row}", rel, frames, MONSTER_CELL)
    # Only the legacy ART-27 golem stands on y=80 (its lowest drawn row is 79); the six-row rows
    # end on row 72 (RealmMonster). Lifting by 6 keeps the tallest attack drawing off the cell's
    # top border (test_sprite_frames) and leaves the kept rows 1 px lower than the new ones.
    lift = 6 if mid == "jotunheim_rune_golem" else 0
    sheet = Image.new("RGBA", (576, 576), (0, 0, 0, 0))
    layout = [("idle", 0, 4), ("walk", 1, 6), ("attack", 2, 4), ("hurt", 3, 1)]
    target_row = {"idle": 0, "walk": 1, "attack": 3, "hurt": 4}
    margins = []
    for name, src_row, count in layout:
        for i in range(count):
            c = legacy.crop((i * 96, src_row * 96, (i + 1) * 96, (src_row + 1) * 96))
            box = alpha_rows(c)
            if box is None:
                sys.exit(f"{mid}: legacy {name} F{i+1} empty")
            if box[1] - lift < 0:
                sys.exit(f"{mid}: lifting {name} F{i+1} by {lift} clips the top (top {box[1]})")
            margins.append(box[1] - lift)
            sheet.paste(c.crop((0, lift, 96, 96)), (i * 96, target_row[name] * 96))
        for i in range(count, 6):
            if alpha_rows(legacy.crop((i * 96, src_row * 96, (i + 1) * 96, (src_row + 1) * 96))) is not None:
                sys.exit(f"{mid}: legacy {name} has a drawing in unused cell {i+1}")
    for name, row in (("windup", 2), ("defeat", 5)):
        sheet.paste(strips[name], (0, row * 96))
    # Lowest drawn row per sheet row, and drawn height of the first frame: kept rows vs new rows.
    bottoms, heights = {}, {}
    for name, row, count in (("idle", 0, 4), ("walk", 1, 6), ("windup", 2, 4), ("attack", 3, 4), ("hurt", 4, 1), ("defeat", 5, 4)):
        boxes = [sheet.crop((i * 96, row * 96, (i + 1) * 96, (row + 1) * 96)).getbbox() for i in range(count)]
        bottoms[name] = max(b[3] - 1 for b in boxes)
        heights[name] = boxes[0][3] - boxes[0][1]
    out = os.path.join(ART, "monsters", f"{mid}_sheet.png")
    before = sha(out)
    sheet.save(out)
    applied.append({"doc": docs, "from": [legacy_rel if not os.path.isabs(legacy_rel) else os.path.relpath(legacy_rel, ROOT).replace("\\", "/"), windup_rel, defeat_rel],
                    "to": f"smash-nine-prototype/assets/art/monsters/{mid}_sheet.png", "replaced": True, "size": [576, 576],
                    "rows": "idle 4 / walk 6 / windup 4 / attack 4 / hurt 1 / defeat 4", "legacy_lift_px": lift,
                    "legacy_min_top_px": min(margins), "lowest_drawn_row": bottoms, "first_frame_height": heights,
                    "before_sha256": before, "sha256": sha(out)})
    notes.append(f"{mid}: lowest row idle {bottoms['idle']} windup {bottoms['windup']} defeat {bottoms['defeat']}; "
                 f"height idle {heights['idle']} windup {heights['windup']} defeat {heights['defeat']}")
    for rel in (windup_rel, defeat_rel):
        mark_adopted(rel)
    if not os.path.isabs(legacy_rel):
        mark_adopted(legacy_rel)


docs = {d["doc"]: d for d in SNAP["docs"]}
assert len(docs) == 222 and all(d["picked"] for d in docs.values()), "snapshot must hold 222 picked rows"
for d in docs.values():
    if d["kind"] == "monster" and d["row"] in ("idle", "walk", "attack", "hurt") and d["choice"] != "none":
        sys.exit(f"{d['doc']}: a monster base row was picked; this script keeps them all")

# 1-2. Fighters
for d in sorted(docs.values(), key=lambda d: d["doc"]):
    if d["kind"] != "fighter" or d["choice"] == "none":
        continue
    form, row = d["form"], d["row"]
    if (form, row) in SHEET_REPAIRS:
        repair_sheet(d["doc"], form, row, d["file"])
    elif row in STRIP_ROWS:
        frames, cell = STRIP_ROWS[row]
        copy_strip(d["doc"], d["file"], f"{folder_of(form)}/{form}_{row}.png", frames, cell)
    else:
        sys.exit(f"{d['doc']}: no adoption path for fighter row {row}")

# 3. Portraits
for d in sorted(docs.values(), key=lambda d: d["doc"]):
    if d["kind"] == "face" and d["choice"] != "none":
        copy(d["doc"], d["file"], f"{folder_of(d['form'])}/{d['form']}_face_{d['row']}.png")

# 4. Projectiles and shockwaves (assets/art/monsters/README.md, SYS-07)
for d in sorted(docs.values(), key=lambda d: d["doc"]):
    if d["kind"] != "projectile":
        continue
    form, row = d["form"], d["row"]
    if row == "shockwave":
        name = "slam_shockwave.png" if form == "slam_shockwave" else f"{form}_shockwave.png"
        copy(d["doc"], d["file"], f"monsters/{name}", (256, 48))
    else:
        name = "ember_fireball.png" if form == "ember_imp" else f"{form}_projectile.png"
        img = Image.open(src_path(d["file"]))
        if img.height != 48 or img.width % 48 or img.width < 96:
            sys.exit(f"{d['doc']}: projectile strip {img.size}")
        copy(d["doc"], d["file"], f"monsters/{name}")

# 5. Monster six-row sheets
monster_ids = sorted({d["form"] for d in docs.values() if d["kind"] == "monster"})
assert len(monster_ids) == 18, monster_ids
for mid in monster_ids:
    legacy_doc = docs.get(f"legacy_sheet~{mid}~sheet")
    windup, defeat = docs[f"monster~{mid}~windup"], docs[f"monster~{mid}~defeat"]
    if windup["choice"] == "none" or defeat["choice"] == "none":
        sys.exit(f"{mid}: windup/defeat not picked")
    if legacy_doc and legacy_doc["choice"] == "fix1":
        legacy_rel = legacy_doc["file"]
    else:
        legacy_rel = os.path.join(ART, "monsters", f"{mid}_sheet.png")
    used = [f"monster~{mid}~windup", f"monster~{mid}~defeat"] + ([legacy_doc["doc"]] if legacy_doc else [])
    windup_rel = OVERRIDES.get(windup["doc"], windup["file"])
    defeat_rel = OVERRIDES.get(defeat["doc"], defeat["file"])
    for doc, picked, rel in ((windup["doc"], windup["file"], windup_rel), (defeat["doc"], defeat["file"], defeat_rel)):
        if rel != picked:
            notes.append(f"{doc}: size-matched {rel} replaces the pick {picked}")
            supersede(picked, rel)
    monster_sheet(mid, legacy_rel, windup_rel, defeat_rel, used)

out = os.path.join(ROOT, "reports", "apply-2026-10-29", "applied.json")
with open(out, "w", encoding="utf-8", newline="\n") as f:
    json.dump({"snapshot": os.path.basename(sys.argv[2]), "applied": applied, "notes": notes}, f, ensure_ascii=False, indent=1)
    f.write("\n")
kinds = {}
for a in applied:
    kinds[a["to"].split("/")[3]] = kinds.get(a["to"].split("/")[3], 0) + 1
print(f"{len(applied)} files written; by folder {kinds}")
for n in notes:
    print(n)
