// Where pixelfx could help SmashNine: the game's current effect next to pixelfx options, on the game's own
// fighters and realm art at 1x (world px; the camera shows 0.85 of it).
//
//   node reports/pixelfx-eval-2026-11-03/areas.mjs [hits] [status] [dust] [weather]
//
// Game numbers used: hit sparks (PlayerBase._spawn_hit_effect) are 4 frames at 44 fps, scaled to fill twice
// spark_size = clamp(18 + damage * 1.35 + knockback * 0.035, 24, 56) * 1.5; landing dust (Vfx "landing_dust") 5
// frames at 41.7 fps, anchor (48, 31), 1x; status icons 24 px at STATUS_ICON_Y -121 above the feet; Nova's
// gravity root ring 6 frames at 10 fps, anchor (48, 16) on the feet.
import {
  TESTS, run, art, stripFrame, fighter, FROWS, loopCol, boxOf, actorOf, canvas, blit, drawBody, realm, label, applyFx, clip, effect, core,
} from "./bench.mjs";

const FREY = "assets/art/frey/frey_sheet.png", NOVA = "assets/art/nova/nova_male_sheet.png", LUNA = "assets/art/luna/luna_sheet.png";

// attacker ramps, dark to bright, from their own art
const RAMP = {
  frey: ["#2a1606", "#5c3410", "#9a6418", "#d8a030", "#f6d860", "#fff3b0", "#ffffff"],
  luna: ["#2a0a24", "#5c1a4c", "#a03a80", "#e070b0", "#ffa8d8", "#ffe0f0", "#ffffff"],
  nova: ["#0a0520", "#2c1474", "#4424a8", "#6a3fd8", "#5ce2e6", "#cdbcff", "#ffffff"],
  yuki: ["#06162a", "#0e3a66", "#1f6fb0", "#4fb0e8", "#9ee0ff", "#e0f8ff", "#ffffff"],
  rio: ["#04201a", "#0a4a3a", "#13806a", "#2cc0a0", "#80f0d0", "#d8fff4", "#ffffff"],
};

/** Nearest-neighbour scaled draw (Godot shows a scaled AnimatedSprite2D with nearest filtering). */
function blitScaled(cv, img, cx, cy, s, mode = "mix") {
  const w = Math.max(1, Math.round(img.w * s)), h = Math.max(1, Math.round(img.h * s)), out = { w, h, data: new Uint8ClampedArray(w * h * 4) };
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      const sx = Math.min(img.w - 1, Math.floor(x / s)), sy = Math.min(img.h - 1, Math.floor(y / s));
      out.data.set(img.data.subarray((sy * img.w + sx) * 4, (sy * img.w + sx) * 4 + 4), (y * w + x) * 4);
    }
  blit(cv, out, cx - w / 2, cy - h / 2, { mode });
}

/**
 * A panel: realm floor, bodies, game strips (strips), pixelfx effects (fx) drawn into whole-panel frames, icons.
 * bodies: [{ sheet, x, row, flip }]; fx: [{ mod, opts, x, y, at, every, actor (body index) }];
 * strips: [{ img, n, fps, anchor | centre, scale, x, y, at, every, mode }]; icons: [{ img, x, y }].
 */
