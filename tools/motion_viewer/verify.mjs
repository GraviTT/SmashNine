// Node-only behavior and delivery checks. This is not a browser or hosted Artifact API test.
import assert from "node:assert/strict";
import vm from "node:vm";
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync, mkdtempSync, mkdirSync, truncateSync, rmSync } from "node:fs";
import { join, dirname, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { writePublishFiles } from "./publish-files.mjs";

const here = dirname(fileURLToPath(import.meta.url)), repo = resolve(here, "../.."), dist = join(here, "dist");
const report = join(repo, "reports/codex-tool-03");
const html = readFileSync(join(dist, "index.html"), "utf8"), script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const M = JSON.parse(script.match(/const M = ([^\n]+);/)[1]);
const checks = [];
const checked = (name, detail) => checks.push({ name, result: "PASS", detail });
const settle = () => new Promise(resolve => setImmediate(resolve));

class Element {
	constructor(tag = "div") {
		this.tagName = tag.toUpperCase(); this.children = []; this.parent = null; this.events = {}; this.dataset = {}; this.style = {};
		this.attributes = {}; this.value = ""; this.disabled = false; this.hidden = false; this._text = ""; this.open = false; this.draws = [];
	}
	get isConnected() { return Boolean(this.root || this.parent?.isConnected); }
	get textContent() { return this._text + this.children.map(c => typeof c === "string" ? c : c.textContent).join(""); }
	set textContent(value) { this._text = String(value); this.clear(); }
	set innerHTML(value) { assert.equal(value, ""); this._text = ""; this.clear(); }
	clear() { for (const c of this.children) if (c instanceof Element) c.parent = null; this.children = []; }
	append(...nodes) { for (const n of nodes) { if (n instanceof Element) n.parent = this; this.children.push(n); } }
	setAttribute(key, value) { this.attributes[key] = String(value); }
	getAttribute(key) { return this.attributes[key] ?? null; }
	addEventListener(name, fn) { (this.events[name] ??= []).push(fn); }
	async fire(name, event = {}) { if (this.disabled && name === "click") return; for (const fn of this.events[name] || []) await fn({ target: this, ...event }); }
	getContext() {
		return this.ctx ??= { canvas: this, clearRect() {}, drawImage: (...args) => this.draws.push(args), save() {}, restore() {}, strokeRect() {}, setLineDash() {}, beginPath() {}, moveTo() {}, lineTo() {}, stroke() {} };
	}
	showModal() { this.open = true; }
	close() { this.open = false; }
	focus() {}
	select() {}
	setSelectionRange() {}
}
const walk = node => node.children.flatMap(c => c instanceof Element ? [c, ...walk(c)] : []);
function environment({ withDb = false, rejectDb = false, nullDb = false, persisted = new Map(), reduced = false, manifest = null } = {}) {
	const elements = Object.fromEntries([...html.matchAll(/\bid="([^"]+)"/g)].map(([, id]) => { const el = new Element(); el.root = true; return [id, el]; }));
	elements.pickDbNote.textContent = html.match(/id="pickDbNote"[^>]*>([^<]*)</)[1];
	const callbacks = new Map(), subscriptions = new Map(), writes = [], imageList = [], frames = [], local = new Map(), keys = {};
	let failWrite = false, holdWrite = null, useCalls = 0;
	class MockImage extends Element {
		constructor() { super("img"); this.complete = true; this.naturalWidth = 256; this.naturalHeight = 256; imageList.push(this); }
		set src(value) {
			this._src = value;
			const file = join(dist, value); if (existsSync(file) && value.endsWith(".png")) { const bytes = readFileSync(file); this.naturalWidth = bytes.readUInt32BE(16); this.naturalHeight = bytes.readUInt32BE(20); }
		}
		get src() { return this._src; }
	}
	const snapshot = name => ({ docs: [...(persisted.get(name) || new Map())].map(([id, value]) => ({ id, exists: true, data: () => value })) });
	const db = { collection(name) {
		assert.ok(["candidate_picks", "motion_speeds"].includes(name));
		return {
			onSnapshot(next, error) { subscriptions.set(name, (subscriptions.get(name) || 0) + 1); callbacks.set(name, { next, error }); next(snapshot(name)); },
			doc(id) { return {
				async set(value) {
					if (holdWrite) await holdWrite;
					if (failWrite) throw new Error("intentional test failure");
					writes.push({ collection: name, id, value });
					if (!persisted.has(name)) persisted.set(name, new Map()); persisted.get(name).set(id, value);
					callbacks.get(name)?.next(snapshot(name));
				},
				async delete() { writes.push({ collection: name, id, remove: true }); persisted.get(name)?.delete(id); callbacks.get(name)?.next(snapshot(name)); },
			}; },
		};
	} };
	const document = { activeElement: null, documentElement: new Element("html"), getElementById: id => { assert.ok(elements[id], `unknown DOM id ${id}`); return elements[id]; },
		createElement: tag => new Element(tag), addEventListener: (name, fn) => keys[name] = fn, execCommand() {} };
	const window = { devicePixelRatio: 1 };
	if (withDb) window.claude = { async use(name) { useCalls++; assert.equal(name, "db"); if (rejectDb) throw new Error("DB unavailable"); return nullDb ? null : db; } };
	const context = vm.createContext({ window, document, Image: MockImage, HTMLInputElement: class {}, HTMLButtonElement: class {},
		matchMedia: () => ({ matches: reduced }), location: { hash: "" }, history: { replaceState() {} },
		localStorage: { getItem: key => local.get(key), setItem: (key, value) => local.set(key, value) },
		getComputedStyle: () => ({ getPropertyValue: () => "#08889e" }), performance: { now: () => 0 },
		requestAnimationFrame: fn => frames.push(fn), navigator: { clipboard: { async writeText(value) { keys.copied = value; } } }, setTimeout() {}, console });
	vm.runInContext(manifest ? script.replace(/const M = [^\n]+;/, () => `const M = ${JSON.stringify(manifest)};`) : script, context);
	return { run: code => vm.runInContext(code, context), elements, document, imageList, frames, writes, subscriptions, persisted, keys,
		get useCalls() { return useCalls; }, failWrite: value => failWrite = value, hold: value => holdWrite = value,
		emit: name => callbacks.get(name).next(snapshot(name)), dbError: name => callbacks.get(name).error() };
}

const local = environment(); await settle();
const catalog = local.run("[...candidateCatalog]");
const kindCounts = Object.fromEntries(["fighter", "monster", "projectile", "face"].map(kind => [kind, catalog.filter(([, c]) => c.kind === kind).length]));
for (const count of Object.values(kindCounts)) assert.ok(count > 0);
const scan = root => readdirSync(root, { withFileTypes: true }).flatMap(entry => entry.isDirectory() ? entry.name === "retired" ? [] : scan(join(root, entry.name)) : [join(root, entry.name)]);
const fighterStems = M.characters.flatMap(c => c.forms.map(f => f.body ? `${c.id}_${f.body}` : c.id));
const expectedCandidates = [];
for (const path of scan(join(repo, "art/bakeoff"))) {
	const name = path.replaceAll("\\", "/").split("/").at(-1);
	if (!/-v\d+\.png$/.test(name)) continue;
	const row = [...fighterStems, ...M.monsters.map(m => m.id)].some(stem => name.startsWith(`${stem}-`) && /^[a-z0-9_]+-v\d+\.png$/.test(name.slice(stem.length + 1)));
	const face = fighterStems.some(stem => new RegExp(`^${stem}_face-(happy|angry|hurt|shadow)-v\\d+\\.png$`).test(name));
	const wave = /^slam_shockwave-v\d+\.png$/.test(name);
	if (!row && !face && !wave) continue;
	const metadataPath = path.replace(/\.png$/, ".json"), metadata = existsSync(metadataPath) ? JSON.parse(readFileSync(metadataPath, "utf8")) : {};
	if (!metadata.adopted) expectedCandidates.push(path.slice(repo.length + 1).replaceAll("\\", "/"));
}
assert.deepEqual(Array.from(catalog, ([, c]) => c.file).sort(), expectedCandidates.sort());
assert.equal(local.run("candidateDb"), null);
assert.ok(/로컬/.test(local.elements.pickDbNote.textContent));
for (const key of ["projectileGrid", "portraitForms"]) assert.ok(walk(local.elements[key]).filter(c => c.className?.includes("pick-toggle")).every(c => c.disabled));
checked("No database", `${catalog.length} candidates independently matched to active source files; pick and memo controls disabled with Korean explanation; motion/image comparison still initializes`);

const sourceFor = file => file.startsWith("sheets/") ? join(repo, "smash-nine-prototype/assets/art", file.slice(7))
	: file.startsWith("current/") ? join(repo, "smash-nine-prototype/assets/art", file.slice(8)) : join(repo, "art", file);
const files = JSON.parse(readFileSync(join(dist, "files.json"), "utf8"));
assert.equal(new Set(files.map(f => f.path)).size, files.length);
for (const f of files) { assert.ok(existsSync(join(dist, f.path))); assert.deepEqual(readFileSync(join(dist, f.path)), readFileSync(sourceFor(f.path))); }
for (const [, c] of catalog) {
	assert.ok(files.some(f => f.path === c.file.slice(4)));
	const meta = join(repo, c.file.replace(/\.png$/, ".json")); if (existsSync(meta)) assert.ok(!JSON.parse(readFileSync(meta, "utf8")).adopted);
}
checked("Delivery integrity", `${files.length} sidecars exist, are unique, and byte-match source assets; all ${catalog.length} candidates are listed and unadopted`);

const baseline = JSON.parse(readFileSync(join(report, "baseline.json"), "utf8"));
const clean = object => JSON.parse(JSON.stringify(object, (key, value) => key === "pick" ? undefined : value));
const compareSheet = (actual, before) => {
	if (!before) { assert.equal(actual, before); return; }
	for (const field of ["file", "cell", "feet"]) assert.equal(actual[field], before[field]);
	for (const oldRow of before.rows.filter(r => r.name !== "projectile")) {
		const row = actual.rows.find(r => r.name === oldRow.name); assert.ok(row);
		assert.deepEqual(clean({ ...row, candidates: undefined }), clean({ ...oldRow, candidates: undefined }));
		for (const candidate of oldRow.candidates || []) {
			const path = join(repo, "art", candidate.file), meta = path.replace(/\.png$/, ".json");
			if (!existsSync(path) || existsSync(meta) && JSON.parse(readFileSync(meta, "utf8")).adopted) continue;
			// Fix passes rewrite a candidate's note; everything the viewer plays from must stay.
			const withoutNote = ({ note, ...rest }) => rest;
			assert.deepEqual(withoutNote(clean(row.candidates.find(c => c.file === candidate.file))), withoutNote(candidate));
		}
	}
};
for (const c of baseline.characters) {
	const actual = M.characters.find(item => item.id === c.id); assert.ok(actual);
	for (const f of c.forms) {
		const form = actual.forms.find(item => item.body === f.body); assert.ok(form);
		compareSheet(form.base, f.base); compareSheet(form.moves, f.moves); assert.deepEqual(form.clips, f.clips);
	}
}
for (const m of baseline.monsters) compareSheet(M.monsters.find(item => item.id === m.id).base, m.base);
checked("Existing data regression", "All fighter forms, rows, speeds, candidate values and 55 clip pairs preserved; monster rows identical except 7 projectiles moved to their own section");

// Visit every fighter, form, monster and row through the same selection path used by buttons.
let rowVisits = 0, candidateVisits = new Set();
for (let entry = 0; entry < local.run("entries.length"); entry++) {
	const forms = local.run(`entries[${entry}].forms.length`);
	for (let form = 0; form < forms; form++) {
		local.run(`state.entry=${entry}; state.form=${form}; state.anim=0; select()`);
		for (let anim = 0; anim < local.run("anims.length"); anim++) {
			local.run(`state.anim=${anim}; select(false,true)`); rowVisits++;
			const a = local.run("anims[state.anim]");
			const toggles = walk(local.elements.stageGrid).filter(c => c.className?.includes("pick-toggle"));
			assert.equal(toggles.length, a.row.candidates?.length || 0);
			for (const view of local.run("stageViews")) {
				const candidate = a.row.candidates?.find(c => c.file === view.anim.sheet.file);
				if (!candidate) continue;
				assert.equal(view.anim.row.loop, candidate.loop ?? a.row.loop);
				assert.equal(view.anim.row.fps, candidate.fps || a.row.fps);
				assert.equal(view.anim.row.frames, candidate.frames || a.row.frames);
				assert.equal(view.anim.sheet.cell, candidate.cell || a.sheet.cell);
			}
			for (const c of a.row.candidates || []) candidateVisits.add([c.pick.kind,c.pick.id,c.pick.row,c.pick.version].join("~"));
			local.run("setPlaying(false); setFrame((stageLead || anims[state.anim]).row.frames-1)");
			assert.equal(local.run("stageFrame"), local.run("stageLead.row.frames-1"));
			local.run("setFrame(stageLead.row.frames)"); assert.equal(local.run("stageFrame"), 0);
		}
	}
}
assert.equal(candidateVisits.size, kindCounts.fighter + kindCounts.monster);
assert.ok(local.run("[...pickControls.values()].reduce((n,set)=>n+set.size,0)") < 100, "detached controls must be released");
checked("Rows and candidates", `${rowVisits} row selections across all forms/monsters; all ${candidateVisits.size} row candidates have buttons and individual loop/fps/frame/cell values; longest-frame stepping wraps; detached controls released`);

// Every projectile draws the declared rectangular crop at 1x and 3x and advances at its own fps.
assert.equal(local.run("projectileViews.length"), M.projectiles.length * 2);
local.run("projectileT=.26; drawProjectiles()");
for (const view of local.run("projectileViews")) {
	const args = view.ctx.canvas.draws.at(-1), p = view.candidate;
	assert.equal(args[1], Math.floor(.26 * p.fps) % p.frames * view.width);
	assert.equal(args[3], view.width); assert.equal(args[4], view.height);
	assert.equal(args[7], view.width * view.scale); assert.equal(args[8], view.height * view.scale);
}
assert.equal(M.projectiles.find(p => p.id === "slam_shockwave").cell.join("x"), "64x48");
local.elements.projectilePlay.fire("click"); const pausedT = local.run("projectileT"); local.frames.shift()(100); assert.equal(local.run("projectileT"), pausedT);
checked("Projectile playback", `${M.projectiles.length} strips including 64x48 shockwave; ${M.projectiles.length * 2} crops at metadata fps and 1x/3x; pause holds time; old image/Line2D comparison present`);

const portraitCards = walk(local.elements.portraitForms).filter(c => c.className === "portrait-card");
assert.equal(portraitCards.length, M.portraits.length + kindCounts.face);
const portraitOpens = walk(local.elements.portraitForms).filter(c => c.className === "portrait-open");
await portraitOpens[1].fire("click"); assert.equal(local.elements.faceDialog.open, true); assert.equal(local.elements.fullFace.src, portraitOpens[1].children[0].src);
await local.elements.closeFace.fire("click"); assert.equal(local.elements.faceDialog.open, false);
assert.ok(html.includes("width: 142px; height: 164px; object-fit: contain"));
checked("Portraits", `${M.portraits.length} forms/current faces and ${kindCounts.face} expressions; 142x164 aspect-preserving CSS; click opens original, Close dismisses (mock DOM)`);

const hosted = environment({ withDb: true }); await settle();
assert.equal(hosted.useCalls, 1); assert.equal(hosted.subscriptions.get("candidate_picks"), 1); assert.equal(hosted.subscriptions.get("motion_speeds"), 1);
const keysByKind = Object.fromEntries(["fighter", "monster", "projectile", "face"].map(kind => [kind, catalog.find(([, c]) => c.kind === kind)[0]]));
for (const [kind, key] of Object.entries(keysByKind)) {
	// Row candidate controls are built on demand in the selected stage; extras are always visible.
	if (["fighter", "monster"].includes(kind)) {
		const info = hosted.run(`candidateCatalog.get(${JSON.stringify(key)})`);
		hosted.run(`for(let e=0;e<entries.length;e++) for(let f=0;f<entries[e].forms.length;f++) { const form=entries[e].forms[f]; if(animsOf(form).some(a=>(a.row.candidates||[]).some(c=>pickId(c.pick)===${JSON.stringify(key)}))) { state.entry=e;state.form=f;select(); state.anim=anims.findIndex(a=>(a.row.candidates||[]).some(c=>pickId(c.pick)===${JSON.stringify(key)}));select(false,true); } }`);
		assert.equal(info.kind, kind);
	}
	const ui = hosted.run(`[...pickControls.get(${JSON.stringify(key)})].find(ui=>ui.root.isConnected)`); assert.ok(ui);
	ui.note.value = `${kind} 선택 메모 <script>그대로 텍스트</script>`; await ui.note.fire("input");
	const count = hosted.writes.length; await ui.toggle.fire("click"); await settle();
	assert.equal(hosted.writes.length, count + 1);
	const write = hosted.writes.at(-1); assert.equal(write.collection, "candidate_picks"); assert.equal(write.id, key); assert.equal(write.value.picked, true);
	assert.deepEqual(Object.keys(write.value).sort(), ["file","id","kind","note","picked","picked_at","row","version"]);
	assert.equal(write.value.note, ui.note.value); assert.ok(!Number.isNaN(Date.parse(write.value.picked_at)));
	assert.ok(hosted.elements.pickedList.textContent.includes(write.value.note)); assert.equal(ui.toggle.getAttribute("aria-pressed"), "true");
}
assert.equal(hosted.elements.picksCount.textContent, "4");
checked("Pick all kinds", "One DB acquisition, one subscription per collection; each fighter/monster/projectile/face click writes exactly one correctly keyed eight-field document; panel and pressed state update");

const faceKey = keysByKind.face, faceUI = hosted.run(`[...pickControls.get(${JSON.stringify(faceKey)})][0]`);
faceUI.note.value = "변경 중 메모"; await faceUI.note.fire("input"); hosted.emit("candidate_picks"); assert.equal(faceUI.note.value, "변경 중 메모");
const count = hosted.writes.length; await faceUI.saveNote.fire("click"); await settle();
assert.equal(hosted.writes.length, count + 1); assert.equal(hosted.writes.at(-1).value.note, "변경 중 메모");
assert.equal(hosted.writes.at(-1).value.picked, true);
await faceUI.toggle.fire("click"); await settle(); assert.equal(hosted.elements.picksCount.textContent, "3"); assert.equal(hosted.writes.at(-1).value.picked, false);
await faceUI.toggle.fire("click"); await settle();
const panelCancel = walk(hosted.elements.pickedList).find(c => c.getAttribute("aria-label") === `${hosted.writes.at(-1).value.id} ${hosted.writes.at(-1).value.row} ${hosted.writes.at(-1).value.version} 선택 취소`);
await panelCancel.fire("click"); await settle(); assert.equal(hosted.elements.picksCount.textContent, "3");
checked("Memo and unpick", "Unrelated snapshots preserve drafts; memo save writes once and keeps picked state; toggle and panel cancellation remove item from picked list");

const reloaded = environment({ withDb: true, persisted: hosted.persisted }); await settle();
assert.equal(reloaded.elements.picksCount.textContent, "3");
assert.equal(reloaded.run(`pickRecords.get(${JSON.stringify(faceKey)}).picked`), false);
assert.equal(reloaded.run(`pickRecords.get(${JSON.stringify(faceKey)}).note`), "변경 중 메모");
const restoredFace = reloaded.run(`[...pickControls.get(${JSON.stringify(faceKey)})][0]`);
assert.equal(restoredFace.note.value, "변경 중 메모"); assert.equal(restoredFace.toggle.getAttribute("aria-pressed"), "false");
checked("Reload restoration", "A fresh VM restores all selected/unselected records, notes, panel and button states from persisted mock DB");

hosted.failWrite(true); faceUI.note.value = "실패해도 보존"; await faceUI.note.fire("input"); await faceUI.toggle.fire("click"); await settle();
assert.match(faceUI.status.textContent, /저장하지 못했습니다/); assert.equal(faceUI.toggle.disabled, false); assert.equal(faceUI.note.value, "실패해도 보존");
assert.equal(hosted.run(`pickRecords.get(${JSON.stringify(faceKey)}).picked`), false);
hosted.failWrite(false); await faceUI.toggle.fire("click"); await settle(); assert.equal(faceUI.toggle.getAttribute("aria-pressed"), "true");
assert.match(hosted.elements.pickDbNote.textContent, /선택 저장 연결됨/);
let release; hosted.hold(new Promise(resolve => release = resolve)); const writesBefore = hosted.writes.length;
const pendingClick = faceUI.toggle.fire("click"); await faceUI.toggle.fire("click"); assert.equal(faceUI.toggle.disabled, true);
release(); await pendingClick; await settle(); hosted.hold(null); assert.equal(hosted.writes.length, writesBefore + 1);
checked("Save failures and duplicate clicks", "Failed writes keep last saved selection and draft and allow retry; pending button blocks duplicate writes");

hosted.run("state.entry=0;state.form=0;state.anim=0;select()");
hosted.elements.rowSpeed.value = ".8"; await hosted.elements.rowSpeed.fire("input");
assert.equal(hosted.run("rowSpeed()"), .8); await hosted.elements.adoptSpeed.fire("click"); await settle();
const speed = hosted.writes.at(-1); assert.equal(speed.collection, "motion_speeds"); assert.equal(speed.value.factor, .8);
assert.equal(speed.value.fps, Math.round(hosted.run("anims[state.anim].row.fps") * .8 * 100) / 100);
assert.ok(hosted.elements.speedChanges.value.includes("×0.80")); await hosted.elements.copySpeeds.fire("click"); assert.equal(hosted.keys.copied, hosted.elements.speedChanges.value);
await hosted.elements.clearSpeed.fire("click"); await settle(); assert.equal(hosted.writes.at(-1).remove, true);
checked("Speed adoption regression", "Row slider, copied changes, motion_speeds adoption fields and deletion still work independently of candidate picks");

// Verify applied speeds do not multiply a persisted adopted slider twice.
const row = hosted.run("anims[state.anim].row"), speedKey = hosted.run("rowKey()"), adoptionKey = hosted.run("adoptId()");
hosted.persisted.get("motion_speeds").set(adoptionKey, { fps: row.fps, factor: .8 }); hosted.emit("motion_speeds");
assert.equal(hosted.run(`state.rowSpeeds[${JSON.stringify(speedKey)}]`), undefined);
assert.match(hosted.elements.adoptState.textContent, /게임에 반영됨/);
checked("Applied speed regression", "A speed already applied in the game resets matching local slider to 1x");

hosted.dbError("candidate_picks"); assert.equal(hosted.run("candidateDb"), null); assert.ok(hosted.run("speedDb") !== null);
assert.equal(faceUI.toggle.disabled, true); assert.match(hosted.elements.pickDbNote.textContent, /DB 연결 없음/);
for (const options of [{ withDb: true, rejectDb: true }, { withDb: true, nullDb: true }]) {
	const fallback = environment(options); await settle(); assert.equal(fallback.run("candidateDb"), null); assert.equal(fallback.elements.adoptSpeed.hidden, true);
}
checked("DB fallback and isolation", "Rejected/null DB and subscription failure remain usable; candidate DB failure does not disable speed DB");

let clipVisits = 0;
for (let e = 0; e < M.characters.length; e++) {
	local.run(`state.entry=${e};state.form=0;select()`);
	const clips = M.characters[e].forms[0].clips || [];
	assert.equal(walk(local.elements.clips).filter(c => c.tagName === "IMG").length, clips.length);
	for (const mode of ["nofx", "fx", "new"]) {
		const radio = walk(local.elements.clips).find(c => c.id === `fx-${mode}`);
		if (!radio) continue; await radio.fire("change");
		const imgs = walk(local.elements.clips).filter(c => c.tagName === "IMG");
		for (let i = 0; i < clips.length; i++) {
			assert.equal(imgs[i].src, mode === "new" && clips[i].newFx ? `clips-new/${clips[i].newFx}` : `clips/${clips[i].files[mode === "nofx" ? "nofx" : "fx"]}`); clipVisits++;
		}
	}
}
checked("Clip regression", `${clipVisits} clip source switches; base attacks and around-character groups; fx/no-fx and available new-fx source paths preserved`);

// This clone has no clips-new payload. Exercise that pre-existing mode with a synthetic manifest.
const candidateClips = structuredClone(M);
candidateClips.characters[0].forms[0].clips[0].newFx = "fixture-candidate.webp";
const clipFixture = environment({ manifest: candidateClips });
const newMode = walk(clipFixture.elements.clips).find(c => c.id === "fx-new"); assert.ok(newMode);
await newMode.fire("change");
const fixtureImgs = walk(clipFixture.elements.clips).filter(c => c.tagName === "IMG");
assert.equal(fixtureImgs[0].src, "clips-new/fixture-candidate.webp");
assert.ok(fixtureImgs.slice(1).every(img => img.src.startsWith("clips/")));
checked("Candidate clip fallback fixture", "Synthetic clips-new manifest: new mode selects candidate source, clips without a new candidate retain current fx source (routing only; no fake asset delivered)");

// Saved picks from earlier publishes remain visible even after their candidate is removed/adopted.
const archived = { kind: "face", id: "archived_form", row: "happy", version: "v99", file: "art/bakeoff/archived.png", picked: true, note: "이전 게시 선택", picked_at: new Date().toISOString() };
const archiveKey = "face~archived_form~happy~v99";
reloaded.persisted.get("candidate_picks").set(archiveKey, archived); reloaded.emit("candidate_picks");
assert.ok(reloaded.elements.pickedList.textContent.includes("현재 후보 목록에 없음"));
await walk(reloaded.elements.pickedList).find(c => c.getAttribute("aria-label") === "archived_form happy v99 선택 취소").fire("click");
await settle(); assert.equal(reloaded.persisted.get("candidate_picks").get(archiveKey).picked, false);
checked("Prior-publish picks", "An absent/adopted candidate's saved choice stays in the top panel and can be unpicked without a current preview");

// Separate versions can both be picked; each resolves to its own stable document.
const versionManifest = structuredClone(M), versionCandidate = structuredClone(versionManifest.portraits[0].candidates[0]);
versionCandidate.version = versionCandidate.pick.version = "v999"; versionManifest.portraits[0].candidates.push(versionCandidate);
const versions = environment({ withDb: true, manifest: versionManifest }); await settle();
const versionIds = versions.run("[...candidateCatalog.keys()].filter(k=>k.startsWith('face~'+M.portraits[0].id+'~'+M.portraits[0].candidates[0].pick.row+'~'))");
assert.ok(versionIds.length >= 2);
for (const key of versionIds) await versions.run(`writePick(${JSON.stringify(key)},true)`);
assert.equal(versions.elements.picksCount.textContent, String(versionIds.length)); assert.equal(new Set(versions.writes.map(w => w.id)).size, versionIds.length);
checked("Future versions fixture", "Synthetic v999 expression gets a distinct pick document and appears beside earlier versions; selecting one does not clear another");

const reduced = environment({ reduced: true }); assert.equal(reduced.run("state.playing"), false); assert.equal(reduced.run("projectilePlaying"), false);
checked("Reduced motion", "Both motion stage and projectile playback initialize paused when reduced motion is requested");

const fixture = mkdtempSync(join(report, ".verify-publish-"));
try {
	writeFileSync(join(fixture, "index.html"), "test");
	assert.throws(() => writePublishFiles(fixture, ["missing.png"]), /publish file missing: missing.png/);
	assert.throws(() => writePublishFiles(fixture, ["../escape.png"]), /unsafe publish path/);
	const tiny = Array.from({ length: 251 }, (_, i) => `sheets/${i}.png`); mkdirSync(join(fixture, "sheets"));
	for (const file of tiny) writeFileSync(join(fixture, file), "x");
	let result = writePublishFiles(fixture, tiny); assert.equal(result.batches, 2);
	assert.equal(JSON.parse(readFileSync(join(fixture, "files-1.json"))).length, 250);
	assert.equal(JSON.parse(readFileSync(join(fixture, "files-2.json"))).length, 1);
	const large = ["a.png", "b.png", "c.png"];
	for (const file of large) { writeFileSync(join(fixture, file), ""); truncateSync(join(fixture, file), 31 * 1024 * 1024); }
	result = writePublishFiles(fixture, large); assert.equal(result.batches, 3);
	for (let i = 1; i <= 3; i++) assert.equal(JSON.parse(readFileSync(join(fixture, `files-${i}.json`))).length, 1);
	checked("Publish limits and missing files", "Missing/unsafe paths fail loudly; 251 sidecars split 250+1; size-limited batches include HTML overhead and retain sheet-first input order");
} finally {
	// Verify the absolute recursive-delete target stays inside this card's report directory.
	assert.ok(resolve(fixture).startsWith(resolve(report) + sep)); assert.ok(fixture.includes(".verify-publish-")); rmSync(fixture, { recursive: true });
}

const allFiles = root => readdirSync(root, { withFileTypes: true }).flatMap(entry => entry.isDirectory() ? allFiles(join(root, entry.name)) : [join(root, entry.name)]);
const diskFiles = allFiles(dist), publishBytes = statSync(join(dist, "index.html")).size + files.reduce((sum, file) => sum + statSync(join(dist, file.path)).size, 0);
const result = { status: "PASS", checked_at: new Date().toISOString(), method: "Node vm, explicit DOM/Image/canvas/Artifact DB doubles; byte-for-byte source comparison; publish limit fixtures",
	counts: { checks: checks.length, candidates: catalog.length, kinds: kindCounts, rowVisits, sidecars: files.length, publishFiles: files.length + 1, publishBytes, distFiles: diskFiles.length, distBytes: diskFiles.reduce((sum, file) => sum + statSync(file).size, 0) }, checks,
	limitations: ["Browser localhost navigation was denied by the approval gate; no real rendered screenshot or browser decoding check", "Hosted claude.use('db') and Artifact upload were not exercised", "Godot was not run; candidates were not applied to game assets"] };
writeFileSync(join(report, "viewer-checks.json"), JSON.stringify(result, null, 2) + "\n");
console.log(`PASS: ${checks.length} checks; ${rowVisits} rows; ${catalog.length} candidates; ${result.counts.publishFiles} publish files / ${publishBytes} bytes`);
