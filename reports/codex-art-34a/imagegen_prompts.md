# ImageGen prompt record

Built-in `image_gen` mode was used with transparent output. Each call referenced the active
character sheet as the idle-scale/pixel-style anchor and the character's main illustration as
the costume/face/equipment reference.

## Base prompt shared structure

- Asset: production source strip for a 2D pixel-art platform-brawler walk animation.
- Layout: exactly seven isolated full-body side-view figures facing right in one horizontal row.
- Figure 1: neutral idle scale anchor matching the active sheet.
- Figures 2–7: contact, down, passing, opposite contact, down, opposite passing.
- Constraints: one newly drawn complete character per frame; identical head size; face visible;
  legs unobscured; transparent background; no text, grid, panel, effects, trails, duplicate limbs,
  pasted head/body parts, logo, or watermark.

Character-specific prompts preserved:

- Frey: blonde Valkyrie, silver/gold armour, blue cape, sword and oval shield; weapon and cape
  behind/above the alternating legs.
- Rio male: indigo-haired navy/teal/silver spellblade, compact raised cyan sword, free-arm
  counter-swing.
- Rio female: indigo ponytail, navy/teal/silver spellblade outfit, compact raised cyan sword,
  ponytail and coat tails behind the legs.
- Yuki: black-violet ponytail, red-white cord and bell, plum/vermilion/ivory onmyoji coat, dark
  trousers and boots, one compact held talisman.

## Targeted second rounds

Rio male and Yuki received one additional built-in ImageGen round because round 1 measured
41.7% and 39.5% feet-band change. The single requested change was stronger foot separation:
far heel/toe contact, deeper down poses, and a clearly lifted passing foot, including a distinct
frame 6 -> frame 1 loop. Frey and Rio female kept their first candidates.

