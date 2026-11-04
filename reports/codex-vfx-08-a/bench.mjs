// Local QA copy of the shared bench; only PFX path changed. No shared output writer.
// pixelfx x SmashNine bench (2026-11-03): the game's own fighter and monster cells, realm art and effect
// strips, drawn in world pixels (fighters: 128 px cells at 1x, feet at y 120 of the cell), with pixelfx
// effects composited at 1x (1 effect px = 1 art px). The camera shows the world at 0.85.
//
//   node reports/pixelfx-eval-2026-11-03/bench.mjs [test ...]
//
// Writes reports/pixelfx-eval-2026-11-03/out/<test>.gif (2x for viewing) and <test>.png (picked moments),
// and game-format candidate strips to art/bakeoff/effects/pixelfx/. pixelfx comes from the pinned checkout next
// to the project (../pixelfx at a84159688af3). Nothing in smash-nine-prototype/ changes.

import { readFileSync, mkdirSync, writeFileSync } from "node:fs";
import { inflateSync } from "node:zlib";
import { join, dirname } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const REPO = join(HERE, "..", "..");
const GAME = join(REPO, "smash-nine-prototype");
const PFX = "C:/Users/TH/Documents/AI/GameProject/pixelfx";
const OUT = join(HERE, "out");
const STRIPS = join(REPO, "art", "bakeoff", "effects", "pixelfx");
const load = (p) => import(pathToFileURL(join(PFX, p)).href);
export const core = await load("src/core/index.js");
const { writeVideo, upscale } = await load("tools/lib/fxlib.mjs");
const { encodePNG } = await load("tools/lib/png.mjs");
const { rasterText } = await load("src/core/font.js");
export const effect = (id) => load(`src/fx/${id}.js`);

// ---- PNG in (8-bit grey, grey+alpha, RGB, RGBA, palette; not interlaced) ------------------------------------

export function readPNG(file) {
  const buf = readFileSync(file);
  let pos = 8, w = 0, h = 0, depth = 0, type = 0, pal = null, trns = null;
  const idat = [];
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos), kind = buf.toString("latin1", pos + 4, pos + 8), body = buf.subarray(pos + 8, pos + 8 + len);
    if (kind === "IHDR") { w = body.readUInt32BE(0); h = body.readUInt32BE(4); depth = body[8]; type = body[9]; if (body[12]) throw new Error(`${file}: interlaced`); }
    else if (kind === "PLTE") pal = body;
    else if (kind === "tRNS") trns = body;
    else if (kind === "IDAT") idat.push(body);
    pos += 12 + len;
  }
  if (depth !== 8) throw new Error(`${file}: bit depth ${depth}`);
  const ch = { 0: 1, 2: 3, 3: 1, 4: 2, 6: 4 }[type], stride = w * ch, raw = inflateSync(Buffer.concat(idat));
  const px = Buffer.alloc(h * stride), data = new Uint8ClampedArray(w * h * 4);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], src = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)), row = y * stride;
    for (let x = 0; x < stride; x++) {
      const a = x >= ch ? px[row + x - ch] : 0, b = y ? px[row - stride + x] : 0, c = x >= ch && y ? px[row - stride + x - ch] : 0;
      let v = src[x];
      if (f === 1) v += a;
      else if (f === 2) v += b;
      else if (f === 3) v += (a + b) >> 1;
      else if (f === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c; }
      px[row + x] = v & 255;
    }
  }
  for (let i = 0; i < w * h; i++) {
    const s = i * ch, d = i * 4;
    if (type === 6) { data[d] = px[s]; data[d + 1] = px[s + 1]; data[d + 2] = px[s + 2]; data[d + 3] = px[s + 3]; }
    else if (type === 2) { data[d] = px[s]; data[d + 1] = px[s + 1]; data[d + 2] = px[s + 2]; data[d + 3] = 255; }
    else if (type === 3) { const k = px[s]; data[d] = pal[k * 3]; data[d + 1] = pal[k * 3 + 1]; data[d + 2] = pal[k * 3 + 2]; data[d + 3] = trns && k < trns.length ? trns[k] : 255; }
    else if (type === 4) { data[d] = data[d + 1] = data[d + 2] = px[s]; data[d + 3] = px[s + 1]; }
    else { data[d] = data[d + 1] = data[d + 2] = px[s]; data[d + 3] = 255; }
  }
  return { w, h, data };
}

const images = new Map();
export const art = (rel) => { if (!images.has(rel)) images.set(rel, readPNG(join(rel.startsWith("art/") || rel.startsWith("reports/") ? REPO : GAME, rel))); return images.get(rel); };

