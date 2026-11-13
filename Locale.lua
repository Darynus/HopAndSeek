-- Texte. Die Oberfläche ist in jedem Client Englisch (Entscheidung Patrick, 13. Okt).
-- Die Logik hängt nie an Texten: Suchen werden über ihre Zauber-ID erkannt.
-- Fehlt ein Schlüssel, erscheint sein Name und er landet in ns.fehlendeTexte (prüft der Rauchtest).
local ADDON, ns = ...

ns.fehlendeTexte = {}
local L = setmetatable({}, { __index = function(_, schluessel)
  ns.fehlendeTexte[schluessel] = true
  return schluessel
end })
ns.L = L

-- Allgemein
L.ADDON_NAME = "Hop & Seek"
L.TITLE_PART1 = "Hop"
L.TITLE_PART2 = "& Seek"
L.SUBTITLE = "Jump to switch between herbs and ore"
L.BY_AUTHOR = "by Darynus"
L.ERR_EVENT = "Error in %s: %s"
L.YES = "yes"
L.NO = "no"
L.UNKNOWN = "not tested yet"

-- Namen der Suchen, falls das Spiel keinen nennt (sonst gilt der Name aus dem Spiel)
L.TRACK_HERBS = "Find Herbs"
L.TRACK_MINERALS = "Find Minerals"
L.TRACK_TREASURE = "Find Treasure"
L.TRACK_OTHER = "Tracking %d"

-- Reiter
L.TAB_STATUS = "Status"
L.TAB_GATHERED = "Gathered"
L.TAB_JOURNAL = "Journal"
L.TAB_SETTINGS = "Settings"
L.TAB_HELP = "Help"

-- Status
L.STATUS_NOW = "Tracking now"
L.STATUS_NONE = "No tracking active"
L.STATUS_CYCLE = "Your cycle"
L.STATUS_CYCLE_EMPTY = "Your character knows none of the tracking types in your cycle. Learn Herbalism or Mining, or pick other types in Settings."
L.STATUS_KEEP = "Only %s is known, so Hop & Seek keeps it on. When it goes off (after logging in or dying), your next jump turns it back on."
L.STATUS_KEEP_OFF = "%s is off: jump once to turn it on."
L.STATUS_NEXT = "Next jump: %s"
L.STATUS_DOUBLE = "Next double jump: %s"
L.STATUS_MOUNTED = "Next jump while mounted: %s"
L.STATUS_PAUSED = "Paused: %s"
L.STATUS_READY = "Ready. Jump to switch."
L.STATUS_CHECK = "Self-check"
L.STATUS_WORKS = "Switching works: %s"
L.STATUS_GCD = "Switching starts a global cooldown: %s"
L.STATUS_COOLDOWN = "Cooldown after a switch: %.1f sec, Hop & Seek waits %d sec"
L.STATUS_GCD_TIP = "Switching costs a global cooldown in this game. Double jump is a good choice, so a normal jump never blocks your next spell."
L.STATUS_BOTH = "Your game can track several types at once. Hop & Seek switched them all on, no need to jump."
L.STATUS_BLOCKED = "The game blocked switching from an add-on (%s). Hop & Seek stays off. Please tell us in the comments."
L.BTN_SWITCH = "Switch now"
L.BTN_TURN_ON = "Turn on"
L.BTN_SWITCH_HELP = "Switches to the next tracking type in your cycle. One click, one switch."

-- Gründe für die Pause
L.PAUSE_COMBAT = "in combat"
L.PAUSE_SWIM = "swimming"
L.PAUSE_FLY = "flying"
L.PAUSE_INSTANCE = "in a dungeon or raid"
L.PAUSE_REST = "in a city or inn"
L.PAUSE_CAST = "casting"
L.PAUSE_DEAD = "dead"
L.PAUSE_TAXI = "on a flight path"
L.PAUSE_OFF = "switched off"
L.PAUSE_BLOCKED = "blocked by the game"
L.PAUSE_NOT_MOUNTED = "not mounted"

