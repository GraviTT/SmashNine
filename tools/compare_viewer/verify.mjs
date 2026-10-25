// Offline source/file checks and JS behavior in mocks. No browser, network, Godot,
// image decoding, CSS layout engine or hosted Artifact service is involved.
import assert from "node:assert/strict";
import vm from "node:vm";
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync, mkdirSync } from "node:fs";
import { join, dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";

const here = dirname(fileURLToPath(import.meta.url)), repo = resolve(here, "../.."), dist = join(here, "dist"), report = join(repo, "reports/codex-tool-04");
const read = p => readFileSync(p, "utf8"), json = p => JSON.parse(read(p));
const html = read(join(dist, "index.html")), script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const M = JSON.parse(script.match(/^const M = (.+);$/m)[1]);
const motion = JSON.parse(read(join(repo, "tools/motion_viewer/dist/index.html")).match(/^const M = (.+);$/m)[1]);
const changes = json(join(here, "changes.json"));
const checks = [];
const checked = (name, scope, detail) => { checks.push({ name, result: "PASS", scope, detail }); console.log(`PASS ${name}`); };
const settle = () => new Promise(resolve => setImmediate(resolve));
const copy = value => JSON.parse(JSON.stringify(value));
const tilesOf = r => r.panels.flatMap(p => p.tiles);
const candidates = M.rows.filter(r => r.kind !== "legacy_sheet").flatMap(r => tilesOf(r).filter(t => t.role === "candidate").map(t => ({ row: r, tile: t })));
const sha = p => createHash("sha256").update(readFileSync(p)).digest("hex");
const rowKey = x => `${x.kind}~${x.id}~${x.row}`;
const scan = root => readdirSync(root, { withFileTypes: true }).flatMap(e => e.isDirectory() ? e.name === "retired" ? [] : scan(join(root, e.name)) : [join(root, e.name)]);

class Element {
	constructor(tag = "div") { this.tagName = tag.toUpperCase(); this.children = []; this.events = {}; this.attributes = {}; this.dataset = {}; this.style = {}; this._text = ""; this.value = ""; this.hidden = false; this.disabled = false; this.checked = false; this.draws = []; }
	get textContent() { return this._text + this.children.map(n => typeof n === "string" ? n : n.textContent).join(""); }
	set textContent(value) { this._text = String(value); this.children = []; }
	append(...nodes) { this.children.push(...nodes); }
	replaceChildren(...nodes) { this._text = ""; this.children = [...nodes]; }
	setAttribute(name, value) { this.attributes[name] = String(value); }
	getAttribute(name) { return this.attributes[name] ?? null; }
	addEventListener(name, fn) { (this.events[name] ??= []).push(fn); }
	async fire(name, extra = {}) { if (this.disabled) return; for (const fn of this.events[name] || []) await fn({ target: this, preventDefault() {}, ...extra }); }
	cloneNode() { const node = new Element(this.tagName); for (const key of ["src", "alt", "width", "height"]) node[key] = this[key]; return node; }
	getContext() { return this.context ??= { clearRect() {}, beginPath() {}, moveTo() {}, lineTo() {}, stroke() {}, drawImage: (...args) => this.draws.push(args) }; }
	getBoundingClientRect() { return { top: 2000, bottom: 2300 }; }
	scrollIntoView() { this.scrolled = true; }
	focus() { this.focused = true; }
}
const walk = e => e.children.flatMap(n => n instanceof Element ? [n, ...walk(n)] : []);
function environment({ withDb = false, nullDb = false, rejectDb = false, persisted = new Map(), reduced = false, noObserver = false } = {}) {
	const roots = Object.fromEntries([...html.matchAll(/\bid="([^"]+)"/g)].map(([, id]) => { const e = new Element(); e.id = id; return [id, e]; }));
	let callbacks, subscriptions = 0, useCalls = 0, failed = false, hold = null;
	const writes = [], loads = [], frames = [], observers = [], documentEvents = {}, windowEvents = {};
	const snapshot = () => ({ docs: [...persisted].map(([id, value]) => ({ id, exists: true, data: () => value })) });
	const database = { collection(name) {
		assert.equal(name, "candidate_picks");
		return { onSnapshot(next, error) { subscriptions++; callbacks = { next, error }; next(snapshot()); }, doc(id) { return { async set(value) {
			if (hold) await hold;
			if (failed) throw new Error("Intentional mock write failure");
			writes.push({ collection: name, id, value: copy(value) }); persisted.set(id, copy(value)); callbacks.next(snapshot());
		} }; } };
	} };
	class MockImage extends Element {
		constructor() { super("img"); }
		set src(file) { this._src = file; loads.push(file); const bytes = readFileSync(join(dist, file)); this.naturalWidth = bytes.readUInt32BE(16); this.naturalHeight = bytes.readUInt32BE(20); this.complete = true; for (const fn of this.events.load || []) fn(); }
		get src() { return this._src; }
	}
	class MockObserver {
		constructor(fn, options) { this.fn = fn; this.options = options; this.targets = new Set(); observers.push(this); }
		observe(e) { this.targets.add(e); } unobserve(e) { this.targets.delete(e); }
		emit(e, isIntersecting) { this.fn([{ target: e, isIntersecting }]); }
	}
	const document = { hidden: false, getElementById: id => { assert.ok(roots[id], `Unknown static ID: ${id}`); return roots[id]; }, createElement: tag => new Element(tag), addEventListener: (n,f) => documentEvents[n] = f };
	const window = { innerHeight: 800, addEventListener: (n,f) => windowEvents[n] = f };
	if (withDb) window.claude = { async use(name) { useCalls++; assert.equal(name, "db"); if (rejectDb) throw new Error("Intentional DB rejection"); return nullDb ? null : database; } };
	const context = vm.createContext({ document, window, Image: MockImage, ...(noObserver ? {} : { IntersectionObserver: MockObserver }), matchMedia: () => ({ matches: reduced }),
		requestAnimationFrame: fn => { frames.push(fn); return frames.length; }, getComputedStyle: () => ({ getPropertyValue: () => "#08889e" }), console });
	vm.runInContext(script, context);
	const run = code => vm.runInContext(code, context);
	return { run, roots, writes, loads, frames, persisted, observers, document, documentEvents, windowEvents,
		get subscriptions() { return subscriptions; }, get useCalls() { return useCalls; }, fail: v => failed = v, hold: promise => hold = promise,
		emit: () => callbacks.next(snapshot()), disconnect: () => callbacks.error(), near: (key, yes = true) => observers[0].emit(run(`views.get(${JSON.stringify(key)}).root`), yes) };
}

let summary = {};
try {
	// Independent filesystem discovery, not just counting the build's array.
	const stems = motion.characters.flatMap(c => c.forms.map(f => f.body ? `${c.id}_${f.body}` : c.id)), monsters = motion.monsters.map(m => m.id);
	const expected = [];
	for (const path of scan(join(repo, "art/bakeoff"))) {
		const file = path.replaceAll("\\", "/"), name = file.split("/").at(-1);
		if (!/-v\d+\.png$/.test(name)) continue;
		const row = [...stems, ...monsters].some(stem => name.startsWith(`${stem}-`) && /^[a-z0-9_]+-v\d+\.png$/.test(name.slice(stem.length + 1)));
		const face = stems.some(stem => new RegExp(`^${stem}_face-(happy|angry|hurt|shadow)-v\\d+\\.png$`).test(name));
		if (!row && !face && !/^slam_shockwave-v\d+\.png$/.test(name)) continue;
		const meta = path.replace(/\.png$/, ".json"); if (!existsSync(meta) || !json(meta).adopted) expected.push(file.slice(repo.length + 1));
	}
	assert.deepEqual(candidates.map(c => c.tile.repoFile).sort(), expected.sort());
	assert.equal(new Set(M.rows.map(r => r.key)).size, M.rows.length);
	assert.ok(M.rows.every(r => r.options.length > 1 && new Set(r.options).size === r.options.length));
	checked("candidate-coverage", "files", `${expected.length} active pickable candidates, each in exactly one row; adopted/retired excluded`);

	const additions = execFileSync("git", ["diff", "--name-status", changes.checkpoint, "HEAD", "--", "art/bakeoff"], { cwd: repo, encoding: "utf8" }).split(/\r?\n/).filter(l => l.startsWith("A\t") && l.endsWith(".png")).map(l => l.slice(2));
	const assemblies = additions.filter(p => /_sheet-v2\.png$/.test(p)), legacyAdded = additions.filter(p => p.includes("/legacy/"));
	assert.deepEqual(additions.filter(p => !assemblies.includes(p) && !legacyAdded.includes(p)).sort(), Object.keys(changes.new).map(p => `art/bakeoff/${p}`).sort());
	for (const [rel, entry] of Object.entries(changes.new)) {
		const matches = candidates.filter(c => c.tile.repoFile === `art/bakeoff/${rel}`); assert.equal(matches.length, 1);
		const { row, tile } = matches[0]; assert.ok(tile.isNew); assert.equal(tile.card, entry.card); assert.equal(tile.change, entry.change);
		const oldPath = `art/bakeoff/${entry.replaces}`, oldMeta = join(repo, oldPath.replace(/\.png$/, ".json"));
		assert.ok(tilesOf(row).some(t => t.repoFile === oldPath) || (existsSync(oldMeta) && json(oldMeta).adopted && tilesOf(row).some(t => t.role === "game")), rel);
	}
	assert.equal(M.changesSha256, sha(join(here, "changes.json")));
	assert.equal(Object.keys(changes.new).length, 66); assert.equal(assemblies.length, 16); assert.equal(legacyAdded.length, 15);
	checked("checkpoint-and-correspondence", "git/files", "66 new PNGs exactly match changes.json; each is beside replaces/adopted game tile; 16 assemblies and 15 legacy sheets separately accounted for; authored text retained");

	const rawRows = JSON.parse(read(join(repo, "smash-nine-prototype/scripts/RealmMonster.gd")).match(/^const ART_ROWS := (.+)$/m)[1]);
	const legacyRows = M.rows.filter(r => r.kind === "legacy_sheet"); assert.equal(legacyRows.length, 15);
	for (const r of legacyRows) {
		assert.equal(r.panels.length, rawRows.length); const change = changes.legacy[r.id];
		assert.deepEqual(r.qa, change.qa); assert.equal(r.change, change.change);
		for (let i = 0; i < rawRows.length; i++) { const [, frames, fps, loop] = rawRows[i], p = r.panels[i];
			assert.equal(p.fps, fps); assert.equal(p.loop, loop); assert.equal(p.tiles.length, 2);
			for (const t of p.tiles) { assert.equal(t.frames, frames); assert.equal(t.start, i); }
			assert.equal(p.tiles[0].repoFile, change.replaces); assert.equal(p.tiles[1].repoFile, `art/bakeoff/${change.file}`);
		}
	}
	for (const entry of changes.no_new_version) assert.equal(M.rows.find(r => r.key === rowKey(entry)).noNewText, entry.text);
	assert.equal(M.rows.filter(r => r.noNewText).length, 5);
	const wave = M.rows.find(r => r.key === "projectile~yggdrasil_root_guardian~shockwave"); assert.ok(wave);
	assert.deepEqual(wave.options, ["v1", "none"]); assert.equal(wave.panels[0].tiles[0].role, "reference"); assert.equal(wave.panels[0].tiles[0].label, "비교용: 공용 v1");
	assert.ok(!M.rows.some(r => r.key === "monster~yggdrasil_root_guardian~shockwave"));
	checked("legacy-no-new-and-guardian", "files", "15 pairs × 4 ART_ROWS; 5 no-new texts (including two rows that also have partial repairs); guardian is one projectile row with non-option reference");

	for (const c of motion.characters) for (const f of c.forms) for (const s of [f.base,f.moves].filter(Boolean)) for (const source of s.rows.filter(r => r.candidates.length)) {
		const id = f.body ? `${c.id}_${f.body}` : c.id, r = M.rows.find(r => r.key === `fighter~${id}~${source.name}`);
		const newest = [...source.candidates].sort((a,b) => Number(a.version.slice(1)) - Number(b.version.slice(1))).at(-1);
		// New rows and one-frame game rows (still poses with a placeholder fps) play at the candidates' own timing.
		const own = source.newRow || source.frames === 1;
		assert.equal(r.panels[0].fps, own ? newest.fps || source.fps : source.fps);
		assert.equal(r.panels[0].loop, own ? newest.loop ?? source.loop : source.loop);
	}
	for (const monster of motion.monsters) for (const source of monster.base.rows.filter(r => r.candidates.length && r.name !== "shockwave")) {
		const r = M.rows.find(r => r.key === `monster~${monster.id}~${source.name}`), newest = source.candidates.at(-1);
		assert.equal(r.panels[0].fps, source.newRow || source.frames === 1 ? newest.fps || source.fps : source.fps);
	}
	for (const r of M.rows) for (const p of r.panels) {
		assert.ok(p.fps > 0); assert.equal(p.width, Math.max(...p.tiles.map(t => t.cell[0]))); assert.equal(p.height, Math.max(...p.tiles.map(t => t.cell[1])));
		for (const t of p.tiles) { assert.ok(!Object.hasOwn(t, "fps"), "FPS belongs to comparison panel, not tile"); assert.equal(t.x + t.cell[0]/2, p.width/2); if (p.feet !== null) assert.equal(t.y + t.feet, p.feet); else assert.equal(t.y + t.cell[1]/2, p.height/2); }
	}
	checked("timing-and-alignment", "data", "Game manifest fps (including adopted speeds), otherwise newest metadata; every panel owns one fps; equal canvas size/scale and aligned feet or centred projectiles");

	const files = json(join(dist, "files.json")), htmlBytes = statSync(join(dist, "index.html")).size;
	assert.equal(new Set(files.map(f => f.path)).size, files.length);
	const expectedFiles = new Set(M.rows.flatMap(r => tilesOf(r).filter(t => t.file).map(t => t.file)));
	assert.deepEqual(files.map(f => f.path).sort(), [...expectedFiles].sort());
	for (const { path } of files) {
		assert.ok(!path.includes("..") && !path.includes("\\") && !path.startsWith("/"));
		const t = M.rows.flatMap(tilesOf).find(t => t.file === path); assert.equal(sha(join(dist, path)), sha(join(repo, t.repoFile)));
	}
	const batchNames = readdirSync(dist).filter(n => /^files-\d+\.json$/.test(n)).sort((a,b) => a.localeCompare(b, undefined, { numeric: true }));
	const batches = batchNames.map(n => json(join(dist,n))), batchDetails = [];
	for (let i = 0; i < batches.length; i++) { const batch = batches[i], bytes = htmlBytes + batch.reduce((n,f) => n + statSync(join(dist,f.path)).size,0); assert.ok(batch.length + 1 <= 250); assert.ok(bytes <= 60_000_000); batchDetails.push({ file: batchNames[i], filesIncludingHtml: batch.length+1, bytesIncludingHtml: bytes }); }
	assert.deepEqual(batches.flat().map(f => f.path), files.map(f => f.path));
	const totalBytes = htmlBytes + files.reduce((n,f) => n + statSync(join(dist,f.path)).size,0);
	summary = { ...M.counts, files: files.length + 1, bytes: totalBytes, batches: batches.length, versionFits: files.length + 1 <= 511 && totalBytes <= 256_000_000, batchDetails };
	assert.ok(summary.versionFits); assert.equal(M.counts.rows, 222); assert.equal(M.counts.newRows, 64); assert.equal(M.counts.gameRepairs, 21);
	checked("publish-integrity", "files", summary);

	const local = environment(); await settle();
	assert.equal(local.loads.length, 0); assert.equal(local.frames.length, 1); assert.equal(local.observers.length, 1); assert.equal(local.observers[0].targets.size, M.rows.length);
	assert.equal(local.observers[0].options.rootMargin, "320px 0px");
	assert.equal(local.roots["db-note"].textContent, "저장은 게시된 페이지에서만 됩니다");
	for (const view of local.run("[...views.values()]")) { assert.ok(view.memo.disabled && view.save.disabled && view.clear.disabled); for (const radio of view.radios.values()) assert.ok(radio.disabled); }
	for (const entry of changes.no_new_version) { const view = local.run(`views.get(${JSON.stringify(rowKey(entry))})`); assert.ok(view.root.textContent.includes("새 버전 없음")); assert.ok(view.root.textContent.includes(entry.text)); }
	checked("local-render-and-badges", "mock DOM", "222 rows render without DB; all pick/memo controls disabled, visible Korean notice and five no-new badges; zero images loaded before intersections");

	const first = M.rows[0], firstView = local.run(`views.get(${JSON.stringify(first.key)})`);
	local.near(first.key); assert.ok(local.loads.length > 0); assert.ok(local.loads.length < files.length); assert.equal(local.run("active.size"), 1);
	let previousLoads = local.loads.length;
	local.near(first.key, false); const beforeDraws = firstView.panels[0].tiles.map(t => t.canvas.draws.length);
	local.run("clock=1.1"); local.frames.shift()(100); assert.deepEqual(firstView.panels[0].tiles.map(t => t.canvas.draws.length), beforeDraws);
	local.near(first.key); assert.equal(local.loads.length, previousLoads);
	// Activate every row once to exercise every crop against actual PNG dimensions.
	for (const r of M.rows) local.near(r.key);
	assert.equal(new Set(local.loads).size, files.length); assert.equal(local.loads.length, files.length);
	for (const moment of [0, .071, .261, .75, 1.08, 1.93]) {
		local.run(`clock=${moment}; for(const v of active) { for(const p of v.panels) for(const t of p.tiles) t.last=-1; draw(v); }`);
		for (const v of local.run("[...views.values()]")) for (const pv of v.panels) for (const tv of pv.tiles) {
			const p = pv.panel, t = tv.tile; if (t.portrait || t.primitive) continue;
			const frame = Math.min(t.frames-1, Math.floor((moment % (t.frames/p.fps + (p.loop ? 0 : .6))) * p.fps));
			const args = tv.canvas.draws.at(-1); assert.ok(args);
			assert.deepEqual(Array.from(args.slice(1)), [(frame%t.columns)*t.cell[0], (t.start+Math.floor(frame/t.columns))*t.cell[1], t.cell[0], t.cell[1], t.x, t.y, t.cell[0], t.cell[1]]);
			assert.ok(args[1]+args[3] <= args[0].naturalWidth && args[2]+args[4] <= args[0].naturalHeight);
		}
	}
	assert.equal(local.run("frameAt(0.99,10,4,false)"), 3); assert.equal(local.run("frameAt(1.001,10,4,false)"), 0);
	const faceView = local.run('[...views.values()].find(v=>v.row.kind==="face")'); assert.ok(faceView.panels[0].tiles.every(t=>t.stage.children[0].tagName === "IMG"));
	checked("lazy-loading-and-playback", "mock Image/canvas/observer", "Offscreen rows do not draw; 325 unique images fetched only as rows enter range; six times checked for every animated crop, frame counts, shared fps and 0.6s nonloop hold; portraits render as images");

	assert.equal(local.frames.length,1); local.run("lastTime=null; clock=0;"); local.frames.shift()(0); local.frames.shift()(100); assert.equal(local.run("clock"), .1);
	await local.roots.speed.fire("change", { target: { value: "1.5" } }); local.frames.shift()(200); local.frames.shift()(300); assert.ok(Math.abs(local.run("clock")-.25)<1e-10);
	await local.roots.play.fire("click"); const paused = local.run("clock"); local.frames.shift()(400); local.frames.shift()(500); assert.equal(local.run("clock"),paused);
	const reduced = environment({ reduced: true }); await settle(); assert.equal(reduced.roots.play.textContent,"재생"); assert.equal(reduced.run("playing"),false);
	await reduced.roots.play.fire("click"); reduced.frames.shift()(0); reduced.frames.shift()(100); assert.ok(reduced.run("clock")>0);
	reduced.document.hidden = true; reduced.documentEvents.visibilitychange(); const hiddenAt = reduced.run("clock"); reduced.frames.shift()(200); assert.equal(reduced.run("clock"),hiddenAt);
	await local.roots.background.fire("change",{target:{value:"dark"}}); assert.equal(local.roots.viewer.dataset.bg,"dark");
	await local.roots.size.fire("change",{target:{value:"large"}}); assert.equal(local.roots.viewer.dataset.size,"large");
	checked("clock-and-controls", "mock clock/DOM", "Exactly one RAF callback scheduled; speed ×1.5, pause/resume, reduced-motion paused start, background-tab pause, background/size state changes");

	const hosted = environment({ withDb: true }); await settle();
	assert.equal(hosted.useCalls,1); assert.equal(hosted.subscriptions,1); assert.equal(hosted.writes.length,0);
	for (const kind of ["fighter","monster","projectile","face","legacy_sheet"]) {
		const row = M.rows.find(r=>r.kind===kind), view = hosted.run(`views.get(${JSON.stringify(row.key)})`), choice = row.options[0];
		view.memo.value = `${kind} 메모 <script>그대로 텍스트</script>`; await view.memo.fire("input"); const previous = hosted.writes.length;
		assert.equal(hosted.writes.length,previous); await view.radios.get(choice).fire("click"); await settle(); assert.equal(hosted.writes.length, previous+1);
		const write = hosted.writes.at(-1); assert.equal(write.collection,"candidate_picks"); assert.equal(write.id,row.key);
		assert.deepEqual(Object.keys(write.value).sort(), ["kind","id","row","choice","file","options","picked","note","picked_at","viewer","commit"].sort());
		assert.deepEqual(write.value.options,row.options); assert.equal(write.value.choice,choice); assert.equal(write.value.file,tilesOf(row).find(t=>t.role==="candidate" && t.version===choice).repoFile);
		assert.equal(write.value.viewer,"compare"); assert.equal(write.value.commit,M.commit); assert.ok(write.value.picked); assert.equal(write.value.note,view.memo.value); assert.equal(view.status.textContent,"저장됨");
		assert.equal(hosted.run(`validRecord(${JSON.stringify(row.key)}, ${JSON.stringify(write.value)})`), true);
	}
	assert.equal(hosted.roots["picked-count"].textContent,`고른 줄 5 / 전체 ${M.rows.length}`);
	checked("one-pick-document", "mock DB/DOM", "One DB acquisition and collection subscription, no writes on load/typing; all five kinds write exactly one 12-field row document per click and update saved list");

	const key = first.key, ui = hosted.run(`views.get(${JSON.stringify(key)})`);
	const alternatives = [...ui.radios.keys()].filter(k=>k!=="none"); if(alternatives.length>1) { await ui.radios.get(alternatives[1]).fire("click"); assert.equal([...ui.radios.values()].filter(r=>r.checked).length,1); }
	await ui.radios.get("none").fire("click"); assert.equal(hosted.writes.at(-1).value.file,null); assert.equal(hosted.writes.at(-1).value.picked,true); assert.equal([...ui.radios.values()].filter(r=>r.checked).length,1);
	ui.memo.value = "입력 중인 메모"; await ui.memo.fire("input"); const oldWriteCount=hosted.writes.length; hosted.emit(); assert.equal(ui.memo.value,"입력 중인 메모"); assert.equal(hosted.writes.length,oldWriteCount);
	await ui.save.fire("click"); assert.equal(hosted.writes.length,oldWriteCount+1); assert.equal(hosted.writes.at(-1).value.note,"입력 중인 메모");
	await ui.clear.fire("click"); assert.equal(hosted.writes.at(-1).value.picked,false); assert.equal([...ui.radios.values()].filter(r=>r.checked).length,0); assert.equal(hosted.roots["picked-count"].textContent,`고른 줄 4 / 전체 ${M.rows.length}`);
	ui.memo.value = "가".repeat(310); await ui.memo.fire("input"); await ui.save.fire("click"); assert.equal(hosted.writes.at(-1).value.note.length,300);
	const reloaded = environment({ withDb:true,persisted:hosted.persisted }); await settle(); assert.equal(reloaded.roots["picked-count"].textContent,hosted.roots["picked-count"].textContent);
	assert.equal(reloaded.run(`views.get(${JSON.stringify(key)}).memo.value.length`),300);
	checked("replace-none-clear-memo-reload", "mock DB/DOM", "One selected radio per row; none is a saved choice with null file; clear writes picked:false; drafts survive snapshots; memo saves once/truncates at 300; new VM restores persisted selections and notes");

	hosted.fail(true); ui.memo.value="실패해도 메모 유지"; await ui.memo.fire("input"); const savedBefore=hosted.writes.length;
	await ui.radios.get(alternatives[0]).fire("click"); assert.equal(hosted.writes.length,savedBefore); assert.ok(ui.status.textContent.includes("다시 눌러")); assert.equal(ui.memo.value,"실패해도 메모 유지"); assert.ok(!ui.radios.get(alternatives[0]).disabled);
	hosted.fail(false); await ui.radios.get(alternatives[0]).fire("click"); assert.equal(hosted.writes.length,savedBefore+1); assert.equal(ui.status.textContent,"저장됨");
	let release; hosted.hold(new Promise(resolve=>release=resolve)); const pending = ui.radios.get("none").fire("click"); await settle();
	assert.equal(ui.status.textContent,"저장 중…"); assert.ok(ui.memo.disabled && [...ui.radios.values()].every(r=>r.disabled)); const countDuring=hosted.writes.length;
	await ui.radios.get("none").fire("click"); release(); await pending; hosted.hold(null); assert.equal(hosted.writes.length,countDuring+1);
	checked("write-failure-and-double-click", "mock DB", "Failure retains draft/previous choice and enables retry; delayed writes show saving status and block a second request");

	const sample = hosted.writes.at(-1).value, malformed = [null, {}, {...sample,picked:"yes"}, {...sample,choice:"v99999"}, {...sample,file:"art/wrong.png"}, {...sample,note:9}, {...sample,note:"x".repeat(301)}, {...sample,options:[sample.choice,sample.choice]}, {...sample,picked_at:"yesterday"}, {...sample,picked_at:"2026-02-31T00:00:00.000Z"}, {...sample,commit:"bad"}, {...sample,viewer:"motion"}, {...sample,kind:"face"}];
	for (const record of malformed) assert.equal(hosted.run(`validRecord(${JSON.stringify(key)},${JSON.stringify(record)})`),false);
	const badPersisted = new Map([[key, {...sample,picked:"yes"}], [key+"~v1",sample], ["unknown~row~id",sample]]), badEnv=environment({withDb:true,persisted:badPersisted}); await settle(); assert.equal(badEnv.run("records.size"),0);
	checked("snapshot-validation", "mock DB", "Malformed fields, invalid dates/choices/paths, other-viewer and four-part old IDs do not count; records are rendered through textContent");

	await hosted.roots.filter.fire("change",{target:{value:"new"}}); assert.equal(hosted.roots["visible-count"].textContent,`${M.counts.newRows}줄 표시`);
	const notNew=M.rows.find(r=>r.newCount===0); assert.equal(hosted.run(`views.get(${JSON.stringify(notNew.key)}).root.hidden`),true);
	hosted.run(`goToRow(rowsByKey.get(${JSON.stringify(notNew.key)}))`); assert.equal(hosted.run("filter"),"all"); assert.equal(hosted.run(`views.get(${JSON.stringify(notNew.key)}).root.scrolled`),true);
	await hosted.roots.filter.fire("change",{target:{value:"unpicked"}}); assert.equal(hosted.run(`views.get(${JSON.stringify(key)}).root.hidden`),true);
	const pickedLink=walk(hosted.roots["picked-list"]).find(e=>e.id===`picked-row-${key.replaceAll("~","-")}`); assert.ok(pickedLink); await pickedLink.fire("click"); assert.equal(hosted.run("filter"),"all");
	for(const opts of [{},{withDb:true,nullDb:true},{withDb:true,rejectDb:true},{noObserver:true}]) { const e=environment(opts); await settle(); assert.equal(e.run("db"),null); assert.ok(e.run("[...views.values()].every(v=>v.memo.disabled)")); assert.equal(e.frames.length,1); }
	hosted.disconnect(); assert.equal(hosted.run("db"),null); assert.ok(ui.radios.get("none").disabled); assert.ok(hosted.roots["db-note"].textContent.includes("새로고침"));
	checked("filters-navigation-db-fallbacks", "mock DOM/DB", "New/unpicked filters, saved-list navigation reveals hidden target; missing/null/rejected DB and subscription loss disable saving; observer fallback initializes without eager image load");

	const staticIds=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]); const dynamic=Object.values(local.roots).flatMap(walk);
	const allIds=[...staticIds,...dynamic.map(e=>e.id).filter(Boolean)]; assert.equal(new Set(allIds).size,allIds.length);
	for (const control of dynamic.filter(e=>["BUTTON","INPUT","TEXTAREA","SELECT"].includes(e.tagName))) assert.ok(control.id);
	assert.ok(!/<(?:!doctype|html|head|body)\b/i.test(html)); assert.ok(html.startsWith("<title>SmashNine 후보 비교</title>"));
	assert.ok(html.includes('<meta name="claude:viewport-fit-sides" content="cover">')); assert.ok(!/<script\b[^>]*\bsrc=/i.test(html));
	for(const pattern of ["padding-left: max(16px, env(safe-area-inset-left, 0px))","padding-right: max(16px, env(safe-area-inset-right, 0px))","top: env(safe-area-inset-top, 0px)",":focus-visible","grid-template-columns: repeat(2, minmax(0, 1fr))","object-fit: contain","image-rendering: pixelated",":root:not([data-theme=\"light\"])",":root[data-theme=\"dark\"]"]) assert.ok(html.includes(pattern),pattern);
	const style=html.match(/<style>([\s\S]*?)<\/style>/)[1]; for(const line of style.split("\n").filter(l=>/#[\da-f]{3,8}\b/i.test(l))) assert.ok(line.trim().startsWith("--"),`Literal color outside token declaration: ${line}`);
	const template=read(join(here,"index.html")); assert.equal(html,template.replace("/*MANIFEST*/null",JSON.stringify(M).replaceAll("<","\\u003c")));
	new vm.Script(script);
	checked("artifact-css-controls-source", "static source/mock DOM", "Unique stable control IDs, Korean UI, fragment/viewport/safe-area/token rules, two-column mobile CSS, keyboard focus, no external JS; built page matches source. CSS layout itself is untested.");
} catch (error) {
	checks.push({ name:"verification-failure", result:"FAIL", scope:"offline", detail: String(error.stack || error) }); console.error(error); process.exitCode=1;
}
mkdirSync(report,{recursive:true});
writeFileSync(join(report,"checks.json"),JSON.stringify({ generatedAt:new Date().toISOString(), commit:M.commit, node:process.version, result:checks.some(c=>c.result==="FAIL")?"FAIL":"PASS", counts:summary, checks,
	limits:["Node mocks only: no browser layout, PNG decode, real paint or animation performance verified", "Artifact DB API/persistence/reload and multi-batch publishing require lead browser/service check", "375px wrapping, safe areas, theme/font rendering and keyboard interaction require a real browser", "No network, package installs or Godot run; no commit performed"] },null,2)+"\n");
console.log(`checks: ${checks.filter(c=>c.result==="PASS").length} passed, ${checks.filter(c=>c.result==="FAIL").length} failed -> reports/codex-tool-04/checks.json`);
