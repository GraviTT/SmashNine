import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';
const dir = path.dirname(fileURLToPath(import.meta.url));
const read = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^\uFEFF/, ''));
const loadCapture = (folder, kind, n) => {
  const base = path.join(folder, `sound-${kind}-${n}`);
  return fs.existsSync(base + '.json') ? read(base + '.json') : JSON.parse(zlib.gunzipSync(fs.readFileSync(base + '-events.json.gz')));
};
const baseline = path.join(dir, '../codex-qa-22');
const gates = [];
let matrix = '# 문 통과 · 선수별 / 활성 구간별\n\n각 칸은 이전→이후 통과 수다. 0은 통과 미관측이며 해당 선수가 살아서 문에 접근했다는 뜻은 아니다. P는 경기 player_id다.\n';
for (const seed of [2105, 2106]) {
  const before = read(path.join(baseline, `gate-soak-${seed}.json`));
  const after = read(path.join(dir, `gate-soak-${seed}.json`));
  if (before.seed !== seed || after.seed !== seed || after.players !== 16) throw Error('Invalid gate input');
  const summarize = data => {
    const groups = {};
    for (const e of data.gate_events) (groups[`${e.window}:${e.player}`] ??= []).push(e.t);
    const intervals = Object.values(groups).flatMap(ts => ts.slice(1).map((t, i) => t - ts[i]));
    return { total: data.gate_events.length, max: Math.max(0, ...Object.values(groups).map(a => a.length)), min_interval: Math.min(...intervals), windows: data.gate_windows, seconds: data.seconds_simulated, nan: data.nan_positions, groups };
  };
  const b = summarize(before), a = summarize(after);
  if (a.min_interval < 2.5 - 1e-6 || a.nan !== 0) throw Error('Gate invariant failed');
  gates.push({ seed, before: b, after: a });
  matrix += `\n## 시드 ${seed}\n\n| 구간 | ${Array.from({length: 16}, (_, i) => 'P' + (i + 1)).join(' | ')} |\n|---|${'---:|'.repeat(16)}\n`;
  for (let w = 1; w <= Math.max(a.windows, b.windows); w++) {
    matrix += `| ${w} | ${Array.from({length: 16}, (_, i) => `${b.groups[`${w}:${i+1}`]?.length ?? 0}→${a.groups[`${w}:${i+1}`]?.length ?? 0}`).join(' | ')} |\n`;
  }
}
fs.writeFileSync(path.join(dir, 'gate-windows.md'), matrix);
const rates = read(path.join(dir, 'rate-comparison.json'));
const validation = [];
for (const c of rates.captures) {
  const raw = loadCapture(c.period === 'before' ? baseline : dir, 'br', c.seed);
  const watched = raw.events.filter(e => e.outcome === 'watched');
  const counts = {};
  for (const e of watched) counts[e.id] = (counts[e.id] ?? 0) + 1;
  const valid = raw.stats.seed === c.seed && raw.events.length === Object.values(raw.requests).reduce((a,b) => a+b, 0)
    && watched.length === c.raw_total && Object.entries(c.ids).every(([id,r]) => r.raw.total === (counts[id] ?? 0))
    && Object.values(c.ids).reduce((a,r) => a+r.gap_eligible.total, 0) === c.synthetic_plays_free_voices;
  if (!valid) throw Error(`Recorder/replay mismatch: ${c.period} ${c.seed}`);
  validation.push({ period: c.period, seed: c.seed, valid, source_plays: raw.actual_sfx_plays, source_voice_peak: raw.actual_voice_peak_after_requests });
}
let table = '# 사운드 ID별 전후 수치\n\n원요청은 관찰 렐름 필터 통과 후 수요, 통과 상한은 모든 ID에 독립 음원·빈 voice가 있다고 가정한 코드 생성 톤 재현이다. 채택 음원의 재생량·중첩·청감이 아니다. 괄호는 정수 1초 피크이며 그 밖은 이동 1초 창 [t,t+1) 피크다. 초별 전체 값은 rate-comparison.json의 seconds다.\n';
for (const seed of [1001, 2105, 2106]) {
  const b = rates.captures.find(c => c.period === 'before' && c.seed === seed);
  const a = rates.captures.find(c => c.period === 'after' && c.seed === seed);
  table += `\n## 8봇 시드 ${seed}\n\n경기 시간 ${b.stats.seconds_simulated}→${a.stats.seconds_simulated}초.\n\n| ID | 원요청 합계 전→후 | 원요청 피크 전→후 | 간격 통과 합계 전→후 | 간격 통과 피크 전→후 |\n|---|---:|---:|---:|---:|\n`;
  for (const id of Object.keys(b.ids)) {
    const r = b.ids[id], s = a.ids[id];
    const peak = key => `${r[key].rolling_peak} (${r[key].aligned_peak})→${s[key].rolling_peak} (${s[key].aligned_peak})`;
    table += `| ${id} | ${r.raw.total}→${s.raw.total} | ${peak('raw')} | ${r.gap_eligible.total}→${s.gap_eligible.total} | ${peak('gap_eligible')} |\n`;
  }
}
fs.writeFileSync(path.join(dir, 'sound-tables.md'), table);
const stories = [];
for (const stage of [1, 5, 9]) {
  const before = loadCapture(baseline, 'story', stage), after = loadCapture(dir, 'story', stage);
  const ids = ['story_text', 'story_advance', 'portal', 'results', 'victory', 'music_results'];
  const count = (d, id) => d.events.filter(e => e.id === id).length;
  const moments = after.events.filter(e => ids.includes(e.id)).map(e => ({ id: e.id, phase: e.phase, screen: e.screen, t: e.t, frame: e.frame }));
  if (after.stats.hook_failures !== 0 || !after.stats.match_over) throw Error('Story hook failure');
  stories.push({ stage, before: Object.fromEntries(ids.map(id => [id, count(before,id)])), after: Object.fromEntries(ids.map(id => [id, count(after,id)])), moments,
    music_before: before.checkpoints.find(c => c.label === 'story_result_or_ending')?.music,
    music_after: after.checkpoints.find(c => c.label === 'story_result_or_ending')?.music });
}
fs.writeFileSync(path.join(dir, 'comparison.json'), JSON.stringify({ gates, validation, stories }, null, 2) + '\n');
const peak = (period, id, key) => Math.max(...rates.captures.filter(c => c.period === period).map(c => c.ids[id][key].rolling_peak));
const shown = [['Gate 2105 / passes', gates[0].before.total, gates[0].after.total, 25], ['Gate 2106 / max per bot + window', gates[1].before.max, gates[1].after.max, 5],
  ['land / raw peak per rolling second', peak('before','land','raw'), peak('after','land','raw'), 25], ['land / gap-eligible ceiling', peak('before','land','gap_eligible'), peak('after','land','gap_eligible'), 25],
  ['hurt / gap-eligible ceiling', peak('before','hurt','gap_eligible'), peak('after','hurt','gap_eligible'), 25], ['hit_light / gap-eligible ceiling', peak('before','hit_light','gap_eligible'), peak('after','hit_light','gap_eligible'), 25]];