function panel({ W = 200, H = 140, floor = 126, realmName = "svartalfheim", sx = 760, sy = 600, bodies = [], fx = [], strips = [], icons = [], title, lightK = 1, ambient = null }) {
  const back = core.createFrame(W, H), front = core.createFrame(W, H), live = [];
  let t = 0;
  for (const s of [...fx, ...strips]) s.next = s.at ?? 0;
  const cellOf = (b, tt) => { const [row, frames, fps] = FROWS[b.row ?? "idle"]; return fighter(b.sheet, row, loopCol(frames, fps, tt)); };
  const pos = (b) => [b.x, floor];
  return {
    W, H,
    tick(dt) {
      t += dt;
      for (const s of fx)
        while (t >= s.next) {
          const opts = { ...(s.opts ?? {}), x: s.x, y: s.y };
          if (s.actor !== undefined) opts.actor = actorOf(cellOf(bodies[s.actor], t));
          live.push({ inst: core.createFx(s.mod, opts), s });
          s.next = s.every ? s.next + s.every : Infinity;
        }
      for (const l of live) l.inst.update(dt);
      for (let i = live.length - 1; i >= 0; i--) if (live[i].inst.done()) live.splice(i, 1);
    },
    draw() {
      const cv = canvas(W, H);
      realm(cv, realmName, { sx, sy, floorY: floor });
      ambient?.drawBack(cv, t);
      core.clearFrame(back);
      core.clearFrame(front);
      for (const l of live) {
        if (l.s.actor !== undefined) l.inst.options.actor = actorOf(cellOf(bodies[l.s.actor], t));
        l.inst.draw(back, "back");
        l.inst.draw(front, "front");
      }
      applyFx(cv, back, lightK);
      for (const b of bodies) drawBody(cv, cellOf(b, t), ...pos(b), { flip: b.flip });
      for (const s of strips) {
        // strips play like AnimatedSprite2D one-shots, restarted every `every` seconds
        const start = s.every ? s.at + Math.floor(Math.max(0, t - s.at) / s.every) * s.every : s.at, age = t - start;
        if (age < 0) continue;
        const i = s.loop ? Math.floor(age * s.fps) % s.n : Math.floor(age * s.fps);
        if (i >= s.n) continue;
        const f = stripFrame(s.img, s.n, i);
        if (s.scale) blitScaled(cv, f, s.x, s.y, s.scale, s.mode);
        else blit(cv, f, s.x - s.anchor[0], s.y - s.anchor[1], { mode: s.mode });
      }
      for (const ic of icons) blit(cv, ic.img, ic.x - (ic.img.w >> 1), ic.y - (ic.img.h >> 1));
      applyFx(cv, front, lightK);
      ambient?.drawFront(cv, t);
      if (title) label(cv, title, 3, 3);
      return cv;
    },
  };
}

// ---- 1. hits: small and frequent, one per character -------------------------------------------------------

const sparkSize = (damage, knockback) => Math.min(56, Math.max(24, 18 + damage * 1.35 + knockback * 0.035)) * 1.5;

TESTS.hits = async () => {
  const hitSpark = await effect("impacts/hit-spark"), crit = await effect("impacts/crit-hit");
  const T = 0.5, X = 120, CHEST = 126 - 52, light = sparkSize(6, 250), heavy = sparkSize(12, 520);
  const target = [{ sheet: NOVA, x: X, flip: true }];
  const now = (id, size, title) => panel({ bodies: target, title, strips: [{ img: art(`assets/art/effects/hit/${id}_hit.png`), n: 4, fps: 44, scale: (size * 2) / 96, x: X - 18, y: CHEST, at: 0.1, every: T }] });
  const pfx = (mod, ramp, title, extra = {}) => panel({ bodies: target, title, fx: [{ mod, opts: { palette: ramp, height: 52, ...extra }, x: X - 18, y: 126, at: 0.1, every: T }] });
  const panels = [
    now("frey", light, "NOW FREY LIGHT (CODEX)"), pfx(hitSpark, RAMP.frey, "PIXELFX HIT-SPARK FREY"),
    now("frey", heavy, "NOW FREY HEAVY (CODEX)"), pfx(crit, RAMP.frey, "PIXELFX CRIT-HIT FREY"),
    now("luna", light, "NOW LUNA (CODEX)"), pfx(hitSpark, RAMP.luna, "PIXELFX HIT-SPARK LUNA"),
    now("yuki", light, "NOW YUKI (CODEX)"), pfx(hitSpark, RAMP.yuki, "PIXELFX HIT-SPARK YUKI"),
  ];
  console.log(`spark size light ${light.toFixed(1)} -> burst ${(light * 2).toFixed(0)} px, heavy ${heavy.toFixed(1)} -> ${(heavy * 2).toFixed(0)} px`);
  clip("hits", panels, { cols: 2, seconds: 2 * T, fps: 30, k: 2, stills: [4, 6, 9, 13] });
};

