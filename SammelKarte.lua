-- Sammelkarte: wo du schon Kräuter und Erz geholt hast, als Nadeln auf der Weltkarte (Vorschlag
-- vom 13. Nov, Patrick: „klingt gut“). Beim ersten Gegenstand eines Knotens merkt sich Hop & Seek
-- die eigene Position (Karten-ID und Lage auf der Karte). Stellen dicht beieinander werden zu einer
-- zusammengefasst, die Nadel wandert dabei zur Mitte. Die Nadel zeigt das Symbol des häufigsten
-- Funds, der Rand ist grün für Kräuter und braun für Erz. Rechtsklick entfernt eine Stelle.
-- Nur eigene Funde, accountweit, nichts wird gesendet. Wie bei Campfire Buddy hängen die Nadeln an
-- der Zeichenfläche der Weltkarte (kein Data Provider, der verursachte bei anderen Taint), mit
-- OpenMap über dessen Schnittstelle für andere Add-ons (OpenMapAPI, MIT).
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F = S.F

local K = { nadeln = {} }
ns.SammelKarte = K

K.NAH = 0.006          -- so nah (Anteil der Kartenbreite) gilt eine Stelle als dieselbe
K.MAX_JE_KARTE = 600   -- höchstens so viele Stellen je Karte, die am längsten unbesuchte fällt weg
K.GROESSE = 14
K.MAX_NADELN = 800     -- höchstens so viele Nadeln auf einmal (OpenMap zeigt viele Zonen)
K.RAND = { kraut = { 0.35, 0.85, 0.30 }, erz = { 0.85, 0.58, 0.30 } }

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

-- Weltlage je Stelle für OpenMap, einmal gerechnet (schwache Schlüssel: weg mit der Stelle)
local welt = setmetatable({}, { __mode = "k" })

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
    welt[beste] = nil
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
  self.geaendert = true
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

local function icon(id)
  return (id and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id))
    or (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(2383)) or 134400
end

local function tooltip(b)
  local e = b.eintrag
  if not e then return end
  GameTooltip:SetOwner(b, "ANCHOR_RIGHT")
  local h = haupt(e)
  local name = h and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(h)
  GameTooltip:SetText(name or (e.art == "kraut" and L.MAP_NODE_HERB or L.MAP_NODE_ORE), 1, 0.82, 0)
  local liste = {}
  for id, n in pairs(e.inhalt or {}) do table.insert(liste, { id = id, n = n }) end
  table.sort(liste, function(a, c) if a.n ~= c.n then return a.n > c.n end return a.id < c.id end)
  for i, d in ipairs(liste) do
    if i > 6 then break end
    local dn = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(d.id) or ("#" .. d.id)
    GameTooltip:AddDoubleLine("|T" .. tostring(icon(d.id)) .. ":14:14|t " .. dn, tostring(d.n), 1, 1, 1, 1, 1, 1)
  end
  local tag = date("%Y-%m-%d", e.zuletzt or 0)
  GameTooltip:AddLine(e.n == 1 and string.format(L.MAP_NODE_ONCE, tag) or string.format(L.MAP_NODE_TIMES, e.n, tag),
    F.leise[1], F.leise[2], F.leise[3])
  GameTooltip:AddLine(L.MAP_NODE_REMOVE, F.leise[1], F.leise[2], F.leise[3])
  GameTooltip:Show()
end

local function neueNadel(flaeche)
  local b = CreateFrame("Button", nil, flaeche)
  b:SetSize(K.GROESSE, K.GROESSE)
  b:RegisterForClicks("RightButtonUp")
  b.rand = b:CreateTexture(nil, "BACKGROUND")
  b.rand:SetPoint("TOPLEFT", -1, 1)
  b.rand:SetPoint("BOTTOMRIGHT", 1, -1)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b:SetScript("OnEnter", tooltip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(self)
    local liste = self.karte and ns.db.knotenKarte[self.karte]
    if not (liste and self.eintrag) then return end
    for i, e in ipairs(liste) do
      if e == self.eintrag then
        table.remove(liste, i)
        break
      end
    end
    GameTooltip:Hide()
    K:Zeichnen(true)
    ns.aktualisieren()
  end)
  return b
end

-- OpenMap mit zusammengesetzter Karte offen? Dann seine Schnittstelle, sonst nil
local function openMap()
  local api = OpenMapAPI
  if type(api) ~= "table" or not (api.IsStitched and api.WorldFromMap and api.MapFromWorld) then return nil end
  local ok, an = pcall(api.IsStitched)
  if ok and an then return api end
end

-- Ein Ort von Karte von nach Karte nach, über OpenMaps Weltlage (darf über 0 bis 1 hinausgehen:
-- OpenMap zeigt über den Rand der Karte hinaus die Nachbarzonen)
local function umrechnen(api, von, x, y, nach)
  local ok, u, v = pcall(api.WorldFromMap, von, x, y)
  if not ok or type(u) ~= "number" or type(v) ~= "number" then return nil end
  local ok2, nx, ny = pcall(api.MapFromWorld, nach, u, v)
  if not ok2 or type(nx) ~= "number" or type(ny) ~= "number" then return nil end
  return nx, ny
end

local function aufOpenMap(api, von, e, nach)
  local w = welt[e]
  if w == nil then
    local ok, u, v = pcall(api.WorldFromMap, von, e.x, e.y)
    w = (ok and type(u) == "number" and type(v) == "number") and { u, v } or false
    welt[e] = w
  end
  if not w then return nil end
  local ok, x, y = pcall(api.MapFromWorld, nach, w[1], w[2])
  if not ok or type(x) ~= "number" or type(y) ~= "number" then return nil end
  return x, y
