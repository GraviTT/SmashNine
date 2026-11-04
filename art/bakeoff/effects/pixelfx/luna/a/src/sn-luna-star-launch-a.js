import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_star_launch A - sharp moment",
  "size": [
    30,
    52
  ],
  "origin": [
    1,
    26
  ],
  "duration": 0.2,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "launch"
  ],
  "options": {
    "kind": "launch",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
