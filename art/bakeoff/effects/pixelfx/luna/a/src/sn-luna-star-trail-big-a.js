import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_star_trail_big A - sharp moment",
  "size": [
    96,
    40
  ],
  "origin": [
    128,
    20
  ],
  "duration": 0.25,
  "fps": 40,
  "loop": true,
  "tags": [
    "smashnine",
    "candidate-a",
    "trail_big"
  ],
  "options": {
    "kind": "trail_big",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
