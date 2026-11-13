-- Journal teilen: Punkte, Serie und Rekorde per Klick an die eigene Gruppe, damit Patrick und sein
-- Kumpel sich vergleichen können (Vorschlag vom 13. Nov). Im Journal steht dann der Stand der
-- anderen neben dem eigenen. Regeln für Add-on-Nachrichten: nur auf Knopfdruck, nie im Bosskampf,
-- höchstens alle 10 Sekunden, nur an Gruppe oder Schlachtzug. Beim Empfang wird streng geprüft,
-- es antwortet nichts von selbst.
local ADDON, ns = ...
local L = ns.L

local T = { vonWem = {} }
ns.Teilen = T

T.PRAEFIX = "HopAndSeek"
T.ABSTAND = 10
T.MAX_FREUNDE = 10

local function zeit() return (GetServerTime and GetServerTime()) or time() end
local function bossKampf() return IsEncounterInProgress and IsEncounterInProgress() end

-- Geht es gerade? Sonst der Grund als Text
function T.Grund()
  if not (IsInGroup and IsInGroup()) then return L.SHARE_NO_GROUP end
  if bossKampf() then return L.SHARE_BOSS end
  if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return L.SHARE_FAILED end
end

-- Ein Klick: eine Nachricht. "J1;Punkte;Serie;beste Serie;Arten;Abzeichen;Gold pro Stunde;Knoten"
function T:Senden()
  local grund = T.Grund()
  if grund then return ns.melde(grund) end
  local jetzt = ns.jetzt()
  if jetzt - (self.zuletzt or -100) < T.ABSTAND then return ns.melde(L.SHARE_WAIT) end
  local E, d = ns.Erfolge, ns.db.erfolge
  local st = E:Stand()
  local r = d.rekord
  local text = string.format("J1;%d;%d;%d;%d;%d;%d;%d", math.floor(d.punkte), st.serie, d.serieBest, E.Arten(),
    st.abzeichen, math.floor(r.gold and r.gold.wert or 0), math.floor(r.knoten and r.knoten.wert or 0))
  local kanal = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
  self.zuletzt = jetzt
  local ok, ergebnis = pcall(C_ChatInfo.SendAddonMessage, T.PRAEFIX, text, kanal)
  -- Retail meldet einen Zahlencode zurück: 0 heißt gesendet
  if ok and (ergebnis == nil or ergebnis == true or ergebnis == 0) then
    ns.melde(L.SHARE_SENT)
  else
    ns.melde(L.SHARE_FAILED)
  end
end

-- Nachricht aus der Gruppe: streng prüfen, dann merken
local function empfangen(praefix, text, kanal, absender)
  if praefix ~= T.PRAEFIX or (kanal ~= "PARTY" and kanal ~= "RAID") then return end
  if type(text) ~= "string" or #text > 120 or type(absender) ~= "string" then return end
  local kurz = string.match(absender, "^([^%-]+)") or absender
  if UnitName and kurz == UnitName("player") then return end
  local jetzt = ns.jetzt()
  if jetzt - (T.vonWem[absender] or -100) < T.ABSTAND then return end
  local w = { string.match(text, "^J1;(%d+);(%d+);(%d+);(%d+);(%d+);(%d+);(%d+)$") }
  if #w ~= 7 then return end
  for i, v in ipairs(w) do w[i] = tonumber(v) end
  -- Unsinnige Werte verwerfen
  if not (w[1] < 1e8 and w[2] < 10000 and w[3] < 10000 and w[4] < 1000 and w[5] <= #ns.Erfolge.ABZEICHEN
    and w[6] < 1e10 and w[7] < 100000) then return end
  T.vonWem[absender] = jetzt
  local f = ns.db.freunde
  f[kurz] = { punkte = w[1], serie = w[2], serieBest = w[3], arten = w[4], abzeichen = w[5], gold = w[6], knoten = w[7],
    zeit = zeit() }
  -- Nur die zuletzt gesehenen behalten
  local namen = {}
  for name in pairs(f) do table.insert(namen, name) end
  if #namen > T.MAX_FREUNDE then
    table.sort(namen, function(a, b) return (f[a].zeit or 0) > (f[b].zeit or 0) end)
    for i = T.MAX_FREUNDE + 1, #namen do f[namen[i]] = nil end
  end
  ns.melde(string.format(L.SHARE_RECEIVED, kurz))
  ns.aktualisieren()
end

-- Die anderen, zuletzt geteilte zuerst: { name, punkte, rang, rangName, serie, ... }
function T.Freunde()
  local liste = {}
  for name, d in pairs(ns.db.freunde or {}) do
    local nr, rname = ns.Erfolge.Rang(d.punkte)
    table.insert(liste, { name = name, rang = nr, rangName = rname, punkte = d.punkte, serie = d.serie,
      serieBest = d.serieBest, arten = d.arten, abzeichen = d.abzeichen, gold = d.gold, knoten = d.knoten, zeit = d.zeit })
  end
  table.sort(liste, function(a, b) return (a.zeit or 0) > (b.zeit or 0) end)
  return liste
end

if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, T.PRAEFIX) end
ns.Ereignis("CHAT_MSG_ADDON", empfangen)