end

local function sichtbar(x, y) return x and x > -1 and x < 2 and y > -1 and y < 2 end

-- Nadeln für die gerade gezeigte Karte. Neu nur, wenn sich Karte, Zoom, OpenMap oder die Stellen
-- geändert haben.
function K:Zeichnen(sofort)
  local wm = WorldMapFrame
  if not (wm and wm.GetCanvas and wm.GetMapID) then return end
  local ok, flaeche = pcall(wm.GetCanvas, wm)
  local ok2, karte = pcall(wm.GetMapID, wm)
  if not (ok and ok2 and flaeche and karte) then return end
  local skala = 1
  if wm.GetCanvasScale then
    local ok3, s = pcall(wm.GetCanvasScale, wm)
    if ok3 and type(s) == "number" and s > 0 then skala = s end
  end
  local om = openMap()
  if not sofort and not self.geaendert and karte == self.karte and skala == self.skala and (om ~= nil) == self.openMap then return end
  self.karte, self.skala, self.openMap, self.geaendert = karte, skala, om ~= nil, false

  -- Ohne OpenMap nur die Stellen dieser Karte. Mit zusammengesetzter Karte auch die der Nachbarn
  -- (deren Mitte liegt nahe genug, sonst ist es ein anderer Kontinent).
  local quellen = {}
  if ns.db and ns.db.karteZeigen then
    for k, liste in pairs(ns.db.knotenKarte) do
      if k == karte then
        table.insert(quellen, 1, { karte = k, liste = liste })
      elseif om and sichtbar(umrechnen(om, k, 0.5, 0.5, karte)) then
        table.insert(quellen, { karte = k, liste = liste })
      end
    end
  end
  local breite, hoehe = flaeche:GetWidth() or 0, flaeche:GetHeight() or 0
  local ebene = (flaeche:GetFrameLevel() or 1) + 800
  if om and om.ArtTopLevel then
    local okE, oben = pcall(om.ArtTopLevel)
    if okE and type(oben) == "number" then ebene = math.max(ebene, oben + 9) end
  end
  local n = 0
  for _, q in ipairs(quellen) do
    for _, e in ipairs(q.liste) do
      if n >= K.MAX_NADELN then break end
      local x, y = e.x, e.y
      if q.karte ~= karte then x, y = aufOpenMap(om, q.karte, e, karte) end
      if sichtbar(x, y) then
        n = n + 1
        local b = self.nadeln[n] or neueNadel(flaeche)
        self.nadeln[n] = b
        b.eintrag, b.karte = e, q.karte
        local farbe = K.RAND[e.art] or K.RAND.kraut
        b.rand:SetColorTexture(farbe[1], farbe[2], farbe[3], 0.9)
        b.icon:SetTexture(icon(haupt(e)))
        b:SetFrameLevel(ebene)
        b:SetScale(1 / skala)
        b:ClearAllPoints()
        b:SetPoint("CENTER", flaeche, "TOPLEFT", x * breite * skala, -y * hoehe * skala)
        b:Show()
      end
    end
  end
  for i = n + 1, #self.nadeln do
    self.nadeln[i].eintrag = nil
    self.nadeln[i]:Hide()
  end
  self.gezeigt = n
end

-- An die Weltkarte hängen, solange sie offen ist. Lädt das Spiel die Weltkarte erst später
-- (Blizzard_WorldMap), dann beim Laden.
local function anhaengen()
  if K.wache or not WorldMapFrame then return end
  local wache = CreateFrame("Frame", nil, WorldMapFrame)
  K.wache = wache
  local warten = 0
  wache:SetScript("OnUpdate", function(_, dt)
    warten = warten + (dt or 0)
    if warten < 0.1 then return end
    warten = 0
    K:Zeichnen(false)
  end)
  wache:SetScript("OnShow", function() K:Zeichnen(true) end)
end

ns.beimSammeln(function(id, menge, q, knotenArt) K:Beute(id, menge, q, knotenArt) end)
ns.Ereignis("LOOT_CLOSED", function() K.aktuell = nil end)
ns.Ereignis("ADDON_LOADED", function(name) if name == "Blizzard_WorldMap" then anhaengen() end end)
ns.beimStart(anhaengen)
ns.beimAktualisieren(function() K.geaendert = true end)

-- OpenMap: neu zeichnen, wenn sich die Ansicht bewegt, und ein Schalter in OpenMaps Menü
ns.beimStart(function()
  local api = OpenMapAPI
  if type(api) ~= "table" then return end
  if api.RegisterCallback then
    pcall(api.RegisterCallback, K, "OpenMap_ViewChanged", function() K:Zeichnen(true) end)
    pcall(api.RegisterCallback, K, "OpenMap_StitchedChanged", function() K:Zeichnen(true) end)
  end
  if api.RegisterMenuToggle then
    pcall(api.RegisterMenuToggle, "HopAndSeek", {
      id = "nodes", label = L.MAP_TOGGLE, icon = S.ICON,
      get = function() return ns.db and ns.db.karteZeigen end,
      set = function(an)
        if ns.db then
          ns.db.karteZeigen = an and true or false
          K:Zeichnen(true)
          ns.aktualisieren()
        end
      end,
    })
  end
end)
