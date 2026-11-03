// Character motions with pixelfx effects added (user 2026-11-03: "Luna와 Frey의 일부 모션에 ... /도트이펙트를
// 적용한 스프라이트를 추가하여 완성도가 높아지는지를 테스트"). Each test plays the game's motion at the game's
// timing, NOW (what the game shows today) next to NOW + PIXELFX, on realm art at 1x world px.
//
//   node reports/pixelfx-eval-2026-11-03/motions.mjs [luna-idle] [luna-land] [frey-run] [frey-chain] [strips]
//
// Timings from the code: Luna/Frey idle 6 frames at 6.3 fps, walk 8 frames at 11.31 fps (MotionSpeeds), land
// strip 2 frames at 12 fps, Vfx landing_dust 5 at 41.7 fps; Frey's J chain (Frey.gd): cut 1 startup 0.07 s +
// 0.16 s, cut 2 0.08 + 0.18, finisher 0.11 + 0.26 with a 0.1 s glint, attack_chain row of the 192 px move sheet
// (wind-up frame during startup, cut frame after), frey_slash 6 frames at 36 fps at the body centre, scale
// reach / 192 (/2 for the 2x file), 0.62 thick, turned to the aim.
import {
  TESTS, run, art, crop, stripFrame, actorOf, boxOf, canvas, blit, realm, label, applyFx, clip, effect, core, bakeStrip, saveStrip,
} from "./bench.mjs";

const FREY = "assets/art/frey/frey_sheet.png", LUNA = "assets/art/luna/luna_sheet.png", MOVES = "assets/art/frey/frey_moves_sheet.png";
const cell = (sheet, index) => { const c = crop(art(sheet), (index % 6) * 128, Math.floor(index / 6) * 128, 128, 128); c.root = [64, 120]; return c; };
const moveCell = (row, col) => { const c = crop(art(MOVES), col * 192, row * 192, 192, 192); c.root = [96, 152]; return c; };
const stripCell = (path, n, i) => { const c = stripFrame(art(path), n, i); c.root = [c.w >> 1, c.h - 8]; return c; };
const IDLE = (t) => Math.floor(Math.max(0, t) * 6.3) % 6;
const WALK = (t) => 6 + (Math.floor(Math.max(0, t) * 11.31) % 8);

function drawBody(cv, c, fx, fy, { flip = false, bright = 1 } = {}) {
  const x = Math.round(flip ? fx - (c.w - 1 - c.root[0]) : fx - c.root[0]), y = Math.round(fy - c.root[1]);
  if (bright === 1) return blit(cv, c, x, y, { flip });
  const b = { w: c.w, h: c.h, data: new Uint8ClampedArray(c.data) };
  for (let i = 0; i < b.data.length; i += 4) for (let k = 0; k < 3; k++) b.data[i + k] = Math.min(255, b.data[i + k] * bright);
  blit(cv, b, x, y, { flip });
}

/** An affine, nearest-sampled, optionally additive draw (Godot Sprite2D with offset, scale, rotation). */
function drawAffine(cv, img, pos, offset, sx, sy, rot, mode = "add") {
  const cs = Math.cos(rot), sn = Math.sin(rot), corners = [[0, 0], [img.w, 0], [0, img.h], [img.w, img.h]].map(([u, v]) => {
    const lx = (u + offset[0]) * sx, ly = (v + offset[1]) * sy;
    return [pos[0] + lx * cs - ly * sn, pos[1] + lx * sn + ly * cs];
  });
  const x0 = Math.floor(Math.min(...corners.map((c) => c[0]))), x1 = Math.ceil(Math.max(...corners.map((c) => c[0])));
  const y0 = Math.floor(Math.min(...corners.map((c) => c[1]))), y1 = Math.ceil(Math.max(...corners.map((c) => c[1])));
  for (let y = Math.max(0, y0); y < Math.min(cv.H, y1); y++)
    for (let x = Math.max(0, x0); x < Math.min(cv.W, x1); x++) {
      const dx = x + 0.5 - pos[0], dy = y + 0.5 - pos[1], lx = dx * cs + dy * sn, ly = -dx * sn + dy * cs;
      const u = Math.floor(lx / sx - offset[0]), v = Math.floor(ly / sy - offset[1]);
      if (u < 0 || v < 0 || u >= img.w || v >= img.h) continue;
      const si = (v * img.w + u) * 4, a = img.data[si + 3] / 255, di = (y * cv.W + x) * 4;
      if (a <= 0) continue;
      for (let k = 0; k < 3; k++) cv.d[di + k] = mode === "add" ? cv.d[di + k] + img.data[si + k] * a : img.data[si + k] * a + cv.d[di + k] * (1 - a);
    }
}

