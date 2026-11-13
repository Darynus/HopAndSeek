<p align="center"><img src="images/logo.png" width="160" alt="Hop & Seek logo"></p>

<h1 align="center">Hop & Seek</h1>

<p align="center"><b>Jump to switch your minimap tracking between Find Herbs and Find Minerals.</b><br>
One switch per jump, nothing happens on its own.</p>

<p align="center">
<a href="https://www.curseforge.com/wow/addons/hop-seek-forever">CurseForge</a> ·
<a href="CHANGELOG.md">Changelog</a> ·
<a href="https://github.com/Darynus/HopAndSeek/issues">Report a bug</a>
</p>

> **Made for WoW Forever** (client 1.60.1). Have fun hopping, and tell me how it hops for you!

You love hopping through Azeroth and grabbing every herb and every ore vein on the way? Then Hop & Seek is your new best friend. Every gatherer knows the struggle: one tracking at a time. Most of us glued a cast sequence macro to some key and pressed it until the finger hurt. Hop & Seek throws that macro out of the window: just jump. Every hop switches your minimap tracking. Be honest, you were jumping anyway.

![How it works](images/hopandseek-1-ablauf.png)

## How it works

- **Jump to switch:** one press of the jump key, one switch. Nothing happens on its own: no timer, no macro, no spell button.
- **No "not ready yet" spam:** switching has a short cooldown in the game. Hop & Seek waits 1, 2 or 3 seconds between switches and never tries while the cooldown runs.
- **Pick your hop:** every jump, double jump (tap jump twice quickly) or only while mounted or in travel form.
- **Your cycle:** Find Herbs and Find Minerals by default. Dwarves can add Find Treasure, hunters their tracks, druids, paladins and warlocks their senses. Hop & Seek only uses what your character knows.
- **Only one gathering profession?** Then Hop & Seek keeps that tracking on. The game switches it off after logging in or dying, your next jump turns it back on, and a line in your chat reminds you.

![Always know what you track](images/hopandseek-2-symbol.png)

## Count what you gather

- **Gathering counter**: herbs, ore, stone and gems you loot from nodes, and the leather and hides you skin, per session and all time, with the number of nodes and an amount per hour. The new Gathered tab lists every item.
- **Gold per hour**: a small gathering window shows your gold per hour, how much you gathered and your best finds while you are out gathering.
- **What it is worth**: with Auctionator installed, Hop & Seek shows the value of your haul, in total and per hour. Midas works too, pick it in the Gathered tab.
- **Light pillar**: a beam of light over the herb, ore vein or creature to skin right in front of you, in three looks: a soft Glow, rising Fireflies or a clear Beam. Switch it on in Settings.
- **Gathering spots on your world map**: every node you gather becomes a small pin with the icon of what grew there. After a few rounds you see the good routes. Works with OpenMap too.
- **Time to train**: a reminder when Herbalism, Mining or Skinning needs a trainer, and the level you need for the next rank.
- The count of this session sits under the tracking icon, the details are in its tooltip. A new session starts after 30 minutes without gathering, or with Start over, and a line in your chat sums up the last one.

## Make gathering a game

The Journal tab turns every trip into a little adventure:

- **Seeker points and ranks**: every node earns points, new kinds and uncommon finds earn more. Climb from Wanderer to Legend of the Wilds.
- **Daily goal and streak**: pick 10, 25, 50 or 100 nodes a day and keep your streak going.
- **Records**: gold per hour, nodes in one session, your best haul and your longest session. Beat them and Hop & Seek lets you know.
- **22 badges**, from First Find to Lotus Luck.
- **Field guide**: every herb, ore, stone and gem you can gather in Forever, including the new ones like Rosecap, Bauxite and Torbernite. Fill it up!
- **Compare with friends**: share your journal with your group with one click and see their ranks and records next to yours.
- A small pop-up with a game sound tells you when you earn something. Prefer it quiet? Switch pop-ups off and get a chat line instead.

## Knows when to stop

No switching in combat, while swimming (the jump key means swim up there), while flying, in dungeons and raids or while you cast. Cities and inns too, if you like.

![Knows when to stop](images/hopandseek-4-pausen.png)

## Checks itself

Hop & Seek checks once whether switching works in your game and how long the cooldown is, and shows it in the Status tab.

![Checks itself](images/hopandseek-3-status.png)

![Make it yours](images/hopandseek-5-optionen.png)

## Install

- **CurseForge app**: search for *Hop & Seek* under World of Warcraft, Forever.
- **By hand**: download the zip from CurseForge and put the `HopAndSeek` folder into `World of Warcraft\_forever_\Interface\AddOns`. Restart the game.

## Commands

| Command | What it does |
|---|---|
| `/hop` | open or close the window |
| `/hop switch` | switch once |
| `/hop on` / `/hop off` | switch Hop & Seek on or off |
| `/hop jump` | switch on every jump |
| `/hop double` | switch on a double jump |
| `/hop mounted` | switch on every jump while mounted |
| `/hop reset` | start a new gathering session |
| `/hop journal` | open the journal: rank, daily goal, records, badges, field guide |
| `/hop share` | share your journal with your group |
| `/hop pillar` | switch the light pillar on or off |
| `/hop news` | show what is new |
| `/hop debug` | show your tracking types and the self-check |
| `/hop help` | list all commands |

## Safe and fair

- **One jump, at most one switch.** No timers, nothing happens without your key press.
- **Only the minimap tracking.** No spells, no macros, no targeting. The gathering counter only reads your loot window.
- **Every game language:** tracking types are recognized by their spell IDs, never by names.
- Free, no ads, MIT license.

## Feedback

Made by a gamer, for gamers. Hop & Seek is free and always will be. Ideas and bug reports are welcome on [GitHub](https://github.com/Darynus/HopAndSeek/issues) or in the CurseForge comments. Happy hopping!
