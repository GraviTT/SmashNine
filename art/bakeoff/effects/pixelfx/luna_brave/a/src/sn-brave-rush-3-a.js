import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_rush_3 A - sharp moment",
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
    "spin"
  ],
  "options": {
    "kind": "spin",
    "aim": -22,
    "reach": 157,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