export function crop(img, x, y, w, h) {
  const out = { w, h, data: new Uint8ClampedArray(w * h * 4) };
  for (let j = 0; j < h; j++)
    for (let i = 0; i < w; i++) {
      const sx = x + i, sy = y + j;
      if (sx < 0 || sy < 0 || sx >= img.w || sy >= img.h) continue;
      out.data.set(img.data.subarray((sy * img.w + sx) * 4, (sy * img.w + sx) * 4 + 4), (j * w + i) * 4);
    }
  return out;
}

/** Frame `i` of a horizontal strip of `n` equal frames. */
export const stripFrame = (img, n, i) => crop(img, Math.floor(img.w / n) * i, 0, Math.floor(img.w / n), img.h);

// ---- fighters and monsters ----------------------------------------------------------------------------------

// rows of the 128 px fighter sheets (PlayerBase.ORIGINAL_SHEET_ROWS): name -> [row, frames, fps]
export const FROWS = { idle: [0, 4, 7], walk: [1, 6, 10], attack: [4, 4, 14], shield: [5, 6, 12], hurt: [6, 1, 1] };
// six-row 96 px monster sheets (RealmMonster.ART_ROWS_SIX)
export const MROWS = { idle: [0, 6, 6], walk: [1, 6, 10], windup: [2, 4, 8], attack: [3, 6, 12], hurt: [4, 2, 8] };

/** A body: cell picture with its feet point. */
export function fighter(sheet, row, col) {
  const c = crop(art(sheet), col * 128, row * 128, 128, 128);
  c.root = [64, 120];
  return c;
}
export function monster(sheet, row, col) {
  const c = crop(art(sheet), col * 96, row * 96, 96, 96);
  c.root = [48, 72];
  return c;
}
/** Column of a looping row at time t. */
export const loopCol = (frames, fps, t) => Math.floor(Math.max(0, t) * fps) % frames;

/** The opaque box of a body relative to its feet: [x0, y0, x1, y1]. */
export function boxOf(c) {
  let x0 = Infinity, y0 = Infinity, x1 = -1, y1 = -1;
  for (let y = 0; y < c.h; y++)
    for (let x = 0; x < c.w; x++)
      if (c.data[(y * c.w + x) * 4 + 3] > 127) { x0 = Math.min(x0, x); x1 = Math.max(x1, x); y0 = Math.min(y0, y); y1 = Math.max(y1, y); }
  return [x0 - c.root[0], y0 - c.root[1], x1 - c.root[0], y1 - c.root[1]];
}

/** A pixelfx actor from a body cell: mask, own colours, feet at (0, 0). */
const actors = new WeakMap();
export function actorOf(c) {
  if (actors.has(c)) return actors.get(c);
  const [bx0, by0, bx1, by1] = boxOf(c), w = bx1 - bx0 + 1, h = by1 - by0 + 1, x0 = bx0 + c.root[0], y0 = by0 + c.root[1];
  const mask = new Uint8Array(w * h), pixels = new Uint32Array(w * h);
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const i = ((y + y0) * c.w + x + x0) * 4;
      if (c.data[i + 3] > 127) { mask[y * w + x] = 1; pixels[y * w + x] = core.rgb(c.data[i], c.data[i + 1], c.data[i + 2]); }
    }
  const a = { mask: { w, h, data: mask }, pixels, x: bx0, y: by0, w, h, k: 2, head: [0, by0], chest: [0, Math.round(by0 * 0.5)] };
  actors.set(c, a);
  return a;
}

// ---- canvas -------------------------------------------------------------------------------------------------

export const canvas = (W, H, fill = [14, 13, 20]) => {
  const d = new Uint8ClampedArray(W * H * 4);
  for (let i = 0; i < W * H; i++) d.set([...fill, 255], i * 4);
  return { W, H, d };
};

