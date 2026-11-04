import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_rush_1 B directional linger",
  "desc": "잽 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    250,
    150
  ],
  "origin": [
    35,
    65
  ],
  "duration": 0.5,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "jab",
    "duration": 0.5,
    "seed": 1020,
    "aimDeg": -1,
    "reach": 131
  }
};
meta.options.palette=palette;
export const draw=paint;
