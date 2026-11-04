import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_rush_3 B directional linger",
  "desc": "회전 킥 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    280,
    200
  ],
  "origin": [
    40,
    120
  ],
  "duration": 0.7,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "spin",
    "duration": 0.7,
    "seed": 1094,
    "aimDeg": -22,
    "reach": 157
  }
};
meta.options.palette=palette;
export const draw=paint;
