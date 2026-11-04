import { palette, drawMotion } from "./frey-motion-b.mjs";
export const meta = {
  "name": "frey_jump B directional linger",
  "desc": "도약 지점 아래와 바깥으로 눌려 나가는 금빛 먼지와 흰 깃털.",
  "tags": [
    "smashnine",
    "candidate-b",
    "jump"
  ],
  "size": [
    160,
    64
  ],
  "origin": [
    80,
    24
  ],
  "duration": 0.6,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "jump",
    "big": false,
    "duration": 0.6
  }
};
meta.options.palette = palette;
export const draw = drawMotion;
