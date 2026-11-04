import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_star_trail A - sharp moment",
  "size": [
    72,
    28
  ],
  "origin": [
    90,
    14
  ],
  "duration": 0.2,
  "fps": 40,
  "loop": true,
  "tags": [
    "smashnine",
    "candidate-a",
    "trail"
  ],
  "options": {
    "kind": "trail",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
