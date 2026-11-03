// Nova's gravity beam (CODEX-VFX-06 contract): Codex candidates A and B next to a pixelfx candidate C,
// in the board's layout (Nova's idle on the left, the foe 300 px to the right on the same floor, 1x).
//
//   node reports/pixelfx-eval-2026-11-03/beam.mjs [sanity] [board] [motion] [strips]
//
// Game numbers (Nova.gd / NovaBeam.gd): the beam leaves her palm (body centre 32 px above the feet, 24 px
// ahead) at 1725 px/s for up to 620 px; on a grounded foe the tip splits and closes round it in 0.1 s, then the
// tether drags it to 69 px in front of her in up to 0.45 s, then lets go.
import {
  TESTS, run, art, stripFrame, fighter, monster, FROWS, MROWS, loopCol, boxOf, canvas, blit, drawBody, drawStrip,
  realm, label, fxAt, clip, savePNG, bakeStrip, saveStrip, effect, core,
} from "./bench.mjs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const NOVA = "assets/art/nova/nova_male_sheet.png", FREY = "assets/art/frey/frey_sheet.png";
const W = 420, H = 150, FLOOR = 128, NX = 50, GAP = 300, BODY = 32, PALM = [24, -32];
const CODEX = (name, v) => `art/bakeoff/effects/nova/${name}-${v}-v2.png`;
// contract: name -> [frames, fps, anchor, loop]
const SPEC = { head: [4, 16, [24, 24], true], split: [4, 40, [80, 80], false], bind: [4, 12, [80, 80], true] };

function scene(cv, { foeX, foePose = "idle", t = 0, monsterSheet = null }) {
  realm(cv, "svartalfheim", { sx: 700, sy: 560, floorY: FLOOR });
  drawBody(cv, fighter(NOVA, FROWS.idle[0], loopCol(4, 7, t)), NX, FLOOR);
  if (monsterSheet) drawBody(cv, monster(monsterSheet, MROWS.idle[0], loopCol(6, 6, t)), foeX, FLOOR, { flip: true });
  else drawBody(cv, fighter(FREY, FROWS[foePose][0], foePose === "idle" ? loopCol(4, 7, t) : 0), foeX, FLOOR, { flip: true });
}

/** The tether tile repeated from x0 to x1 along y (the game stretches one 64x16 frame along the line). */
function tether(cv, tile, x0, x1, y) {
  x0 = Math.round(x0); x1 = Math.round(x1); y = Math.round(y);
  for (let x = x0; x < x1; x += tile.w) {
    const w = Math.min(tile.w, x1 - x), part = { w, h: tile.h, data: new Uint8ClampedArray(w * tile.h * 4) };
    for (let j = 0; j < tile.h; j++) part.data.set(tile.data.subarray(j * tile.w * 4, (j * tile.w + w) * 4), j * w * 4);
    blit(cv, part, x, y - (tile.h >> 1), { mode: "add" });
  }
}

/** One Codex candidate's frame of `item` on the board. */
function codexFrame(v, item, i) {
  const [n] = SPEC[item];
  return stripFrame(art(CODEX(`nova_beam_${item}`, v)), n, i);
}

TESTS.sanity = async () => {
  // Board panel A "결박 F1 상대 +300px", rebuilt here to check the compositing against reports/codex-vfx-06.
  const cv = canvas(W, H), foe = NX + GAP, at = [foe, FLOOR - BODY];
  scene(cv, { foeX: foe });
  tether(cv, art(CODEX("nova_beam_tile", "a")), NX + PALM[0], foe - 40, FLOOR + PALM[1]);
  drawStrip(cv, codexFrame("a", "bind", 0), SPEC.bind[2], at, { mode: "add" });
  label(cv, "SANITY: A BIND F1 +300PX", 3, 3);
  savePNG(join(HERE, "out", "beam-sanity.png"), cv, 2);
  console.log("foe box (feet-relative):", boxOf(fighter(FREY, 0, 0)), "nova box:", boxOf(fighter(NOVA, 0, 0)));
};

