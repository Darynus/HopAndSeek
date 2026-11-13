-- Befehle für /hop. Alles geht auch im Fenster, die Befehle sind Abkürzungen.
local ADDON, ns = ...
local L = ns.L
local SU = ns.Suche

local BEFEHLE = {
  { "", L.CMD_WINDOW },
  { "switch", L.CMD_SWITCH },
  { "on | off", L.CMD_ON },
  { "jump | double | mounted", L.CMD_MODE },
  { "reset", L.CMD_RESET },
  { "journal", L.CMD_JOURNAL },
  { "share", L.CMD_SHARE },
  { "pillar [glow | fireflies | beam]", L.CMD_PILLAR },
  { "news", L.CMD_NEWS },
  { "debug", L.CMD_DEBUG },
  { "help", L.CMD_HELP },
}
ns.BEFEHLE = BEFEHLE

local MODUS = { jump = "sprung", double = "doppel", mounted = "reiten" }
local MODUS_TEXT = { sprung = L.TRIGGER_JUMP, doppel = L.TRIGGER_DOUBLE, reiten = L.TRIGGER_MOUNTED }

local function zeile(text) DEFAULT_CHAT_FRAME:AddMessage("  " .. text) end

local function hilfe()
  ns.melde(L.COMMANDS)
  for _, b in ipairs(BEFEHLE) do zeile("/hop" .. (b[1] ~= "" and (" " .. b[1]) or "") .. "   " .. b[2]) end
end

-- Alle Suchen des Chars mit Zauber-ID und das Ergebnis der Selbstprüfung, für Fehlerberichte
local function debug()
  SU:Lesen()
  local p = ns.db.probe
  ns.melde(string.format("on %s, trigger %s, paused %s", tostring(ns.db.an), tostring(ns.db.ausloeser),
    tostring(SU:Pause("sprung") or "-")))
  local ids = {}
  for id in pairs(SU.liste) do table.insert(ids, id) end
  table.sort(ids, function(a, b) return SU.liste[a].nr < SU.liste[b].nr end)
  for _, id in ipairs(ids) do
    local e = SU.liste[id]
    zeile(string.format("%d. %s (%d)%s%s", e.nr, SU.Name(id), id, e.aktiv and " active" or "", ns.db.kreis[id] and " in cycle" or ""))
  end
  if #ids == 0 then zeile("no tracking types found") end
  -- Lichtsäule: was sie gerade sieht. Steht nach /reload auch in den gespeicherten Daten (diagnose).
  if ns.Lichtsaeule then
    local d = ns.Lichtsaeule.Diagnose()
    ns.db.diagnose = d
    zeile(string.format("pillar on %s, possible %s, target %s, kind %s", d.an, d.moeglich, d.ziel, d.art))
    zeile(string.format("dead %s, loot %s, looted %s, plate %s, skinning %s", d.tot, d.beute, d.gepluendert, d.plakette, d.kuerschnern))
    zeile("professions: " .. table.concat(d.berufe, "; "))
  end
  zeile(string.format("works %s, gcd %s, several %s, blocked %s, API %s", tostring(p.geht), tostring(p.gcd),
    tostring(p.mehrere), tostring(p.gesperrt), (ns.api("C_Minimap.SetTracking") and "C_Minimap")
    or (ns.api("SetTracking") and "SetTracking") or "none"))
end

SLASH_HOPANDSEEK1 = "/hop"
SLASH_HOPANDSEEK2 = "/hopseek"
SlashCmdList.HOPANDSEEK = function(eingabe)
  if not ns.db then return end
  local wort = string.lower(string.match(eingabe or "", "^%s*(%S*)") or "")
  if wort == "" or wort == "window" then
    ns.Fenster:Umschalten()
  elseif wort == "switch" then
    SU:Wechseln("klick")
  elseif wort == "on" or wort == "off" then
    if wort == "on" then ns.db.an = true elseif wort == "off" then ns.db.an = false end
    if ns.db.an then ns.db.probe.gesperrt = nil end
    ns.melde(ns.db.an and L.MSG_ON or L.MSG_OFF)
    ns.aktualisieren()
  elseif MODUS[wort] then
    ns.db.ausloeser = MODUS[wort]
    ns.melde(string.format(L.MSG_MODE, MODUS_TEXT[MODUS[wort]]))
    ns.aktualisieren()
  elseif wort == "reset" then
    ns.Sammeln:Neu()
    ns.melde(L.MSG_GATHER_RESET)
  elseif wort == "journal" then
    ns.Fenster:Zeigen("journal")
  elseif wort == "share" then
    ns.Teilen:Senden()
  elseif wort == "pillar" then
    local stil = ({ glow = "schein", fireflies = "funken", beam = "strahl" })[string.lower(string.match(eingabe or "", "^%s*%S+%s+(%S+)") or "")]
    if ns.Lichtsaeule and stil then
      ns.Lichtsaeule:StilSetzen(stil)
      if not ns.db.lichtsaeule then ns.Lichtsaeule:Schalten(true) end
      ns.aktualisieren()
    elseif ns.Lichtsaeule then
      ns.Lichtsaeule:Schalten(not ns.db.lichtsaeule)
    end
  elseif wort == "news" then
    ns.Neuigkeiten:Umschalten()
  elseif wort == "debug" then
    debug()
  elseif wort == "help" then
    hilfe()
  else
    ns.melde(L.MSG_UNKNOWN_COMMAND)
  end
end
