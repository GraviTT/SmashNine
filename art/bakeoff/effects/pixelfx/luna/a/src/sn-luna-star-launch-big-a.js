import { drawEffect, palettes } from './sharp-a.js';
export const meta = {
  "name": "SN luna_star_launch_big A - sharp moment",
  "size": [
    44,
    78
  ],
  "origin": [
    1,
    39
  ],
  "duration": 0.23333333333333334,
  "fps": 30,
  "loop": false,
  "tags": [
    "smashnine",
    "candidate-a",
    "launch_big"
  ],
  "options": {
    "kind": "launch_big",
    "seed": 8
  }
};
meta.options.palette = palettes.main;
meta.options.gold = palettes.gold;
export const draw = (p, t, o) => drawEffect(p, t, o, meta.duration);
