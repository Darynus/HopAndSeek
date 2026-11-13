-- Wegweiser zur nächsten bekannten Sammelstelle (Patrick, 13. Nov: die Säule auch für weiter
-- entfernte Ziele; „Ja, bau das ein“). Die Lichtsäule braucht eine Plakette des Spiels und geht nur in
-- Reichweite der Zielhilfe. Für alles weiter weg setzt Hop & Seek auf Klick den Wegpunkt des Spiels
-- auf die nächste Stelle der Sammelkarte (SammelKarte.lua), deren Beruf der Char hat. Das Spiel zeigt
-- dann seine Markierung mit Entfernung, auf der Karte steht seine Nadel. Wer dort sammelt, bekommt
-- nach dem Plündern die nächste Stelle. Übersprungen werden die Stelle, an der man steht, und Stellen,
-- an denen man vor weniger als zehn Minuten gesammelt hat (wachsen noch nach).
-- Nur auf Klick oder Taste. Einen eigenen Wegpunkt des Spielers ersetzt der Klick, den von Hop & Seek
-- nimmt es nur weg, solange er noch der eigene ist. Nur eigene Daten, nichts wird gesendet.
local ADDON, ns = ...
local L = ns.L

local W = { uebersprungen = {} }
ns.Wegweiser = W

W.NACHWACHSEN = 10 * 60   -- Sekunden: hier frisch gesammelt, wächst wohl noch nach
W.HIER = 25               -- Meter: so nah steht man an einer Stelle (oder hat sie erreicht)

local function zeit() return (GetServerTime and GetServerTime()) or time() end

-- Größe einer Karte in Metern (Breite, Höhe), einmal gefragt. Ohne Größe wird in Kartenanteilen
-- gerechnet, dann gibt es keine Meterangabe.
local groessen = {}
local function groesse(karte)
  local g = groessen[karte]
  if g ~= nil then return g or nil end
  g = false
  if C_Map and C_Map.GetMapWorldSize then
    local ok, b, h = pcall(C_Map.GetMapWorldSize, karte)
    if ok and type(b) == "number" and type(h) == "number" and b > 0 and h > 0 then g = { b, h } end
  end
  groessen[karte] = g
  return g or nil
end

-- Abstand zweier Punkte einer Karte: Meter und true, oder Kartenanteil und false
local function abstand(karte, x1, y1, x2, y2)
  local g = groesse(karte)
  if g then return math.sqrt(((x2 - x1) * g[1]) ^ 2 + ((y2 - y1) * g[2]) ^ 2), true end
  return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), false
end

local function nah(karte, x1, y1, x2, y2)
  local d, meter = abstand(karte, x1, y1, x2, y2)
  return d <= (meter and W.HIER or ns.SammelKarte.NAH)
end

-- Welche Stellen kommen in Frage? Die, deren Beruf der Char hat. Weiß Hop & Seek nichts über seine
-- Berufe, alle.
local function arten()
  local t = {}
  if ns.Berufe then
    t.kraut = ns.Berufe.Hat("kraut") or nil
    t.erz = ns.Berufe.Hat("erz") or nil
  end
  if not (t.kraut or t.erz) then t.kraut, t.erz = true, true end
  return t
end

-- Nächste Stelle von hier. Rückgabe: { e, karte, abstand, meter } oder nil und der Grund
-- ("ort": keine Position, etwa in einer Instanz; "keine": nichts Passendes auf dieser Karte)
function W:Suchen()
  local karte, x, y = ns.SammelKarte.Position()
  if not karte then return nil, "ort" end
  local passt, jetzt = arten(), zeit()
  local beste
  for _, e in ipairs(ns.db.knotenKarte[karte] or {}) do
    if passt[e.art] and not self.uebersprungen[e] and not (e.zuletzt and jetzt - e.zuletzt < W.NACHWACHSEN)
      and not nah(karte, x, y, e.x, e.y) then
      local d, meter = abstand(karte, x, y, e.x, e.y)
      if not beste or d < beste.abstand then beste = { e = e, karte = karte, abstand = d, meter = meter } end
    end
  end
  if not beste then return nil, "keine" end
  return beste
end

-- Steht noch der Wegpunkt von Hop & Seek, oder hat der Spieler einen eigenen gesetzt (oder ihn weggenommen)?
local function istUnserer(self)
  local p = self.punkt
  if not (p and C_Map and C_Map.GetUserWaypoint) then return false end
  local ok, wp = pcall(C_Map.GetUserWaypoint)
  if not ok or type(wp) ~= "table" or type(wp.position) ~= "table" then return false end
  return wp.uiMapID == p.karte and math.abs((wp.position.x or -1) - p.x) < 0.0005
    and math.abs((wp.position.y or -1) - p.y) < 0.0005
end
W.IstUnserer = istUnserer

-- Name der Stelle: ihr häufigster Fund (wie die Nadel auf der Karte), sonst Kraut oder Erz
function W.Name(e)
  local id = ns.SammelKarte.Haupt(e)
  local name = id and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
  return name or (e.art == "kraut" and L.MAP_NODE_HERB or L.MAP_NODE_ORE)
end

