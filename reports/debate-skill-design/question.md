# Debate question: character skill diversity (2026-10-15)

## The question

SmashNine has five fighters: Frey, Yuki, Luna (with her 6-second Brave Luna form), Nova and Rio. The user's request (2026-10-15, Korean): "밸런스보다 스킬의 다양성 개발을 우선한다. 각 캐릭터의 스킬을 어떻게 구성하고, 차별점과 개성을 주고, 그렇게 하여 캐릭터가 어떤 역할을 하게 될지."

How should each character's skills be composed so that the five are clearly different and each has its own personality? And what role does each character then play, both inside a fight and across a battle-royale match?

Answer for the whole roster and for each character:

1. **Roster first:** where the current kits overlap or converge on the same template (name the moves), and the role map you propose for the five (how each wins, where and when in a match each is strong, who beats whom).
2. **Per character:**
   - identity in one sentence
   - the one core rule only this character has
   - button by button (J and its directional/aerial variants, K, L, I, passive), what to keep, change or add, each with the reason
   - role in a fight, role in the match
   - weakness and the opponent's counterplay
   - cost: which current sprite rows and effect files can be reused, what needs new art, what the bot (`EnemyAI.gd`) must learn

## Decision criteria (ranked)

1. Each character is clearly different from the other four, and its concept shows in its moves (the user's finishing criteria 1 and 5 in `design/DECISIONS.md` D31).
2. It serves the game's pillars in `FINAL_GAME_GOAL.md`: knockback as space control; HP-based elimination where a ring-out costs HP; collapsing realms and a 5–7 minute battle royale; the fixed six-button control.
3. Players can read what each skill is and combos feel good (criteria 3 and 4).
4. Strengths and weaknesses are clear and skill can cover them; a bot can play the character's identity (criteria 6 and 7).
5. Art cost: every character's sprite rows were redrawn on 2026-10-13~15. Reusing the current rows is much cheaper than new ones.

## Constraints

- Diversity comes before balance in this work. Numbers get tuned later.
- The controls are fixed: move, jump, J (basic, by direction and air/ground), K, L, I (ultimate, 30 s shared cooldown), Guard (shared by all).
- Frey's balance has been on hold since 2026-10-06 by the user. You may still propose kit changes for Frey; say what they would cost her identity as the benchmark character.
- Rio's kit (J 3-hit mana slash, K dimension slash, L rune shield, I six gem swords, 2 air jumps) was the user's pick in D21. Changes are allowed; say why.
- Solo battle royale, 8 players now (16 later), nine realms on a 3×3 grid with hazards, portals, monsters, soul crystals and three soul-card picks (`scripts/match/SoulCards.gd`).
- The code wins over the character `.md` docs where they disagree (`design/SKILLS.md` is written from the code).

## Read

- `design/SKILLS.md` (every move as the code plays it: numbers, sprite rows, effect files)
- `smash-nine-prototype/FINAL_GAME_GOAL.md`
- `smash-nine/GAME_DESIGN_DOCUMENT.md`, section 3 (roster, role classes)
- `smash-nine-prototype/characters/*/*.md` (each character's design doc)
- `design/DECISIONS.md` (D21, D26, D30, D31 in particular)
- `reports/codex-qa-17/README.md` (section "다섯 캐릭터 차별화")
- `design/BOT_TUNING.md` section 6 (what the bot must follow when a kit changes)
- character scripts under `smash-nine-prototype/characters/` and `smash-nine-prototype/scripts/match/SoulCards.gd` as needed
