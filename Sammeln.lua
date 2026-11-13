-- Sammelzähler: zählt Kräuter, Erz, Steine und Edelsteine, die der Char aus Vorkommen in der Welt
-- holt, je Sitzung und insgesamt, mit Knoten und Menge pro Stunde (Patricks Wunsch, 13. Nov).
-- Erkannt wird an der Beute, nie an Namen:
--   - Quelle ist ein Objekt der Welt (GUID "GameObject-..."), kein Gegner und keine Truhe im Beutel
--   - im Beutefenster liegt ein Kraut (Handelswaren 7/9) oder Metall und Stein (7/7). Dann zählt
--     alles an Handelswaren aus diesem Fenster mit, zum Beispiel Edelsteine aus einer Erzader.
-- Gezählt wird erst, wenn ein Platz im Beutefenster leer wird, also wirklich genommen ist.
-- Der Wert kommt aus Auctionator über dessen Schnittstelle für andere Add-ons (Auctionator.API.v1),
-- sonst aus Midas (MidasAPI, MIT), nur wenn eins davon geladen ist. Andere Teile hängen sich mit
-- ns.beimSammeln an (Journal, Sammelkarte). Nur lesen und anzeigen, nichts geschieht von selbst.
local ADDON, ns = ...
local L = ns.L

local Z = { beute = {}, hoerer = {} }
ns.Sammeln = Z

-- Wer mithören will, wenn etwas aus einem Kraut oder einer Ader genommen wird:
-- f(Gegenstands-ID, Menge, Qualität, knotenArt), knotenArt nur beim ersten Gegenstand eines Knotens
function ns.beimSammeln(f) table.insert(Z.hoerer, f) end

local HANDELSWAREN, UK_KRAUT, UK_METALL = 7, 9, 7
local NEUE_SITZUNG = 30 * 60   -- so lange nichts gesammelt: die nächste Sitzung beginnt

local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end
local function zeit() return (GetServerTime and GetServerTime()) or time() end

-- Klasse und Unterklasse eines Gegenstands aus den Spieldaten
local function klasse(itemID)
  local f = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
  if not f then return nil end
  local ok, id, _, _, _, _, k, u = pcall(f, itemID)
  if not ok or not id then return nil end
  return k, u
end

function Z.Art(itemID)
  local k, u = klasse(itemID)
  if k == HANDELSWAREN and u == UK_KRAUT then return "kraut" end
  if k == HANDELSWAREN and u == UK_METALL then return "erz" end
end

-- Sitzung: { start, zuletzt (Serverzeit), menge = { [ID] = Anzahl }, knoten = { kraut, erz } }.
-- Gespeichert, damit ein /reload oder kurzes Ausloggen die Sitzung nicht beendet.
function Z:Sitzung()
  local s = ns.db.sitzung
  if not s or not s.start or zeit() - (s.zuletzt or s.start) > NEUE_SITZUNG then
    if s and s.start then Z:Bilanz(s) end
    s = { start = nil, zuletzt = nil, menge = {}, knoten = { kraut = 0, erz = 0 } }
    ns.db.sitzung = s
  end
  return s
end

function Z:Neu()
  local s = ns.db.sitzung
  if s and s.start then Z:Bilanz(s) end
  ns.db.sitzung = nil
  self:Sitzung()
  ns.aktualisieren()
end

-- Bilanz einer beendeten Sitzung als Zeile im Chat: Dauer, Menge, Knoten, Wert, bester Fund.
-- Gemerkt in ns.db.letzteSitzung für den Reiter Gathered.
function Z:Bilanz(s)
  local knoten = (s.knoten and ((s.knoten.kraut or 0) + (s.knoten.erz or 0))) or 0
  if knoten == 0 then return end
  local t = Z.Summe(s.menge)
  local dauer = math.max(0, (s.zuletzt or s.start) - s.start)
  local teile = { ns.dauer(dauer), Z.Text(t, knoten) }
  if t.wert then
    local w = string.format(L.GATHER_WORTH, ns.geld(t.wert))
    if dauer >= 300 then w = w .. " " .. string.format(L.GATHER_WORTH_RATE, ns.geld(t.wert * 3600 / dauer)) end
    table.insert(teile, w)
  end
  local text = string.format(L.SESSION_SUMMARY, table.concat(teile, ", "))
  local best
  for _, e in ipairs(t.liste) do
    if e.wert and (not best or e.wert > best.wert) then best = e end
  end
  if best then
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(best.id)
    if name then text = text .. " " .. string.format(L.SESSION_BEST, name) end
  end
  ns.db.letzteSitzung = { text = text, ende = s.zuletzt or s.start }
  ns.melde(text)
