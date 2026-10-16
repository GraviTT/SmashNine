You are the Codex image builder unit of SmashNine, second pass on design/tasks/CODEX-DOC-02.md. Same clone, same branch codex/doc-02; your ten images are in reports/sprite-audit-2026-10-16/images/.
The lead reviewed every image. Edit only what is listed below and keep everything else (titles, captions, colours, sizes). Same rules as the card: real frames or sprites only, no image_gen, text drawn with Pillow, strings exactly as written. New strings allowed in this pass, exactly: "왼쪽 점 = 그림 · 오른쪽 점 = 이펙트", "Rio 룬 반격", "지금 (v1)", "후보 (v2)", "Frey · 피격 상자 42×64", "그림", "이펙트".

- 01-summary: the reader cannot tell which dot is which. Add a third legend line "왼쪽 점 = 그림 · 오른쪽 점 = 이펙트", and the small labels "그림" and "이펙트" under the first pair of dots (Frey). Draw the sprites at 2× (NEAREST) so they fill the empty middle.
- 02-guard: frame 38 is covered by white X-shaped parry flashes in both rows, so the arc is hard to see. Use a frame with no parry flash in either row (frame 29 works for Frey), the same index for all six. Crop so about 40 px under the floor line show (the caption says the old arc went under the floor; that part must be visible), and draw the floor line in #ffd166.
- 03-j-trail: the Nova panel shows the shared slash being removed, which is image 04's point, not thickness. Replace Nova with Rio ground J, at the frame where its trail is biggest. Luna is cut off at the lower left: recrop so her whole body is in the panel.
- 04-doubled: label the first panel "Rio 룬 반격" instead of "Rio".
- 06-bloom: the clip targets are grey boxes and Brave Luna's clip has no target, so the panels do not show the change. Replace both panels with a composite of real sprites in the game's layer order. The target is Frey's idle frame at 2×. The bloom is one frame of effects/skill/luna_star_bloom.png, drawn at the size a J bloom has in the game (visible diameter about 123 px at 1×, so 246 px at 2×), centred on Frey's chest.
  - 전: bloom drawn over Frey.
  - 후: Frey drawn over the bloom.
  - Label them with the usual 전/후 tags. Keep the title and captions.
- 08-rio-head: the same-size boxes do not show head size, the idles are squeezed and cut off, and the lower half is empty. Show full figures at the same 3× scale standing on one shared floor line, in two groups:
  - male: idle, attack
  - female: idle, attack, low_sweep, dimension_slash
  
  In each group, draw two thin horizontal #ffd166 guide lines across all its figures, at the idle head's top and at its chin. A smaller head then visibly falls short of the guides. Keep the ×ratio labels. Remove the boxes.
- 09-nova-hurt: the layout is broken: an empty third box runs off the right edge, and the v2 panel is narrower. Make two equal panels, centred, labelled "지금 (v1)" and "후보 (v2)". Add a small #ffd166 bracket marking the 8 px gap between v1's lowest foot and the floor line.
- 10-kept: draw the Frey panel at 2× and label it "Frey · 피격 상자 42×64".

Then rebuild contact.png and update images.md. Look at every changed image yourself (view_image) at full size and at 400×225. Update commit.ps1 if the file list changed. Final answer in Korean: what changed in each image, and anything you could not do.