// ---- the pixelfx candidate C, baked into the contract's strips -------------------------------------------------

const C_IDS = { head: "arcane/sn-gravity-head", split: "arcane/sn-gravity-split", bind: "arcane/sn-gravity-bind", tile: "arcane/sn-gravity-tether" };
const NOTES = {
  head: "pixelfx C: 네 갈래 발톱을 접은 끝, 날아가며 천천히 돈다(흰 심, 청록 끝).",
  split: "pixelfx C: 닿는 순간 고리에서 흰 번쩍임, 발톱 네 개가 부채처럼 펴졌다가 몸 둘레 두 궤도(앞 둘 밝게, 뒤 둘 어둡게)를 따라 감겨 오른쪽에서 만난다.",
  bind: "pixelfx C: 감긴 발톱이 조였다 풀리고, 빛이 발톱을 따라 고리 쪽으로 흐르며 불꽃이 줄(왼쪽)로 흘러간다. 1번 그림 = split 4번.",
  tile: "pixelfx C: 흰 심의 얇은 보라 띠에 청록 가닥이 감기고 16px마다 빛 구슬. 64px마다 이음매 없이 반복.",
};

TESTS.strips = async () => {
  const bake = async (item, frames, fps, size, anchor, loop) => {
    const strip = bakeStrip(await effect(C_IDS[item]), {}, { frames, fps, w: size[0], h: size[1], anchor, additive: true, minLight: 40, border: item === "tile" ? 0 : 1 });
    if (item === "tile") // the cord must tile: keep its left and right columns, clear only the top and bottom rows
      for (let x = 0; x < strip.w; x++) for (const y of [0, strip.h - 1]) strip.data.fill(0, (y * strip.w + x) * 4, (y * strip.w + x) * 4 + 4);
    saveStrip(`nova_beam_${item}-c-v2`, strip, { note: NOTES[item], replaces: { head: "assets/art/effects/nova_beam_head.png", split: "assets/art/effects/skill/nova_beam_split.png", bind: "assets/art/effects/skill/nova_beam_bind.png", tile: "assets/art/effects/nova_beam_tile.png" }[item], frames, fps, anchor, loop, additive: true, source: `pixelfx ${C_IDS[item]} (pinned a84159688af3)` });
  };
  await bake("head", 4, 16, [48, 48], [24, 24], true);
  await bake("split", 4, 40, [160, 160], [80, 80], false);
  await bake("bind", 4, 12, [160, 160], [80, 80], true);
  await bake("tile", 1, 1, [64, 16], [0, 8], true);
};

// ---- the board: A | B | C in the Codex board's rows ---------------------------------------------------------

const VERS = ["a", "b", "c"];
const file = (item, v) => (v === "c" ? `art/bakeoff/effects/pixelfx/nova_beam_${item}-c-v2.png` : CODEX(`nova_beam_${item}`, v));
const frameOf = (v, item, i) => stripFrame(art(file(item, v)), SPEC[item][0], i);
const tile = (v) => art(file("tile", v));

/** One board cell: the scene with candidate v's art for a row. */
function cell(v, row) {
  const cv = canvas(W, H), palm = [NX + PALM[0], FLOOR + PALM[1]];
  const foeX = row.foe ?? NX + GAP;
  scene(cv, { foeX });
  if (row.item === "head") {
    const hx = NX + PALM[0] + 150;
    tether(cv, tile(v), palm[0], hx - 12, palm[1]);
    drawStrip(cv, frameOf(v, "head", row.f ?? 0), SPEC.head[2], [hx, palm[1]], { mode: "add" });
  } else {
    const at = [foeX, FLOOR - BODY];
    tether(cv, tile(v), palm[0], foeX - 40, palm[1]);
    drawStrip(cv, frameOf(v, row.item, row.f), SPEC[row.item][2], at, { mode: "add" });
  }
  label(cv, `${v.toUpperCase()} ${row.title}`, 3, 3);
  return cv;
}

