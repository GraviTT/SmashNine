// Builds the pick cup page (시안 월드컵) for one round: copies the round's media next to the page and
// writes items.json, then lists every file for the Artifact publish (dist/files.json).
//
//   node tools/pick_cup/build.mjs [rounds/<round>.json]   (default: the newest round file)
//
// Media paths in a round file are repo-relative; in dist they become media/<item>/<candidate>.<ext>.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync, readdirSync, rmSync, statSync } from "node:fs";
import { join, dirname, extname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, "..", "..");
const DIST = join(HERE, "dist");
const rounds = readdirSync(join(HERE, "rounds")).filter((f) => f.endsWith(".json")).sort();
const roundFile = process.argv[2] ? join(HERE, process.argv[2]) : join(HERE, "rounds", rounds[rounds.length - 1]);
const round = JSON.parse(readFileSync(roundFile, "utf8"));

const SEGMENT = /^[A-Za-z0-9_.~:@+-]+$/; // the db's path grammar: ids become document-id parts
rmSync(DIST, { recursive: true, force: true });
mkdirSync(join(DIST, "media"), { recursive: true });
const files = [];
for (const item of round.items) {
  if (!SEGMENT.test(item.id)) throw new Error(`item id ${item.id}: letters, digits and _ . ~ : @ + - only`);
  if (item.candidates.length < 2) throw new Error(`item ${item.id}: needs two or more candidates`);
  for (const c of item.candidates) {
    if (!SEGMENT.test(c.id)) throw new Error(`candidate id ${c.id}: letters, digits and _ . ~ : @ + - only`);
    const src = join(REPO, c.media);
    const out = join("media", item.id, c.id + extname(c.media).toLowerCase());
    mkdirSync(join(DIST, dirname(out)), { recursive: true });
    copyFileSync(src, join(DIST, out));
    c.media = out.split("\\").join("/");
    files.push(c.media);
  }
}
writeFileSync(join(DIST, "items.json"), JSON.stringify(round, null, 2) + "\n");
copyFileSync(join(HERE, "index.html"), join(DIST, "index.html"));
files.unshift("items.json");
writeFileSync(join(DIST, "files.json"), JSON.stringify(files, null, 2) + "\n");
const bytes = files.reduce((n, f) => n + statSync(join(DIST, f)).size, 0);
console.log(`round ${round.round}: ${round.items.length} items, ${files.length - 1} media files, ${(bytes / 1024).toFixed(0)} KB -> ${relative(REPO, DIST)}`);
