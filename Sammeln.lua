-- Sammelzähler: zählt, was der Char aus Vorkommen in der Welt holt (Kräuter, Erz, Steine,
-- Edelsteine) und beim Kürschnern (Leder, Bälge, Schuppen), je Sitzung und insgesamt, mit Knoten
-- und Menge pro Stunde (Patricks Wunsch, 13. Nov; Kürschnern kam am selben Tag dazu).
-- Erkannt wird an der Beute, nie an Namen:
--   - Knoten: Quelle ist ein Objekt der Welt (GUID "GameObject-..."), im Fenster liegt ein Kraut
--     (Handelswaren 7/9) oder Metall und Stein (7/7). Dann zählt alles an Handelswaren aus diesem
--     Objekt mit, zum Beispiel Edelsteine aus einer Erzader. Kisten zählen nicht: Ein Objekt, das kein
--     bekanntes Kraut und keine bekannte Ader ist, zählt nur mit dem Beruf dazu und ohne Geld oder
--     anderes in der Beute (Patrick, 13. Nov: eine Kiste mit Zinnerz, Char ohne Sammelberuf).
--   - Kürschnern: Quelle ist eine Kreatur, im Fenster liegt Leder (7/6), dazu kein Geld und nichts
--     außer Handelswaren (normale Beute von Gegnern bringt fast immer Geld oder anderes mit), oder
--     der Char hat gerade gekürschnert (Zauber-ID).
-- Gezählt wird erst, wenn ein Platz im Beutefenster leer wird, also wirklich genommen ist.
-- Die Sitzung gehört dem Char (Patrick, 13. Nov: nach dem Umloggen lief sie beim anderen Char
-- weiter), die Gesamtzahlen dem Account.
-- Der Wert kommt aus Auctionator über dessen Schnittstelle für andere Add-ons (Auctionator.API.v1),
-- sonst aus Midas (MidasAPI, MIT), nur wenn eins davon geladen ist. Andere Teile hängen sich mit
-- ns.beimSammeln an (Journal, Sammelkarte, Berufe). Nur lesen und anzeigen, nichts geschieht von
-- selbst.
local ADDON, ns = ...
local L = ns.L

local Z = { beute = {}, hoerer = {}, stand = 0, gepluendert = {}, gepluendertListe = {} }
ns.Sammeln = Z

-- Wer mithören will, wenn etwas genommen wird: f(Gegenstands-ID, Menge, Qualität, knotenArt),
-- knotenArt ("kraut", "erz", "leder") nur beim ersten Gegenstand eines Knotens oder Kadavers
function ns.beimSammeln(f) table.insert(Z.hoerer, f) end

local HANDELSWAREN, UK_KRAUT, UK_METALL, UK_LEDER = 7, 9, 7, 6
local NEUE_SITZUNG = 30 * 60   -- so lange nichts gesammelt: die nächste Sitzung beginnt
-- Kürschnern in Classic (Lehrling bis Meister). Nur ein zusätzliches Zeichen, erkannt wird auch ohne.
local KUERSCHNERN = { [8613] = true, [8617] = true, [8618] = true, [10768] = true }

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
  if k ~= HANDELSWAREN then return nil end
  if u == UK_KRAUT then return "kraut" end
  if u == UK_METALL then return "erz" end
  if u == UK_LEDER then return "leder" end
end

