// CODEX-VFX-07: 공중의 73도 내려 베기 뒤 금빛 궤적이 조각나고 쇳불꽃이 아래로 길게 흩어진다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createFollow } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_jfx_down_air-b",
  "desc": "공중의 73도 내려 베기 뒤 금빛 궤적이 조각나고 쇳불꽃이 아래로 길게 흩어진다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    240,
    440
  ],
  "origin": [
    65,
    95
  ],
  "duration": 0.7,
  "loop": false,
  "fps": 20,
  "options": {
    "aimDeg": 73,
    "reach": 157,
    "floorY": null,
    "duration": 0.7,
    "seed": 71
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createFollow(resolveOptions(meta,o));
