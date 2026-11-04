import {drawSharp,palettes} from './sharp09-a.js';
export const meta={
  "name": "SN brave_side_air A - sharp moment",
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
    "flying"
  ],
  "options": {
    "kind": "flying",
    "aim": -5,
    "reach": 170,
    "seed": 9
  }
};
meta.options.palette=palettes.main;
meta.options.gold=palettes.gold;
export const draw=(p,t,o)=>drawSharp(p,t,o,meta.duration);
