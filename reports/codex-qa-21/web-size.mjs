import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { gzipSync, gunzipSync } from 'node:zlib';
const dir = path.dirname(fileURLToPath(import.meta.url));
const web = path.join(dir, 'web');
const pck = fs.readFileSync(path.join(web, 'index.pck'));
const md5 = b => createHash('md5').update(b).digest('hex');
const format = pck.readUInt32LE(4);
if (pck.toString('ascii', 0, 4) !== 'GDPC') throw Error('Unexpected pack magic');
// Discover directory/header offsets empirically, then validate every entry against pack MD5.
// This keeps the audit independent of assumptions about a specific PCK format revision.
const candidates = new Set([96, 100, 104, 108, 112]);
const bases = new Set([0, Number(pck.readBigUInt64LE(24))]);
for (let n = 24; n < 112; n += 8) {
  const value = Number(pck.readBigUInt64LE(n));
  if (Number.isSafeInteger(value) && value >= 0 && value < pck.length - 8) candidates.add(value);
}
for (let n = 64; n < 512; n += 4) candidates.add(n);
let entries, parsedHeader;
outer: for (const offset of candidates) for (const flagBytes of [4, 0]) for (const base of bases) {
  try {
    const count = pck.readUInt32LE(offset);
    if (count < 10 || count > 50000) continue;
    let cursor = offset + 4;
    const found = [];
    for (let i = 0; i < count; i++) {
      const length = pck.readUInt32LE(cursor); cursor += 4;
      if (length < 2 || length > 4096 || cursor + length + 32 + flagBytes > pck.length) throw Error('path');
      const name = pck.toString('utf8', cursor, cursor + length).replace(/\0+$/, ''); cursor += length;
      if ((!name.includes('/') && !name.includes('.')) || name.includes('\0') || /[\x01-\x1f]/.test(name)) throw Error('name');
      const start = Number(pck.readBigUInt64LE(cursor)) + base; cursor += 8;
      const size = Number(pck.readBigUInt64LE(cursor)); cursor += 8;
      const hash = pck.subarray(cursor, cursor + 16).toString('hex'); cursor += 16;
      const flags = flagBytes ? pck.readUInt32LE(cursor) : 0; cursor += flagBytes;
      if (start < 0 || size < 0 || start + size > pck.length || flags > 16) throw Error('range');
      if (md5(pck.subarray(start, start + size)) !== hash) throw Error('MD5');
      found.push({ path: name, offset: start, bytes: size, md5: hash, flags });
    }
    entries = found; parsedHeader = { format, directory_offset: offset, file_base: base, flag_bytes: flagBytes, md5_verified: found.length }; break outer;
  } catch { /* Try the next plausible header; no partial parse is accepted. */ }
}
if (!entries) throw Error('No directory layout passed complete bounds and MD5 validation: ' + pck.subarray(0, 128).toString('hex'));
const types = {};
const groups = new Map();
for (const entry of entries) {
  const ext = path.extname(entry.path) || '(none)';
  (types[ext] ??= { count: 0, bytes: 0 }).count++;
  types[ext].bytes += entry.bytes;
  const key = `${entry.bytes}:${entry.md5}`;
  const bucket = groups.get(key) ?? []; bucket.push(entry); groups.set(key, bucket);
}
const duplicates = [...groups.values()].filter(g => g.length > 1 && g[0].bytes > 1024).map(g => ({ bytes_each: g[0].bytes, redundant_bytes: g[0].bytes * (g.length - 1), paths: g.map(e => e.path) })).sort((a,b) => b.redundant_bytes - a.redundant_bytes);
const files = fs.readdirSync(web).filter(n => fs.statSync(path.join(web, n)).isFile()).map(name => {
  const bytes = fs.readFileSync(path.join(web, name));
  const compressed = gzipSync(bytes, { level: 9 });
  const identical = gunzipSync(compressed).equals(bytes);
  if (!identical) throw Error('gzip roundtrip mismatch: ' + name);
  return { name, bytes: bytes.length, gzip9_bytes: compressed.length, gzip_roundtrip_identical: identical, sha256: createHash('sha256').update(bytes).digest('hex') };
});
const payload = files.filter(f => ['index.pck', 'index.wasm', 'index.js'].includes(f.name));
const report = { generated_at: new Date().toISOString(), note: 'Fresh export using unchanged Web preset. gzip is an offline estimate, not a measured browser transfer or startup duration.', header: parsedHeader, files, initial_core_raw_bytes: payload.reduce((s,f) => s+f.bytes,0), initial_core_gzip9_bytes: payload.reduce((s,f) => s+f.gzip9_bytes,0), pack_types: Object.entries(types).map(([ext,v])=>({ext,...v})).sort((a,b)=>b.bytes-a.bytes), largest_entries: [...entries].sort((a,b)=>b.bytes-a.bytes).slice(0,40), duplicate_groups: duplicates, excluded_category_entries_found: entries.filter(e=> /source|contact_sheet|tests\//i.test(e.path)), all_entries: entries };
fs.writeFileSync(path.join(dir, 'web-size.json'), JSON.stringify(report, null, 2)+'\n');
console.log(JSON.stringify({ header: report.header, files, core_raw: report.initial_core_raw_bytes, core_gzip9: report.initial_core_gzip9_bytes, pack_types: report.pack_types, largest: report.largest_entries.slice(0,10), duplicate_savings: duplicates.reduce((s,g)=>s+g.redundant_bytes,0) }, null, 2));
