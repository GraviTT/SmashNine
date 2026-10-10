// Builds the motion viewer into tools/motion_viewer/dist/: index.html with the manifest
// inlined, plus every fighter and monster sheet under dist/sheets/. Row tables come from the
// game code (PlayerBase ORIGINAL_SHEET_ROWS, each character's MOVE_SHEET_ROWS, RealmMonster
// ART_ROWS), move labels from the *_moves_README.md tables, so the viewer slices sheets the way
// the game does. Run from the repo root: node tools/motion_viewer/build.mjs
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync, readdirSync, rmSync } from "node:fs";
import { join, dirname } from "node:path";
import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "..", "..");
const game = join(repo, "smash-nine-prototype");
const art = join(game, "assets", "art");
const dist = join(here, "dist");

const read = (p) => readFileSync(p, "utf8");

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

const sheets = []; // [src relative to assets/art]
function sheet(rel, rows, labels, cell, feet) {
	if (!existsSync(join(art, rel))) return null;
	sheets.push(rel);
	return { file: `sheets/${rel}`, cell, feet, rows: rows.map((r) => ({ ...r, label: labels[r.name] || "" })) };
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
	const forms = [];
	for (const body of bodies) {
		const stem = body ? `${c.id}_${body}` : c.id;
		const base = sheet(`${folder}/${stem}_sheet.png`, baseRows, BASE_LABELS, 128, 120);
		const moves = sheet(`${folder}/${stem}_moves_sheet.png`, moveRows, moveLabels(join(art, folder, `${stem}_moves_README.md`)), 128, 120);
		forms.push({ body, base, moves });
	}
	characters.push({ id: c.id, name: c.name, forms });
}

const monsters = [];
for (const f of readdirSync(join(art, "monsters")).filter((f) => f.endsWith("_sheet.png") && !f.includes("source")).sort()) {
	const id = f.replace(/_sheet\.png$/, "");
	const [realm, ...rest] = id.split("_");
	const generic = id === "mossling" || id === "ember_imp";
	monsters.push({
		id,
		realm: generic ? "공용" : realm[0].toUpperCase() + realm.slice(1),
		name: (generic ? id : rest.join(" ")).replace(/_/g, " "),
		base: sheet(`monsters/${f}`, monsterRows, { idle: "대기", walk: "걷기", attack: "공격", hurt: "피격" }, 96, 72),
	});
}

let commit = "";
try { commit = execSync("git rev-parse --short HEAD", { cwd: repo }).toString().trim(); } catch {}
const now = new Date();
const pad = (n) => String(n).padStart(2, "0");
const built = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}`;
const manifest = { built, commit, columns: 6, characters, monsters };

rmSync(dist, { recursive: true, force: true });
for (const rel of sheets) {
	const to = join(dist, "sheets", rel);
	mkdirSync(dirname(to), { recursive: true });
	copyFileSync(join(art, rel), to);
}
const html = read(join(here, "index.html")).replace("/*MANIFEST*/null", JSON.stringify(manifest));
writeFileSync(join(dist, "index.html"), html);
writeFileSync(join(dist, "files.json"), JSON.stringify(sheets.map((rel) => ({ path: `sheets/${rel}` }))));
const moveRowCount = characters.reduce((n, c) => n + c.forms.reduce((m, f) => m + (f.moves ? f.moves.rows.length : 0), 0), 0);
console.log(`motion viewer: ${characters.length} fighters, ${monsters.length} monsters, ${sheets.length} sheets, ${moveRowCount} move rows -> ${dist}`);