fs.writeFileSync(path.join(dir, 'chart-data.json'), JSON.stringify(shown, null, 2) + '\n');
let svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1050" height="570" viewBox="0 0 1050 570"><rect width="1050" height="570" fill="#111827"/><g font-family="Arial,sans-serif" fill="#e5e7eb"><text x="30" y="35" font-size="24">SYS-08 | observed changes</text><text x="30" y="60" font-size="14">Before (QA-22): gray / After: blue. Rates are free-voice, direct-stream ceilings.</text>';
for (let i = 0; i < shown.length; i++) {
  const [label,b,a,max] = shown[i], y = 100 + i*70;
  svg += `<text x="30" y="${y+12}" font-size="16">${label}</text><rect x="470" y="${y-10}" width="${b/max*470}" height="19" fill="#6b7280"/><text x="${480+b/max*470}" y="${y+5}" font-size="14">${b}</text><rect x="470" y="${y+13}" width="${a/max*470}" height="19" fill="#38bdf8"/><text x="${480+a/max*470}" y="${y+28}" font-size="14">${a}</text>`;
}
svg += '<text x="30" y="550" font-size="13">Headless measurements. No shipped sound assets. See README.md for assumptions and exact seed tables.</text></g></svg>';
fs.writeFileSync(path.join(dir, 'comparison.svg'), svg);
for (const name of fs.readdirSync(dir).filter(n => /^sound-(br|story)-\d+\.json$/.test(n))) {
  const raw = fs.readFileSync(path.join(dir, name)), zip = zlib.gzipSync(raw);
  if (!zlib.gunzipSync(zip).equals(raw)) throw Error('Gzip roundtrip failure');
  fs.writeFileSync(path.join(dir, name.replace('.json', '-events.json.gz')), zip);
}
console.log(JSON.stringify({ gates: gates.map(g => ({seed:g.seed,before:g.before.total,after:g.after.total,max:[g.before.max,g.after.max]})), validation, stories: stories.map(s => ({stage:s.stage,before:s.before,after:s.after,music:s.music_after})) },null,2));