-- Objekt-ID aus der GUID eines Objekts ("GameObject-0-Server-Instanz-Zone-ID-Nummer")
function Z.ObjektID(guid)
  if type(guid) ~= "string" or geheim(guid) then return nil end
  return tonumber(string.match(guid, "^GameObject%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
end

-- Schlüssel des Chars für Sitzung und Bilanz
function Z.Char()
  return (UnitName and UnitName("player") or "?") .. "-" .. (GetRealmName and GetRealmName() or "?")
end

-- Sitzung des Chars: { start, zuletzt (Serverzeit), menge = { [ID] = Anzahl },
-- knoten = { kraut, erz, leder } }. Gespeichert, damit ein /reload oder kurzes Ausloggen die
-- Sitzung nicht beendet.
function Z:Sitzung()
  local k = Z.Char()
  local s = ns.db.sitzungen[k]
  if not s or not s.start or zeit() - (s.zuletzt or s.start) > NEUE_SITZUNG then
    if s and s.start then Z:Bilanz(s) end
    s = { start = nil, zuletzt = nil, menge = {}, knoten = { kraut = 0, erz = 0, leder = 0 } }
    ns.db.sitzungen[k] = s
  end
  return s
end

function Z:Neu()
  local k = Z.Char()
  local s = ns.db.sitzungen[k]
  if s and s.start then Z:Bilanz(s) end
  ns.db.sitzungen[k] = nil
  self:Sitzung()
  ns.aktualisieren()
end

-- Zuletzt beendete Sitzung dieses Chars als Text (für den Reiter Gathered)
function Z.LetzteBilanz()
  local b = ns.db.bilanzen[Z.Char()]
  return b and b.text
end

-- Bilanz einer beendeten Sitzung als Zeile im Chat: Dauer, Menge, Knoten, Wert, bester Fund
function Z:Bilanz(s)
  local kn = s.knoten or {}
  local knoten, koerper = (kn.kraut or 0) + (kn.erz or 0), kn.leder or 0
  if knoten + koerper == 0 then return end
  local t = Z.Summe(s.menge)
  local dauer = math.max(0, (s.zuletzt or s.start) - s.start)
  local teile = { ns.dauer(dauer), Z.Text(t, knoten, koerper) }
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
  ns.db.bilanzen[Z.Char()] = { text = text, ende = s.zuletzt or s.start }
  ns.melde(text)
end

-- Ist dieser Platz Geld oder Währung? (Kürschnern bringt nie Geld)
local function istGeld(platz)
  if GetLootSlotType then
    local ok, typ = pcall(GetLootSlotType, platz)
    if ok and type(typ) == "number" and not geheim(typ) then return typ >= 2 end
  end
  if LootSlotHasItem then
    local ok, hat = pcall(LootSlotHasItem, platz)
    if ok and not geheim(hat) then return not hat end
  end
  return false
end

local function geradeGekuerschnert()
  return Z.gekuerschnert ~= nil and ns.jetzt() - Z.gekuerschnert < 5
end

-- Beutefenster öffnet: Plätze mit Handelswaren aus einem Kraut, einer Ader oder einem gekürschnerten
-- Kadaver merken
local function lesen()
  -- Kommt das Ereignis für dasselbe Fenster noch einmal, gilt die erste Lesung (sonst zählte der
  -- Knoten doppelt)
  if Z.offen then return end
  Z.offen = true
  Z.beute, Z.knoten, Z.gezaehlt, Z.objekt = {}, nil, false, nil
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
  local gegenstaende, sorten, geld, fremd = {}, {}, false, false
  for platz = 1, n do
    local quelle
    if ohneQuelle then
      if not gegner then quelle = "objekt" end
    else
      local okQ, guid = pcall(GetLootSourceInfo, platz)
      if okQ and type(guid) == "string" and not geheim(guid) then
        if string.find(guid, "^GameObject") then
          quelle = "objekt"
          Z.objekt = Z.objekt or Z.ObjektID(guid)
        elseif string.find(guid, "^Creature") then
          quelle = "kreatur"
          -- Für die Lichtsäule: diesen Kadaver hat der Char geplündert (die letzten 30)
          if not Z.gepluendert[guid] then
            Z.gepluendert[guid] = true
            table.insert(Z.gepluendertListe, guid)
            if #Z.gepluendertListe > 30 then Z.gepluendert[table.remove(Z.gepluendertListe, 1)] = nil end
          end
        end
      end
    end
    if istGeld(platz) then geld = true end
    local okL, link = pcall(GetLootSlotLink, platz)
    local okI, _, _, menge, _, qualitaet = pcall(GetLootSlotInfo, platz)
    if okL and okI and type(link) == "string" and not geheim(link) then
      local id = tonumber(string.match(link, "item:(%d+)"))
      local k = id and klasse(id)
      if id and k == HANDELSWAREN and quelle then
        if geheim(qualitaet) or type(qualitaet) ~= "number" then
          qualitaet = C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(id)
        end
        gegenstaende[platz] = { id = id, menge = (type(menge) == "number" and menge > 0) and menge or 1, q = qualitaet,
          quelle = quelle }
        local art = Z.Art(id)
        if art then sorten[quelle .. "-" .. art] = true end
      elseif id then
        fremd = true
      end
    end
  end
  -- Kiste oder Knoten? Ein bekanntes Kraut oder eine bekannte Ader (Objekt-IDs in Lichtsaeule.lua)
  -- zählt immer. Jedes andere Objekt nur, wenn der Char den Beruf dazu hat und die Beute wie aus
  -- einem Knoten aussieht: kein Geld, nur Handelswaren. Kisten bringen fast immer Geld oder anderes
  -- mit. Beim Kürschnern genauso: Ohne den Beruf ist Leder nur Beute.
  local function kann(art) return not ns.Berufe or ns.Berufe.Hat(art) end
  local function knoten(art)
    if not sorten["objekt-" .. art] then return false end
    local bekannt = Z.objekt and ns.Lichtsaeule and ns.Lichtsaeule.OBJEKTE[Z.objekt]
    if bekannt then return bekannt == art end
    return not geld and not fremd and kann(art)
  end
  -- Kraut hat Vorrang: Kräuter wachsen nicht in Erzadern, Steine liegen aber auch mal dabei
  if knoten("kraut") then
    Z.knoten = "kraut"
  elseif knoten("erz") then
    Z.knoten = "erz"
  elseif sorten["kreatur-leder"] and (geradeGekuerschnert() or (not geld and not fremd and kann("leder"))) then
    Z.knoten = "leder"
  end
  if not Z.knoten then return end
  local ausKreatur = Z.knoten == "leder"
  for platz, b in pairs(gegenstaende) do
    if (b.quelle == "kreatur") == ausKreatur then Z.beute[platz] = b end
  end
  -- Für die Lichtsäule: dieses Objekt ist ein Kraut oder eine Ader (gelernt, nicht geraten)
  if Z.objekt and not ausKreatur then ns.db.knotenObjekte[Z.objekt] = Z.knoten end
end

-- Ein Platz wurde genommen: zählen, wenn das Fenster von einem Kraut, einer Erzader oder einem
-- gekürschnerten Kadaver kam
local function genommen(platz)
  local b = Z.beute[platz]
  if not (b and Z.knoten and ns.db and ns.db.zaehlen) then return end
  Z.beute[platz] = nil
  local s = Z:Sitzung()
  local jetzt = zeit()
  s.start = s.start or jetzt
  s.zuletzt = jetzt
  s.menge[b.id] = (s.menge[b.id] or 0) + b.menge
  Z.stand = Z.stand + 1
  local g = ns.db.gesamt
  g.menge[b.id] = (g.menge[b.id] or 0) + b.menge
  local knotenNeu
  if not Z.gezaehlt then
    Z.gezaehlt = true
    knotenNeu = Z.knoten
    -- Wer hier Leder bekommt, kann Kürschnern (sicherer als jede Berufs-ID, für die Lichtsäule)
    if Z.knoten == "leder" then ns.db.kuerschner[Z.Char()] = true end
    s.knoten[Z.knoten] = (s.knoten[Z.knoten] or 0) + 1
    g.knoten[Z.knoten] = (g.knoten[Z.knoten] or 0) + 1
  end
  -- Journal (Punkte, Tagesziel, Rekorde, Abzeichen, Sammelbuch), Sammelkarte und Berufe hören mit.
  -- Ein Fehler dort darf das Zählen nicht stören.
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

-- Preis eines Gegenstands in Kupfer aus der gewählten Quelle (Patrick, 13. Nov: nicht von Midas
-- abhängen, das haben wenige; Auctionator ist Standard, Midas oder beide auf Wunsch). nil ohne Preis.
local function quelle() return (ns.db and ns.db.preisQuelle) or "auctionator" end
function Z.Preis(itemID)
  local q = quelle()
  local a = q ~= "midas" and auctionator()
  if a then
    local ok, preis = pcall(a.GetAuctionPriceByItemID, L.ADDON_NAME, itemID)
    if ok and type(preis) == "number" and preis > 0 then return preis end
  end
  local m = q ~= "auctionator" and midas()
  if m then
    local ok, preis = pcall(m.GetFairPrice, itemID)
    if ok and type(preis) == "number" and preis > 0 then return preis end
  end
end

function Z.MitPreisen()
  local q = quelle()
  return (q ~= "midas" and auctionator() ~= nil) or (q ~= "auctionator" and midas() ~= nil)
end

-- Welche gewählte Quelle fehlt? Name für den Hinweis, sonst nil
function Z.FehlendeQuelle()
  local q = quelle()
  if q == "midas" and not midas() then return L.PRICE_MIDAS end
  if q == "auctionator" and not auctionator() then return L.PRICE_AUCTIONATOR end
  if q == "beide" and not auctionator() and not midas() then return L.PRICE_AUCTIONATOR end
end

-- Zusammenfassung einer Liste { [ID] = Anzahl }: Kräuter, Erz und Stein (dazu Edelsteine und
-- anderes aus der Ader), Leder, Wert in Kupfer (nil ohne Preise), Einträge sortiert nach Menge
function Z.Summe(menge)
  local t = { kraut = 0, erz = 0, leder = 0, rest = 0, alle = 0, wert = nil, liste = {} }
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

-- "52 herbs, 3 ore, stone and gems from 23 nodes", mit Kürschnern "8 leather and hides from 8
-- creatures". Arten ohne Fund fallen weg, Einzahl stimmt ("from 1 node", Patricks Screenshot).
function Z.Text(t, knoten, koerper)
  knoten = knoten or t.knoten or 0
  koerper = koerper or t.koerper or 0
  local teile = {}
  if t.kraut > 0 then table.insert(teile, t.kraut == 1 and L.GATHER_HERB_ONE or string.format(L.GATHER_HERBS, t.kraut)) end
  local erz = t.erz + t.rest
  if erz > 0 then table.insert(teile, erz == 1 and L.GATHER_ORE_ONE or string.format(L.GATHER_ORE, erz)) end
  if (t.leder or 0) > 0 then
    table.insert(teile, t.leder == 1 and L.GATHER_LEATHER_ONE or string.format(L.GATHER_LEATHER, t.leder))
  end
  if #teile == 0 then return L.GATHER_NOTHING end
  local quellen = {}
  if knoten > 0 or koerper == 0 then
    table.insert(quellen, knoten == 1 and L.GATHER_NODE_ONE or string.format(L.GATHER_NODES, knoten))
  end
  if koerper > 0 then
    table.insert(quellen, koerper == 1 and L.GATHER_CREATURE_ONE or string.format(L.GATHER_CREATURES, koerper))
  end
  return string.format(L.GATHER_FROM, table.concat(teile, ", "), table.concat(quellen, L.GATHER_AND))
end

-- Laufende Sitzung mit Rate: Gegenstände und Wert pro Stunde. Unter 5 Minuten keine Rate.
-- knoten: Kräuter und Adern, koerper: gekürschnerte Kadaver, quellen: beides zusammen.
-- Das Sammelfenster fragt jede Sekunde: Die Summe (mit den Preisen) wird nur neu gerechnet, wenn
-- sich etwas geändert hat oder 30 Sekunden um sind, damit Hop & Seek wenig Leistung braucht.
function Z:Stand()
  local s = self:Sitzung()
  local schluessel = table.concat({ tostring(s), Z.stand, tostring(ns.db.preisQuelle), tostring(Z.MitPreisen()),
    math.floor(ns.jetzt() / 30) }, ":")
  local t = Z.summeSchluessel == schluessel and Z.summe
  if not t then
    t = Z.Summe(s.menge)
    Z.summe, Z.summeSchluessel = t, schluessel
  end
  t.proStunde, t.wertProStunde = nil, nil
  t.knoten = (s.knoten.kraut or 0) + (s.knoten.erz or 0)
  t.koerper = s.knoten.leder or 0
  t.quellen = t.knoten + t.koerper
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
ns.Ereignis("UNIT_SPELLCAST_SUCCEEDED", function(einheit, _, zauber)
  if einheit == "player" and KUERSCHNERN[zauber] then Z.gekuerschnert = ns.jetzt() end
end)
-- 1.2.2: Sitzungen, die eine Kiste gestartet hat (Patrick, 13. Nov: Ignis, Hexenmeister ohne
-- Sammelberuf, hatte nach einer Kiste mit Zinnerz eine Sitzung). Einmal je Char, ein paar Sekunden
-- nach dem Einloggen (vorher nennt Forever die Berufe nicht): Ohne Sammelberuf ist die Sitzung weg,
-- ohne Bilanz im Chat.
local function kistenSitzungWeg()
  if not (ns.db and ns.Berufe) then return end
  local k = Z.Char()
  ns.db.sitzungGeprueft = ns.db.sitzungGeprueft or {}
  if ns.db.sitzungGeprueft[k] then return end
  ns.db.sitzungGeprueft[k] = true
  local B = ns.Berufe
  B.Vergessen()
  if B.Hat("kraut") or B.Hat("erz") or B.Hat("leder") then return end
  local s = ns.db.sitzungen[k]
  if s and s.start then
    ns.db.sitzungen[k] = nil
    Z:Sitzung()
    ns.aktualisieren()
  end
end
ns.beimStart(function()
  if C_Timer and C_Timer.After then C_Timer.After(8, kistenSitzungWeg) end
end)

ns.beimStart(function()
  -- Bis 1.2.0 gab es eine Sitzung für den ganzen Account: weg damit, sie gehörte keinem Char
  ns.db.sitzung, ns.db.letzteSitzung = nil, nil
  -- Hat dieser Char in seiner Sitzung schon gekürschnert, ist er Kürschner (für die Lichtsäule)
  local s = ns.db.sitzungen[Z.Char()]
  if s and s.knoten and (s.knoten.leder or 0) > 0 then ns.db.kuerschner[Z.Char()] = true end
  Z:Sitzung()
end)
