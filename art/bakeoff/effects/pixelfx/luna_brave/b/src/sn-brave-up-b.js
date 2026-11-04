import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_up B directional linger",
  "desc": "어퍼컷 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    200,
    280
  ],
  "origin": [
    80,
    235
  ],
  "duration": 0.7,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "upper",
    "duration": 0.7,
    "seed": 1131,
    "aimDeg": -83,
    "reach": 156
  }
};
meta.options.palette=palette;
export const draw=paint;
