import { palette, drawMotion } from "./frey-motion-b.mjs";
export const meta = {
  "name": "frey_air_jump B directional linger",
  "desc": "공중 두 번째 발차기 아래로 벌어지는 흰 깃털 여덟 개와 금빛 알갱이.",
  "tags": [
    "smashnine",
    "candidate-b",
    "air"
  ],
  "size": [
    160,
    72
  ],
  "origin": [
    80,
    20
  ],
  "duration": 0.7,
  "loop": false,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "air",
    "big": false,
    "duration": 0.7
  }
};
meta.options.palette = palette;
export const draw = drawMotion;