// the mix the hits test points to: the game's Codex burst as the main shape, pixelfx sparks as follow-through
TESTS.mix = async () => {
  const hitSpark = await effect("impacts/hit-spark"), crit = await effect("impacts/crit-hit");
  const T = 0.6, X = 120, CHEST = 126 - 52, light = sparkSize(6, 250), heavy = sparkSize(12, 520), target = [{ sheet: NOVA, x: X, flip: true }];
  const burst = (id, size) => ({ img: art(`assets/art/effects/hit/${id}_hit.png`), n: 4, fps: 44, scale: (size * 2) / 96, x: X - 18, y: CHEST, at: 0.1, every: T });
  const sparks = (mod, ramp) => ({ mod, opts: { palette: ramp, height: 52 }, x: X - 18, y: 126, at: 0.1, every: T });
  const panels = [
    panel({ bodies: target, title: "NOW FREY LIGHT", strips: [burst("frey", light)] }),
    panel({ bodies: target, title: "NOW + PIXELFX SPARKS", strips: [burst("frey", light)], fx: [sparks(hitSpark, RAMP.frey)] }),
    panel({ bodies: target, title: "NOW FREY HEAVY", strips: [burst("frey", heavy)] }),
    panel({ bodies: target, title: "NOW + PIXELFX CRIT-HIT", strips: [burst("frey", heavy)], fx: [sparks(crit, RAMP.frey)] }),
    panel({ bodies: target, title: "NOW NOVA LIGHT", strips: [burst("nova", light)] }),
    panel({ bodies: target, title: "NOW + PIXELFX SPARKS (NOVA)", strips: [burst("nova", light)], fx: [sparks(hitSpark, RAMP.nova)] }),
  ];
  clip("hits-mix", panels, { cols: 2, seconds: T, fps: 30, k: 2, stills: [4, 7, 10, 14] });
};

// ---- 2. status that follows the body (Frey's real idle cells as pixelfx's actor) -----------------------------

TESTS.status = async () => {
  const X = 100, F = [{ sheet: FREY, x: X }], ui = (n) => art(`smash-nine-prototype/assets/art/ui/status/${n}.png`.replace("smash-nine-prototype/", ""));
  const root = art("assets/art/effects/skill/nova_gravity_root.png");
  const slowed = await effect("status/slowed"), electrified = await effect("lightning/electrified"), blessing = await effect("holy/blessing"), frozen = await effect("status/frozen");
  const panels = [
    panel({ bodies: F, title: "NOW SLOW: ICON (CODEX)", icons: [{ img: art("assets/art/ui/status/slow.png"), x: X, y: 126 - 121 + 10 }] }),
    panel({ bodies: F, title: "PIXELFX STATUS/SLOWED ON HER", fx: [{ mod: slowed, opts: {}, x: X, y: 126, actor: 0 }] }),
    panel({ bodies: F, title: "NOW GRAVITY: RING + PIPS (CODEX)", strips: [{ img: root, n: 6, fps: 10, anchor: [48, 16], x: X, y: 126, at: 0, loop: true }], icons: [{ img: art("assets/art/ui/status/nova_gravity_2.png"), x: X, y: 126 - 121 - 26 + 30 }] }),
    panel({ bodies: F, title: "PIXELFX ELECTRIFIED IN NOVA VIOLET", fx: [{ mod: electrified, opts: { sparks: ["#ffffff", "#cdbcff", "#9a78f2", "#6a3fd8"] }, x: X, y: 126, actor: 0 }] }),
    panel({ bodies: F, title: "PIXELFX HOLY/BLESSING (ULT ARMOUR?)", fx: [{ mod: blessing, opts: {}, x: X, y: 126, actor: 0 }] }),
    panel({ bodies: F, title: "PIXELFX STATUS/FROZEN (YUKI?)", fx: [{ mod: frozen, opts: {}, x: X, y: 126, actor: 0 }] }),
  ];
  console.log("frey box", boxOf(fighter(FREY, 0, 0)));
  clip("status", panels, { cols: 2, seconds: 3, fps: 30, k: 2, stills: [15, 45, 80] });
};

