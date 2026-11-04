import {drawSharp,palettes} from '../../../luna_brave/a/src/sharp09-a.js';
export const meta={
  "name": "SN luna_air_jump A - sharp moment",
  "size": [
    174,
    90
  ],
  "origin": [
    87,
    24
  ],
  "duration": 0.3333333333333333,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "air"
  ],
  "options": {
    "kind": "air",
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
