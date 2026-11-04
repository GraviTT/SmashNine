import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN frey_jump A - sharp moment",
  "size": [
    124,
    32
  ],
  "origin": [
    62,
    9
  ],
  "duration": 0.3333333333333333,
  "fps": 24,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "jump"
  ],
  "options": {
    "kind": "jump",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