// ---- 3. dust and pickups: particles ------------------------------------------------------------------------

TESTS.dust = async () => {
  const X = 100, F = [{ sheet: NOVA, x: X }], T = 1.2;
  const landing = await effect("impacts/heavy-landing"), poof = await effect("spawn/poof"), collect = await effect("pickups/collect-burst");
  const dust = art("assets/art/effects/landing_dust.png");
  const panels = [
    panel({ bodies: F, title: "NOW LANDING DUST (CODEX)", strips: [{ img: dust, n: 5, fps: 41.667, anchor: [48, 31], x: X, y: 126, at: 0.1, every: T }] }),
    panel({ bodies: F, title: "PIXELFX HEAVY-LANDING", fx: [{ mod: landing, opts: { stone: "#4a4458" }, x: X, y: 126, at: 0.1, every: T, actor: 0 }] }),
    panel({ title: "PIXELFX COLLECT-BURST (CRYSTAL)", fx: [{ mod: collect, opts: { palette: RAMP.nova }, x: X, y: 126, at: 0.1, every: T }] }),
    panel({ title: "PIXELFX POOF", fx: [{ mod: poof, opts: {}, x: X, y: 126, at: 0.1, every: T }] }),
  ];
  clip("dust", panels, { cols: 2, seconds: T, fps: 30, k: 2, stills: [4, 8, 14, 22] });
};

// ---- 4. weather loops over a realm: something the game has none of -----------------------------------------

/** A weather loop tiled across the panel at 1x (weather effects are 320 x 180 screens). */
function weather(mod, opts, { k = 1 } = {}) {
  const [w, h] = mod.meta.size, f = core.createFrame(w, h), inst = core.createFx(mod, { ...opts, x: mod.meta.origin[0], y: mod.meta.origin[1] });
  let last = 0;
  const step = (t) => { if (t > last) { inst.update(t - last); last = t; } };
  return {
    drawBack(cv, t) { step(t); core.clearFrame(f); inst.draw(f, "back"); for (let x = 0; x < cv.W; x += w) for (let y = 0; y < cv.H; y += h) applyFx(cv, f, k, x, y); },
    drawFront(cv, t) { core.clearFrame(f); inst.draw(f, "front"); for (let x = 0; x < cv.W; x += w) for (let y = 0; y < cv.H; y += h) applyFx(cv, f, k, x, y); },
  };
}

TESTS.weather = async () => {
  const W = 360, H = 200, floor = 182, F = (sheet) => [{ sheet, x: 120 }, { sheet: NOVA, x: 250, flip: true }];
  const snow = await effect("weather/snow"), leaves = await effect("weather/falling-leaves"), fireflies = await effect("weather/fireflies"), rays = await effect("weather/god-rays");
  console.log("weather sizes", [snow, leaves, fireflies, rays].map((m) => `${m.meta.name} ${m.meta.size} ${m.meta.duration}s`).join(", "));
  const p = (realmName, sx, sy, title, amb) => panel({ W, H, floor, realmName, sx, sy, bodies: F(FREY), title, ambient: amb });
  const panels = [
    p("niflheim", 700, 520, "NIFLHEIM NOW (STATIC)", null),
    p("niflheim", 700, 520, "NIFLHEIM + PIXELFX SNOW", weather(snow, {})),
    p("vanaheim", 700, 520, "VANAHEIM NOW (STATIC)", null),
    p("vanaheim", 700, 520, "VANAHEIM + FALLING LEAVES", weather(leaves, {})),
    p("alfheim", 700, 520, "ALFHEIM NOW (STATIC)", null),
    p("alfheim", 700, 520, "ALFHEIM + FIREFLIES", weather(fireflies, {})),
  ];
  clip("weather", panels, { cols: 2, seconds: 3, fps: 20, k: 2, stills: [10, 40] });
};

await run(process.argv.slice(2));