end

-- Beutefenster öffnet: Plätze mit Handelswaren aus einem Objekt der Welt merken
local function lesen()
  -- Kommt das Ereignis für dasselbe Fenster noch einmal, gilt die erste Lesung (sonst zählte der
  -- Knoten doppelt)
  if Z.offen then return end
  Z.offen = true
  Z.beute, Z.knoten, Z.gezaehlt = {}, nil, false
  if not (GetNumLootItems and GetLootSlotLink and GetLootSlotInfo) then return end
  -- Angeln holt auch aus einem Objekt der Welt (dem Schwimmer): nie mitzählen
  if IsFishingLoot then
    local okA, angeln = pcall(IsFishingLoot)
    if okA and angeln then return end
  end
  local ok, n = pcall(GetNumLootItems)
  if not ok or type(n) ~= "number" then return end
  -- Ohne GetLootSourceInfo (falls ein Client es nicht hat): Beute zählt nur, wenn kein toter Gegner
  -- im Ziel ist, also nicht von einem Gegner kommt
  local ohneQuelle = not GetLootSourceInfo
  local gegner = ohneQuelle and UnitExists and UnitExists("target") and UnitIsDead and UnitIsDead("target")
  for platz = 1, n do
    local okQ, guid = true, nil
    if not ohneQuelle then okQ, guid = pcall(GetLootSourceInfo, platz) end
    local vomObjekt = okQ and ((ohneQuelle and not gegner)
      or (type(guid) == "string" and not geheim(guid) and string.find(guid, "^GameObject") ~= nil))
    local okL, link = pcall(GetLootSlotLink, platz)
    local okI, _, _, menge, _, qualitaet = pcall(GetLootSlotInfo, platz)
    if vomObjekt and okL and okI and type(link) == "string" and not geheim(link) then
      local id = tonumber(string.match(link, "item:(%d+)"))
      local k = id and klasse(id)
      if id and k == HANDELSWAREN then
        local art = Z.Art(id)
        if geheim(qualitaet) or type(qualitaet) ~= "number" then
          qualitaet = C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(id)
        end
        Z.beute[platz] = { id = id, menge = (type(menge) == "number" and menge > 0) and menge or 1, q = qualitaet }
        -- Kraut hat Vorrang: Kräuter wachsen nicht in Erzadern, Steine liegen aber auch mal dabei
        if art == "kraut" or (art == "erz" and Z.knoten ~= "kraut") then Z.knoten = art end
      end
    end
  end
end

-- Ein Platz wurde genommen: zählen, wenn das Fenster von einem Kraut oder einer Erzader kam
local function genommen(platz)
  local b = Z.beute[platz]
  if not (b and Z.knoten and ns.db and ns.db.zaehlen) then return end
  Z.beute[platz] = nil
  local s = Z:Sitzung()
  local jetzt = zeit()
  s.start = s.start or jetzt
  s.zuletzt = jetzt
  s.menge[b.id] = (s.menge[b.id] or 0) + b.menge
  local g = ns.db.gesamt
  g.menge[b.id] = (g.menge[b.id] or 0) + b.menge
  local knotenNeu
  if not Z.gezaehlt then
    Z.gezaehlt = true
    knotenNeu = Z.knoten
    s.knoten[Z.knoten] = (s.knoten[Z.knoten] or 0) + 1
    g.knoten[Z.knoten] = (g.knoten[Z.knoten] or 0) + 1
  end
  -- Journal (Punkte, Tagesziel, Rekorde, Abzeichen, Sammelbuch) und Sammelkarte hören mit. Ein
  -- Fehler dort darf das Zählen nicht stören.
  for _, f in ipairs(Z.hoerer) do
    local ok, fehler = pcall(f, b.id, b.menge, b.q, knotenNeu)
    if not ok then ns.melde(string.format(L.ERR_EVENT, "LOOT_SLOT_CLEARED", tostring(fehler))) end
  end
  ns.aktualisieren()
end

-- Preisquellen: Auctionator (Auctionator.API.v1) und Midas (MidasAPI.GetFairPrice, ein fairer
-- Marktpreis aus den Scans). Beide über ihre Schnittstellen für andere Add-ons.
local function auctionator()
  local api = type(Auctionator) == "table" and type(Auctionator.API) == "table" and Auctionator.API.v1
  if type(api) == "table" and api.GetAuctionPriceByItemID then return api end
end
local function midas()
  if type(MidasAPI) == "table" and type(MidasAPI.GetFairPrice) == "function" then return MidasAPI end
end

