-- Lehrer-Finder (Patrick, 13. Nov: „wo finde ich denn den nächsten Lehrer ... Allianz und Horde“).
-- Für Kräuterkunde, Bergbau und Kürschnern: der nächste Lehrer der eigenen Fraktion (oder ein
-- neutraler) auf diesem Kontinent, mit dem Wegpunkt des Spiels wie beim Wegweiser. Nur Lehrer, die
-- bis Artisan lehren. Die Junior-Lehrer in den Startgebieten lehren nur bis 75 und fehlen deshalb.
-- Lagen nachgeschlagen bei Warcraft Tavern, „Profession Trainer Locations“ für WoW Forever (13. Nov
-- 2026), Karten-IDs von Classic. Die neuen Gebiete von Forever (Zephras Isle, Riverglades) fehlen
-- noch, ihre Karten-IDs sind nicht bekannt. Gemessen wird über die Weltlage der Karten
-- (C_Map.GetWorldPosFromMapPos), auch über Zonengrenzen hinweg. Nur auf Klick oder Befehl.
local ADDON, ns = ...
local L = ns.L

local LH = {}
ns.Lehrer = LH

local A, H = "Alliance", "Horde"
-- { Art, Fraktion (nil: neutral), Karten-ID, x, y }
LH.LISTE = {
  -- Kräuterkunde
  { "kraut", A, 1433, 0.168, 0.468 },   -- Alma Jainrose, Lakeshire, Redridge Mountains
  { "kraut", A, 1445, 0.641, 0.475 },   -- Brant Jasperbloom, Theramore Isle, Dustwallow Marsh
  { "kraut", A, 1440, 0.506, 0.670 },   -- Cylania Rootstalker, Silverwind Refuge, Ashenvale
  { "kraut", A, 1416, 0.184, 0.634 },   -- Edward Egan, Dalaran, Alterac Mountains
  { "kraut", A, 1457, 0.479, 0.686 },   -- Firodren Mooncaller, Darnassus
  { "kraut", nil, 1434, 0.276, 0.778 }, -- Flora Silverwind, Booty Bay, Stranglethorn Vale
  { "kraut", A, 1429, 0.399, 0.483 },   -- Herbalist Pomeroy, vor Stormwind, Elwynn Forest
  { "kraut", A, 1432, 0.366, 0.484 },   -- Kali Healtouch, Thelsamar, Loch Modan
  { "kraut", A, 1438, 0.577, 0.606 },   -- Malorne Bladeleaf, Dolanaar, Teldrassil
  { "kraut", nil, 1450, 0.456, 0.468 }, -- Malvor, Nighthaven, Moonglade
  { "kraut", A, 1455, 0.556, 0.580 },   -- Reyna Stonebranch, Ironforge
  { "kraut", A, 1453, 0.314, 0.629 },   -- Shylamiir, Stormwind (The Park)
  { "kraut", A, 1453, 0.545, 0.839 },   -- Tannysa, Stormwind (Mage Quarter)
  { "kraut", A, 1437, 0.080, 0.559 },   -- Telurinon Moonshadow, Menethil Harbor, Wetlands
  { "kraut", H, 1434, 0.322, 0.276 },   -- Angrun, Grom'gol, Stranglethorn Vale
  { "kraut", H, 1424, 0.618, 0.197 },   -- Aranae Venomblood, Tarren Mill, Hillsbrad Foothills
  { "kraut", H, 1420, 0.599, 0.521 },   -- Faruza, Brill, Tirisfal Glades
  { "kraut", H, 1454, 0.556, 0.400 },   -- Jandi, Orgrimmar (The Drag)
  { "kraut", H, 1456, 0.497, 0.396 },   -- Komin Winterhoof, Thunder Bluff
  { "kraut", H, 1458, 0.548, 0.501 },   -- Martha Alliestar, Undercity
  { "kraut", H, 1411, 0.554, 0.751 },   -- Mishiki, Sen'jin Village, Durotar
  { "kraut", H, 1444, 0.760, 0.434 },   -- Ruw, Camp Mojache, Feralas
  -- Bergbau
  { "erz", A, 1432, 0.372, 0.469 },     -- Brock Stoneseeker, Thelsamar, Loch Modan
  { "erz", A, 1426, 0.691, 0.555 },     -- Dank Drizzlecut, Gol'Bolar Quarry, Dun Morogh
  { "erz", A, 1453, 0.591, 0.377 },     -- Gelman Stonehand, Stormwind (Dwarven District)
  { "erz", A, 1455, 0.503, 0.280 },     -- Geofram Bouldertoe, Ironforge
  { "erz", A, 1439, 0.382, 0.410 },     -- Kurdram Stonehammer, Auberdine, Darkshore
  { "erz", A, 1431, 0.740, 0.496 },     -- Matt Johnson, Darkshire, Duskwood
  { "erz", nil, 1446, 0.510, 0.280 },   -- Pikkle, Gadgetzan, Tanaris
  { "erz", A, 1426, 0.500, 0.504 },     -- Yarr Hammerstone, Kharanos, Dun Morogh
  { "erz", H, 1456, 0.345, 0.575 },     -- Brek Stonehoof, Thunder Bluff
  { "erz", H, 1458, 0.559, 0.360 },     -- Brom Killian, Undercity
  { "erz", H, 1421, 0.433, 0.406 },     -- Johan Focht, The Sepulcher, Silverpine Forest
  { "erz", H, 1411, 0.518, 0.407 },     -- Krunn, Razor Hill, Durotar
  { "erz", H, 1454, 0.730, 0.270 },     -- Makaru, Orgrimmar (Valley of Honor)
  -- Kürschnern
  { "leder", A, 1455, 0.396, 0.328 },   -- Balthus Stoneflayer, Ironforge
  { "leder", A, 1457, 0.642, 0.217 },   -- Eladriel, Darnassus
  { "leder", A, 1429, 0.463, 0.622 },   -- Helene Peltskinner, Goldshire, Elwynn Forest
  { "leder", A, 1440, 0.501, 0.672 },   -- Jayla, Silverwind Refuge, Ashenvale
  { "leder", A, 1453, 0.723, 0.623 },   -- Maris Granger, Stormwind (Old Town)
  { "leder", A, 1438, 0.421, 0.500 },   -- Radnaal Maneweaver, Teldrassil
  { "leder", A, 1433, 0.836, 0.711 },   -- Wilma Ranthal, Redridge Mountains
  { "leder", H, 1413, 0.451, 0.590 },   -- Dranh, Camp Taurajo, The Barrens
  { "leder", H, 1458, 0.710, 0.595 },   -- Killian Hagey, Undercity
  { "leder", H, 1444, 0.744, 0.430 },   -- Kulleg Stonehorn, Camp Mojache, Feralas
  { "leder", H, 1443, 0.232, 0.698 },   -- Malux, Shadowprey Village, Desolace
  { "leder", H, 1456, 0.447, 0.433 },   -- Mooranta, Thunder Bluff
  { "leder", H, 1420, 0.656, 0.601 },   -- Rand Rhobart, Death's Watch, Tirisfal Glades
  { "leder", H, 1454, 0.631, 0.453 },   -- Thuwd, Orgrimmar (The Drag)
  { "leder", H, 1412, 0.450, 0.614 },   -- Yonn Deepcut, Bloodhoof Village, Mulgore
}

