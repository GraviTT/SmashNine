import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_low B directional linger",
  "desc": "낮은 후리기 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    270,
    145
  ],
  "origin": [
    35,
    48
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "low",
    "duration": 0.6,
    "seed": 1168,
    "aimDeg": -3,
    "reach": 157
  }
};
meta.options.palette=palette;
export const draw=paint;