-- Einstellungen
L.SET_ON = "Switch tracking when I jump"
L.SET_ON_HELP = "The main switch. Off: jumping is just jumping."
L.SET_TRIGGER = "Switch on"
L.TRIGGER_JUMP = "Every jump"
L.TRIGGER_JUMP_HELP = "Every press of the jump key switches once."
L.TRIGGER_DOUBLE = "Double jump"
L.TRIGGER_DOUBLE_HELP = "Press the jump key twice quickly. A single jump stays a normal jump."
L.TRIGGER_MOUNTED = "Mounted"
L.TRIGGER_MOUNTED_HELP = "Every jump, but only while mounted or in travel form."
L.SET_WAIT = "Wait between switches"
L.WAIT_1 = "1 sec"
L.WAIT_2 = "2 sec"
L.WAIT_3 = "3 sec"
L.WAIT_HELP = "Switching has a short cooldown in the game. Hop & Seek waits at least this long and never switches while a cooldown runs, so you do not see \"not ready yet\"."
L.SET_CYCLE = "Tracking types in the cycle"
L.SET_CYCLE_HELP = "Hop & Seek only uses the ones your character knows."
L.SET_PAUSE_REST = "Pause in cities and inns"
L.SET_PAUSE_REST_HELP = "No switching where you rest. Herbs and ore do not grow there."
L.SET_SOUND = "Soft sound on switch"
L.SET_SOUND_HELP = "A quiet click when the tracking changes."
L.SET_ICON = "Show the tracking icon"
L.SET_ICON_HELP = "Small icon of the active tracking. Drag it to move it, click it to switch."
L.SET_LOCK = "Lock the icon"
L.SET_LOCK_HELP = "The icon stays where it is."
L.SET_CHAT = "Tell me in chat when it switches"
L.SET_CHAT_HELP = "One short line per switch."
L.SET_MINIMAP = "Show minimap button"
L.SET_MINIMAP_HELP = "Left-click opens Hop & Seek, right-click switches once."

-- Sammelzähler
L.GATHER_SESSION = "This Session"
L.GATHER_TOTAL = "All Time"
L.GATHER_SINCE = "since %s"
L.GATHER_NONE = "Nothing gathered yet. Herbs, ore, stone and gems from nodes count here."
L.GATHER_HERB_ONE = "1 herb"
L.GATHER_HERBS = "%d herbs"
L.GATHER_ORE_ONE = "1 ore, stone or gem"
L.GATHER_ORE = "%d ore, stone and gems"
L.GATHER_FROM = "%s from %s"
L.GATHER_NODE_ONE = "1 node"
L.GATHER_NODES = "%d nodes"
L.GATHER_NOTHING = "nothing yet"
L.GATHER_BAR_TITLE = "Gathering"
L.GATHER_BAR_HELP = "This gathering session. Drag to move, right-click opens the Gathered tab."
L.GATHER_BAR_CLOSE = "Hide"
L.GATHER_BAR_CLOSE_HELP = "Hides this window until your next gathering session."
L.GATHER_BAR_GOLD_RATE = "%s per hour"
L.GATHER_BAR_WORTH = "Worth %s so far"
L.GATHER_BAR_NO_VALUE = "No prices yet, scan the auction house"
L.GATHER_BAR_NO_PRICES = "Gold per hour: install Auctionator or Midas"
L.GATHER_BAR_MEASURING = "per hour after 5 min"
L.GATHER_BAR_HOURS = "%d:%02d h"
L.GATHER_BAR_MINUTES = "%d min"
L.SET_GATHER_BAR = "Show the gathering window"
L.SET_GATHER_BAR_HELP = "A small window with gold per hour and your best finds while you gather. It hides when the session ends."
L.GATHER_RATE = "%.0f per hour"
L.GATHER_WORTH = "worth %s"
L.GATHER_WORTH_RATE = "(%s per hour)"
L.GATHER_HELP = "Counts what you gather from herb and ore nodes, by item, the same in every game language."
L.GATHER_NO_PRICES = "Install Auctionator or Midas and scan the auction house once to see what it is worth."
L.BTN_GATHER_RESET = "Start over"
L.BTN_GATHER_RESET_HELP = "Starts a new session. Your all time numbers stay. A new session also starts by itself after 30 minutes without gathering."
L.SET_GATHER = "Count what I gather"
L.SET_GATHER_HELP = "Counts herbs, ore, stone and gems you loot from nodes. Only reads your loot window, nothing else."
L.SET_GATHER_ICON = "Show the count under the tracking icon"
L.SET_GATHER_ICON_HELP = "A small number with everything you gathered this session."
L.GOLD_SUFFIX = "g"
L.SILVER_SUFFIX = "s"
L.COPPER_SUFFIX = "c"

