// Offline only. The existing motion builder is an unchanged, read-only data source;
// its explicitly permitted ignored dist/ is the only output outside our own directory.
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync, rmSync, statSync } from "node:fs";
import { join, dirname, resolve, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";

const here = dirname(fileURLToPath(import.meta.url)), repo = resolve(here, "../.."), dist = resolve(here, "dist");
const read = path => readFileSync(path, "utf8");
const json = path => JSON.parse(read(path));
const git = (...args) => execFileSync("git", args, { cwd: repo, encoding: "utf8" }).trim();
const need = (condition, message) => { if (!condition) throw new Error(message); };
const forms = { frey: "프레이", luna: "루나", luna_brave: "브레이브 루나", nova_male: "노바 남성", nova_female: "노바 여성", rio_male: "리오 남성", rio_female: "리오 여성", yuki: "유키" };
const rowNames = { idle: "대기", walk: "걷기", jump: "점프", fall: "낙하", attack: "공격", shield: "방어", hurt: "피격", defeat: "쓰러짐", land: "착지", victory: "승리", windup: "공격 준비", gravity_brake: "중력 제동", mana_combo: "마나 검격 연속 공격", low_sweep: "하단 베기", dimension_slash: "차원 베기", happy: "기쁨", angry: "분노", shadow: "그림자", shockwave: "지면 충격파", projectile: "투사체", sheet: "옛 시트 전체" };
const monsterNames = { alfheim_moon_moth: "알프헤임 달나방", alfheim_moon_stag: "알프헤임 달사슴", asgard_aegis_ram: "아스가르드 방패 산양", asgard_runic_raven: "아스가르드 룬 까마귀", ember_imp: "불씨 임프", jotunheim_rune_golem: "요툰헤임 룬 골렘", jotunheim_storm_wisp: "요툰헤임 폭풍 정령", midgard_rooftop_slinger: "미드가르드 지붕 투석병", mossling: "이끼 정령", muspelheim_magma_boar: "무스펠헤임 용암 멧돼지", niflheim_frost_owl: "니플헤임 서리 올빼미", niflheim_glacier_wolf: "니플헤임 빙하 늑대", svartalfheim_cog_drone: "스바르트알프헤임 톱니 드론", svartalfheim_gear_beetle: "스바르트알프헤임 톱니 딱정벌레", vanaheim_seed_sprite: "바나헤임 씨앗 요정", vanaheim_vine_hound: "바나헤임 덩굴 사냥개", yggdrasil_root_guardian: "이그드라실 뿌리 수호자", yggdrasil_root_oracle: "이그드라실 뿌리 예언자", slam_shockwave: "공용 지면 충격파" };

need(dist === resolve(repo, "tools/compare_viewer/dist"), "Unexpected output directory");
// Checked absolute motion output before invoking a builder that removes it recursively.
need(resolve(repo, "tools/motion_viewer/dist") === resolve(here, "../motion_viewer/dist"), "Unexpected motion output");
execFileSync(process.execPath, [join(repo, "tools/motion_viewer/build.mjs")], { cwd: repo, stdio: "pipe" });
const motion = JSON.parse(read(join(repo, "tools/motion_viewer/dist/index.html")).match(/^const M = (.+);$/m)[1]);
const changes = json(join(here, "changes.json"));
const keyOf = (kind, id, row) => `${kind}~${id}~${row}`;
const sourcePath = file => file.startsWith("bakeoff/") ? `art/${file}` : file.startsWith("sheets/") ? `smash-nine-prototype/assets/art/${file.slice(7)}` : file.startsWith("current/") ? `smash-nine-prototype/assets/art/${file.slice(8)}` : null;
const files = new Map();
function register(file) {
	const source = sourcePath(file);
	need(source && !isAbsolute(file) && !file.includes("\\") && !file.split("/").includes(".."), `Unsafe asset path: ${file}`);
	need(existsSync(join(repo, source)), `Wrong/missing path (changes.json unchanged): ${source}`);
	files.set(file, source);
	return source;
}
function dimensions(file) {
	const b = readFileSync(join(repo, register(file)));
	need(b.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])), `Not a PNG: ${file}`);
	return [b.readUInt32BE(16), b.readUInt32BE(20)];
}
function tile(file, options = {}) {
	const size = dimensions(file), cell = options.cell ?? size;
	const pair = Array.isArray(cell) ? cell : [cell, cell];
	const t = { file, repoFile: sourcePath(file), frames: 1, start: 0, role: "game", ...options, cell: pair, columns: size[0] / pair[0] };
	need(pair.length === 2 && pair.every(x => Number.isInteger(x) && x > 0), `Invalid cell: ${file}`);
	need(Number.isInteger(t.columns) && Number.isInteger(t.frames) && t.frames > 0 && t.start >= 0, `Invalid frames: ${file}`);
	need((t.start + Math.ceil(t.frames / t.columns)) * pair[1] <= size[1], `Frames exceed image: ${file}`);
	return t;
}
function candidate(c, fallback = {}) {
	const entry = changes.new[c.file.replace(/^bakeoff\//, "")];
	return tile(c.file, { role: "candidate", version: c.version, frames: c.frames || fallback.frames || 1,
		cell: c.cell || fallback.cell, feet: c.feet ?? fallback.feet ?? null,
		isNew: Boolean(entry), card: entry?.card || "", change: entry?.change || "",
		gameRepair: Boolean(entry?.game_repair), replaces: entry?.replaces || null });
}
const rows = [], groups = [];
function addGroup(id, label) { groups.push({ id, label }); }
function panel(label, fps, loop, tiles, centred = false) {
	need(Number.isFinite(fps) && fps > 0, `Invalid fps: ${label}`);
	const width = Math.max(...tiles.map(t => t.cell[0])), height = Math.max(...tiles.map(t => t.cell[1]));
	const feet = centred ? null : Math.max(...tiles.map(t => t.feet ?? t.cell[1]));
	for (const t of tiles) {
		t.x = (width - t.cell[0]) / 2;
		t.y = centred ? (height - t.cell[1]) / 2 : feet - (t.feet ?? t.cell[1]);
		need(t.y >= 0 && t.y + t.cell[1] <= height, `Feet alignment clips image: ${t.file}`);
	}
	return { label, fps, loop: Boolean(loop), width, height, feet, tiles };
}
function addRow(kind, id, row, group, formName, label, hasGame, panels, extra = {}) {
	const candidates = panels.flatMap(p => p.tiles.filter(t => t.role === "candidate"));
	const versions = [...new Set(candidates.map(t => t.version))];
	const fresh = [...new Map(candidates.filter(t => t.isNew).map(t => [t.file, t])).values()];
	const key = keyOf(kind, id, row);
	need(!rows.some(r => r.key === key), `Duplicate row: ${key}`);
	rows.push({ key, kind, id, row, group, formName, label, hasGame, panels,
		options: [...versions, "none"], newCount: fresh.length, gameRepair: candidates.some(t => t.gameRepair),
		noNewText: changes.no_new_version.find(n => keyOf(n.kind, n.id, n.row) === key)?.text || "", ...extra });
}
function motionRow(kind, id, group, formName, sheet, r) {
	if (!r.candidates.length) return;
	// The old builder currently also discovers this as an extra monster row.
	// Relocate it to the required projectile selection unit, never duplicate its option.
	if (id === "yggdrasil_root_guardian" && r.name === "shockwave") return;
	const sorted = [...r.candidates].sort((a,b) => Number(a.version.slice(1)) - Number(b.version.slice(1)));
	const newest = sorted.at(-1), hasGame = !r.newRow && r.start !== null;
	const fps = hasGame ? r.fps : newest.fps || r.fps;
	const loop = hasGame ? r.loop : newest.loop ?? r.loop;
	const tiles = hasGame ? [tile(sheet.file, { label: "지금 게임", cell: sheet.cell, feet: sheet.feet, frames: r.frames, start: r.start })] : [];
	tiles.push(...sorted.map(c => candidate(c, { cell: sheet.cell, feet: sheet.feet, frames: r.frames })));
	need(rowNames[r.name], `Add Korean row label: ${r.name}`);
	addRow(kind, id, r.name, group, formName, rowNames[r.name], hasGame, [panel(rowNames[r.name], fps, loop, tiles)]);
}
for (const c of motion.characters) for (const f of c.forms) {
	const id = f.body ? `${c.id}_${f.body}` : c.id, group = `fighter-${id}`;
	addGroup(group, forms[id]);
	for (const sheet of [f.base, f.moves].filter(Boolean)) for (const r of sheet.rows) motionRow("fighter", id, group, forms[id], sheet, r);
}
addGroup("monsters", "몬스터");
for (const m of motion.monsters) for (const r of m.base.rows) motionRow("monster", m.id, "monsters", monsterNames[m.id], m.base, r);
addGroup("projectiles", "투사체");
for (const id of new Set(motion.projectiles.map(p => p.id))) {
	const candidates = motion.projectiles.filter(p => p.id === id).sort((a,b) => Number(a.version.slice(1)) - Number(b.version.slice(1)));
	const newest = candidates.at(-1), tiles = [];
	if (newest.current) tiles.push(tile(newest.current, { label: "지금 게임" }));
	else tiles.push({ role: "game", label: "지금 게임 · 도형 재현", primitive: "shockwave", frames: 1, cell: [64,48] });
	tiles.push(...candidates.map(c => candidate(c)));
	addRow("projectile", id, id === "slam_shockwave" ? "shockwave" : "projectile", "projectiles", monsterNames[id], newest.name, true,
		[panel(newest.name, newest.fps, newest.loop, tiles, true)], { note: "같은 원본 픽셀 배율로 비교합니다. 게임의 표시 배율과는 다를 수 있습니다." });
}
{
	const rel = "monsters/yggdrasil_root_guardian-shockwave-v1.png", meta = json(join(repo, "art/bakeoff", rel.replace(/\.png$/, ".json")));
	const c = { ...meta, file: `bakeoff/${rel}`, version: "v1" };
	const reference = candidate(motion.projectiles.find(p => p.id === "slam_shockwave" && p.version === "v1"));
	reference.role = "reference"; reference.label = "비교용: 공용 v1";
	addRow("projectile", "yggdrasil_root_guardian", "shockwave", "projectiles", "이그드라실 뿌리 수호자", "수호자 전용 지면 충격파 · 새 줄", false,
		[panel("지면 충격파", meta.fps, meta.loop, [reference, candidate(c)], true)], { note: "고르면 게임 코드 연결이 필요함" });
}
addGroup("faces", "대화 초상화");
for (const f of motion.portraits) for (const expression of ["happy", "angry", "hurt", "shadow"]) {
	const cs = f.candidates.filter(c => c.pick.row === expression).sort((a,b) => Number(a.version.slice(1)) - Number(b.version.slice(1)));
	if (!cs.length) continue;
	const tiles = [tile(f.current, { role: "reference", label: "지금 게임 · 무표정 참고", portrait: true }), ...cs.map(c => ({ ...candidate(c), portrait: true }))];
	addRow("face", f.id, expression, "faces", forms[f.id], rowNames[expression], false, [panel(rowNames[expression], 1, true, tiles, true)]);
}
addGroup("legacy", "옛 몬스터 시트 수리본");
for (const [id, entry] of Object.entries(changes.legacy)) {
	const monster = motion.monsters.find(m => m.id === id);
	need(monster, `Unknown legacy monster: ${id}`);
	need(sourcePath(monster.base.file) === entry.replaces, `Wrong legacy replaces path (changes.json unchanged): ${entry.replaces}`);
	const panels = monster.base.rows.filter(r => !r.newRow && r.start !== null).map(r => panel(rowNames[r.name], r.fps, r.loop, [
		tile(monster.base.file, { label: "지금 게임", cell: monster.base.cell, feet: monster.base.feet, frames: r.frames, start: r.start }),
		tile(`bakeoff/${entry.file}`, { role: "candidate", version: "fix1", label: "수리본", cell: monster.base.cell, feet: monster.base.feet, frames: r.frames, start: r.start, card: entry.card }),
	]));
	addRow("legacy_sheet", id, "sheet", "legacy", monsterNames[id], "옛 시트 전체", true, panels,
		{ gameRepair: true, qa: entry.qa, change: entry.change, card: entry.card, note: "새 6줄 후보를 고르면 이 수리본은 필요 없음" });
}

// Fail closed against the checkpoint and the lead's authored correspondence table.
const candidates = rows.flatMap(r => r.panels.flatMap(p => p.tiles.filter(t => t.role === "candidate").map(t => ({ row: r, tile: t }))));
const added = git("diff", "--name-status", changes.checkpoint, "HEAD", "--", "art/bakeoff").split(/\r?\n/).filter(l => l.startsWith("A\t") && l.endsWith(".png")).map(l => l.slice(2));
const assemblies = added.filter(p => /_sheet-v2\.png$/.test(p));
const legacyAdded = added.filter(p => p.startsWith("art/bakeoff/monsters/legacy/"));
const rowAdded = added.filter(p => !assemblies.includes(p) && !legacyAdded.includes(p));
for (const file of rowAdded) need(Object.hasOwn(changes.new, file.slice("art/bakeoff/".length)), `Added candidate absent from changes.json: ${file}`);
for (const [rel, entry] of Object.entries(changes.new)) {
	const matches = candidates.filter(c => c.tile.repoFile === `art/bakeoff/${rel}`);
	need(matches.length === 1 && matches[0].tile.isNew, `changes.json new path not shown once: ${rel}`);
	need(rowAdded.includes(`art/bakeoff/${rel}`), `New entry not added since checkpoint: ${rel}`);
	const { row } = matches[0], replaces = `art/bakeoff/${entry.replaces}`;
	need(existsSync(join(repo, replaces)), `Wrong replaces path (changes.json unchanged): ${entry.replaces}`);
	const alongside = row.panels.some(p => p.tiles.some(t => t.repoFile === replaces));
	const metaPath = join(repo, replaces.replace(/\.png$/, ".json"));
	const adopted = existsSync(metaPath) && json(metaPath).adopted;
	need(alongside || (adopted && row.hasGame), `Replacement is not next to old/adopted game row: ${rel}`);
}
for (const entry of changes.no_new_version) need(rows.some(r => r.key === keyOf(entry.kind, entry.id, entry.row) && r.noNewText === entry.text), `Missing no-new row: ${entry.id}/${entry.row}`);
const counts = { rows: rows.length, newRows: rows.filter(r => r.newCount > 0).length, gameRepairs: rows.filter(r => r.gameRepair).length, noNewRows: rows.filter(r => r.noNewText).length,
	newCandidates: Object.keys(changes.new).length, candidates: new Set(candidates.filter(c => c.row.kind !== "legacy_sheet").map(c => c.tile.file)).size, legacyPairs: Object.keys(changes.legacy).length };
const manifest = { commit: git("rev-parse", "HEAD"), built: new Date().toISOString(), checkpoint: changes.checkpoint,
	changesSha256: createHash("sha256").update(readFileSync(join(here, "changes.json"))).digest("hex"), counts, groups, rows,
	audit: { addedCandidates: rowAdded.length, excludedAssemblies: assemblies.length, legacyAdded: legacyAdded.length } };
const template = read(join(here, "index.html"));
need(template.includes("/*MANIFEST*/null"), "Missing manifest placeholder");
const html = template.replace("/*MANIFEST*/null", JSON.stringify(manifest).replaceAll("<", "\\u003c"));
// Resolve and verify before every recursive removal; no cross-shell file operations.
need(dist === resolve(repo, "tools/compare_viewer/dist"), "Unsafe dist removal");
rmSync(dist, { recursive: true, force: true }); mkdirSync(dist, { recursive: true });
for (const [file, source] of files) { const target = join(dist, file); mkdirSync(dirname(target), { recursive: true }); copyFileSync(join(repo, source), target); }
writeFileSync(join(dist, "index.html"), html);
// Sidecar lists exclude HTML, as the publisher supplies it separately. Reserve one
// file slot AND its bytes in every request (249 sidecars + HTML <= 250).
const htmlBytes = Buffer.byteLength(html), batches = []; let batch = [], bytes = htmlBytes;
for (const file of files.keys()) {
	const size = statSync(join(dist, file)).size;
	need(size + htmlBytes <= 60_000_000, `Asset exceeds request limit: ${file}`);
	if (batch.length >= 249 || bytes + size > 60_000_000) { batches.push(batch); batch = []; bytes = htmlBytes; }
	batch.push({ path: file }); bytes += size;
}
if (batch.length) batches.push(batch);
writeFileSync(join(dist, "files.json"), JSON.stringify([...files.keys()].map(path => ({ path }))) + "\n");
batches.forEach((b, i) => writeFileSync(join(dist, `files-${i + 1}.json`), JSON.stringify(b) + "\n"));
const publish = { files: files.size + 1, bytes: htmlBytes + [...files.keys()].reduce((n, p) => n + statSync(join(dist, p)).size, 0), batches: batches.length };
publish.versionFits = publish.files <= 511 && publish.bytes <= 256_000_000;
console.log(`compare viewer: rows ${counts.rows}, rows with new versions ${counts.newRows}, game-repair comparisons ${counts.gameRepairs}, no-new rows ${counts.noNewRows}`);
console.log(`candidates ${counts.candidates} (${counts.newCandidates} new), legacy pairs ${counts.legacyPairs}; checkpoint additions ${rowAdded.length}, excluded assemblies ${assemblies.length}`);
console.log(`publish: files ${publish.files}, bytes ${publish.bytes}, batches ${publish.batches}; one Artifact version fits: ${publish.versionFits}`);
console.log(`전체 ${counts.rows}줄 · 옛·새 나란히 ${counts.newRows}줄 · 게임 시트 수리본 비교 ${counts.gameRepairs} · 새 버전 없음 ${counts.noNewRows}줄`);
