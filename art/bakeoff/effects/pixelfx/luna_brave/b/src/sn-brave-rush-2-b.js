import {palette, drawFollow as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_rush_2 B directional linger",
  "desc": "보디 킥 방향을 따라 끊어진 분홍·금빛 선과 별조각이 남고 아래로 가라앉는다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    270,
    160
  ],
  "origin": [
    35,
    65
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "kick",
    "duration": 0.6,
    "seed": 1057,
    "aimDeg": -3,
    "reach": 147
  }
};
meta.options.palette=palette;
export const draw=paint;
