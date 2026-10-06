# Smash Nine Realms Prototype

Godot 4.7 combat-feel prototype for Smash Nine Realms.

## Controls

- `A / D`: move
- `W / Space`: jump
- `J`: directional basic attack
- `K`: skill 1
- `L`: skill 2
- `I`: ultimate test burst
- `1`: switch player character to Frey
- `2`: switch player character to Yuki
- `3`: switch player character to Luna
- `4`: switch player character to Nova
- `5`: decrease active player count
- `6`: increase active player count
- `Q`: use an adjacent-realm portal while standing on it
- `H`: spawn/remove training dummy

## Current Prototype Scope

- Nine 3x3 realms with unique layouts, spawn points, tactical identities, and collapse states
- All realms exist as separate world spaces at the same time; the camera follows the current player realm
- Each realm is expanded to a 3840x2160 play space with connected platform sections
- The camera smoothly follows the human player and stops naturally at realm boundaries
- Realm terrain distinguishes solid main platforms from one-way sub platforms
- Main platforms are sparse, long, and thick; sub platforms are smaller and more numerous
- Platform metadata exposes role, drop-through permission, and optional realm concept tags
- Adjacent-realm portals with guaranteed support platforms below them
- Portal travel requires standing on the portal platform and pressing `Q`
- Central realm starts locked and opens during late convergence
- Collapse countdowns appear on the minimap, throughout the warned realm background, and above connected portals
- Realm collapse warning and collapse flow; trapped combatants are defeated and respawn in a playable realm
- Four prototype characters: Frey, Yuki, Luna, Nova
- Shared movement and jump rules
- Character-specific basic attacks and two skill buttons
- Directional basic attacks with movement input
- One air jump for more flexible aerial combat
- HP-based defeat
- Ringout causes HP damage and respawn, with damage rising as match pressure increases
- HP reaches zero: defeat, then respawn after 3 seconds for early testing
- Simple score reward for the attacker
- Debug UI for HP, score, and ringout count
