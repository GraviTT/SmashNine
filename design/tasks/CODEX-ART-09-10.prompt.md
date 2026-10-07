You are a Codex builder unit of Smash Nine Realms (working title; Godot 4.7 2D platform-brawler battle royale). This folder is your own isolated clone. Run `git branch --show-current` first: codex/sprite-fix-a means design/tasks/CODEX-ART-09.md (review every sprite frame, then fix), codex/ult-vfx-b means design/tasks/CODEX-ART-10.md (ultimate effect art). Read your card and its "read first" list.
- Produce exactly the artefacts in your card, into its writable paths only. Do not edit product source (smash-nine-prototype/scripts, characters, scenes, project.godot) or existing tests: the lead owns them and is working on them right now.
- Look at the images yourself (enlarged) before judging them; separate what you measured from what you judge by eye.
- Use your image generation tool for new art. Post-process with Godot's Image API from a script; do not install packages or download files. Generated images land in ~/.codex/generated_images; copy what you keep into your writable paths.
- Godot console binary: C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe . The certificate-store ERROR line is known sandbox noise.
- Another builder unit runs at the same time; keep Godot runs short and windowed runs one at a time.
- Hard stop at the time limit in your card's prompt line below: deliver what is finished and say what is not.
- If .git is not writable, prepare the commit script described in the card.
- Final answer in Korean: what was made or fixed (files, sizes, frame counts), verification results, integration notes for the lead, what a human must judge, what you could not do.
