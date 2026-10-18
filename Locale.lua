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
L.CMD_HELP = "show this list"
L.MSG_ON = "Hop & Seek is on."
L.MSG_OFF = "Hop & Seek is off."
L.MSG_MODE = "Switch on: %s."
L.MSG_UNKNOWN_COMMAND = "Unknown command. Type /hop help."

-- Minikarte und Optionen
L.MINIMAP_TOOLTIP = "Left-click: open window\nRight-click: switch once\nDrag: move button"
L.OPTIONS_PAGE_TEXT = "Jump to switch your minimap tracking between herbs and ore. All settings are in the Hop & Seek window."
L.OPEN_WINDOW = "Open Hop & Seek"