-- Journal: Rang, Tagesziel, Rekorde, Abzeichen, Sammelbuch (Erfolge.lua, Meldung.lua)
L.RANKS = { "Wanderer", "Forager", "Seeker", "Pathfinder", "Prospector", "Wildwalker", "Trailblazer",
  "Master Seeker", "Grand Seeker", "Legend of the Wilds" }
L.RANK_MORE = "%s %d"
L.RANK_TITLE = "Rank %d: %s"
L.RANK_TO_NEXT = "%s points to %s"
L.JOURNAL_POINTS_TEXT = "%s points"
L.JOURNAL_POINTS = "Seeker points"
L.JOURNAL_POINTS_HELP = "Every node gives 10 points, a new kind for your field guide 50, an uncommon find 15 and your daily goal 100. Your points make your rank. All characters of your account count together."
L.JOURNAL_TODAY = "Today"
L.TODAY_NODES = "%d of %d nodes today"
L.STREAK_ONE = "Streak: 1 day"
L.STREAK_DAYS = "Streak: %d days"
L.STREAK_NONE = "Reach your goal to start a streak"
L.STREAK_BEST = "%s (best %d)"
L.JOURNAL_GOAL = "Goal"
L.JOURNAL_GOAL_HELP = "Your daily goal in nodes, for all your characters together. Reach it on days in a row to build a streak."
L.JOURNAL_RECORDS = "Records"
L.RECORDS = { gold = "Gold per hour", knoten = "Nodes in one session", wert = "Best haul", dauer = "Longest session" }
L.RECORD_NONE = "none yet"
L.RECORD_NEEDS_PRICES = "needs AH prices"
L.JOURNAL_BADGES = "Badges"
L.JOURNAL_BADGES_COUNT = "Badges %d/%d"
L.JOURNAL_BADGES_HELP = "Milestones for gathering. Hover a badge to see what it takes."
L.JOURNAL_BOOK = "Field guide"
L.JOURNAL_BOOK_COUNT = "Field guide %d/%d"
L.JOURNAL_BOOK_HELP = "Every herb, ore, stone and gem you can gather in Forever. Grey ones are still out there."
L.JOURNAL_MINUTES_OF = "%d / %d min"
L.BOOK_GROUPS = { kraut = "Herbs", erz = "Ore and stone", edel = "Gems and more" }
L.BOOK_GROUP = "%s  %d/%d"
L.BOOK_FOUND = "Gathered %s, first found %s"
L.BOOK_MISSING = "Not found yet"
L.BADGE_EARNED = "Earned %s"
L.BADGE_NEEDS_PRICES = "Needs Auctionator or Midas for prices."
L.SET_POPUPS = "Pop-ups"
L.SET_POPUPS_HELP = "A small pop-up at the top of the screen for new badges, ranks, records, finds and your daily goal. Off: a line in the chat instead."
L.SET_POPUP_SOUND = "Sound"
L.SET_POPUP_SOUND_HELP = "Plays a short game sound with each pop-up."
L.TOAST_HELP = "Left-click opens the journal, right-click closes this."
L.TOAST_BADGE = "Badge earned"
L.TOAST_RANK = "New rank"
L.TOAST_RANK_NEXT = "Next: %s at %s points"
L.TOAST_RECORD = "New record"
L.TOAST_RECORD_OLD = "Old best: %s"
L.RECORD_NODES_TEXT = "%d nodes in one session"
L.RECORD_HAUL_TEXT = "A haul worth %s"
L.TOAST_DAILY = "Daily goal reached"
L.TOAST_FIND = "New find"
L.TOAST_FINDS = "%d new finds"
L.TOAST_FIND_SUB = "Field guide %d/%d"
L.BAR_RANK = "%s  %s/%s"
L.BAR_TODAY = "Today %d/%d"
L.SESSION_SUMMARY = "Session over: %s."
L.SESSION_BEST = "Best find: %s."
L.SET_GATHER_MAP = "Show gathering spots on the world map"
L.SET_GATHER_MAP_HELP = "Every herb and ore node you gather becomes a small pin on your world map, also on OpenMap. Spots close together count as one. Right-click a pin to remove it."
L.GATHER_MAP_COUNT = "%d spots"
L.MAP_TOGGLE = "Gathering spots (Hop & Seek)"
L.MAP_NODE_HERB = "Herb"
L.MAP_NODE_ORE = "Ore"
L.MAP_NODE_ONCE = "Gathered once, on %s"
L.MAP_NODE_TIMES = "Gathered %d times, last on %s"
L.MAP_NODE_REMOVE = "Right-click: remove this spot"
L.SKILL_HERBALISM = "Herbalism"
L.SKILL_MINING = "Mining"
L.SKILL_LEVEL = "%s %d/%d"
L.SKILL_CAPPED_TITLE = "Time to train"
L.SKILL_CAPPED_HELP = "You reached the limit. Visit a trainer to keep learning."
L.SKILL_CAPPED_SHORT = "%s %d/%d: visit a trainer"
L.SHARE_BUTTON = "Share"
L.SHARE_BUTTON_HELP = "Sends your rank, streak and records to your group, once per click. Group members with Hop & Seek see them in their journal."
L.SHARE_NO_GROUP = "Join a group to share your journal."
L.SHARE_BOSS = "Not during a boss fight."
L.SHARE_WAIT = "Please wait a few seconds before sharing again."
L.SHARE_SENT = "Journal shared with your group."
L.SHARE_FAILED = "Could not share right now."
L.SHARE_RECEIVED = "%s shared their journal. Have a look at the Journal tab."
L.FRIENDS_TITLE = "Friends"
L.FRIENDS_NONE = "Share your journal with your group to compare with your friends."
L.FRIEND_LINE = "%s: %s, %s points"
L.FRIEND_POINTS = "%s points, streak %d (best %d)"
L.FRIEND_KINDS = "%d kinds in the field guide, %d badges"
L.FRIEND_GOLD = "Best gold per hour: %s"
L.FRIEND_NODES = "Most nodes in one session: %d"
L.FRIEND_SHARED = "Shared %s"
L.BADGES = {
  knoten1 = { "First Find", "Gather your first herb or ore node." },
  knoten100 = { "Hundred Hops", "Gather 100 nodes." },
  knoten500 = { "Seasoned Seeker", "Gather 500 nodes." },
  knoten1000 = { "Thousand Hops", "Gather 1,000 nodes." },
  knoten5000 = { "Nothing Escapes You", "Gather 5,000 nodes." },
  kraut250 = { "Green Thumb", "Gather 250 herb nodes." },
  erz250 = { "Rock Solid", "Gather 250 ore nodes." },
  selten1 = { "Shiny!", "Find something uncommon in a node, like a gem or silver ore." },
  selten50 = { "Treasure Hunter", "Find 50 uncommon or better items in nodes." },
  arten10 = { "Collector", "Find 10 different kinds for your field guide." },
  arten25 = { "Naturalist", "Find 25 different kinds for your field guide." },
  arten50 = { "Walking Encyclopedia", "Find 50 different kinds for your field guide." },
  lotus = { "Lotus Luck", "Find a Black Lotus." },
  sitzung50 = { "On a Roll", "Gather 50 nodes in one session." },
  sitzung100 = { "Unstoppable", "Gather 100 nodes in one session." },
  stunde = { "Long Haul", "Keep one gathering session going for an hour." },
  gold1 = { "Pocket Money", "Reach 1 gold per hour in a session of 15 minutes or more." },
  gold10 = { "Gold Rush", "Reach 10 gold per hour in a session of 15 minutes or more." },
  gold25 = { "Tycoon", "Reach 25 gold per hour in a session of 15 minutes or more." },
  tag1 = { "Daily Dose", "Reach your daily goal." },
  serie7 = { "Seven in a Row", "Reach your daily goal 7 days in a row." },
  serie30 = { "Creature of Habit", "Reach your daily goal 30 days in a row." },
}
L.MSG_GATHER_RESET = "New gathering session started."

