# Debate log: character skill diversity

- Question: `question.md` (2026-10-15).
- Lead position: `reports/skill-design-2026-10-15/README.md` (commit `80a2711`), frozen before the blind run. Copy in the lead's scratchpad as `position.md`.
- Blind conditions: Codex ran read-only and ephemeral at effort high in the analyst clone (`SmashNine-units/analyst/SmashNine`, branch `debate/skill-design`) checked out at `f3737e4`, the commit before the lead's proposal; no ref in that clone reaches `80a2711`. The prompt forbids looking for the lead's position.
- User request (2026-10-15): compare with an independent Codex proposal that has not seen the lead's document.

## Blind (`blind.md`)

Codex (gpt-5.6-sol, effort high, 447 s): keep most of the kit and add two rules — Yuki's link line between two seals (one slow per crossing, no damage) and Rio's dimension link (K after a landed J1/J2 keeps the combo step). Frey, Luna and Nova keep their kits; the bot must play each identity.

Facts checked by the lead: Rio K resets the combo today (`Rio.gd:248`, `_dimension_slash_start` → `_reset_combo()`); the bot presses Luna's Heart Laser at a fixed 4.4 s (`EnemyAI.gd:95`, `ULTIMATE_FOLLOWUPS`); soul cards are six shared cards (`SoulCards.gd:7-12`).

## Revision of the lead's position (2026-10-15, after the blind answer)

The blind answer was compared with the frozen position; the comparison is section 7 of `reports/skill-design-2026-10-15/README.md` (Korean).

- **Frey: changed.** The lead had recommended a shield vanguard (horizontal shield charge K, shield-bash J3, poise passive). It now recommends keeping the kit. Reason: once Rio's K becomes a combo link, Frey's K overlaps only with Brave Luna's 6-second K. Changing the benchmark kit also costs a new move row while Frey's balance is on hold. The shield vanguard stays as an alternative for the user.
- **Yuki: changed.** Codex's link line replaces the lead's radius-slow trap. Two points make a visible line, which gives the two-seal cap a meaning, and one slow per line is less oppressive. The lead's caged ultimate stays an option.
- **Rio: changed.** Codex's dimension link becomes Rio's core rule, with lower J knockback (both agree). The lead's third-party bonus stays an option; the pogo air-down J is lowered in priority.
- **Nova: partly.** The lead's zero-gravity up-J is lowered to an option; Codex's bot momentum sequences are accepted.
- **Luna: both kept.** The multi-hit star bonus (lead) and the bot's laser decision (Codex) do not conflict.
- **Bot behaviour per identity** (Codex, all five) is accepted as part of each character's work (D31 criterion 6).
- **Open (not measured, the user's call):** the matchup maps differ. Lead: Frey > Yuki/normal Luna, Rio/Nova > Frey, Yuki > Rio/Nova, Luna switches. Codex: prepared Yuki > Frey > Rio > Nova > Luna > Yuki. They clash on Frey vs Yuki and Frey vs Rio. Check with fixed scenes and 8-player soaks once the changes are in.

No attack round has run yet; the user asked for the blind comparison only.
