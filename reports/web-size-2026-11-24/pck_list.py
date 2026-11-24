"""List the files inside a Godot 4 .pck (format v2 or v3), also when it is split into .partN files.

Usage: python pck_list.py <web dir> [out.tsv]
Prints a per-folder summary; writes every entry (path, size) to out.tsv.
"""
import os
import struct
import sys
from collections import defaultdict

web = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else None
whole = os.path.join(web, "index.pck")
if os.path.exists(whole):
    data = open(whole, "rb").read()
else:
    parts = []
    i = 0
    while os.path.exists(os.path.join(web, f"index.pck.part{i}")):
        parts.append(open(os.path.join(web, f"index.pck.part{i}"), "rb").read())
        i += 1
    data = b"".join(parts)

pos = 0
def u32():
    global pos
    v = struct.unpack_from("<I", data, pos)[0]
    pos += 4
    return v
def u64():
    global pos
    v = struct.unpack_from("<Q", data, pos)[0]
    pos += 8
    return v

assert data[:4] == b"GDPC", data[:4]
pos = 4
version = u32(); major = u32(); minor = u32(); patch = u32()
flags = u32()
file_base = u64()
if version >= 3:
    dir_offset = u64()
    pos = dir_offset
else:
    pos += 16 * 4
count = u32()
entries = []
for _ in range(count):
    sl = u32()
    path = data[pos:pos + sl].rstrip(b"\0").decode("utf-8")
    pos += sl
    ofs = u64(); size = u64(); pos += 16; u32()
    entries.append((path, size))

total = sum(s for _, s in entries)
print(f"pck v{version} engine {major}.{minor}.{patch}, {count} files, {total/1e6:.1f} MB of {len(data)/1e6:.1f} MB")

def top(path, depth):
    p = path.replace("res://", "")
    bits = p.split("/")
    return "/".join(bits[:depth]) if len(bits) > depth else p

for depth in (1, 3):
    groups = defaultdict(lambda: [0, 0])
    for p, s in entries:
        g = groups[top(p, depth)]
        g[0] += s; g[1] += 1
    print(f"\n-- by folder (depth {depth}) --")
    for k, (s, n) in sorted(groups.items(), key=lambda kv: -kv[1][0])[:30]:
        print(f"{s/1e6:8.2f} MB {n:5d}  {k}")

if out:
    with open(out, "w", encoding="utf-8") as f:
        for p, s in sorted(entries, key=lambda e: -e[1]):
            f.write(f"{s}\t{p}\n")