-- Anzeige
L.ICON_TOOLTIP_CYCLE = "Cycle:"
L.ICON_TOOLTIP_HELP = "Click: switch now\nRight-click: open Hop & Seek\nDrag: move"

-- Meldungen
L.MSG_SWITCHED = "Tracking: %s"
L.MSG_BOTH = "Your game tracks several types at once. All tracking types in your cycle are on now."
L.MSG_BLOCKED = "The game blocked switching from an add-on. Hop & Seek is off for now."
L.MSG_NOTHING = "Nothing to track: your character knows none of the tracking types in your cycle."
L.MSG_KEPT_ON = "%s is on again."
L.MSG_ALREADY_ON = "%s is already on."
L.MSG_REMIND = "%s is off. Jump once and Hop & Seek turns it back on."
L.ICON_KEPT_ON = "Kept on by Hop & Seek"

-- Hilfe
L.HELP_TITLE = "How it works"
L.HELP_TEXT = "Hop & Seek switches your minimap tracking when you jump: Find Herbs, then Find Minerals, then Find Herbs again. Each press of the jump key switches once, nothing happens on its own.\n\nOnly one gathering profession? Then Hop & Seek keeps that tracking on: when it goes off after logging in or dying, your next jump turns it back on.\n\nIt pauses in combat, while swimming or flying, in dungeons and raids, while casting and, if you like, in cities and inns.\n\nIf a switch costs a global cooldown in your game, pick Double jump in Settings: then a normal jump stays a normal jump."
L.HELP_COMMANDS = "Commands"

