import {palette, drawHit as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_hit_after_big B directional linger",
  "desc": "강한 적중 뒤 더 넓고 긴 별조각 여운. 중심 섬광은 기존 적중 그림이 담당한다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    290,
    175
  ],
  "origin": [
    125,
    70
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "hit",
    "duration": 0.8,
    "seed": 1316,
    "big": true
  }
};
meta.options.palette=palette;
export const draw=paint;
