// CODEX-VFX-07: 강한 적중 뒤 더 큰 검날 조각과 다섯 반짝임이 남고 쇳불꽃이 넓게 흩어진다. 몸 중앙은 비운다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createHit } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_hit_after_big-b",
  "desc": "강한 적중 뒤 더 큰 검날 조각과 다섯 반짝임이 남고 쇳불꽃이 넓게 흩어진다. 몸 중앙은 비운다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    200,
    180
  ],
  "origin": [
    90,
    80
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "options": {
    "big": true,
    "duration": 0.6,
    "seed": 83
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createHit(resolveOptions(meta,o));