const ROWS = [
  { item: "head", f: 0, title: "HEAD F1 +150PX" },
  ...[0, 1, 2, 3].map((f) => ({ item: "split", f, title: `SPLIT F${f + 1} +300PX` })),
  ...[0, 1, 2, 3].map((f) => ({ item: "bind", f, title: `BIND F${f + 1} +300PX` })),
  { item: "bind", f: 0, foe: NX + 150, title: "BIND F1 +150PX" },
  { item: "bind", f: 0, foe: NX + 69, title: "BIND F1 +69PX" },
];

TESTS.board = async () => {
  const gap = 4, cols = 3, BW = cols * W + (cols - 1) * gap, BH = ROWS.length * H + (ROWS.length - 1) * gap;
  const board = canvas(BW, BH, [40, 38, 52]);
  ROWS.forEach((row, r) => VERS.forEach((v, c) => blit(board, { w: W, h: H, data: cell(v, row).d }, c * (W + gap), r * (H + gap))));
  savePNG(join(HERE, "out", "beam-board.png"), board, 1);
  // a closer look at the wrap: split F2-F4 and bind F1 on the foe, 3x
  const ZW = 170, ZH = 150, zoom = canvas(cols * ZW + (cols - 1) * gap, 4 * ZH + 3 * gap, [40, 38, 52]);
  [[1, "split"], [2, "split"], [3, "split"], [0, "bind"]].forEach(([f, item], r) =>
    VERS.forEach((v, c) => {
      const full = cell(v, { item, f, title: `${item.toUpperCase()} F${f + 1}` }), x0 = NX + GAP - 85;
      const part = canvas(ZW, ZH);
      blit(part, { w: W, h: H, data: full.d }, -x0, 0);
      label(part, `${v.toUpperCase()} ${item.toUpperCase()} F${f + 1}`, 3, 3);
      blit(zoom, { w: ZW, h: ZH, data: part.d }, c * (ZW + gap), r * (ZH + gap));
    }));
  savePNG(join(HERE, "out", "beam-wrap-3x.png"), zoom, 3);
  console.log(`board ${BW}x${BH}, wrap close-up 3x`);
};

// ---- motion at the game's timing: A, B, C stacked ---------------------------------------------------------

const SPEED = 1725, SPLIT_T = 0.1, DRAG_T = 0.45, HOLD = 0.35, END_X = NX + 69;

/** One panel playing the whole move with candidate v (frames picked from the strips like AnimatedSprite2D). */
function movePanel(v, { foeStart = NX + GAP, monsterSheet = null, bindStrip = null, splitStrip = null, title } = {}) {
  const palm = [NX + PALM[0], FLOOR + PALM[1]], reach = foeStart - 40 - palm[0], fly = reach / SPEED;
  let t = 0;
  const split = splitStrip ?? art(file("split", v)), bind = bindStrip ?? art(file("bind", v)), head = art(file("head", v));
  return {
    W, H,
    tick(dt) { t += dt; },
    draw() {
      const cv = canvas(W, H), T0 = fly, T1 = fly + SPLIT_T, T2 = T1 + DRAG_T, loop = T2 + HOLD;
      const tt = t % loop;
      let foeX = foeStart, pose = "idle";
      if (tt >= T1 && tt < T2) { const u = (tt - T1) / DRAG_T; foeX = foeStart + (END_X - foeStart) * (1 - (1 - u) * (1 - u)); pose = "hurt"; }
      else if (tt >= T2) { foeX = END_X; pose = "hurt"; }
      else if (tt >= T0) pose = "hurt";
      scene(cv, { foeX, foePose: pose, t: tt, monsterSheet });
      const at = [foeX, FLOOR - BODY];
      if (tt < T0) {
        const hx = palm[0] + SPEED * tt;
        tether(cv, tile(v), palm[0], hx - 12, palm[1]);
        drawStrip(cv, stripFrame(head, 4, Math.floor(tt * 16) % 4), SPEC.head[2], [hx, palm[1]], { mode: "add" });
      } else if (tt < T1) {
        tether(cv, tile(v), palm[0], foeX - 40, palm[1]);
        drawStrip(cv, stripFrame(split, 4, Math.min(3, Math.floor((tt - T0) * 40))), SPEC.split[2], at, { mode: "add" });
      } else if (tt < T2) {
        tether(cv, tile(v), palm[0], foeX - 40, palm[1]);
        drawStrip(cv, stripFrame(bind, 4, Math.floor((tt - T1) * 12) % 4), SPEC.bind[2], at, { mode: "add" });
      }
      label(cv, title ?? v.toUpperCase(), 3, 3);
      return cv;
    },
  };
}

