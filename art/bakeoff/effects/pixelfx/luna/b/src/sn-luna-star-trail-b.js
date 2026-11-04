import { palette, drawTrail } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_star_trail B directional linger",
  "desc": "작은 별 뒤에서 서로 떨어진 분홍·금 빛줄기와 작은 별들이 뒤로 흐르는 반복 꼬리.",
  "tags": [
    "smashnine",
    "candidate-b",
    "trail"
  ],
  "size": [
    144,
    52
  ],
  "origin": [
    130,
    26
  ],
  "duration": 0.5,
  "loop": true,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "trail",
    "big": false,
    "duration": 0.5
  }
};
meta.options.palette = palette;
export const draw = drawTrail;
