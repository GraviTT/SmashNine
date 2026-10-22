// Builds the motion viewer into tools/motion_viewer/dist/: index.html with the manifest
// inlined, plus every fighter and monster sheet under dist/sheets/. Row tables come from the
// game code (PlayerBase ORIGINAL_SHEET_ROWS, each character's MOVE_SHEET_ROWS, RealmMonster
// ART_ROWS), move labels from the *_moves_README.md tables, so the viewer slices sheets the way
// the game does. Run from the repo root: node tools/motion_viewer/build.mjs
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync, readdirSync, rmSync } from "node:fs";
import { join, dirname, basename, relative, resolve } from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { writePublishFiles } from "./publish-files.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "..", "..");
const game = join(repo, "smash-nine-prototype");
const art = join(game, "assets", "art");
const bakeoffRoot = join(repo, "art", "bakeoff");
const clipsRoot = join(repo, "art", "clips");
const dist = resolve(here, "dist");
if (dist !== resolve(repo, "tools/motion_viewer/dist")) throw new Error(`unexpected build output directory: ${dist}`);

const read = (p) => readFileSync(p, "utf8");

let clipManifest = { clips: [] };
try {
	const path = join(clipsRoot, "manifest.json");
	if (existsSync(path)) clipManifest = JSON.parse(read(path));
} catch (error) {
	console.warn(`invalid clip manifest: ${error.message}`);
}
// Clips captured with candidate effects installed (art/clips-new, same layout) become the viewer's
// third effect mode, next to "off" and today's effects.
const newClipsRoot = join(repo, "art", "clips-new");
try {
	const path = join(newClipsRoot, "manifest.json");
	const fresh = existsSync(path) ? JSON.parse(read(path)).clips || [] : [];
	const byMove = new Map(fresh.map((clip) => [`${clip.form}/${clip.move}`, clip]));
	for (const clip of clipManifest.clips || []) {
		const match = byMove.get(`${clip.form}/${clip.move}`);
		if (match && match.files && match.files.fx) clip.newFx = match.files.fx;
	}
} catch (error) {
	console.warn(`invalid candidate clip manifest: ${error.message}`);
}
const clipsFor = (form) => (clipManifest.clips || []).filter((clip) => clip.form === form);

// Speeds the user adopted and the game plays (characters/common/MotionSpeeds.gd, written by
// apply_speeds.py from the viewer's motion_speeds records): "<id>/<body|default>/<row>" -> fps.
const motionSpeeds = new Map();
{
	const path = join(game, "characters", "common", "MotionSpeeds.gd");
	if (existsSync(path)) for (const m of read(path).matchAll(/"([a-z0-9_]+\/[a-z]+\/[a-z0-9_]+)":\s*([\d.]+)/g)) motionSpeeds.set(m[1], +m[2]);
}
// A row the game plays at an adopted speed shows that speed; drawnFps keeps the table's.
function applySpeeds(id, body, sheetData) {
	if (!sheetData) return;
	for (const row of sheetData.rows) {
		const fps = motionSpeeds.get(`${id}/${body || "default"}/${row.name}`);
		if (fps && Math.abs(fps - row.fps) > 0.001) { row.drawnFps = row.fps; row.fps = fps; }
	}
}

// const NAME := [ ["row", frames, fps, loop], ... ]
function rowTable(file, constName) {
	const src = read(file);
	const start = src.indexOf(`const ${constName} := [`);
	if (start < 0) return [];
	let depth = 0, end = start;
	for (let i = src.indexOf("[", start); i < src.length; i++) {
		if (src[i] === "[") depth++;
		if (src[i] === "]" && --depth === 0) { end = i; break; }
	}
	const rows = [];
	const re = /\[\s*"([a-z0-9_]+)"\s*,\s*(\d+)\s*,\s*([\d.]+)\s*,\s*(true|false)\s*\]/g;
	for (const m of src.slice(start, end + 1).matchAll(re)) {
		rows.push({ name: m[1], frames: +m[2], fps: +m[3], loop: m[4] === "true" });
	}
	return rows;
}