TESTS.motion = async () => {
  const fly = (NX + GAP - 40 - NX - PALM[0]) / SPEED, total = fly + SPLIT_T + DRAG_T + HOLD;
  clip("beam-motion", VERS.map((v) => movePanel(v, { title: `${v.toUpperCase()}${v === "c" ? " (PIXELFX)" : " (CODEX)"}` })), {
    cols: 1, seconds: total * 2, fps: 40, k: 2,
    stills: [Math.round((fly + 0.01) * 40), Math.round((fly + 0.06) * 40), Math.round((fly + 0.12) * 40), Math.round((fly + 0.33) * 40)],
  });
};

// ---- fitting the wrap to the target: a monster 96 px cell next to a fighter ----------------------------------

TESTS.fit = async () => {
  const sheet = "assets/art/monsters/svartalfheim_gear_beetle_sheet.png";
  const box = (await import("./bench.mjs")).boxOf(monster(sheet, 0, 0)); // [x0, y0, x1, y1] from the feet
  const w = box[2] - box[0], h = -box[1], cyFeet = -(h / 2) - 2, cy = cyFeet + BODY;
  const opts = { rx: Math.max(18, w / 2 + 8), ry: Math.max(18, h / 2 + 9), cy };
  console.log("beetle box", box, "-> wrap options", opts);
  const mk = async (item, frames, fps, size, anchor) => bakeStrip(await effect(C_IDS[item]), opts, { frames, fps, w: size[0], h: size[1], anchor, additive: true, minLight: 40 });
  const split = await mk("split", 4, 40, [160, 160], [80, 80]), bind = await mk("bind", 4, 12, [160, 160], [80, 80]);
  saveStrip("nova_beam_bind-c-small-v2", bind, { note: "pixelfx C, 작은 대상(몬스터 96칸, 톱니 딱정벌레 크기)에 맞춰 다시 구운 결박. 같은 코드, 옵션 rx·ry·cy만 다름.", frames: 4, fps: 12, anchor: [80, 80], loop: true, additive: true, options: opts });
  saveStrip("nova_beam_split-c-small-v2", split, { note: "pixelfx C, 작은 대상에 맞춘 분리.", frames: 4, fps: 40, anchor: [80, 80], loop: false, additive: true, options: opts });
  const fly = (NX + GAP - 40 - NX - PALM[0]) / SPEED;
  clip("beam-fit-monster", [
    movePanel("a", { monsterSheet: sheet, title: "A ON A SMALL MONSTER (FIXED ART)" }),
    movePanel("b", { monsterSheet: sheet, title: "B ON A SMALL MONSTER (FIXED ART)" }),
    movePanel("c", { monsterSheet: sheet, splitStrip: split, bindStrip: bind, title: "C REBAKED FOR ITS BOX (PIXELFX)" }),
  ], { cols: 1, seconds: fly + SPLIT_T + DRAG_T + HOLD, fps: 40, k: 2, stills: [Math.round((fly + 0.12) * 40), Math.round((fly + 0.3) * 40)] });
};

await run(process.argv.slice(2));