-- Wegpunkt des Spiels setzen und verfolgen lassen (Markierung mit Entfernung auf dem Bildschirm)
function W:Setzen(z)
  if not (C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates) then
    ns.melde(L.NEXT_UNSUPPORTED)
    return false
  end
  if C_Map.CanSetUserWaypointOnMap then
    local ok, kann = pcall(C_Map.CanSetUserWaypointOnMap, z.karte)
    if ok and kann == false then
      ns.melde(L.NEXT_UNSUPPORTED)
      return false
    end
  end
  local okP, punkt = pcall(UiMapPoint.CreateFromCoordinates, z.karte, z.e.x, z.e.y)
  if not okP or not punkt then
    ns.melde(L.NEXT_UNSUPPORTED)
    return false
  end
  -- Vorher merken: das Spiel meldet USER_WAYPOINT_UPDATED womöglich sofort
  local altZiel, altPunkt = self.ziel, self.punkt
  self.ziel, self.punkt = z.e, { karte = z.karte, x = z.e.x, y = z.e.y }
  if not pcall(C_Map.SetUserWaypoint, punkt) then
    self.ziel, self.punkt = altZiel, altPunkt
    ns.melde(L.NEXT_UNSUPPORTED)
    return false
  end
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, true) end
  return true
end

-- Klick, /hop next oder Taste: zur nächsten Stelle. Läuft der Wegweiser schon, wird die jetzige
-- übersprungen (etwa weil dort nichts mehr wächst).
function W:Weiter()
  if self.ziel and istUnserer(self) then
    self.uebersprungen[self.ziel] = true
  else
    self.ziel, self.punkt, self.uebersprungen = nil, nil, {}
  end
  local z, grund = self:Suchen()
  if not z then
    if self.ziel then self.uebersprungen[self.ziel] = nil end
    ns.melde(grund == "ort" and L.NEXT_NO_POSITION or (self.ziel and L.NEXT_NO_OTHER or L.NEXT_NONE))
    return false
  end
  if not self:Setzen(z) then return false end
  if z.meter then
    ns.melde(string.format(L.NEXT_SPOT, W.Name(z.e), math.floor(z.abstand + 0.5)))
  else
    ns.melde(string.format(L.NEXT_SPOT_NO_DISTANCE, W.Name(z.e)))
  end
  ns.aktualisieren()
  return true
end

-- Rechtsklick oder /hop next stop: Wegweiser aus. Den Wegpunkt nimmt es nur weg, wenn es noch der
-- von Hop & Seek ist.
function W:Aus(still)
  if istUnserer(self) then
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then pcall(C_SuperTrack.SetSuperTrackedUserWaypoint, false) end
    if C_Map and C_Map.ClearUserWaypoint then pcall(C_Map.ClearUserWaypoint) end
  end
  local lief = self.ziel ~= nil
  self.ziel, self.punkt, self.erreicht, self.uebersprungen = nil, nil, nil, {}
  if not still and lief then ns.melde(L.NEXT_OFF) end
  ns.aktualisieren()
end

function W.Laeuft() return W.ziel ~= nil end

-- Gesammelt: an der Zielstelle (oder ganz nah daran) geht es nach dem Plündern weiter. Die Stelle
-- dieses Knotens kennt die Sammelkarte schon (ihr Haken läuft vorher).
ns.beimSammeln(function(_, _, _, knotenArt)
  if not W.ziel or not (knotenArt == "kraut" or knotenArt == "erz") then return end
  local K = ns.SammelKarte
  if K.aktuell == W.ziel then
    W.erreicht = true
    return
  end
  local karte, x, y = K.Position()
  if karte and W.punkt and karte == W.punkt.karte and nah(karte, x, y, W.punkt.x, W.punkt.y) then W.erreicht = true end
end)

ns.Ereignis("LOOT_CLOSED", function()
  if not W.erreicht then return end
  W.erreicht = nil
  if not istUnserer(W) then
    W.ziel, W.punkt = nil, nil
    return
  end
  W.uebersprungen = {}
  local z = W:Suchen()
  if z and W:Setzen(z) then
    ns.aktualisieren()
  else
    W:Aus(true)
    ns.melde(L.NEXT_LAST)
  end
end)

-- Der Spieler hat den Wegpunkt weggenommen oder einen eigenen gesetzt: Wegweiser still aus
ns.Ereignis("USER_WAYPOINT_UPDATED", function()
  if W.ziel and not istUnserer(W) then
    W.ziel, W.punkt, W.erreicht, W.uebersprungen = nil, nil, nil, {}
    ns.aktualisieren()
  end
end)

-- Taste (Bindings.xml): Esc > Options > Keybindings > AddOns > Hop & Seek. Ein Tastendruck ist ein
-- Klick auf diesen unsichtbaren Knopf, links die nächste Stelle, rechts aus. Wie bei Campfire Buddy
-- nach ActionButtonUseKeyDown beim Drücken oder beim Loslassen.
local taste = CreateFrame("Button", "HopAndSeekNextSpot", UIParent)
taste:RegisterForClicks(((GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")) and "AnyDown") or "AnyUp")
taste:SetScript("OnClick", function(_, knopf)
  if knopf == "RightButton" then W:Aus() else W:Weiter() end
end)
taste:Hide()
W.taste = taste

BINDING_HEADER_HOPANDSEEK = L.ADDON_NAME
_G["BINDING_NAME_CLICK HopAndSeekNextSpot:LeftButton"] = L.BIND_NEXT
_G["BINDING_NAME_CLICK HopAndSeekNextSpot:RightButton"] = L.BIND_NEXT_OFF
