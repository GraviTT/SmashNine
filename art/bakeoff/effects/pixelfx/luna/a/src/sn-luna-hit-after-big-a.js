import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_hit_after_big A - sharp moment",
  "size": [
    162,
    60
  ],
  "origin": [
    81,
    21
  ],
  "duration": 0.36666666666666664,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "hit_big"
  ],
  "options": {
    "kind": "hit_big",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