/** A panel driven by a script: script(t) -> { body, x, y, flip, bright, strips: [...], spawns: [...] }. */
function panel({ W, H, floor, realmName = "alfheim", sx = 700, sy = 520, title, script, lightK = 1 }) {
  const back = core.createFrame(W, H), front = core.createFrame(W, H), live = [];
  let t = 0;
  const fired = new Set();
  return {
    W, H,
    tick(dt) {
      t += dt;
      const s = script(t, floor);
      for (const sp of s.spawns ?? []) {
        if (fired.has(sp.key)) continue;
        fired.add(sp.key);
        live.push(core.createFx(sp.mod, { ...(sp.opts ?? {}), x: sp.x, y: sp.y, flip: sp.flip ?? false }));
        if (sp.age) live[live.length - 1].update(sp.age);
      }
      if (s.reset) fired.clear();
      for (const l of live) l.update(dt);
      for (let i = live.length - 1; i >= 0; i--) if (live[i].done()) live.splice(i, 1);
    },
    draw() {
      const cv = canvas(W, H), s = script(t, floor);
      realm(cv, realmName, { sx, sy, floorY: floor });
      core.clearFrame(back);
      core.clearFrame(front);
      for (const l of live) { if (s.actor) l.options.actor = s.actor; l.draw(back, "back"); l.draw(front, "front"); }
      for (const loop of s.loops ?? []) { loop.inst.draw(back, "back"); loop.inst.draw(front, "front"); }
      applyFx(cv, back, lightK);
      drawBody(cv, s.body, s.x, s.y, { flip: s.flip, bright: s.bright ?? 1 });
      for (const st of s.strips ?? []) st.draw(cv);
      applyFx(cv, front, lightK);
      label(cv, title, 3, 3);
      return cv;
    },
  };
}

import { readFileSync } from "node:fs";
import { join as joinPath, dirname as dirOf } from "node:path";
import { fileURLToPath as toPath } from "node:url";
const STRIP_DIR = joinPath(dirOf(toPath(import.meta.url)), "..", "..", "art", "bakeoff", "effects", "pixelfx");
/** A baked candidate strip, played like Vfx.spawn: frame floor(age * fps), anchor on the point, add or normal blend. */
function strip(name) {
  const meta = JSON.parse(readFileSync(joinPath(STRIP_DIR, `${name}.json`), "utf8")), img = art(`art/bakeoff/effects/pixelfx/${name}.png`);
  return {
    meta,
    at(age, x, y, { loop = meta.loop } = {}) {
      const i = Math.floor(age * meta.fps);
      if (age < 0 || (!loop && i >= meta.frames)) return null;
      const f = stripFrame(img, meta.frames, i % meta.frames);
      return { draw: (cv) => blit(cv, f, Math.round(x - meta.anchor[0]), Math.round(y - meta.anchor[1]), { mode: meta.blend === "add" ? "add" : "mix" }) };
    },
  };
}

/** A looping pixelfx effect that follows a body: driven by the panel clock, given the body's current cell. */
function follower(mod, opts) {
  const inst = core.createFx(mod, { ...opts, x: 0, y: 0 });
  let last = 0;
  return { inst, at(t, x, y, actor) { if (t > last) { inst.update(t - last); last = t; } inst.options.x = x; inst.options.y = y; if (actor) inst.options.actor = actor; return { inst }; } };
}

// ---- Luna idle: stars round her (loop) --------------------------------------------------------------------

/** The wand's star on an idle cell: the centre of the opaque pixels right of x 88, rows 64-96. */
function wandOf(c) {
  let sx = 0, sy = 0, n = 0;
  for (let y = 60; y < 100; y++) for (let x = 88; x < 128; x++) if (c.data[(y * c.w + x) * 4 + 3] > 127) { sx += x; sy += y; n++; }
  return n ? [Math.round(sx / n) - c.root[0], Math.round(sy / n) - c.root[1]] : [36, -40];
}

