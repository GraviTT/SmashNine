import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_hit_after A - sharp moment",
  "size": [
    120,
    42
  ],
  "origin": [
    60,
    19
  ],
  "duration": 0.3,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "hit"
  ],
  "options": {
    "kind": "hit",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
