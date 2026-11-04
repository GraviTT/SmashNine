import {palette, drawHit as paint} from "./brave-linger-b.mjs";
export const meta={
  "name": "brave_hit_after B directional linger",
  "desc": "적중 불꽃 바깥에 분홍·금빛 별조각이 전방으로 길게 흐른다. 중심은 비운다.",
  "tags": [
    "smashnine",
    "stars",
    "directional",
    "one-shot"
  ],
  "size": [
    240,
    140
  ],
  "origin": [
    105,
    65
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "bg": "dark",
  "options": {
    "kind": "hit",
    "duration": 0.6,
    "seed": 1279
  }
};
meta.options.palette=palette;
export const draw=paint;
