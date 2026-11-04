// Frey pilot, candidate A (lead, 2026-11-04, CODEX-VFX-07 spec): bakes the J follow-through for her up, down and
// air J and the hit afterglow into Vfx strips in art/bakeoff/effects/pixelfx/frey/a/.
//   node reports/pixelfx-frey-pilot-2026-11-04/bake_a.mjs
// Reach and shown angle come from PlayerBase._draw_attack_art for each move (Frey.gd _up_slash, _down_cut,
// _air_slash): reach = farthest hit point along the aim + half the hit box, all at COMBAT 1.5.
import { mkdirSync } from "node:fs";
import { effect, bakeStrip, saveStrip } from "../pixelfx-eval-2026-11-03/bench.mjs";

mkdirSync(new URL("../../art/bakeoff/effects/pixelfx/frey/a/", import.meta.url), { recursive: true });
const PAL = ["#3a2206", "#7a4a10", "#c08020", "#f0c040", "#fff0a0", "#ffffff"];
const jfx = await effect("melee/sn-frey-jfx-a"), hit = await effect("impacts/sn-frey-hit-after-a");
const J = [
  ["frey_jfx_up-a", "↑J 지상", { reach: 155, aim: -83, floorY: 32 }, { w: 200, h: 260, anchor: [80, 210] }],
  ["frey_jfx_up_air-a", "↑J 공중", { reach: 155, aim: -83, floorY: null }, { w: 200, h: 260, anchor: [80, 210] }],
  ["frey_jfx_down-a", "↓J 지상 (땅에서는 15°로 눕혀 보임)", { reach: 157, aim: 15, floorY: 32 }, { w: 300, h: 150, anchor: [20, 80] }],
  ["frey_jfx_down_air-a", "↓J 공중", { reach: 157, aim: 73, floorY: null }, { w: 200, h: 260, anchor: [60, 60] }],
  ["frey_jfx_side_air-a", "공중 J", { reach: 186, aim: -2.3, floorY: null }, { w: 300, h: 150, anchor: [20, 70] }],
];
for (const [name, move, opts, box] of J) {
  const strip = bakeStrip(jfx, { palette: PAL, ...opts }, { frames: 19, fps: 20, ...box, additive: true, minLight: 40 });
  saveStrip(`frey/a/${name}`, strip, {
    note: `리드 A안: ${move} 뒤 칼끝에서 불꽃이 튀고, 궤적이 사라지면 금빛 반짝임과 테두리 잔상이 남는다(지상 3연타 불꽃을 이 기술의 방향으로 돌림, 중력은 아래).`,
    attach: `${move}: frey_slash와 같은 순간 · 같은 자리(몸 중심), 바라보는 쪽으로 좌우만 뒤집음`,
    frames: 19, fps: 20, anchor: box.anchor, blend: "add", source: "pixelfx melee/sn-frey-jfx-a (pinned a84159688af3)",
  });
}
for (const [name, big, box, frames] of [["frey_hit_after-a", false, { w: 128, h: 112, anchor: [64, 56] }, 10], ["frey_hit_after_big-a", true, { w: 192, h: 160, anchor: [96, 80] }, 14]]) {
  const strip = bakeStrip(hit, { palette: PAL, big }, { frames, fps: 20, ...box, additive: true, minLight: 40 });
  saveStrip(`frey/a/${name}`, strip, {
    note: `리드 A안: Frey 적중 불꽃 뒤에 남는 것 — 얇은 금빛 고리가 열리고, 강철 불꽃이 맞은 방향으로 날아가 떨어지고, 몸 둘레에 반짝임. 가운데는 비움.${big ? " 강한 적중(넉백 480 이상)용." : ""}`,
    attach: "맞은 몸 중심(공격자 적중 불꽃 자리), 적중 한 번에 한 번, 바라보는 쪽으로 좌우만 뒤집음",
    frames, fps: 20, anchor: box.anchor, blend: "add", source: "pixelfx impacts/sn-frey-hit-after-a (pinned a84159688af3)",
  });
}
