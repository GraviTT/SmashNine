import {drawSharp,palettes} from '../../../luna_brave/a/src/sharp09-a.js';
export const meta={
  "name": "SN luna_jump A - sharp moment",
  "size": [
    156,
    66
  ],
  "origin": [
    78,
    28
  ],
  "duration": 0.3,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "jump"
  ],
  "options": {
    "kind": "jump",
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
