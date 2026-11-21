-- Sammelkarte: wo du schon Kräuter und Erz geholt hast (Vorschlag vom 13. Nov, Patrick: „klingt
-- gut“). Beim ersten Gegenstand eines Knotens merkt sich Hop & Seek die eigene Position (Karten-ID
-- und Lage auf der Karte). Stellen dicht beieinander werden zu einer zusammengefasst. Nur eigene
-- Funde, accountweit, nichts wird gesendet. Das Radar (Radar.lua) zeigt die Stellen in seiner
-- Reichweite mit Entfernung und Zeit bis dorthin.
-- Nadeln auf der Weltkarte gibt es seit 1.2.1 nicht mehr (Patrick, 13. Nov: „eigentlich braucht man
-- das nicht auf der Map“, dafür gibt es Karten-Add-ons). Den Wegweiser „Next spot“ gibt es seit 1.3.0
-- nicht mehr (Patrick, 20. Nov: „bringt keinen Mehrwert“).
local ADDON, ns = ...

local K = {}
ns.SammelKarte = K

K.NAH = 0.006          -- so nah (Anteil der Kartenbreite) gilt eine Stelle als dieselbe
K.MAX_JE_KARTE = 600   -- höchstens so viele Stellen je Karte, die am längsten unbesuchte fällt weg
K.NACHWACHSEN = 10 * 60 -- Sekunden: hier frisch gesammelt, wächst wohl noch nach

local function zeit() return (GetServerTime and GetServerTime()) or time() end
local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end
local function zahl(v) return type(v) == "number" and not geheim(v) end

-- Größe einer Karte in Metern (Breite, Höhe), einmal gefragt. Erst C_Map.GetMapWorldSize, sonst über
-- die Weltlage zweier Ecken der Karte (C_Map.GetWorldPosFromMapPos, so rechnet es auch Blackthornes
-- Farmer). Nennt Forever keins von beiden: nil.
local function ecke(karte, u, v)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local ok, _, pos = pcall(C_Map.GetWorldPosFromMapPos, karte, CreateVector2D(u, v))
  if not ok or type(pos) ~= "table" or not pos.GetXY then return nil end
  local ok2, wx, wy = pcall(pos.GetXY, pos)
  if ok2 and zahl(wx) and zahl(wy) then return wx, wy end
end

local groessen = {}
function K.Groesse(karte)
  local g = groessen[karte]
  if g ~= nil then return g or nil end
  g = false
  if C_Map and C_Map.GetMapWorldSize then
    local ok, b, h = pcall(C_Map.GetMapWorldSize, karte)
    if ok and zahl(b) and zahl(h) and b > 0 and h > 0 then g = { b, h } end
  end
  if not g then
    -- Quer über die Karte geht es entlang der y-Achse der Welt, hinunter entlang der x-Achse
    local ax, ay = ecke(karte, 0, 0)
    local bx, by = ecke(karte, 1, 1)
    if ax and bx and math.abs(ay - by) > 0 and math.abs(ax - bx) > 0 then g = { math.abs(ay - by), math.abs(ax - bx) } end
  end
  groessen[karte] = g
  return g or nil
end

-- Welche Stellen zählen für diesen Char? Die, deren Beruf er hat. Weiß Hop & Seek nichts über seine
-- Berufe, alle.
function K.Arten()
  local t = {}
  if ns.Berufe then
    t.kraut = ns.Berufe.Hat("kraut") or nil
    t.erz = ns.Berufe.Hat("erz") or nil
  end
  if not (t.kraut or t.erz) then t.kraut, t.erz = true, true end
  return t
end

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

-- Höchstens MAX_JE_KARTE Stellen je Karte: die am längsten unbesuchte fällt weg
local function kuerzen(liste)
  if #liste <= K.MAX_JE_KARTE then return end
  local alt = 1
  for i, e in ipairs(liste) do
    if (e.zuletzt or 0) < (liste[alt].zuletzt or 0) then alt = i end
  end
  table.remove(liste, alt)
end

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
    -- Eine Stelle, die bisher nur das Radar kannte (n = 0), rückt dabei ganz an den Ort des Sammelns
    beste.x = runden((beste.x * beste.n + x) / (beste.n + 1))
    beste.y = runden((beste.y * beste.n + y) / (beste.n + 1))
    beste.n = beste.n + 1
    beste.zuletzt = zeit()
  else
    beste = { x = runden(x), y = runden(y), art = art, n = 1, inhalt = {}, zuletzt = zeit() }
    table.insert(liste, beste)
    kuerzen(liste)
  end
  self.aktuell = beste
end

-- Vom Sammelzähler: beim ersten Gegenstand die Stelle, dann zählt jeder Gegenstand für sie. Dazu, was
-- welches Objekt bringt (objektFunde, für Stellen, die das Radar mit Alt gelernt hat).
function K:Beute(id, menge, _, knotenArt)
  if knotenArt == "kraut" or knotenArt == "erz" then
    self:Knoten(knotenArt)
  elseif knotenArt then
    self.aktuell = nil
  end
  local e = self.aktuell
  if e then e.inhalt[id] = (e.inhalt[id] or 0) + (menge or 1) end
  local obj = e and ns.Sammeln.objekt
  if obj then
    local funde = ns.db.objektFunde[obj] or {}
    ns.db.objektFunde[obj] = funde
    funde[id] = (funde[id] or 0) + (menge or 1)
  end
end

-- Eine Stelle, die das Radar gezeigt hat (Alt über einem Punkt, Name aus dem Tooltip des Spiels;
-- Patrick, 20. Nov: „wenn ich jetzt eine neue Node sehe, dann hat er die gar nicht eingezeichnet“).
-- Gemerkt, wenn dort noch keine Stelle derselben Art liegt. n = 0: noch nie dort gesammelt; fund ist,
-- was dort wohl wächst. Rückgabe: die neue Stelle oder nil.
function K:Gesehen(karte, x, y, art, name, fund)
  local liste = ns.db.knotenKarte[karte]
  if not liste then
    liste = {}
    ns.db.knotenKarte[karte] = liste
  end
  for _, e in ipairs(liste) do
    if e.art == art and (e.x - x) * (e.x - x) + (e.y - y) * (e.y - y) <= K.NAH * K.NAH then return nil end
  end
  local e = { x = runden(x), y = runden(y), art = art, n = 0, inhalt = {}, name = name, fund = fund, gesehen = zeit() }
  table.insert(liste, e)
  kuerzen(liste)
  return e
end

-- Namen der Knoten lernen: Steht die Zielhilfe auf einem Kraut oder einer Ader (Objekt-ID bekannt),
-- merkt sich Hop & Seek den Namen, den das Spiel nennt, in der Sprache des Spiels. Damit erkennt das
-- Radar Adern im Tooltip der Minikarte (Kräuter heißen wie ihr Kraut).
ns.Ereignis("PLAYER_SOFT_INTERACT_CHANGED", function()
  if not (ns.db and UnitGUID and UnitName) then return end
  local okG, guid = pcall(UnitGUID, "softinteract")
  local obj = okG and ns.Sammeln.ObjektID(guid)
  if not obj then return end
  local art = ns.db.knotenObjekte[obj] or (ns.Lichtsaeule and ns.Lichtsaeule.OBJEKTE[obj])
  if art ~= "kraut" and art ~= "erz" then return end
  local okN, name = pcall(UnitName, "softinteract")
  if okN and type(name) == "string" and name ~= "" and not geheim(name) then ns.db.knotenNamen[name] = obj end
end)

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