TESTS["luna-idle"] = async () => {
  const stars = await effect("arcane/sn-luna-idle-stars"), W = 200, H = 150, floor = 138, X = 96;
  const wand = wandOf(cell(LUNA, 0));
  console.log("luna wand star (feet-relative):", wand, "box", boxOf(cell(LUNA, 0)));
  const starStrips = { v1: strip("luna_idle_stars-v1"), v2: strip("luna_idle_stars-v2") };
  const panels = [
    panel({ W, H, floor, title: "LUNA IDLE NOW", script: (t, fl) => ({ body: cell(LUNA, IDLE(t)), x: X, y: fl }) }),
    ...["v1", "v2"].map((v) => panel({ W, H, floor, title: `+ PIXELFX ${v.toUpperCase()}`, script: (t, fl) => ({ body: cell(LUNA, IDLE(t)), x: X, y: fl, strips: [starStrips[v].at(t, X, fl, { loop: true })] }) })),
  ];
  clip("motion-luna-idle", panels, { cols: 3, seconds: 8 / 3, fps: 24, k: 2, stills: [6, 18, 30, 44] });
};

// ---- Luna landing: grey dust now, her stardust with pixelfx -----------------------------------------------

TESTS["luna-land"] = async () => {
  const dustFx = await effect("impacts/sn-luna-stardust-land"), W = 200, H = 170, floor = 156, X = 100, LAND = 0.42, LOOP = 1.5;
  const dust = art("assets/art/effects/landing_dust.png");
  const air = cell(LUNA, 24), land = (i) => stripCell("assets/art/luna/luna_land.png", 2, i);
  const stardust = { v1: strip("luna_land_stardust-v1"), v2: strip("luna_land_stardust-v2") };
  const script = (ver) => (t, fl) => {
    const withFx = !!ver, tt = t % LOOP;
    let body, y = fl;
    if (tt < LAND) { body = air; const u = tt / LAND; y = fl - 96 * (1 - u * u); }
    else if (tt < LAND + 2 / 12) body = land(Math.floor((tt - LAND) * 12));
    else body = cell(LUNA, IDLE(tt - LAND - 2 / 12));
    const s = { body, x: X, y, strips: [], spawns: [] };
    const age = tt - LAND;
    if (!withFx && age >= 0 && age < 5 / 41.667) {
      const fr = stripFrame(dust, 5, Math.floor(age * 41.667));
      s.strips.push({ draw: (cv) => blit(cv, fr, X - 48, fl - 31) });
    }
    if (withFx && age >= 0) { const d = stardust[ver].at(age, X, fl); if (d) s.strips.push(d); }
    return s;
  };
  const panels = [
    panel({ W, H, floor, title: "LUNA LANDING NOW (GREY DUST)", script: script(null) }),
    panel({ W, H, floor, title: "+ PIXELFX STARDUST V1", script: script("v1") }),
    panel({ W, H, floor, title: "+ PIXELFX STARDUST V2", script: script("v2") }),
  ];
  const f = (s) => Math.round(s * 24);
  clip("motion-luna-land", panels, { cols: 3, seconds: LOOP * 2, fps: 24, k: 2, stills: [f(LAND + 0.02), f(LAND + 0.1), f(LAND + 0.22), f(LAND + 0.4)] });
};

// ---- Frey running: footstep dust ----------------------------------------------------------------------------

/** The leading foot on a walk cell: [x, ok] of the frontmost cluster on the bottom rows, if both feet are down. */
function footOf(c) {
  const xs = [];
  for (let x = 0; x < c.w; x++) for (let y = 116; y <= 120; y++) if (c.data[(y * c.w + x) * 4 + 3] > 127) { xs.push(x); break; }
  if (!xs.length) return null;
  const clusters = [];
  for (const x of xs) { if (!clusters.length || x - clusters[clusters.length - 1].x1 > 3) clusters.push({ x0: x, x1: x }); else clusters[clusters.length - 1].x1 = x; }
  return { feet: clusters.length, front: clusters[clusters.length - 1], back: clusters[0] };
}