/** Draw an image with its top-left at (x, y). mode "add" is Godot's BLEND_MODE_ADD (dst + src.rgb * src.a). */
export function blit(cv, img, x, y, { flip = false, alpha = 1, mode = "mix" } = {}) {
  x = Math.round(x); y = Math.round(y);
  for (let j = 0; j < img.h; j++) {
    const ty = y + j;
    if (ty < 0 || ty >= cv.H) continue;
    for (let i = 0; i < img.w; i++) {
      const tx = x + i;
      if (tx < 0 || tx >= cv.W) continue;
      const si = (j * img.w + (flip ? img.w - 1 - i : i)) * 4, a = (img.data[si + 3] / 255) * alpha;
      if (a <= 0) continue;
      const di = (ty * cv.W + tx) * 4;
      for (let k = 0; k < 3; k++) cv.d[di + k] = mode === "add" ? cv.d[di + k] + img.data[si + k] * a : img.data[si + k] * a + cv.d[di + k] * (1 - a);
    }
  }
}
/** A body with its feet at (fx, fy), mirrored about the feet when facing left. */
export function drawBody(cv, c, fx, fy, opts = {}) {
  const x = opts.flip ? fx - (c.w - 1 - c.root[0]) : fx - c.root[0];
  blit(cv, c, x, fy - c.root[1], opts);
}
/** A strip frame drawn like Vfx.spawn: anchor on `at`, optional additive. */
export function drawStrip(cv, frame, anchor, at, { flip = false, mode = "mix", alpha = 1 } = {}) {
  const ax = flip ? frame.w - anchor[0] : anchor[0];
  blit(cv, frame, at[0] - ax, at[1] - anchor[1], { flip, mode, alpha });
}

/** A pixelfx frame over the canvas at 1x: colour blends, light adds (k scales the light). */
export function applyFx(cv, f, lightK = 1, ox = 0, oy = 0) {
  for (let fy = 0; fy < f.h; fy++) {
    const y = fy + oy;
    if (y < 0 || y >= cv.H) continue;
    for (let fx = 0; fx < f.w; fx++) {
      const x = fx + ox;
      if (x < 0 || x >= cv.W) continue;
      const i = fy * f.w + fx, c = f.color[i], l = f.light[i] & 0xffffff, di = (y * cv.W + x) * 4, ca = c >>> 24;
      if (ca) {
        const a = ca / 255;
        cv.d[di] = (c & 255) * a + cv.d[di] * (1 - a);
        cv.d[di + 1] = ((c >>> 8) & 255) * a + cv.d[di + 1] * (1 - a);
        cv.d[di + 2] = ((c >>> 16) & 255) * a + cv.d[di + 2] * (1 - a);
      }
      if (l) {
        cv.d[di] += (l & 255) * lightK;
        cv.d[di + 1] += ((l >>> 8) & 255) * lightK;
        cv.d[di + 2] += ((l >>> 16) & 255) * lightK;
      }
    }
  }
}

/** Realm floor: the far and middle background layers cropped at (sx, sy), platform art along the floor line. */
export function realm(cv, name, { sx = 600, sy = 420, floorY = null, platform = true } = {}) {
  for (const layer of ["bg_far", "bg_mid"]) {
    const img = art(`assets/art/realm_${name}/${layer}.png`);
    blit(cv, crop(img, sx, sy, cv.W, cv.H), 0, 0);
  }
  if (floorY !== null && platform) {
    const p = art(`assets/art/realm_${name}/platform_main.png`);
    let top = 0;
    for (; top < p.h; top++) if (p.data[(top * p.w + (p.w >> 1)) * 4 + 3] > 127) break;
    for (let x = -40; x < cv.W; x += p.w - 8) blit(cv, p, x, floorY - top + 1);
  }
}

export function label(cv, str, x, y, rgb = [236, 232, 246]) {
  const put = (X, Y, c) => { if (X >= 0 && Y >= 0 && X < cv.W && Y < cv.H) cv.d.set([...c, 255], (Y * cv.W + X) * 4); };
  rasterText(str, "mini", (gx, gy) => put(x + gx + 1, y + gy + 1, [0, 0, 0]));
  rasterText(str, "mini", (gx, gy) => put(x + gx, y + gy, rgb));
}

// ---- pixelfx instances ------------------------------------------------------------------------------------

/** A live pixelfx effect drawn into its own frame and composited with its origin at (x, y) of the canvas. */
export function fxAt(mod, opts, x, y, pad = 8) {
  const [w, h] = mod.meta.size, [ox, oy] = mod.meta.origin;
  const inst = core.createFx(mod, { ...opts, x: ox + pad, y: oy + pad });
  const back = core.createFrame(w + pad * 2, h + pad * 2), front = core.createFrame(w + pad * 2, h + pad * 2);
  return {
    inst,
    update(dt) { inst.update(dt); },
    done() { return inst.done(); },
    drawBack(cv, k = 1) { core.clearFrame(back); inst.draw(back, "back"); applyFx(cv, back, k, Math.round(x - ox - pad), Math.round(y - oy - pad)); },
    drawFront(cv, k = 1) { core.clearFrame(front); inst.draw(front, "front"); applyFx(cv, front, k, Math.round(x - ox - pad), Math.round(y - oy - pad)); },
  };
}

// ---- output -----------------------------------------------------------------------------------------------

