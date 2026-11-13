-- Sammelkarte: wo du schon Kräuter und Erz geholt hast (Vorschlag vom 13. Nov, Patrick: „klingt
-- gut“). Beim ersten Gegenstand eines Knotens merkt sich Hop & Seek die eigene Position (Karten-ID
-- und Lage auf der Karte). Stellen dicht beieinander werden zu einer zusammengefasst. Nur eigene
-- Funde, accountweit, nichts wird gesendet. Der Wegweiser (Wegweiser.lua) führt zur nächsten Stelle.
-- Nadeln auf der Weltkarte gibt es seit 1.2.1 nicht mehr (Patrick, 13. Nov: „eigentlich braucht man
-- das nicht auf der Map“, dafür gibt es Karten-Add-ons).
local ADDON, ns = ...

local K = {}
ns.SammelKarte = K

K.NAH = 0.006          -- so nah (Anteil der Kartenbreite) gilt eine Stelle als dieselbe
K.MAX_JE_KARTE = 600   -- höchstens so viele Stellen je Karte, die am längsten unbesuchte fällt weg

local function zeit() return (GetServerTime and GetServerTime()) or time() end
local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end

local function lage(karte)
  local ok, pos = pcall(C_Map.GetPlayerMapPosition, karte, "player")
  if not ok or type(pos) ~= "table" or not pos.GetXY then return nil end
  local x, y = pos:GetXY()
  if type(x) ~= "number" or type(y) ~= "number" or geheim(x) or geheim(y) or (x == 0 and y == 0) then return nil end
  return x, y
end

-- Wo steht der Spieler? Karten-ID, x, y, auf der Karte der Zone: In Höhlen und kleinen Orten mit
-- eigener Karte (Typ über 3) geht es eine Stufe höher, solange der Spieler dort zu sehen ist. So
-- stehen die Nadeln auf der Zonenkarte, die man beim Planen ansieht. nil in Instanzen.
function K.Position()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local ok, karte = pcall(C_Map.GetBestMapForUnit, "player")
  if not ok or type(karte) ~= "number" or geheim(karte) then return nil end
  local x, y = lage(karte)
  if not x then return nil end
  for _ = 1, 3 do
    local info = C_Map.GetMapInfo and C_Map.GetMapInfo(karte)
    if not (type(info) == "table" and (info.mapType or 0) > 3 and info.parentMapID and info.parentMapID > 0) then break end
    local px, py = lage(info.parentMapID)
    if not px then break end
    karte, x, y = info.parentMapID, px, py
  end
  return karte, x, y
end

local function runden(v) return math.floor(v * 10000 + 0.5) / 10000 end

-- Ein neuer Knoten: Stelle merken oder eine nahe Stelle derselben Art zählen
function K:Knoten(art)
  self.aktuell = nil
  local karte, x, y = K.Position()
  if not karte then return end
  local liste = ns.db.knotenKarte[karte]
  if not liste then
    liste = {}
    ns.db.knotenKarte[karte] = liste
  end
  local beste, abstand
  for _, e in ipairs(liste) do
    if e.art == art then
      local d = (e.x - x) * (e.x - x) + (e.y - y) * (e.y - y)
      if d <= K.NAH * K.NAH and (not abstand or d < abstand) then beste, abstand = e, d end
    end
  end
  if beste then
    beste.x = runden((beste.x * beste.n + x) / (beste.n + 1))
    beste.y = runden((beste.y * beste.n + y) / (beste.n + 1))
    beste.n = beste.n + 1
    beste.zuletzt = zeit()
  else
    beste = { x = runden(x), y = runden(y), art = art, n = 1, inhalt = {}, zuletzt = zeit() }
    table.insert(liste, beste)
    if #liste > K.MAX_JE_KARTE then
      local alt = 1
      for i, e in ipairs(liste) do
        if (e.zuletzt or 0) < (liste[alt].zuletzt or 0) then alt = i end
      end
      table.remove(liste, alt)
    end
  end
  self.aktuell = beste
end

-- Vom Sammelzähler: beim ersten Gegenstand die Stelle, dann zählt jeder Gegenstand für sie
function K:Beute(id, menge, _, knotenArt)
  if knotenArt == "kraut" or knotenArt == "erz" then
    self:Knoten(knotenArt)
  elseif knotenArt then
    self.aktuell = nil
  end
  local e = self.aktuell
  if e then e.inhalt[id] = (e.inhalt[id] or 0) + (menge or 1) end
end

-- Stellen insgesamt (für die Zahl am Schalter)
function K.Anzahl()
  local n = 0
  for _, liste in pairs(ns.db.knotenKarte or {}) do n = n + #liste end
  return n
end

-- Häufigster Fund einer Stelle, Kräuter und Erz vor Beifang (Steine, Edelsteine)
local function haupt(e)
  local beste, menge
  for id, n in pairs(e.inhalt or {}) do
    local art = ns.Sammeln.Art(id)
    local wert = n + (art == e.art and 1000000 or 0)
    if not menge or wert > menge or (wert == menge and id < beste) then beste, menge = id, wert end
  end
  return beste
end
K.Haupt = haupt

ns.beimSammeln(function(id, menge, q, knotenArt) K:Beute(id, menge, q, knotenArt) end)
ns.Ereignis("LOOT_CLOSED", function() K.aktuell = nil end)
