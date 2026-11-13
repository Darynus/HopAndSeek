# Hop & Seek changelog

## 1.2.0 (2026-11-13)

- **Gathering counter**: herbs, ore, stone and gems you loot from nodes, per session and all time, with the number of nodes and an amount per hour. See the new Gathered tab. The count of this session sits under the tracking icon, the details are in its tooltip.
- **Gathering window**: a small window like the bar of Campfire Buddy shows your gold per hour, how much you gathered and your best finds. It appears with the first node of a session and hides when the session ends. Drag it anywhere, right-click opens the Gathered tab.
- **What it is worth**: with Auctionator installed, Hop & Seek shows the value of your haul, in total and per hour.
- **Journal**: a new tab that makes gathering a game.
  - Every node earns seeker points, new kinds and uncommon finds earn more. Your points make your rank, from Wanderer to Legend of the Wilds.
  - Set a daily goal (10, 25, 50 or 100 nodes) and keep your streak going day after day.
  - Records for gold per hour, nodes in one session, your best haul and your longest session.
  - 22 badges, from First Find to Lotus Luck.
  - A field guide with every herb, ore, stone and gem you can gather in Forever, the new ones included. Grey ones are still out there.
  - A small pop-up with a game sound tells you when you earn something. Click it to open the journal, or switch pop-ups off for a chat line instead.
  - The gathering window shows your rank and today's nodes, its tooltip shows your streak and records. `/hop journal` opens the tab.
- A new session starts by itself after 30 minutes without gathering, or with Start over and `/hop reset`.
- **What's new** window once after each update. `/hop news` shows it again.
- Square minimaps: the minimap button follows the square edge.

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