local NAMEN = { kraut = "SKILL_HERBALISM", erz = "SKILL_MINING", leder = "SKILL_SKINNING" }
function LH.Name(art) return L[NAMEN[art]] or art end

-- Weltlage eines Kartenpunkts: Kontinent, x, y (Meter), oder nil
local function welt(karte, x, y)
  if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
  local ok, kontinent, pos = pcall(C_Map.GetWorldPosFromMapPos, karte, CreateVector2D(x, y))
  if not ok or kontinent == nil or type(pos) ~= "table" then return nil end
  local wx, wy = pos.x, pos.y
  if pos.GetXY then wx, wy = pos:GetXY() end
  if type(wx) ~= "number" or type(wy) ~= "number" then return nil end
  return kontinent, wx, wy
end

-- Die Weltlage der Lehrer ändert sich nicht: einmal rechnen (false: unbekannt)
local lagen = {}
local function lehrerLage(t)
  local w = lagen[t]
  if w == nil then
    local k, wx, wy = welt(t[3], t[4], t[5])
    w = k ~= nil and { k, wx, wy } or false
    lagen[t] = w
  end
  return w or nil
end

-- Nächster Lehrer für diese Art. Rückgabe: { t, abstand } oder nil und der Grund ("ort": keine
-- Position, etwa in einer Instanz; "keiner": keiner auf diesem Kontinent für diese Fraktion)
function LH:Suchen(art)
  local karte, x, y = ns.SammelKarte.Position()
  if not karte then return nil, "ort" end
  local k, wx, wy = welt(karte, x, y)
  if k == nil then return nil, "ort" end
  local fraktion = UnitFactionGroup and UnitFactionGroup("player")
  local beste
  for _, t in ipairs(LH.LISTE) do
    if t[1] == art and (t[2] == nil or t[2] == fraktion) then
      local w = lehrerLage(t)
      if w and w[1] == k then
        local d = math.sqrt((w[2] - wx) ^ 2 + (w[3] - wy) ^ 2)
        if not beste or d < beste.abstand then beste = { t = t, abstand = d } end
      end
    end
  end
  if not beste then return nil, "keiner" end
  return beste
end

-- Welcher Beruf braucht den Lehrer? Am Limit zuerst, dann kurz davor, dann der erste Sammelberuf
function LH.Bedarf()
  local B = ns.Berufe
  if not B then return nil end
  local liste = B.Liste()
  for _, p in ipairs(liste) do if B.AmLimit(p) then return p.art end end
  for _, p in ipairs(liste) do
    if p.max < B.ENDE and p.rang >= p.max - B.BALD then return p.art end
  end
  return liste[1] and liste[1].art or nil
end

-- Klick, Befehl oder Hinweis im Sammelfenster: Wegpunkt zum nächsten Lehrer. Der Wegweiser zur
-- nächsten Sammelstelle geht dabei aus (es gibt nur einen Wegpunkt).
function LH:Zeigen(art)
  art = art or LH.Bedarf()
  if not art then
    ns.melde(L.TRAINER_NO_PROFESSION)
    return false
  end
  local z, grund = self:Suchen(art)
  if not z then
    ns.melde(grund == "ort" and L.NEXT_NO_POSITION or string.format(L.TRAINER_NONE, LH.Name(art)))
    return false
  end
  if ns.Wegweiser and ns.Wegweiser.Laeuft() then ns.Wegweiser:Aus(true) end
  if not ns.Wegweiser.Wegpunkt(z.t[3], z.t[4], z.t[5]) then return false end
  local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(z.t[3])
  local zone = type(info) == "table" and info.name or "?"
  ns.melde(string.format(L.TRAINER_SET, LH.Name(art), zone, math.floor(z.abstand + 0.5)))
  return true
end
