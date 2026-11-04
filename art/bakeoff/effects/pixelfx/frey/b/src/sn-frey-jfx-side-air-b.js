// CODEX-VFX-07: 공중 옆 베기의 끝과 휘어진 검날에 금빛 반짝임이 남고 불꽃이 앞으로 튀며 낙하한다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createFollow } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_jfx_side_air-b",
  "desc": "공중 옆 베기의 끝과 휘어진 검날에 금빛 반짝임이 남고 불꽃이 앞으로 튀며 낙하한다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    330,
    360
  ],
  "origin": [
    35,
    100
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "options": {
    "aimDeg": -2,
    "reach": 186,
    "floorY": null,
    "duration": 0.8,
    "seed": 71
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createFollow(resolveOptions(meta,o));
