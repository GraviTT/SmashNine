import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_up A - sharp moment",
  "size": [
    310,
    450
  ],
  "origin": [
    95,
    185
  ],
  "duration": 0.3333333333333333,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "upper"
  ],
  "options": {
    "kind": "upper",
    "aim": -83,
    "reach": 156,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