TESTS["frey-run"] = async () => {
  const steps = { v1: strip("frey_step_dust-v1"), v2: strip("frey_step_dust-v2") }, W = 480, H = 150, floor = 138, SPEED = 400, LOOP = 1.25;
  const feet = Array.from({ length: 8 }, (_, i) => footOf(cell(FREY, 6 + i)));
  console.log("walk frames, feet on the floor:", feet.map((f, i) => `${i}:${f ? f.feet : 0}`).join(" "));
  // a step lands on the frames where a new foot reaches the floor in front (two clusters, the front one new)
  const contacts = [];
  for (let i = 0; i < 8; i++) { const f = feet[i], p = feet[(i + 7) % 8]; if (f && f.feet >= 2 && (!p || p.feet < 2 || f.front.x1 - p.front.x1 > 6)) contacts.push(i); }
  console.log("contact frames:", contacts);
  const script = (ver) => (t, fl) => {
    const withFx = !!ver, step = steps[ver], tt = t % LOOP, x = 40 + SPEED * tt, frame = Math.floor(tt * 11.31) % 8;
    const s = { body: cell(FREY, 6 + frame), x, y: fl, strips: [] };
    if (withFx)
      for (let k = 0; k <= Math.floor(tt * 11.31); k++) {
        const fr = k % 8;
        if (!contacts.includes(fr)) continue;
        const t0 = k / 11.31, d = step.at(tt - t0, 40 + SPEED * t0 - 64 + feet[fr].front.x0, fl);
        if (d) s.strips.push(d);
      }
    return s;
  };
  const panels = [
    panel({ W, H, floor, realmName: "midgard", title: "FREY RUN NOW", script: script(null) }),
    panel({ W, H, floor, realmName: "midgard", title: "+ PIXELFX STEP DUST V1", script: script("v1") }),
    panel({ W, H, floor, realmName: "midgard", title: "+ PIXELFX STEP DUST V2", script: script("v2") }),
  ];
  clip("motion-frey-run", panels, { cols: 1, seconds: LOOP * 2, fps: 24, k: 2, stills: [8, 14, 20] });
};

// ---- Frey's J chain: the slash strip now, + glint and sparks at the end of each arc ------------------------

const CUTS = [
  { start: 0, startup: 0.07, recovery: 0.16, pose: [0, 1], reach: 181, aim: [1, -0.06], big: false },
  { start: 0.23, startup: 0.08, recovery: 0.18, pose: [2, 3], reach: 193, aim: [1, -0.1], big: false },
  { start: 0.49, startup: 0.11, recovery: 0.26, pose: [4, 5], reach: 209.5, aim: [1, -0.18], big: true, glint: true },
];

TESTS["frey-chain"] = async () => {
  const sparkStrips = { v1: [1, 2, 3].map((i) => strip(`frey_slash_sparks_${i}-v1`)), v2: [1, 2, 3].map((i) => strip(`frey_slash_sparks_${i}-v2`)) };
  const slash = art("assets/art/attack_vfx/frey_slash.png");
  const W = 340, H = 170, floor = 156, X = 80, LOOP = 1.45, BODY = [X, floor - 32];
  const script = (ver) => (t, fl) => {
    const withFx = !!ver, tt = t % LOOP, s = { body: cell(FREY, IDLE(tt - 0.86)), x: X, y: fl, strips: [], spawns: [] };
    for (const c of CUTS) {
      const age = tt - c.start, hit = c.startup;
      if (age >= 0 && age < c.startup + c.recovery) s.body = moveCell(8, age < hit ? c.pose[0] : c.pose[1]);
      if (c.glint && age >= 0 && age < 0.1) s.bright = 1 + 0.8 * (1 - age / 0.1);
      const sa = age - hit;
      if (sa >= 0 && sa < 6 / 36) {
        const frame = stripFrame(slash, 6, Math.floor(sa * 36)), len = Math.hypot(...c.aim), aim = [c.aim[0] / len, c.aim[1] / len];
        const scale = Math.min(3, Math.max(0.5, c.reach / 192)) / 2, rot = Math.atan2(aim[1], aim[0]);
        s.strips.push({ draw: (cv) => drawAffine(cv, frame, BODY, [0, -128], scale, scale * 0.62, rot, "add") });
      }
      if (withFx) { const d = sparkStrips[ver][CUTS.indexOf(c)].at(sa, BODY[0], BODY[1]); if (d) s.strips.push(d); }
    }
    return s;
  };
  const panels = [
    panel({ W, H, floor, realmName: "asgard", title: "FREY J CHAIN NOW", script: script(null) }),
    panel({ W, H, floor, realmName: "asgard", title: "+ PIXELFX SPARKS V1", script: script("v1") }),
    panel({ W, H, floor, realmName: "asgard", title: "+ PIXELFX SPARKS V2", script: script("v2") }),
  ];
  const f = (s) => Math.round(s * 30);
  clip("motion-frey-chain", panels, { cols: 1, seconds: LOOP * 2, fps: 30, k: 2, stills: [f(0.13), f(0.27), f(0.4), f(0.68), f(0.8), f(0.95)] });
};

