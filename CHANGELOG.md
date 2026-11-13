# Hop & Seek changelog

## 1.2.1 (2026-11-13)

- **Next spot**: the pin in the gathering window, `/hop next` or a key binding sets the game's own marker on the nearest herb or ore vein you gathered before, with the distance on your screen. Gather there, and the marker moves on to the next spot. Spots you gathered in the last ten minutes are skipped, and only kinds your professions can gather count. Right-click the pin or `/hop next stop` ends the guide, your own map pin stays untouched once you set a new one.
- **Key bindings**: Esc > Options > Keybindings > AddOns > Hop & Seek.
- Gathering spots no longer show on the world map and in OpenMap, map add-ons do that better. Hop & Seek still remembers every node you gather for Next spot, and the Gathered tab shows how many spots it knows.
- The light pillar does less work in busy places.

## 1.2.0 (2026-11-13)

- **Gathering counter**: herbs, ore, stone and gems you loot from nodes, and the leather and hides you skin, per session and all time, with the number of nodes and an amount per hour. See the new Gathered tab. The count of this session sits under the tracking icon, the details are in its tooltip.
- **Gathering window**: a small window like the bar of Campfire Buddy shows your gold per hour, how much you gathered and your best finds. It appears with the first node of a session and hides when the session ends. Drag it anywhere, right-click opens the Gathered tab.
- **What it is worth**: with Auctionator installed, Hop & Seek shows the value of your haul, in total and per hour. Prefer Midas? Pick it as your price source in the Gathered tab.
- **Journal**: a new tab that makes gathering a game.
  - Every node earns seeker points, new kinds and uncommon finds earn more. Your points make your rank, from Wanderer to Legend of the Wilds.
  - Set a daily goal (10, 25, 50 or 100 nodes) and keep your streak going day after day.
  - Records for gold per hour, nodes in one session, your best haul and your longest session.
  - 22 badges, from First Find to Lotus Luck.
  - A field guide with every herb, ore, stone and gem you can gather in Forever, the new ones included. Grey ones are still out there.
  - A small pop-up with a game sound tells you when you earn something. Click it to open the journal, or switch pop-ups off for a chat line instead.
  - The gathering window shows your rank and today's nodes, its tooltip shows your streak and records. `/hop journal` opens the tab.
  - **Share** your journal with your group with one click and compare ranks and records with your friends. Also `/hop share`.
- **Gathering spots on your world map**: every node you gather becomes a small pin with the icon of what grew there, green for herbs and brown for ore. Spots close together count as one, caves count for their zone. Works with OpenMap, right-click removes a pin.
- **Time to train**: Hop & Seek tells you once when Herbalism or Mining reaches the limit of your rank, and the gathering window reminds you until you have visited a trainer.
- **Session summary**: when a session ends, a line in your chat sums it up: time, nodes, value and your best find.
- **Light pillar**: a beam of light over the herb, ore vein or creature to skin right in front of you, in three looks: Glow, Fireflies and Beam. Switch it on in Settings or with `/hop pillar`. It uses the game's soft targeting and puts the game's settings back when you switch it off.
- **Skinning counts too**: leather and hides in the counter, gold per hour, points, a badge and a new page in the field guide.
- **Time to train** knows the level you need: 150 from level 10, 225 from level 20, 300 from level 35. The gathering window reminds you a little before the limit.
- Each character has its own gathering session.
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
