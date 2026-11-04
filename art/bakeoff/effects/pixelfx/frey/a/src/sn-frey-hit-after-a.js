// SmashNine (sn-), Frey pilot candidate A (2026-11-04, CODEX-VFX-07 spec): what stays after Frey's hit spark (the
// game's 4-frame burst at the struck body's centre, gone after 0.09 s). A thin gold ring opens from the impact,
// steel sparks fly on in the hit's direction (facing right) and fall, glints pop round the body and fade. The
// middle stays clear so the struck fighter reads. `big` for a strong hit (knockback 480 or more).
import { Particles, Lights, P, Rng, fit, sparkle, WHITE } from "../../core/index.js";

export const meta = {
  name: "SN Frey hit afterglow A",
  desc: "SmashNine pilot A: after Frey's hit spark a thin gold ring opens, steel sparks fly on in the hit's direction and fall, glints pop round the body; the middle stays clear.",
  tags: ["impact", "hit", "sparks", "smashnine", "one-shot", "directional"],
  size: [128, 128],
  origin: [64, 64],
  duration: 0.5,
  loop: false,
  fps: 20,
  bg: "dark",
  options: { palette: ["#3a2206", "#7a4a10", "#c08020", "#f0c040", "#fff0a0", "#ffffff"], big: false, seed: 5 },
};

export function create(o) {
  const C = fit(o.palette, 6), R = new Rng(o.seed), big = o.big;
  const ps = new Particles({ rng: R, sparks: [WHITE, C[4], C[3], C[2]] }), lights = new Lights();
  // sparks start outside the body's middle; most fly on in the hit's direction (+x), a few spray back
  for (let i = 0, n = big ? 16 : 9; i < n; i++) {
    const a = R.chance(0.8) ? R.range(-1.1, 0.9) : R.range(Math.PI - 0.7, Math.PI + 0.5), r0 = R.range(13, 18);
    const sp = R.range(80, big ? 220 : 160);
    ps.spawn(P.SPARK, Math.cos(a) * r0, Math.sin(a) * r0 * 0.85, Math.cos(a) * sp, Math.sin(a) * sp - 25, R.range(0.16, big ? 0.38 : 0.28), R.pick([WHITE, C[4], C[5]]), 1, R.range(0, 0.04));
  }
  for (let i = 0; i < (big ? 6 : 3); i++)
    ps.spawn(P.EMBER, R.range(-16, 16), R.range(-20, 12), R.range(-10, 14), -R.range(12, 28), R.range(0.26, big ? 0.45 : 0.34), C[4], 1, R.range(0.04, big ? 0.16 : 0.1));
  const glints = Array.from({ length: big ? 7 : 4 }, () => {
    const a = R.range(0, Math.PI * 2), r = R.range(18, big ? 32 : 25);
    return { x: Math.cos(a) * r, y: Math.sin(a) * r * 0.85, at: R.range(0.0, big ? 0.26 : 0.18), life: R.range(0.16, 0.28), arm: R.range(2.5, big ? 5.5 : 4) };
  });
  let t = 0, flashed = false;
  return {
    update(dt) {
      t += dt;
      if (!flashed) { flashed = true; lights.add(0, 0, big ? 30 : 20, C[3], big ? 0.6 : 0.4, 0.14); }
      ps.update(dt);
      lights.update(dt);
    },
    draw(p) {
      // the ring opens fast, then thins and fades
      const q = Math.min(1, t / (big ? 0.26 : 0.2)), k = 1 - q;
      if (k > 0.05) {
        const r = 13 + (big ? 24 : 15) * (1 - (1 - q) * (1 - q));
        p.ring(0, 0, r, k > 0.5 ? 2 : 1, k > 0.6 ? C[5] : C[4], 0.85 * k);
        if (big && q > 0.15) p.ring(0, 0, r * 0.72, 1, C[3], 0.6 * k);
      }
      for (const g of glints) {
        const age = t - g.at;
        if (age < 0 || age > g.life) continue;
        const s = Math.sin(Math.PI * (age / g.life));
        if (s > 0.1) sparkle(p, g.x, g.y + 14 * age, 0.5 + g.arm * s, WHITE, C[4], 0.45 * s);
      }
      ps.draw(p);
      lights.draw(p);
    },
  };
}