// Move labels from a README table: the first `backticked` cell is the row, the column whose
// header says "Move" (or "Input and move") is the label.
function moveLabels(readme) {
	const labels = {};
	if (!existsSync(readme)) return labels;
	let moveCol = -1;
	for (const line of read(readme).split(/\r?\n/)) {
		if (!line.trim().startsWith("|")) { moveCol = -1; continue; }
		const cells = line.split("|").slice(1, -1).map((c) => c.trim());
		if (moveCol < 0) {
			moveCol = cells.findIndex((c) => /input and move/i.test(c));
			if (moveCol < 0) moveCol = cells.findIndex((c) => /^move$/i.test(c));
			continue;
		}
		const name = (line.match(/`([a-z0-9_]+)`/) || [])[1];
		if (name && cells[moveCol] && !/^-+:?$/.test(cells[moveCol])) labels[name] = cells[moveCol].replace(/`/g, "");
	}
	return labels;
}

const BASE_LABELS = { idle: "대기", walk: "걷기", jump: "점프", fall: "낙하", attack: "공격 (공용 4칸)", shield: "방어", hurt: "피격" };
const baseRows = rowTable(join(game, "characters/common/PlayerBase.gd"), "ORIGINAL_SHEET_ROWS");
const monsterRows = rowTable(join(game, "scripts/RealmMonster.gd"), "ART_ROWS");

function allFiles(root) {
	if (!existsSync(root)) return [];
	return readdirSync(root, { withFileTypes: true }).flatMap((entry) => {
		const path = join(root, entry.name);
		return entry.isDirectory() ? allFiles(path) : [path];
	});
}

// Candidates moved to a "retired" folder stay in the repo but leave the viewer.
const candidateFiles = allFiles(bakeoffRoot).filter((path) => path.toLowerCase().endsWith(".png") && !/[\\/]retired[\\/]/.test(path));
function candidateFrom(path, version) {
	const metaPath = path.replace(/\.png$/i, ".json");
	let meta = {};
	try { if (existsSync(metaPath)) meta = JSON.parse(read(metaPath)); }
	catch (error) { throw new Error(`invalid candidate metadata: ${metaPath}: ${error.message}`); }
	if (meta.adopted) return null;
	const rel = relative(bakeoffRoot, path).replaceAll("\\", "/");
	return { file: `bakeoff/${rel}`, version, note: String(meta.note || ""), fps: Number(meta.fps) || null,
		frames: Number(meta.frames) || null, cell: meta.cell || null, feet: Number(meta.feet) || null,
		loop: typeof meta.loop === "boolean" ? meta.loop : null, source: path };
}
function candidatesFor(stem, row) {
	const prefix = `${stem}-${row}-v`;
	return candidateFiles.flatMap((path) => {
		const file = basename(path);
		if (!file.startsWith(prefix) || !/\.png$/i.test(file)) return [];
		const version = file.slice(prefix.length, -4);
		if (!/^\d+$/.test(version)) return [];
		const candidate = candidateFrom(path, `v${version}`);
		return candidate ? [candidate] : [];
	}).sort((a, b) => a.version.localeCompare(b.version, undefined, { numeric: true }));
}

// Cell size from the PNG header: six columns (128 base sheets, 192 move sheets since D34).
const cellOf = (rel) => existsSync(join(art, rel)) ? readFileSync(join(art, rel)).readUInt32BE(16) / 6 : 128;

// Row names that have candidates (<stem>-<row>-vN.png) but are not in the game's tables.
function newRowNames(stem, known) {
	const names = new Set();
	for (const path of candidateFiles) {
		const file = basename(path);
		if (!file.startsWith(`${stem}-`)) continue;
		const rest = file.slice(stem.length + 1, -4), at = rest.lastIndexOf("-v");
		const row = at > 0 ? rest.slice(0, at) : "";
		if (row && row !== "projectile" && /^[a-z0-9_]+$/.test(row) && /^\d+$/.test(rest.slice(at + 2)) && !known.has(row)) names.add(row);
	}
	return [...names].sort();
}

const sheets = []; // [src relative to assets/art]
const candidateCopies = [];
function sheet(rel, rows, labels, cell, feet, stem = null) {
	if (!existsSync(join(art, rel))) return null;
	sheets.push(rel);
	// A row longer than six frames continues on the next sheet row (Luna's 12-frame transform).
	let start = 0;
	return { file: `sheets/${rel}`, cell, feet, rows: rows.map((r) => {
		const at = start; start += Math.ceil(r.frames / 6);
		const candidates = stem ? candidatesFor(stem, r.name) : [];
		candidateCopies.push(...candidates);
		return { ...r, start: at, label: labels[r.name] || "", candidates: candidates.map(({ source, ...item }) => item) };
	}) };
}

const CHARACTERS = [
	{ id: "frey", name: "Frey", script: "frey/Frey.gd" },
	{ id: "luna", name: "Luna", script: "luna/Luna.gd" },
	{ id: "luna_brave", name: "Brave Luna", script: "luna/Luna.gd", moveConst: "BRAVE_MOVE_SHEET_ROWS", folder: "luna", bodies: [""] },
	{ id: "nova", name: "Nova", script: "nova/Nova.gd" },
	{ id: "rio", name: "Rio", script: "rio/Rio.gd" },
	{ id: "yuki", name: "Yuki", script: "yuki/Yuki.gd" },
];

const characters = [];
for (const c of CHARACTERS) {
	const folder = c.folder || c.id;
	let bodies = c.bodies;
	if (!bodies) {
		const data = read(join(game, "characters", c.id, `${c.id[0].toUpperCase()}${c.id.slice(1)}Data.gd`));
		const list = (data.match(/"bodies":\s*\[([^\]]*)\]/) || [])[1] || "";
		bodies = [...list.matchAll(/"(\w+)"/g)].map((m) => m[1]);
		// One body: the sheet carries no body suffix.
		if (bodies.length <= 1) bodies = [""];
	}
	const moveRows = rowTable(join(game, "characters", c.script), c.moveConst || "MOVE_SHEET_ROWS");
	// A redrawn character has its own base table (Frey.SHEET_ROWS, D33); its J chain is a move row.
	const ownBase = rowTable(join(game, "characters", c.script), c.baseConst || "SHEET_ROWS");
	const forms = [];
	for (const body of bodies) {
		const stem = body ? `${c.id}_${body}` : c.id;
		const basePath = `${folder}/${stem}_sheet.png`, movePath = `${folder}/${stem}_moves_sheet.png`;
		const bc = cellOf(basePath), mc = cellOf(movePath);
		const base = sheet(basePath, ownBase.length ? ownBase : baseRows, ownBase.length ? { ...BASE_LABELS, attack: "공격 (예비 줄)" } : BASE_LABELS, bc, bc / 2 + 56, stem);
		const moves = sheet(movePath, moveRows, moveLabels(join(art, folder, `${stem}_moves_README.md`)), mc, mc / 2 + 56, stem);
		// Candidates for a move the game has no row for yet (e.g. Yuki's tumble) show as new rows.
		if (moves) {
			const known = new Set([...(base ? base.rows : []), ...moves.rows].map((r) => r.name));
			for (const row of newRowNames(stem, known)) {
				const candidates = candidatesFor(stem, row);
				if (!candidates.length) continue;
				candidateCopies.push(...candidates);
				const first = candidates[0];
				moves.rows.push({ name: row, frames: first.frames || 6, fps: first.fps || 12, loop: row === "tumble", start: null, newRow: true, label: "새 줄 — 게임에 아직 없음", candidates: candidates.map(({ source, ...item }) => item) });
			}
		}
		applySpeeds(c.id, body, base); applySpeeds(c.id, body, moves);
		forms.push({ body, base, moves, clips: clipsFor(c.id) });
	}
	characters.push({ id: c.id, name: c.name, forms });
}

const monsters = [];
for (const f of readdirSync(join(art, "monsters")).filter((f) => f.endsWith("_sheet.png") && !f.includes("source")).sort()) {
	const id = f.replace(/_sheet\.png$/, "");
	const [realm, ...rest] = id.split("_");
	const generic = id === "mossling" || id === "ember_imp";
	const labels = { idle: "대기", walk: "이동", windup: "준비 — 마지막 자세 유지", attack: "공격", hurt: "피격", defeat: "쓰러짐" };
	const base = sheet(`monsters/${f}`, monsterRows, labels, 96, 72, id);
	const known = new Set(base.rows.map((r) => r.name));
	const extraRows = newRowNames(id, known).sort((a, b) => ["windup", "defeat"].indexOf(a) - ["windup", "defeat"].indexOf(b));
	for (const row of extraRows) {
		const candidates = candidatesFor(id, row);
		if (!candidates.length) continue;
		candidateCopies.push(...candidates);
		const first = candidates[0];
		base.rows.push({ name: row, frames: first.frames || 4, fps: first.fps || 8, loop: first.loop ?? false, start: null, newRow: true, label: `${labels[row] || row} · 새 줄 — 게임에 아직 없음`, candidates: candidates.map(({ source, ...item }) => item) });
	}
	// Keep the game's physical row indices, but display anticipation before the action.
	const displayOrder = ["idle", "walk", "windup", "attack", "hurt", "defeat"];
	base.rows.sort((a, b) => displayOrder.indexOf(a.name) - displayOrder.indexOf(b.name));
	monsters.push({
		id,
		realm: generic ? "공용" : realm[0].toUpperCase() + realm.slice(1),
		name: (generic ? id : rest.join(" ")).replace(/_/g, " "),
		base,
	});
}

let commit = "";
try { commit = execSync("git rev-parse --short HEAD", { cwd: repo }).toString().trim(); } catch {}
const now = new Date();
const pad = (n) => String(n).padStart(2, "0");
const built = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
// Pick IDs use the form's sheet stem (nova_male / nova_female stay independent).
const tagPick = (candidate, kind, id, row) => {
	candidate.pick = { kind, id, row, version: candidate.version, file: `art/${candidate.file}` };
	return candidate;
};
for (const c of characters) for (const f of c.forms) for (const s of [f.base, f.moves].filter(Boolean))
	for (const r of s.rows) for (const candidate of r.candidates) tagPick(candidate, "fighter", f.body ? `${c.id}_${f.body}` : c.id, r.name);
for (const m of monsters) for (const r of m.base.rows) for (const candidate of r.candidates) tagPick(candidate, "monster", m.id, r.name);

const extraCopies = [];
const PROJECTILE_NAMES = { ember_imp: "불덩이", niflheim_frost_owl: "얼음 파편", jotunheim_storm_wisp: "번개",
	midgard_rooftop_slinger: "투석", vanaheim_seed_sprite: "씨앗", svartalfheim_cog_drone: "폭탄", yggdrasil_root_oracle: "유도 구체", slam_shockwave: "공용 지면 충격파" };
const projectiles = [];
for (const path of candidateFiles) {
	if (relative(bakeoffRoot, path).replaceAll("\\", "/").split("/")[0] !== "monsters") continue;
	const match = basename(path).match(/^(?:(.+)-projectile|(slam_shockwave))-v(\d+)\.png$/);
	if (!match) continue;
	const id = match[1] || match[2], candidate = candidateFrom(path, `v${match[3]}`);
	if (!candidate) continue;
	if (!candidate.frames || !candidate.fps || !candidate.cell) throw new Error(`projectile timing/cell missing: ${path}`);
	const cell = Array.isArray(candidate.cell) ? candidate.cell : [candidate.cell, candidate.cell];
	if (!Number.isInteger(candidate.frames) || candidate.frames < 1 || !Number.isFinite(candidate.fps) || candidate.fps <= 0 || cell.length !== 2 || cell.some(n => !Number.isInteger(n) || n < 1)) throw new Error(`invalid projectile metadata: ${path}`);
	const data = readFileSync(path);
	if (data.readUInt32BE(16) !== cell[0] * candidate.frames || data.readUInt32BE(20) !== cell[1]) throw new Error(`invalid projectile strip: ${path}`);
	candidateCopies.push(candidate);
	const { source, ...item } = tagPick(candidate, "projectile", id, id === "slam_shockwave" ? "shockwave" : "projectile");
	let current = null;
	if (id !== "slam_shockwave") {
		const rel = `monsters/${id === "ember_imp" ? "ember_fireball" : `${id}_projectile`}.png`;
		if (!existsSync(join(art, rel))) throw new Error(`current projectile missing: ${rel}`);
		current = `current/${rel}`; extraCopies.push({ source: join(art, rel), file: current });
	}
	projectiles.push({ id, name: PROJECTILE_NAMES[id] || id, current, ...item });
}
projectiles.sort((a, b) => a.id.localeCompare(b.id) || a.version.localeCompare(b.version, undefined, { numeric: true }));

const portraits = [];
for (const c of characters) for (const f of c.forms) {
	const stem = f.body ? `${c.id}_${f.body}` : c.id, folder = c.id === "luna_brave" ? "luna" : c.id;
	const rel = `${folder}/${stem}_face.png`, current = `current/${rel}`;
	if (!existsSync(join(art, rel))) throw new Error(`neutral portrait missing: ${rel}`);
	extraCopies.push({ source: join(art, rel), file: current });
	const candidates = ["happy", "angry", "hurt", "shadow"].flatMap(expression => candidatesFor(`${stem}_face`, expression).map(candidate => {
		candidateCopies.push(candidate);
		const { source, ...item } = tagPick(candidate, "face", stem, expression);
		return item;
	}));
	portraits.push({ id: stem, name: `${c.name}${f.body ? f.body === "male" ? " 남성" : " 여성" : ""}`, current, candidates });
}
const manifest = { built, commit, columns: 6, characters, monsters, projectiles, portraits };

rmSync(dist, { recursive: true, force: true });
for (const rel of sheets) {
	const to = join(dist, "sheets", rel);
	mkdirSync(dirname(to), { recursive: true });
	copyFileSync(join(art, rel), to);
}
for (const candidate of new Map(candidateCopies.map((item) => [item.file, item])).values()) {
	const to = join(dist, candidate.file);
	mkdirSync(dirname(to), { recursive: true });
	copyFileSync(candidate.source, to);
}
for (const item of extraCopies) {
	const to = join(dist, item.file); mkdirSync(dirname(to), { recursive: true }); copyFileSync(item.source, to);
}
const clipCopies = [];
for (const clip of clipManifest.clips || []) {
	for (const rel of Object.values(clip.files || {})) {
		const source = join(clipsRoot, rel), to = join(dist, "clips", rel);
		if (!existsSync(source)) throw new Error(`clip missing: ${source}`);
		mkdirSync(dirname(to), { recursive: true });
		copyFileSync(source, to);
		clipCopies.push(`clips/${rel.replaceAll("\\", "/")}`);
	}
	if (clip.newFx) {
		const source = join(newClipsRoot, clip.newFx), to = join(dist, "clips-new", clip.newFx);
		if (!existsSync(source)) throw new Error(`candidate clip missing: ${source}`);
		mkdirSync(dirname(to), { recursive: true });
		copyFileSync(source, to);
		clipCopies.push(`clips-new/${clip.newFx.replaceAll("\\", "/")}`);
	}
}
const template = read(join(here, "index.html"));
if (!template.includes("/*MANIFEST*/null")) throw new Error("viewer manifest placeholder missing");
const html = template.replace("/*MANIFEST*/null", JSON.stringify(manifest).replaceAll("<", "\\u003c"));
writeFileSync(join(dist, "index.html"), html);
const published = [...sheets.map((rel) => `sheets/${rel}`), ...candidateCopies.map(item => item.file), ...extraCopies.map(item => item.file), ...clipCopies];
const publish = writePublishFiles(dist, published);
console.log(`publish: ${publish.publishFiles} files including HTML, ${publish.publishBytes} bytes, ${publish.batches} batches; version fits: ${publish.versionFits}`);
const moveRowCount = characters.reduce((n, c) => n + c.forms.reduce((m, f) => m + (f.moves ? f.moves.rows.length : 0), 0), 0);
console.log(`motion viewer: ${characters.length} fighters, ${monsters.length} monsters, ${sheets.length} sheets, ${moveRowCount} move rows, ${new Set(candidateCopies.map((item) => item.file)).size} candidates, ${clipCopies.length} clips -> ${dist}`);
