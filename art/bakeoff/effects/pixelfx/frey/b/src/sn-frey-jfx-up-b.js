// CODEX-VFX-07: 위로 벤 검의 호에서 금빛 쇳불꽃이 흩어지고, 떨어진 불꽃은 발 높이에서 한 번 튄다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createFollow } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_jfx_up-b",
  "desc": "위로 벤 검의 호에서 금빛 쇳불꽃이 흩어지고, 떨어진 불꽃은 발 높이에서 한 번 튄다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    200,
    250
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
    "floorY": 32,
    "duration": 0.8,
    "seed": 71
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createFollow(resolveOptions(meta,o));
