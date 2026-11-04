// SmashNine (sn-), Frey pilot candidate A (2026-11-04, CODEX-VFX-07 spec): the follow-through after her other J
// moves (up, down, air side), made from the ground chain's sparks (sn-frey-slash-sparks) turned to the move's aim.
// The origin is the slash strip's anchor (her body centre). The crescent lies along `aim` (degrees, facing
// right, positive is down); gravity stays down. On the ground sparks bounce on `floorY` (px below the origin, her
// feet); in the air (`floorY: null`) they fall away. `reach`: the crescent's length; `big` for a stronger cut.
import { Particles, Lights, P, Rng, fit, sparkle, WHITE } from "../../core/index.js";

export const meta = {
  name: "SN Frey J follow-through A",
  desc: "SmashNine pilot A: after Frey's up, down and air J, tip sparks fly on, gold glints hang along the curve and a gold edge afterimage breaks up; turned to the aim, gravity down.",
  tags: ["melee", "sword", "sparks", "follow-through", "smashnine", "one-shot", "directional"],
  size: [240, 240],
  origin: [80, 170],
  duration: 0.95,
  loop: false,
  fps: 20,
  bg: "dark",
  // `aim`, not `angle`: the framework turns the whole painter by `angle` (radians), gravity included.
  options: { palette: ["#3a2206", "#7a4a10", "#c08020", "#f0c040", "#fff0a0", "#ffffff"], reach: 155, aim: -83, floorY: 32, big: false, seed: 8 },
};

const TIP_AT = 0.08, FADE_AT = 0.15;

export function create(o) {
  const C = fit(o.palette, 6), R = new Rng(o.seed), Rr = o.reach;
  const th = (o.aim * Math.PI) / 180, cs = Math.cos(th), sn = Math.sin(th);
  /** The slash's own frame (x along the cut, y across it) into the origin's frame. */
  const rot = (x, y) => [x * cs - y * sn, x * sn + y * cs];
  const ground = o.floorY == null ? undefined : () => o.floorY;
  const ps = new Particles({ rng: R, ground, sparks: [WHITE, C[4], C[3], C[2]] }), lights = new Lights();
  const tip = rot(Rr * 0.88, -2), n = o.big ? 20 : 12;
  for (let i = 0; i < n; i++) {
    const a = R.range(-0.8, 0.55), sp = R.range(90, o.big ? 260 : 210);
    const [ox, oy] = rot(R.range(-6, 2), R.range(-4, 4)), [vx, vy] = rot(Math.cos(a) * sp, Math.sin(a) * sp);
    ps.spawn(P.SPARK, tip[0] + ox, tip[1] + oy, vx, vy - 15, R.range(0.16, 0.32), R.pick([C[4], C[5], WHITE]), 1, TIP_AT + R.range(0, 0.03));
  }
  for (let i = 0; i < (o.big ? 8 : 5); i++) {
    const [ex, ey] = rot(R.range(Rr * 0.4, Rr * 0.85), R.range(-14, 10));
    ps.spawn(P.EMBER, ex, ey, R.range(-8, 20), -R.range(8, 24), R.range(0.35, 0.55), C[4], 1, FADE_AT + R.range(0, 0.08));
  }
  // glints along the crescent's outer edge, from one end through the tip to the other
  const glints = Array.from({ length: o.big ? 16 : 11 }, () => {
    const phi = R.range(-1.25, 1.25);
    const [x, y] = rot(Rr * 0.32 + Rr * 0.58 * Math.cos(phi) + R.range(-4, 4), Rr * 0.16 * Math.sin(phi) + R.range(-3, 3));
    return { x, y, at: FADE_AT + R.range(-0.03, 0.16), life: R.range(0.32, 0.58), arm: R.range(3.5, o.big ? 7 : 5.5), gold: R.chance(0.6) };
  });
  const edge = [];
  for (let i = 0; i <= 28; i++) { const phi = -1.15 + (2.3 * i) / 28; edge.push(rot(Rr * 0.32 + Rr * 0.58 * Math.cos(phi), Rr * 0.16 * Math.sin(phi))); }
  // the afterimage is two pixels thick across the cut, whatever its angle
  const nx = Math.round(-sn), ny = Math.round(cs);
  let t = 0, flashed = false;
  return {
    update(dt) {
      t += dt;
      if (!flashed && t >= TIP_AT) { flashed = true; lights.add(tip[0], tip[1], o.big ? 34 : 24, C[3], o.big ? 0.75 : 0.55, 0.18); }
      ps.update(dt);
      lights.update(dt);
    },
    draw(p) {
      const ag = t - FADE_AT;
      if (ag > 0 && ag < 0.3) {
        const k = 1 - ag / 0.3;
        for (let i = 0; i < 28; i++) {
          if ((i + Math.floor(ag * 40)) % 4 === 0 && k < 0.7) continue; // it breaks up as it fades
          const [ax, ay] = edge[i], [bx, by] = edge[i + 1];
          p.line(ax, ay, bx, by, k > 0.55 ? WHITE : C[5]);
          p.line(ax + nx, ay + ny, bx + nx, by + ny, k > 0.55 ? C[5] : C[4]);
          if (i % 3 === 0) p.glow(ax, ay, 8, C[3], 0.45 * k);
        }
      }
      for (const g of glints) {
        const age = t - g.at;
        if (age < 0 || age > g.life) continue;
        const q = age / g.life, k = Math.sin(Math.PI * Math.min(1, q * 1.4)), x = g.x + 6 * age, y = g.y + 30 * age * age;
        if (k > 0.1) sparkle(p, x, y, 0.5 + g.arm * k, g.gold ? C[5] : WHITE, g.gold ? C[3] : C[4], 0.4 * k);
      }
      ps.draw(p);
      lights.draw(p);
    },
  };
}
