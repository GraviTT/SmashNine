import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_low A - sharp moment",
  "size": [
    310,
    450
  ],
  "origin": [
    95,
    185
  ],
  "duration": 0.26666666666666666,
  "loop": false,
  "fps": 30,
  "tags": [
    "smashnine",
    "candidate-a",
    "low"
  ],
  "options": {
    "kind": "low",
    "aim": -3,
    "reach": 157,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
