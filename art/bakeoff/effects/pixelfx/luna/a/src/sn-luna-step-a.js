import {drawSharp,palettes} from '../../../luna_brave/a/src/sharp09-a.js';
export const meta={
  "name": "SN luna_step A - sharp moment",
  "size": [
    90,
    42
  ],
  "origin": [
    72,
    28
  ],
  "duration": 0.35,
  "loop": false,
  "fps": 20,
  "tags": [
    "smashnine",
    "candidate-a",
    "step"
  ],
  "options": {
    "kind": "step",
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
