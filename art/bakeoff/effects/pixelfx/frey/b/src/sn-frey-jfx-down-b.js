// CODEX-VFX-07: 지상의 15도 내려 베기를 따라 금빛 검날 조각이 남고 쇳불꽃이 발 높이에서 튄다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createFollow } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_jfx_down-b",
  "desc": "지상의 15도 내려 베기를 따라 금빛 검날 조각이 남고 쇳불꽃이 발 높이에서 튄다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    300,
    150
  ],
  "origin": [
    35,
    90
  ],
  "duration": 0.75,
  "loop": false,
  "fps": 20,
  "options": {
    "aimDeg": 15,
    "reach": 157,
    "floorY": 32,
    "duration": 0.75,
    "seed": 71
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createFollow(resolveOptions(meta,o));