-- Preis eines Gegenstands in Kupfer, erst Auctionator, sonst Midas. nil ohne Preis.
function Z.Preis(itemID)
  local a = auctionator()
  if a then
    local ok, preis = pcall(a.GetAuctionPriceByItemID, L.ADDON_NAME, itemID)
    if ok and type(preis) == "number" and preis > 0 then return preis end
  end
  local m = midas()
  if m then
    local ok, preis = pcall(m.GetFairPrice, itemID)
    if ok and type(preis) == "number" and preis > 0 then return preis end
  end
end

function Z.MitPreisen()
  return auctionator() ~= nil or midas() ~= nil
end

-- Zusammenfassung einer Liste { [ID] = Anzahl }: Kräuter, Erz und Stein (dazu Edelsteine und
-- anderes aus der Ader), Wert in Kupfer (nil ohne Auctionator), Einträge sortiert nach Menge
function Z.Summe(menge)
  local t = { kraut = 0, erz = 0, rest = 0, alle = 0, wert = nil, liste = {} }
  for id, n in pairs(menge or {}) do
    local art = Z.Art(id) or "rest"
    t[art] = t[art] + n
    t.alle = t.alle + n
    local preis = Z.Preis(id)
    if preis then t.wert = (t.wert or 0) + preis * n end
    table.insert(t.liste, { id = id, anzahl = n, wert = preis and preis * n or nil })
  end
  table.sort(t.liste, function(a, b)
    if a.anzahl ~= b.anzahl then return a.anzahl > b.anzahl end
    return a.id < b.id
  end)
  return t
end

-- "52 herbs, 3 ore, stone and gems from 23 nodes": Arten ohne Fund fallen weg, Einzahl stimmt
-- ("from 1 node", Patricks Screenshot 13. Nov)
function Z.Text(t, knoten)
  knoten = knoten or t.knoten or 0
  local teile = {}
  if t.kraut > 0 then table.insert(teile, t.kraut == 1 and L.GATHER_HERB_ONE or string.format(L.GATHER_HERBS, t.kraut)) end
  local erz = t.erz + t.rest
  if erz > 0 then table.insert(teile, erz == 1 and L.GATHER_ORE_ONE or string.format(L.GATHER_ORE, erz)) end
  if #teile == 0 then return L.GATHER_NOTHING end
  return string.format(L.GATHER_FROM, table.concat(teile, ", "),
    knoten == 1 and L.GATHER_NODE_ONE or string.format(L.GATHER_NODES, knoten))
end

-- Laufende Sitzung mit Rate: Gegenstände und Wert pro Stunde. Unter 5 Minuten keine Rate.
function Z:Stand()
  local s = self:Sitzung()
  local t = Z.Summe(s.menge)
  t.knoten = (s.knoten.kraut or 0) + (s.knoten.erz or 0)
  t.start = s.start
  local dauer = s.start and (zeit() - s.start) or 0
  t.dauer = dauer
  if dauer >= 300 then
    t.proStunde = t.alle * 3600 / dauer
    if t.wert then t.wertProStunde = t.wert * 3600 / dauer end
  end
  return t
end

-- Dauer als Text: "42 min", ab einer Stunde "1:07 h"
function ns.dauer(sekunden)
  sekunden = math.max(0, math.floor(sekunden or 0))
  if sekunden >= 3600 then
    return string.format(L.GATHER_BAR_HOURS, math.floor(sekunden / 3600), math.floor(sekunden / 60) % 60)
  end
  return string.format(L.GATHER_BAR_MINUTES, math.floor(sekunden / 60))
end

-- Geld als kurzer Text: "3g 20s", unter einem Gold "45s 12c"
function ns.geld(kupfer)
  kupfer = math.floor(kupfer or 0)
  local g, s, c = math.floor(kupfer / 10000), math.floor(kupfer / 100) % 100, kupfer % 100
  if g > 0 then return string.format("%d%s %d%s", g, L.GOLD_SUFFIX, s, L.SILVER_SUFFIX) end
  if s > 0 then return string.format("%d%s %d%s", s, L.SILVER_SUFFIX, c, L.COPPER_SUFFIX) end
  return string.format("%d%s", c, L.COPPER_SUFFIX)
end

ns.Ereignis("LOOT_READY", lesen)
ns.Ereignis("LOOT_OPENED", lesen)
ns.Ereignis("LOOT_SLOT_CLEARED", genommen)
ns.Ereignis("LOOT_CLOSED", function() Z.beute, Z.knoten, Z.gezaehlt, Z.offen = {}, nil, false, false end)
ns.beimStart(function() Z:Sitzung() end)
