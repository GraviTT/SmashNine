import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN frey_air_jump A - sharp moment",
  "size": [
    138,
    38
  ],
  "origin": [
    68,
    9
  ],
  "duration": 0.3333333333333333,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "air"
  ],
  "options": {
    "kind": "air",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
