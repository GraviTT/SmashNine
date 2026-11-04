import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_side_air B directional linger",
  "desc": "비행 킥 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    290,
    170
  ],
  "origin": [
    35,
    75
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "fly",
    "duration": 0.6,
    "seed": 1205,
    "aimDeg": -5,
    "reach": 170
  }
};
meta.options.palette=palette;
export const draw=paint;
