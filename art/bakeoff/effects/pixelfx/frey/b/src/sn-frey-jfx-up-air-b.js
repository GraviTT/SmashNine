// CODEX-VFX-07: 공중 대공 베기 뒤 금빛 검날 흔적과 반짝임이 남고 불꽃은 바닥 없이 아래로 떨어진다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createFollow } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_jfx_up_air-b",
  "desc": "공중 대공 베기 뒤 금빛 검날 흔적과 반짝임이 남고 불꽃은 바닥 없이 아래로 떨어진다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    200,
    370
  ],
  "origin": [
    70,
    190
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "options": {
    "aimDeg": -83,
    "reach": 155,
    "floorY": null,
    "duration": 0.8,
    "seed": 71
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createFollow(resolveOptions(meta,o));
