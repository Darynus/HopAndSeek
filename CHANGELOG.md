# Hop & Seek changelog

## 1.1.1 (2026-11-06)

- **Fix**: minimap button collectors like MinimapButtonButton now pick up the Hop & Seek button.

## 1.1.0 (2026-10-18)

- **Only one gathering profession?** Then Hop & Seek keeps that tracking on. The game switches it off after logging in or dying, your next jump turns it back on, and a line in your chat reminds you. Switching between two tracking types still needs both professions (or two types in your cycle).

## 1.0.0 (2026-10-18)

The first release. Have fun hopping!

- **Jump to switch** your minimap tracking: Find Herbs, Find Minerals, Find Herbs again. One switch per press of the jump key, nothing happens on its own.
- **No "not ready yet":** switching has a short cooldown in the game. Hop & Seek waits 1, 2 or 3 seconds between switches (2 by default) and never tries while a cooldown runs.
- **Three triggers:** every jump, double jump (press jump twice quickly) or only while mounted or in travel form.
- **Pauses** in combat, while swimming or flying, in dungeons and raids, while casting and, if you like, in cities and inns.
- **Your cycle:** Find Herbs and Find Minerals by default. Find Treasure and the hunter, druid, paladin and warlock tracking types can join, only the ones your character knows are used.
- **Tracking icon:** shows the active tracking, greyed out while paused. Click it to switch once, drag it to move it.
- **Self-check:** Hop & Seek notes whether switching works in your game and whether it starts a global cooldown. If it does, the Status tab suggests the double jump.
- **Its own icon:** your Find Herbs and Find Minerals icons in one circle, split by a golden line. The same icon everywhere.
- Window in the look of the game with Status, Settings and Help, minimap button, entry in the add-on menu and under Options > AddOns. Commands: `/hop`, `/hop switch`, `/hop on`, `/hop off`, `/hop jump`, `/hop double`, `/hop mounted`, `/hop debug`.
