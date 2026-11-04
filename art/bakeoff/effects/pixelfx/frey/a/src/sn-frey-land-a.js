import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN frey_land A - sharp moment",
  "size": [
    124,
    28
  ],
  "origin": [
    62,
    22
  ],
  "duration": 0.26666666666666666,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "land"
  ],
  "options": {
    "kind": "land",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
