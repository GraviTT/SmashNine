import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_down_air B directional linger",
  "desc": "급강하 킥 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    200,
    360
  ],
  "origin": [
    70,
    50
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "dive",
    "duration": 0.8,
    "seed": 1242,
    "aimDeg": 81,
    "reach": 206
  }
};
meta.options.palette=palette;
export const draw=paint;
