import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN frey_land_big A - sharp moment",
  "size": [
    178,
    42
  ],
  "origin": [
    89,
    34
  ],
  "duration": 0.4,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "land_big"
  ],
  "options": {
    "kind": "land_big",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
