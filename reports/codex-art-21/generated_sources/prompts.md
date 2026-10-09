# Built-in ImageGen prompt set

Mode: built-in ImageGen, `transparent_background=true`. Each call used the canonical illustration,
the 4× target frame, and its 4× row sequence as reference images.

## Frey attack r4c3

- Use case: `precise-object-edit`
- Asset: transparent single-frame pixel-art sprite for a 128×128 atlas cell.
- Request: preserve the target's body pose, face, helmet wings, blonde hair, sword angle, armor,
  cape, palette, chibi proportions, and pixel style. Replace only the too-thin edge-on shield
  with a readable foreshortened oval blue-and-gold shield, including the gold star, on her forward
  arm. The pose is attack follow-through/recovery, facing right.
- Constraints: feet on the established baseline; generous transparent margin; no crop, text,
  border, checkerboard, watermark, soft rendering, semi-transparent halo, extra limb, or weapon.

## Luna idle r0c1

- Use case: `precise-object-edit`
- Asset: transparent single-frame pixel-art sprite for a 128×128 atlas cell.
- Request: preserve the exact idle-phase body pose, face, long pink hair, bow, costume, hands,
  palette, proportions, and pixel style. Replace only the broken wand-head fragment with the
  complete five-point pale-cyan star head with gold outline from the illustration and neighboring
  idle frames, attached to the existing handle.
- Constraints: facing right, feet on baseline, transparent margin; no new magic effect, pose or
  costume change, crop, text, border, checkerboard, watermark, soft rendering, or alpha halo.

## Luna idle r0c2

- Same invariants as r0c1, but preserve r0c2's distinct idle phase so the result continues to
  animate between r0c1 and r0c3. Restore only the complete cyan-and-gold five-point wand head.

The returned PNGs are `frey_attack4_imagegen.png`, `luna_idle2_imagegen.png`, and
`luna_idle3_imagegen.png`. `prepare_frey_candidate.gd` crops opaque bounds, nearest-neighbor
reduces them to the recorded target heights, applies a 0.5 hard-alpha cutoff, centers them, and
places the lowest opaque pixel at y=120. The retained 128px candidates sit beside the sources.
