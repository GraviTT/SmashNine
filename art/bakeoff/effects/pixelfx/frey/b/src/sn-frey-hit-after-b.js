// CODEX-VFX-07: 기존 적중 불꽃이 잦아들 때 몸 양옆에 짧은 금빛 검날 조각과 작은 쇳불꽃이 남는다.
import { resolveOptions } from "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/src/core/index.js";
import { PALETTE, createHit } from "./frey-b-common.mjs";
export const meta = {
  "name": "frey_hit_after-b",
  "desc": "기존 적중 불꽃이 잦아들 때 몸 양옆에 짧은 금빛 검날 조각과 작은 쇳불꽃이 남는다.",
  "tags": [
    "smashnine",
    "frey",
    "candidate-b",
    "one-shot"
  ],
  "size": [
    160,
    150
  ],
  "origin": [
    75,
    70
  ],
  "duration": 0.45,
  "loop": false,
  "fps": 20,
  "options": {
    "big": false,
    "duration": 0.45,
    "seed": 83
  }
};
meta.options.palette = PALETTE;
export const create = (o) => createHit(resolveOptions(meta,o));
