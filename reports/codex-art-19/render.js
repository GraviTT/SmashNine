/* CODEX-ART-19: deterministic SVG/PNG renderer. No external packages. */
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const ROOT = path.resolve(__dirname, "../..");
const OUT = __dirname;
const DATA_PATH = path.join(ROOT, "reports", "bot-behavior", "tree.json");
const FINAL_PATH = path.join(ROOT, "reports", "bot-behavior", "bot-behavior-tree.png");
const CHROME = "C:/Program Files/Google/Chrome/Application/chrome.exe";
const EDGE = "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const BROWSER = fs.existsSync(CHROME) ? CHROME : EDGE;
const W = 3840;
const H = 2800;
const DARK = "#1F2430";
const BG = "#F7F8FB";
const WHITE = "#FFFFFF";

const data = JSON.parse(fs.readFileSync(DATA_PATH, "utf8"));

function esc(value) {
	return String(value).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function expectedStrings() {
	const out = [data.title, data.subtitle, data.root];
	for (const group of data.groups) {
		out.push(group.label);
		for (const branch of group.branches) out.push(branch.label, ...branch.leaves);
	}
	out.push(data.characters_label);
	for (const character of data.characters) out.push(character.name, character.role, character.profile, ...character.leaves);
	out.push(data.footer);
	return out;
}

const EXPECTED = expectedStrings();

function estimate(text, size, bold = false) {
	let units = 0;
	for (const ch of text) {
		if (ch === " ") units += 0.34;
		else if (/^[\x00-\x7F]$/.test(ch)) units += /[MW@%]/.test(ch) ? 0.78 : 0.57;
		else units += 0.96;
	}
	return units * size * (bold ? 1.03 : 1);
}

function wrap(text, maxWidth, size, bold = false) {
	const forced = String(text).split("\n");
	const lines = [];
	for (const part of forced) {
		const words = part.split(" ");
		let line = "";
		for (const word of words) {
			const next = line ? `${line} ${word}` : word;
			if (line && estimate(next, size, bold) > maxWidth) {
				lines.push(line);
				line = word;
			} else {
				line = next;
			}
		}
		lines.push(line);
	}
	return lines;
}

function tint(hex, amount = 0.9) {
	const n = parseInt(hex.slice(1), 16);
	const r = (n >> 16) & 255;
	const g = (n >> 8) & 255;
	const b = n & 255;
	const mix = c => Math.round(c + (255 - c) * amount).toString(16).padStart(2, "0");
	return `#${mix(r)}${mix(g)}${mix(b)}`;
}

function textTag(state, text, x, y, width, size, opts = {}) {
	const bold = !!opts.bold;
	const lineHeight = opts.lineHeight || Math.round(size * 1.34);
	const lines = opts.lines || wrap(text, width, size, bold);
	const anchor = opts.anchor || "start";
	const fill = opts.fill || DARK;
	const parent = opts.parent || "";
	const cls = opts.cls || "source-text";
	state.texts.push(text);
	for (let i = 0; i < lines.length; i++) {
		const tw = estimate(lines[i], size, bold);
		let x0 = x;
		if (anchor === "middle") x0 -= tw / 2;
		else if (anchor === "end") x0 -= tw;
		const baseline = y + i * lineHeight;
		state.textBoxes.push({text, line: i, parent, x: x0, y: baseline - size, w: tw, h: size * 1.22});
	}
	const tspans = lines.map((line, i) => `<tspan x="${x}" dy="${i === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`).join("");
	return `<text class="${cls}" data-source-text="${esc(text)}" data-parent="${esc(parent)}" x="${x}" y="${y}" font-size="${size}" font-weight="${bold ? 700 : 400}" fill="${fill}" text-anchor="${anchor}">${tspans}</text>`;
}

function nodeRect(state, id, x, y, w, h, fill = WHITE, stroke = "#D8DDEA", sw = 2, radius = 22) {
	state.nodes.push({id, x, y, w, h});
	return `<rect id="box-${id}" data-box="${id}" x="${x}" y="${y}" width="${w}" height="${h}" rx="${radius}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/>`;
}

function connector(points, color, width = 8) {
	const d = points.map((p, i) => `${i ? "L" : "M"}${p[0]},${p[1]}`).join(" ");
	return `<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round" opacity="0.82"/>`;
}

function svgStart() {
	return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
	<defs>
		<pattern id="grid" width="64" height="64" patternUnits="userSpaceOnUse"><path d="M64 0H0V64" fill="none" stroke="#DDE2EE" stroke-width="1" opacity="0.34"/></pattern>
	</defs>
	<rect width="${W}" height="${H}" fill="${BG}"/><rect width="${W}" height="${H}" fill="url(#grid)"/>`;
}

function header(state) {
	let s = "";
	s += textTag(state, data.title, 120, 112, 1800, 76, {bold: true, lineHeight: 86, parent: "title"});
	s += textTag(state, data.subtitle, 120, 178, 3500, 34, {parent: "subtitle", fill: "#535B6E"});
	s += `<path d="M120 214 H3720" stroke="#D9DEEA" stroke-width="3"/>`;
	return s;
}

function footer(state) {
	let s = `<path d="M120 2728 H3720" stroke="#D9DEEA" stroke-width="3"/>`;
	s += textTag(state, data.footer, 1920, 2772, 3500, 28, {anchor: "middle", parent: "footer", fill: "#535B6E"});
	return s;
}

function drawRoot(state, x, y, w = 560, h = 170) {
	let s = nodeRect(state, "root", x, y, w, h, DARK, DARK, 0, 34);
	s += `<rect x="${x + 18}" y="${y + 18}" width="10" height="${h - 36}" rx="5" fill="#FFB53D"/>`;
	const lines = data.root.split("\n");
	s += textTag(state, data.root, x + w / 2 + 10, y + 66, w - 80, 46, {bold: true, anchor: "middle", fill: WHITE, lineHeight: 56, lines, parent: "root"});
	return s;
}

function drawGroupLabel(state, group, id, x, y, w = 220, h = 94) {
	let s = nodeRect(state, id, x, y, w, h, DARK, group.color, 5, 22);
	s += `<rect x="${x}" y="${y}" width="14" height="${h}" rx="7" fill="${group.color}"/>`;
	s += textTag(state, group.label, x + w / 2 + 5, y + 61, w - 40, 44, {bold: true, anchor: "middle", fill: WHITE, parent: id});
	return s;
}

function branchHeight(branch, width, leafSize = 28) {
	let h = 78;
	for (const leaf of branch.leaves) h += wrap(leaf, width - 74, leafSize).length * 37 + 14;
	return h + 18;
}

function drawBranch(state, group, branch, id, x, y, w, h = null, leafSize = 28) {
	const actualH = h || branchHeight(branch, w, leafSize);
	let s = nodeRect(state, id, x, y, w, actualH, WHITE, tint(group.color, 0.35), 3, 20);
	s += `<rect x="${x}" y="${y}" width="${w}" height="64" rx="18" fill="${tint(group.color, 0.86)}"/>`;
	s += `<rect x="${x}" y="${y + 46}" width="${w}" height="18" fill="${tint(group.color, 0.86)}"/>`;
	s += `<circle cx="${x + 30}" cy="${y + 32}" r="8" fill="${group.color}"/>`;
	s += textTag(state, branch.label, x + 52, y + 44, w - 72, 34, {bold: true, parent: id});
	let cy = y + 94;
	for (const leaf of branch.leaves) {
		const lines = wrap(leaf, w - 74, leafSize);
		s += `<circle cx="${x + 30}" cy="${cy - 8}" r="5" fill="${group.color}"/>`;
		s += textTag(state, leaf, x + 52, cy, w - 74, leafSize, {lines, lineHeight: 37, parent: id});
		cy += lines.length * 37 + 14;
	}
	return {svg: s, h: actualH};
}

function faceHref(character) {
	return "../../" + character.face.replace(/\\/g, "/");
}

function drawCharacter(state, character, id, x, y, w, h, compact = false) {
	const pale = tint(character.color, 0.9);
	let s = nodeRect(state, id, x, y, w, h, WHITE, character.color, 4, 24);
	s += `<rect x="${x}" y="${y}" width="${w}" height="${compact ? 126 : 142}" rx="22" fill="${pale}"/>`;
	s += `<rect x="${x}" y="${y + (compact ? 105 : 121)}" width="${w}" height="22" fill="${pale}"/>`;
	const face = compact ? 92 : 108;
	const fx = x + 24;
	const fy = y + 18;
	s += `<rect x="${fx}" y="${fy}" width="${face}" height="${face}" rx="24" fill="#E7EBF4" stroke="${character.color}" stroke-width="4"/>`;
	s += `<image href="${esc(faceHref(character))}" x="${fx}" y="${fy}" width="${face}" height="${face}" preserveAspectRatio="xMidYMid slice" style="image-rendering:pixelated"/>`;
	const tx = fx + face + 22;
	s += textTag(state, character.name, tx, y + 53, w - (tx - x) - 20, compact ? 36 : 40, {bold: true, parent: id});
	s += textTag(state, character.role, tx, y + 92, w - (tx - x) - 20, 28, {bold: true, fill: "#4B5264", parent: id});
	s += textTag(state, character.profile, x + 24, y + (compact ? 157 : 174), w - 48, 28, {bold: true, parent: id});
	let cy = y + (compact ? 205 : 224);
	const leafSize = 28;
	for (const leaf of character.leaves) {
		const lines = wrap(leaf, w - 66, leafSize);
		s += `<circle cx="${x + 27}" cy="${cy - 8}" r="5" fill="${character.color}"/>`;
		s += textTag(state, leaf, x + 48, cy, w - 66, leafSize, {lines, lineHeight: 36, parent: id});
		cy += lines.length * 36 + 11;
	}
	return s;
}

function drawCharactersLabel(state, x, y, w = 390, h = 94) {
	let s = nodeRect(state, "characters-label", x, y, w, h, DARK, "#FFB53D", 5, 22);
	s += `<rect x="${x}" y="${y}" width="14" height="${h}" rx="7" fill="#FFB53D"/>`;
	s += textTag(state, data.characters_label, x + w / 2 + 6, y + 61, w - 38, 44, {bold: true, anchor: "middle", fill: WHITE, parent: "characters-label"});
	return s;
}

function renderA() {
	const state = {texts: [], nodes: [], textBoxes: []};
	let s = svgStart() + header(state);
	s += `<g id="connectors">`;
	s += connector([[1640, 1038], [1550, 1038], [1550, 350], [1280, 350]], data.groups[0].color);
	s += connector([[2200, 1038], [2290, 1038], [2290, 350], [2320, 350]], data.groups[1].color);
	s += connector([[1640, 1082], [1550, 1082], [1550, 1210], [1280, 1210]], data.groups[2].color);
	s += connector([[2200, 1082], [2290, 1082], [2290, 1210], [2320, 1210]], data.groups[3].color);
	s += connector([[1920, 1130], [1920, 2140]], "#FFB53D");
	s += `</g>`;
	s += drawRoot(state, 1640, 960, 560, 170);

	const panels = [
		{x: 80, y: 285, w: 1440, h: 720, group: data.groups[0], labelX: 1260, labelY: 303},
		{x: 2320, y: 285, w: 1440, h: 720, group: data.groups[1], labelX: 2320, labelY: 303},
		{x: 80, y: 1140, w: 1440, h: 980, group: data.groups[2], labelX: 1260, labelY: 1163},
		{x: 2320, y: 1140, w: 1440, h: 805, group: data.groups[3], labelX: 2320, labelY: 1163}
	];
	for (const [pi, p] of panels.entries()) {
		s += `<rect x="${p.x}" y="${p.y}" width="${p.w}" height="${p.h}" rx="30" fill="${tint(p.group.color, 0.96)}" stroke="${tint(p.group.color, 0.55)}" stroke-width="3"/>`;
		s += drawGroupLabel(state, p.group, `a-g-${p.group.id}`, p.labelX, p.labelY, 230, 94);
		const columns = p.group.branches.length === 4 ? 2 : p.group.branches.length;
		const bw = p.group.branches.length === 4 ? 670 : 430;
		const gap = 26;
		const startX = p.x + 28;
		const startY = p.y + 130;
		for (let i = 0; i < p.group.branches.length; i++) {
			const col = i % columns;
			const row = Math.floor(i / columns);
			const bx = startX + col * (bw + gap);
			const by = startY + row * (p.group.branches.length === 4 ? 428 : 328);
			const bh = p.group.branches.length === 4 ? 410 : p.h - 158;
			s += drawBranch(state, p.group, p.group.branches[i], `a-${p.group.id}-${i}`, bx, by, bw, bh, 28).svg;
		}
	}

	s += drawCharactersLabel(state, 1700, 2140, 440, 94);
	const cw = 704, gap = 28, start = 104;
	for (let i = 0; i < data.characters.length; i++) {
		s += connector([[1920, 2234], [1920, 2242], [start + i * (cw + gap) + cw / 2, 2242], [start + i * (cw + gap) + cw / 2, 2250]], data.characters[i].color, 6);
		s += drawCharacter(state, data.characters[i], `a-char-${data.characters[i].id}`, start + i * (cw + gap), 2250, cw, 475, true);
	}
	s += footer(state) + `</svg>`;
	return {svg: s, state};
}

function renderB() {
	const state = {texts: [], nodes: [], textBoxes: []};
	let s = svgStart() + header(state);
	const railX = 600;
	s += `<g id="connectors">${connector([[560, 1390], [railX, 1390], [railX, 350]], "#AAB2C3", 10)}${connector([[railX, 350], [railX, 2350]], "#AAB2C3", 10)}</g>`;
	s += drawRoot(state, 40, 1305, 520, 170);
	const ys = [280, 700, 1120, 1590];
	const hs = [370, 370, 420, 330];
	for (let gi = 0; gi < data.groups.length; gi++) {
		const group = data.groups[gi];
		const gy = ys[gi];
		const gh = hs[gi];
		s += connector([[railX, gy + gh / 2], [650, gy + gh / 2]], group.color, 8);
		s += drawGroupLabel(state, group, `b-g-${group.id}`, 650, gy + gh / 2 - 47, 220, 94);
		const bx0 = 940;
		const gap = 24;
		const bw = Math.floor((2820 - gap * (group.branches.length - 1)) / group.branches.length);
		for (let bi = 0; bi < group.branches.length; bi++) {
			const bx = bx0 + bi * (bw + gap);
			s += connector([[870, gy + gh / 2], [905, gy + gh / 2], [905, gy + 28], [bx, gy + 28]], group.color, 5);
			s += drawBranch(state, group, group.branches[bi], `b-${group.id}-${bi}`, bx, gy, bw, gh, 28).svg;
		}
	}
	const charY = 2128;
	s += connector([[railX, 2350], [650, 2350]], "#FFB53D", 8);
	s += drawCharactersLabel(state, 650, 2303, 440, 94);
	const cw = 525, gap = 15, start = 1140;
	for (let i = 0; i < data.characters.length; i++) {
		const cx = start + i * (cw + gap);
		s += connector([[1090, 2350], [1110, 2350], [1110, 2100], [cx + cw / 2, 2100], [cx + cw / 2, charY]], data.characters[i].color, 5);
		s += drawCharacter(state, data.characters[i], `b-char-${data.characters[i].id}`, cx, charY, cw, 570, true);
	}
	s += footer(state) + `</svg>`;
	return {svg: s, state};
}

function renderC() {
	const state = {texts: [], nodes: [], textBoxes: []};
	let s = svgStart() + header(state);
	const rootX = 1640, rootY = 260;
	s += `<g id="connectors">`;
	const colX = [80, 1000, 1920, 2840];
	for (let i = 0; i < 4; i++) {
		const center = colX[i] + 440;
		s += connector([[1920, 430], [1920, 448], [center, 448], [center, 470]], data.groups[i].color, 8);
	}
	s += connector([[1920, 430], [1920, 1897]], "#FFB53D", 9);
	s += `</g>`;
	s += drawRoot(state, rootX, rootY, 560, 170);
	for (let gi = 0; gi < 4; gi++) {
		const group = data.groups[gi];
		const x = colX[gi];
		s += `<rect x="${x}" y="470" width="880" height="1400" rx="30" fill="${tint(group.color, 0.96)}" stroke="${tint(group.color, 0.55)}" stroke-width="3"/>`;
		s += drawGroupLabel(state, group, `c-g-${group.id}`, x + 305, 490, 270, 94);
		let y = 616;
		for (let bi = 0; bi < group.branches.length; bi++) {
			const branch = group.branches[bi];
			const remaining = 1768 - y;
			const natural = branchHeight(branch, 824, 28);
			const countLeft = group.branches.length - bi;
			const h = Math.max(natural, Math.floor((remaining - (countLeft - 1) * 18) / countLeft));
			s += connector([[x + 440, y - 32], [x + 440, y]], group.color, 5);
			s += drawBranch(state, group, branch, `c-${group.id}-${bi}`, x + 28, y, 824, h, 28).svg;
			y += h + 18;
		}
	}
	s += drawCharactersLabel(state, 1700, 1870, 440, 94);
	const cw = 704, gap = 28, start = 104, charY = 2000;
	for (let i = 0; i < data.characters.length; i++) {
		const cx = start + i * (cw + gap);
		s += connector([[1920, 1964], [1920, 1982], [cx + cw / 2, 1982], [cx + cw / 2, charY]], data.characters[i].color, 6);
		s += drawCharacter(state, data.characters[i], `c-char-${data.characters[i].id}`, cx, charY, cw, 700, false);
	}
	s += footer(state) + `</svg>`;
	return {svg: s, state};
}

function multiset(values) {
	const m = new Map();
	for (const value of values) m.set(value, (m.get(value) || 0) + 1);
	return m;
}

function compareText(actual) {
	const a = multiset(actual), e = multiset(EXPECTED);
	const missing = [], extra = [];
	for (const [k, n] of e) if ((a.get(k) || 0) !== n) missing.push({text: k, expected: n, actual: a.get(k) || 0});
	for (const [k, n] of a) if ((e.get(k) || 0) !== n) extra.push({text: k, expected: e.get(k) || 0, actual: n});
	return {expectedCount: EXPECTED.length, actualCount: actual.length, missing, extra, ok: missing.length === 0 && extra.length === 0};
}

function overlapCheck(nodes) {
	const overlaps = [];
	for (let i = 0; i < nodes.length; i++) for (let j = i + 1; j < nodes.length; j++) {
		const a = nodes[i], b = nodes[j];
		const ox = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
		const oy = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
		if (ox > 0.5 && oy > 0.5) overlaps.push([a.id, b.id, ox, oy]);
	}
	return overlaps;
}

function textGeometryCheck(state) {
	const overlaps = [];
	for (let i = 0; i < state.textBoxes.length; i++) for (let j = i + 1; j < state.textBoxes.length; j++) {
		const a = state.textBoxes[i], b = state.textBoxes[j];
		const ox = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
		const oy = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
		if (ox > 0.5 && oy > 0.5) overlaps.push([a.text, a.line, b.text, b.line, ox, oy]);
	}
	const byId = new Map(state.nodes.map(n => [n.id, n]));
	const outsideParent = [];
	for (const t of state.textBoxes) {
		const p = byId.get(t.parent);
		if (!p) continue;
		if (t.x < p.x - 0.5 || t.y < p.y - 0.5 || t.x + t.w > p.x + p.w + 0.5 || t.y + t.h > p.y + p.h + 0.5) outsideParent.push([t.text, t.line, t.parent]);
	}
	return {overlaps, outsideParent};
}

function luminance(hex) {
	const rgb = [1, 3, 5].map(i => parseInt(hex.slice(i, i + 2), 16) / 255).map(v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4));
	return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2];
}

function contrast(a, b) {
	const x = luminance(a), y = luminance(b);
	return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
}

function html(svg) {
	return `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;width:${W}px;height:${H}px;overflow:hidden;background:${BG}}svg{display:block;font-family:"Malgun Gothic",sans-serif;text-rendering:geometricPrecision}.source-text{dominant-baseline:alphabetic}</style></head><body>${svg}</body></html>`;
}

function runRaster(svgPath, pngPath) {
	const script = path.join(OUT, "rasterize.ps1");
	const result = cp.spawnSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, "-SvgPath", svgPath, "-PngPath", pngPath], {encoding: "utf8", timeout: 45000});
	if (result.error || result.status !== 0 || !fs.existsSync(pngPath)) throw new Error(`raster render failed: ${result.error || result.status}\n${result.stderr || result.stdout}`);
}

function pngSize(file) {
	const b = fs.readFileSync(file);
	if (b.toString("ascii", 1, 4) !== "PNG") throw new Error(`not PNG: ${file}`);
	return {width: b.readUInt32BE(16), height: b.readUInt32BE(20)};
}

function makeImagePage(src, width, height, sourceX = 0, sourceY = 0, scale = 1) {
	const abs = path.resolve(src).replace(/\\/g, "/");
	return `<!doctype html><html><head><style>html,body{margin:0;width:${width}px;height:${height}px;overflow:hidden;background:${BG}}img{position:absolute;left:${-sourceX * scale}px;top:${-sourceY * scale}px;width:${W * scale}px;height:${H * scale}px;image-rendering:auto}</style></head><body><img src="file:///${abs}"></body></html>`;
}

function makeContact(variants) {
	const cw = 3060, ch = 1450, topW = 960, topH = 700, cropW = 960, cropH = 675;
	const cropPoints = [{x: 80, y: 1140}, {x: 790, y: 1120}, {x: 1920, y: 690}];
	let body = "";
	for (let i = 0; i < variants.length; i++) {
		const left = 60 + i * 990;
		const src = path.resolve(variants[i]).replace(/\\/g, "/");
		body += `<div style="position:absolute;left:${left}px;top:28px;width:${topW}px;height:${topH}px;overflow:hidden;border:2px solid #CAD1DF;background:white"><img src="file:///${src}" style="width:960px;height:700px"></div>`;
		body += `<div style="position:absolute;left:${left}px;top:754px;width:${cropW}px;height:${cropH}px;overflow:hidden;border:2px solid #CAD1DF;background:white"><img src="file:///${src}" style="position:absolute;left:${-cropPoints[i].x}px;top:${-cropPoints[i].y}px;width:${W}px;height:${H}px"></div>`;
	}
	return `<!doctype html><html><head><style>html,body{margin:0;width:${cw}px;height:${ch}px;overflow:hidden;background:#E9EDF5}img{display:block}</style></head><body>${body}</body></html>`;
}

function main() {
	fs.mkdirSync(OUT, {recursive: true});
	const variants = {a: renderA(), b: renderB(), c: renderC()};
	const checks = {generatedAt: new Date().toISOString(), source: path.relative(ROOT, DATA_PATH), variants: {}, contrast: {}};
	for (const [name, result] of Object.entries(variants)) {
		const text = compareText(result.state.texts);
		const overlaps = overlapCheck(result.state.nodes);
		const textGeometry = textGeometryCheck(result.state);
		if (!text.ok) throw new Error(`${name}: text mismatch ${JSON.stringify(text)}`);
		if (overlaps.length) throw new Error(`${name}: node overlaps ${JSON.stringify(overlaps)}`);
		if (textGeometry.overlaps.length || textGeometry.outsideParent.length) throw new Error(`${name}: text geometry ${JSON.stringify(textGeometry)}`);
		const svgPath = path.join(OUT, `variant-${name}.svg`);
		const htmlPath = path.join(OUT, `variant-${name}.html`);
		const pngPath = path.join(OUT, `variant-${name}.png`);
		fs.writeFileSync(svgPath, result.svg, "utf8");
		fs.writeFileSync(htmlPath, html(result.svg), "utf8");
		runRaster(svgPath, pngPath);
		checks.variants[name] = {text, overlaps, textGeometry, edgeClipping: result.state.nodes.filter(n => n.x < 0 || n.y < 0 || n.x + n.w > W || n.y + n.h > H), png: pngSize(pngPath)};
	}

	fs.copyFileSync(path.join(OUT, "variant-c.png"), FINAL_PATH);
	const compose = cp.spawnSync("powershell", ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", path.join(OUT, "compose.ps1"), "-OutDir", OUT, "-FinalPath", FINAL_PATH], {encoding: "utf8", timeout: 45000});
	if (compose.error || compose.status !== 0) throw new Error(`compose failed: ${compose.error || compose.status}\n${compose.stderr || compose.stdout}`);

	checks.final = {chosen: "variant-c", png: pngSize(FINAL_PATH), halfPreview: pngSize(path.join(OUT, "chosen-50.png")), contact: pngSize(path.join(OUT, "contact.png"))};
	checks.contrast = {
		"dark_on_background": contrast(DARK, BG),
		"dark_on_white": contrast(DARK, WHITE),
		"white_on_dark": contrast(WHITE, DARK),
		"muted_on_background": contrast("#535B6E", BG),
		"dark_on_lightest_branch_tint_min": Math.min(...data.groups.map(g => contrast(DARK, tint(g.color, 0.86))), ...data.characters.map(c => contrast(DARK, tint(c.color, 0.9))))
	};
	checks.contrast.minimum = Math.min(...Object.values(checks.contrast));
	fs.writeFileSync(path.join(OUT, "checks.json"), JSON.stringify(checks, null, 2) + "\n", "utf8");
	process.stdout.write(JSON.stringify(checks, null, 2) + "\n");
}

main();