/** Panels in a grid played together: a GIF (k x) and a PNG of picked frames (k x). */
export function clip(name, panels, { cols, seconds, fps = 30, k = 2, stills = [], gap = 2 }) {
  const pw = panels[0].W, ph = panels[0].H, rows = Math.ceil(panels.length / cols);
  const W = cols * pw + (cols - 1) * gap, H = rows * ph + (rows - 1) * gap, n = Math.round(seconds * fps);
  const frames = [], picks = [];
  for (let i = 0; i < n; i++) {
    const cv = canvas(W, H, [40, 38, 52]);
    panels.forEach((p, j) => {
      if (i > 0) p.tick(1 / fps);
      blit(cv, { w: pw, h: ph, data: p.draw().d }, (j % cols) * (pw + gap), Math.floor(j / cols) * (ph + gap));
    });
    frames.push({ color: cv.d });
    if (stills.includes(i)) { label(cv, `${(i / fps).toFixed(2)}S`, W - 30, H - 9, [255, 230, 140]); picks.push(cv); }
  }
  mkdirSync(OUT, { recursive: true });
  writeVideo(join(OUT, `${name}.gif`), { w: W, h: H, fps, frames }, k, { loops: 1 });
  if (picks.length) {
    const sh = picks.length * H + (picks.length - 1) * 4, sheet = canvas(W, sh, [255, 255, 255]);
    picks.forEach((p, i) => blit(sheet, { w: W, h: H, data: p.d }, 0, i * (H + 4)));
    writeFileSync(join(OUT, `${name}.png`), encodePNG(W * k, sh * k, upscale(sheet.d, W, sh, k)));
  }
  console.log(`${name}: ${n} frames ${W}x${H} -> out/${name}.gif${picks.length ? ` + ${name}.png` : ""}`);
}

export function savePNG(file, cv, k = 1) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, encodePNG(cv.W * k, cv.H * k, k === 1 ? cv.d : upscale(cv.d, cv.W, cv.H, k)));
}

// ---- strips for the game (Vfx.gd: one row of equal frames, anchor, fps, additive) ---------------------------

/**
 * Bake a pixelfx effect into a game strip: frames of size [w, h] with the effect's origin at `anchor`.
 * additive: colour and light summed premultiplied into opaque pixels (alpha 0/1), so Godot's add blend shows the same.
 * mixed (normal blend): translucent colour keeps its alpha and the light is folded in as colour over it, alpha
 * raised by the light's brightness (soft dust with glints; reads like the add blend over dark realms).
 * Neither: the colour layer only, alpha kept. The 1 px border of every frame stays empty (D32).
 */
export function bakeStrip(mod, opts, { frames, fps, w, h, anchor, additive = true, mixed = false, lightK = 1, minLight = 10, border = 1, start = 0 }) {
  const inst = core.createFx(mod, { ...opts, x: anchor[0], y: anchor[1] });
  const step = 1 / fps, out = { w: w * frames, h, data: new Uint8ClampedArray(w * frames * h * 4) };
  const f = core.createFrame(w, h);
  if (start > 0) inst.update(start);
  for (let n = 0; n < frames; n++) {
    if (n > 0) inst.update(step);
    core.clearFrame(f);
    inst.draw(f, "back");
    inst.draw(f, "front");
    for (let y = border; y < h - border; y++)
      for (let x = border; x < w - border; x++) {
        const i = y * w + x, c = f.color[i], l = f.light[i] & 0xffffff, a = (c >>> 24) / 255, d = (y * out.w + n * w + x) * 4;
        let r = (c & 255) * a, g = ((c >>> 8) & 255) * a, b = ((c >>> 16) & 255) * a;
        if (mixed) {
          r += (l & 255) * lightK; g += ((l >>> 8) & 255) * lightK; b += ((l >>> 16) & 255) * lightK;
          const al = Math.min(1, a + Math.max(r, g, b) / 255 * (1 - a));
          if (al * 255 < 6 || (a === 0 && Math.max(r, g, b) < minLight)) continue;
          out.data[d] = r / al; out.data[d + 1] = g / al; out.data[d + 2] = b / al; out.data[d + 3] = al * 255;
        } else if (additive) {
          r += (l & 255) * lightK; g += ((l >>> 8) & 255) * lightK; b += ((l >>> 16) & 255) * lightK;
          if (Math.max(r, g, b) < minLight && a === 0) continue;
          out.data[d] = r; out.data[d + 1] = g; out.data[d + 2] = b; out.data[d + 3] = 255;
        } else if (a > 0) {
          out.data[d] = c & 255; out.data[d + 1] = (c >>> 8) & 255; out.data[d + 2] = (c >>> 16) & 255; out.data[d + 3] = a * 255;
        }
      }
  }
  return out;
}
