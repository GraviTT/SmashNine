import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_rush_1 A - sharp moment",
  "size": [
    310,
    450
  ],
  "origin": [
    95,
    185
  ],
  "duration": 0.23333333333333334,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "jab"
  ],
  "options": {
    "kind": "jab",
    "aim": -1,
    "reach": 131,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