// ---- strips for the game (Vfx.gd format), candidates only ----------------------------------------------------

TESTS["strips-v2"] = () => bakeAll("v2");
TESTS.strips = () => bakeAll("v1");
async function bakeAll(V) {
  const save = async (base, id, opts, spec, meta) => {
    const name = base.replace(/-v1$/, `-${V}`);
    const mod = await effect(id), strip = bakeStrip(mod, opts, { ...spec, minLight: 40 });
    saveStrip(name, strip, { ...meta, frames: spec.frames, fps: spec.fps, anchor: spec.anchor, blend: spec.mixed ? "mix" : spec.additive ? "add" : "mix", source: `pixelfx ${id} (pinned a84159688af3)` });
  };
  const luna0 = cell(LUNA, 0);
  await save("luna_idle_stars-v1", "arcane/sn-luna-idle-stars", { wand: wandOf(luna0), actor: actorOf(luna0) },
    { frames: 16, fps: 12, w: 128, h: 128, anchor: [64, 120], additive: true },
    { loop: true, attach: "Luna 대기(idle) 동안 몸에 붙여 반복(local, 발 기준)", note: "pixelfx: 실루엣 가장자리와 지팡이 별에서 작은 분홍·금 별이 반짝이고, 지팡이에서 빛 알갱이가 떠오른다." });
  await save("luna_land_stardust-v1", "impacts/sn-luna-stardust-land", {},
    V === "v1" ? { frames: 10, fps: 20, w: 176, h: 64, anchor: [88, 56], additive: false, mixed: true } : { frames: 17, fps: 20, w: 208, h: 104, anchor: [104, 72], additive: false, mixed: true },
    { loop: false, attach: "Luna 착지 순간, 발 위치(지금 landing_dust 자리)", note: "pixelfx: 분홍 별가루 뭉치가 양쪽으로 굴러 나가고 바닥 고리, 튀어 오르는 작은 별. 회색 먼지 대신." });
  await save("frey_step_dust-v1", "impacts/sn-frey-step-dust", {},
    V === "v1" ? { frames: 8, fps: 16, w: 76, h: 32, anchor: [54, 28], additive: false, mixed: true } : { frames: 11, fps: 16, w: 96, h: 40, anchor: [70, 34], additive: false, mixed: true },
    { loop: false, attach: "Frey 달리기, 걷기 줄 4·8번째 그림(앞발이 닿는 순간)에 그 발 위치, 바라보는 쪽 반대로 흩날림", note: "pixelfx: 발 뒤로 작은 먼지 뭉치 둘과 알갱이." });
  for (const [i, c] of CUTS.entries())
    await save(`frey_slash_sparks_${i + 1}-v1`, "melee/sn-frey-slash-sparks", { reach: c.reach * (350 / 384), big: c.big, floorY: 32 },
      { frames: V === "v1" ? 15 : 19, fps: 20, w: 280, h: 128, anchor: [20, 64], additive: true },
      { loop: false, attach: `Frey J ${i + 1}번째 베기, frey_slash와 같은 자리(몸 중심)·같은 순간`, note: "pixelfx: 초승달 끝에서 불꽃이 튀고, 사라진 뒤 금빛 반짝임이 곡선을 따라 남아 떨어진다." });
}

await run(process.argv.slice(2));
