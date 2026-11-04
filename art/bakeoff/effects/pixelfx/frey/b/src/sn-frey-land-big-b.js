import { palette, drawMotion } from "./frey-motion-b.mjs";
export const meta = {
  "name": "frey_land_big B directional linger",
  "desc": "큰 착지에서 넓게 굴러 나가는 황금 먼지와 깃털. 작은 착지보다 넓고 오래 남는다.",
  "tags": [
    "smashnine",
    "candidate-b",
    "land"
  ],
  "size": [
    216,
    80
  ],
  "origin": [
    108,
    57
  ],
  "duration": 0.8,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "land",
    "big": true,
    "duration": 0.8
  }
};
meta.options.palette = palette;
export const draw = drawMotion;
