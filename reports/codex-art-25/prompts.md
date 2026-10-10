# ART-25 ImageGen final prompt set

Mode: built-in ImageGen, one generation round per asset. Every output below was retained as
`*_source.png`; no external image source or downloaded file was used.

## Monster sheets

Common final prompt: create one transparent-background fantasy pixel-art monster animation
sheet arranged as a strict 6-column × 4-row grid. Rows are idle, walk, attack and hurt; keep
the same dark outline weight, pixel density and game-size silhouette as the referenced
`mossling_sheet.png` and `ember_imp_sheet.png`. The matching realm `bg_mid.png` is the palette
and theme reference. Right-facing, no text, no UI, no watermark, no frame dividers.

Subjects: Asgard winged aegis ram; Niflheim frost owl; Alfheim crescent moon moth;
Svartalfheim brass gear beetle; Vanaheim vine hound; Jotunheim rune-stone golem;
Yggdrasil Heart root oracle. The first, fourth, fifth and sixth are melee silhouettes; the
second, third and seventh have readable ranged casting poses.

Projectile final prompt: one single centered right-facing fantasy pixel-art projectile on a
transparent background, strong dark outline, no text/UI/watermark, matching the referenced
monster and realm palette. Subjects: Niflheim frost bolt, Alfheim moon seed, Yggdrasil soul seed.

## UI

Realm emblem final prompt: one centered 32×32-ready fantasy pixel emblem, transparent
background, thick dark-navy outline, readable at minimap size, no letters/text/frame/character/
watermark, matching the referenced realm background. Subjects: winged sun gate, lantern
rooftops, frost crystal, crescent leaf, flame mountain, gear tower, forest temple pool, giant
monolith, Yggdrasil crystal heart.

Status icon final prompt: one centered 24×24-ready fantasy pixel icon, transparent background,
dark-navy outline, no letters/text/frame/character/watermark. Subjects: super armor shield,
stun stars, Luna charge star, Frey pursuit wings, broken shield, low-HP heart.

Frame final prompt: one symmetric ornate blue-gold fantasy pixel-art 9-slice UI border,
transparent outside and center, square clean corners, no text/icons/characters/watermark.
Targets: skill slot, long HP bar, card panel, large result panel and menu button.

Title final prompt: cinematic 16:9 pixel-art start-screen background showing all nine floating
realms around the luminous Yggdrasil Heart, based on both concept paintings and current realm
art, with a calm dark logo-safe area in the upper center, no title/text/UI/characters/watermark.
