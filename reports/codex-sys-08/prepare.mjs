import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
for (const seed of [1001, 2105, 2106]) {
  const source = path.join(dir, '../codex-qa-22', `sound-br-${seed}-events.json.gz`);
  fs.writeFileSync(path.join(dir, `before-br-${seed}.json`), zlib.gunzipSync(fs.readFileSync(source)));
}
for (const name of fs.readdirSync(dir).filter(n => /^sound-(br|story)-\d+-events\.json\.gz$/.test(n))) {
  const output = path.join(dir, name.replace('-events.json.gz', '.json'));
  if (!fs.existsSync(output)) fs.writeFileSync(output, zlib.gunzipSync(fs.readFileSync(path.join(dir, name))));
}
console.log('SYS08 replay inputs prepared; no files written under the Godot project.');