-- Befehle
L.COMMANDS = "Commands:"
L.CMD_WINDOW = "open or close the window"
L.CMD_SWITCH = "switch once"
L.CMD_ON = "switch Hop & Seek on or off"
L.CMD_MODE = "jump, double or mounted"
L.CMD_DEBUG = "show the tracking types and the self-check"
L.CMD_RESET = "start a new gathering session"
L.CMD_JOURNAL = "open the journal: rank, daily goal, records, badges, field guide"
L.CMD_SHARE = "share your journal with your group"
L.CMD_NEWS = "show what is new in this version"
L.CMD_HELP = "show this list"
L.MSG_ON = "Hop & Seek is on."
L.MSG_OFF = "Hop & Seek is off."
L.MSG_MODE = "Switch on: %s."
L.MSG_UNKNOWN_COMMAND = "Unknown command. Type /hop help."

-- Minikarte und Optionen
L.MINIMAP_TOOLTIP = "Left-click: open window\nRight-click: switch once\nDrag: move button"
L.OPTIONS_PAGE_TEXT = "Jump to switch your minimap tracking between herbs and ore. All settings are in the Hop & Seek window."
L.OPEN_WINDOW = "Open Hop & Seek"

-- Neuigkeiten nach einem Update (Neuigkeiten.lua), neueste Version zuerst
L.NEWS_TITLE = "What's new in %s"
L.NEWS_VERSION = "Version %s"
L.NEWS_AGAIN = "Show this after updates"
L.NEWS_AGAIN_HELP = "A short window once after Hop & Seek was updated. /hop news shows it again."
L.NEWS_OK = "Got it"
L.NEWS = {
  { version = "1.2.0", zeilen = {
    "Gathering counter: herbs, ore, stone and gems you loot from nodes, per session and all time, with nodes and an amount per hour. See the new Gathered tab.",
    "A small gathering window shows your gold per hour and your best finds while you gather. With Auctionator, Hop & Seek knows what your haul is worth.",
    "New Journal tab: every node earns points for your rank, set a daily goal and keep your streak, beat your records, earn badges and fill your field guide with every herb, ore and gem of Forever.",
    "Gathering spots on your world map: every node you gather becomes a small pin, also on OpenMap.",
    "Share your journal with your group and compare ranks and records with your friends.",
    "Hop & Seek tells you when Herbalism or Mining needs a trainer and sums up each gathering session in your chat.",
    "Prices also come from Midas when Auctionator is not installed.",
    "The count of this session sits under the tracking icon, the details are in its tooltip.",
    "Works with square minimaps, and minimap button collectors pick up the button.",
  } },
}
