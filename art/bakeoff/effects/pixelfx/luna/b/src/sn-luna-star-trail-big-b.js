import { palette, drawTrail } from "./luna-motion-b.mjs";
export const meta = {
  "name": "luna_star_trail_big B directional linger",
  "desc": "큰 별의 중심을 비워 둔 채 더 길게 흐르는 분홍·금빛 별가루 꼬리.",
  "tags": [
    "smashnine",
    "candidate-b",
    "trail"
  ],
  "size": [
    192,
    60
  ],
  "origin": [
    174,
    30
  ],
  "duration": 0.6,
  "loop": true,
  "fps": 20,
  "options": {
    "seed": 47,
    "kind": "trail",
    "big": true,
    "duration": 0.6
  }
};
meta.options.palette = palette;
export const draw = drawTrail;
