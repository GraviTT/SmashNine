import { palette, drawMotion } from "./frey-motion-b.mjs";
export const meta = {
  "name": "frey_land B directional linger",
  "desc": "낮은 착지에서 바닥을 따라 양쪽으로 미끄러지는 작은 먼지와 깃털.",
  "tags": [
    "smashnine",
    "candidate-b",
    "land"
  ],
  "size": [
    160,
    64
  ],
  "origin": [
    80,
    45
  ],
  "duration": 0.55,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "land",
    "big": false,
    "duration": 0.55
  }
};
meta.options.palette = palette;
export const draw = drawMotion;
