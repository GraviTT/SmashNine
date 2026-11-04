import { palette, drawHit } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_hit_after B directional linger",
  "desc": "기존 적중 불꽃 옆에서 별 조각이 탄의 진행 방향으로 떠밀려 내려오는 여운. 몸 가운데는 비운다.",
  "tags": [
    "smashnine",
    "candidate-b",
    "hit"
  ],
  "size": [
    176,
    100
  ],
  "origin": [
    76,
    40
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "hit",
    "big": false,
    "duration": 0.6
  }
};
meta.options.palette = palette;
export const draw = drawHit;
