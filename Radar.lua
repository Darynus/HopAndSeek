-- Radar (Patrick, 20. Nov: wie das alte Add-on „Farmer“, das es zu TBC gab): die Minikarte des Spiels
-- groß in der Bildschirmmitte um den Charakter, mit Norden, Osten, Süden und Westen am Rand. So sieht
-- man die echten Knoten des Spiels um sich herum und muss nicht nach oben rechts schauen.
-- Gelände weg (Patrick, 20. Nov: „Man möchte eigentlich nur noch die Notes sehen, Norden, Süden,
-- Westen“): Das Spiel kann den Boden der Minikarte weglassen und die Punkte trotzdem zeichnen
-- (C_Minimap.SetDrawGroundTextures, gebaut für die Ersatzkarte in Torghast). Kennt Forever das nicht,
-- bleibt die ganze Karte blass wie in der ersten Fassung (FarmHud, das wir dafür gelesen haben, ohne
-- Code zu übernehmen, schreibt: Gelände und Punkte zeichnet die Minikarte in einem Stück). Für den
-- Fall gibt es /hop radar test: eine durchsichtige Maske. Ob die Punkte dann bleiben, zeigt nur das Spiel.
-- Namen (Patrick: „mit der Maus auf die Notes geht, kann man nicht sehen, was es ist“): Die Tooltips
-- der Punkte zeichnet das Spiel, aber nur, wenn die Minikarte die Maus annimmt. Solange Alt gedrückt
-- ist, nimmt das Radar die Maus an, sonst gehen Klicks durch in die Welt.
-- Bekannte Stellen (Patrick: „wie viel Meter ist das noch entfernt ... oder Estimated Time to
-- Arrive“): Die Punkte des Spiels kann kein Add-on beschriften, die gemerkten Stellen der Sammelkarte
-- schon. Jede in Reichweite bekommt eine Klammer mit Entfernung und Zeit bis dorthin, mit dem Tempo,
-- mit dem man gerade läuft oder reitet. Ein Punkt in der Klammer: Der Knoten steht. Eine leere
-- Klammer: abgeerntet oder noch nicht nachgewachsen. Frisch gesammelt (unter 10 Minuten): blass.
-- In der Klammer das Symbol dessen, was dort meist wächst (Patrick: „das Icon der Blume drin ... so wie
-- das andere Add-on“), unter der Minikarte, damit der Punkt des Spiels darüber sichtbar bleibt. Die
-- Farbe der Klammer sagt wie im Spiel, ob es noch Punkte gibt (orange, gelb, grün, grau, rot).
-- Namen ohne Alt (Patrick, 20. Nov: „wird mir leider nicht angezeigt, was das für ein Kraut ist. Man
-- sieht einfach nur den gelben Punkt“): Zeigt die Maus auf eine Klammer, steht ihr Name daneben. Dafür
-- braucht das Radar die Maus nicht, es rechnet nur, wo der Zeiger steht. Für Punkte ohne Klammer bleibt
-- Alt, der Hinweis darauf steht unter dem Radar, bis das Spiel einmal einen Namen gezeigt hat.
-- Pfeil (Patrick, 20. Nov: „so einen Pfeil wie bei Rested XP ... der einen immer den direkten Weg zur
-- Node anzeigt“): nur im Radar, ein goldener Pfeil am Char und eine Punktlinie, die gerade Linie ohne
-- Wegfindung. Seit dem 21. Nov auf Abruf: Alt und Klick auf einen Punkt (siehe R:MausKlick). Der Pfeil
-- zur nächsten gemerkten Stelle hat geraten und Patrick im Kreis geführt.
-- Technik: Die Minikarte wandert in den Rahmen des Radars (SetParent, Größe, Ebene, Zoom ganz weit).
-- Ihre Kinder (Knöpfe anderer Add-ons, Zoom, Uhr) und Rahmen, die an ihr hängen, kommen solange auf einen
-- Platzhalter an ihrer alten Stelle. Maus und Mausrad sind aus. Drehen mit der Blickrichtung über die
-- Einstellung des Spiels (rotateMinimap), nach Wunsch. Im Kampf wird alles blass.
-- Beim Ausschalten und beim Ausloggen kommt alles zurück, wie es war.
-- Umbauen nur außerhalb des Kampfes (die Minikarte kann geschützte Knöpfe tragen), sonst danach.
-- Nur Anzeige: nichts wird angeklickt, gezaubert oder gesendet.
local ADDON, ns = ...
local L = ns.L

local R = { an = false }
ns.Radar = R

R.KAMPF_ANTEIL = 0.25          -- im Kampf: so viel bleibt vom Radar
R.DECKKRAFT_OHNE_BODEN = 0.9   -- ohne Gelände: die Punkte fast voll, es verdeckt ja nichts mehr
R.ZIELE_MAX = 30               -- höchstens so viele Klammern, die nächsten zuerst
R.TASTE = "CLICK HopAndSeekRadar:LeftButton"
R.MASKE_LEER = "Interface\\AddOns\\HopAndSeek\\Media\\RadarLeer"
R.ZIEL_TEXTUR = "Interface\\AddOns\\HopAndSeek\\Media\\RadarZiel"
R.PFEIL_TEXTUR = "Interface\\AddOns\\HopAndSeek\\Media\\RadarPfeil"
R.PUNKT_TEXTUR = "Interface\\AddOns\\HopAndSeek\\Media\\Kreis"
-- Farbe der Klammern: nach der Stufe wie im Spiel (Berufe.Schwierigkeit), weiß, solange sie unbekannt ist
R.FARBE_UNBEKANNT = { 0.85, 0.85, 0.85 }
R.FARBE_PFEIL = { 1, 0.82, 0.25 }  -- Gold wie N, O, S, W
R.HINWEIS_DAUER = 15           -- Sekunden: so lange steht der Hinweis auf Alt unter dem Radar
R.ZEIGEN_NAH = 12              -- Bildpunkte: so nah an einer Klammer zeigt die Maus ihren Namen
R.PFEIL_ABSTAND = 56           -- Bildpunkte vom Char bis zum Pfeil (näher, wenn die Stelle nah ist)
R.ANGEKOMMEN = 8               -- Meter: so nah am Ziel des Pfeils gilt es als erreicht
R.PUNKTE_ABSTAND = 10          -- Bildpunkte zwischen den Punkten der Linie zur Stelle
R.PUNKTE_MAX = 30
-- Rahmen, die an der Minikarte hängen, ohne ihre Kinder zu sein (je nach Version des Spiels)
local ANGEHAENGT = { "MinimapBackdrop", "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture", "MinimapZoomIn",
  "MinimapZoomOut", "MiniMapTracking", "MiniMapTrackingFrame", "MiniMapMailFrame", "MinimapZoneTextButton",
  "GameTimeFrame", "TimeManagerClockButton", "MiniMapWorldMapButton", "MinimapToggleButton",
  "MiniMapBattlefieldFrame", "MiniMapLFGFrame", "QueueStatusMinimapButton", "MiniMapInstanceDifficulty" }
-- Richtungen am Rand: Winkel wie GetPlayerFacing (0 Norden, gegen den Uhrzeigersinn, Westen pi/2)
local RICHTUNGEN = { { "RADAR_N", 0 }, { "RADAR_W", math.pi / 2 }, { "RADAR_S", math.pi }, { "RADAR_E", -math.pi / 2 } }
-- Durchmesser der Minikarte in Metern je Zoomstufe, draußen und drinnen (wie im Spiel)
local DRAUSSEN = { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 }
local DRINNEN = { [0] = 300, 240, 180, 120, 80, 50 }
local atan2 = math.atan2 or math.atan

local function imKampf() return InCombatLockdown and InCombatLockdown() end
local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end
local function zahl(v) return type(v) == "number" and not geheim(v) end
local function zeit() return (GetServerTime and GetServerTime()) or time() end

local function cvar(name)
  if C_CVar and C_CVar.GetCVar then
    local ok, w = pcall(C_CVar.GetCVar, name)
    if ok then return w end
  end
  if GetCVar then
    local ok, w = pcall(GetCVar, name)
    if ok then return w end
  end
end

local function cvarSetzen(name, wert)
  local ok
  if C_CVar and C_CVar.SetCVar then ok = pcall(C_CVar.SetCVar, name, wert)
  elseif SetCVar then ok = pcall(SetCVar, name, wert) end
  if Minimap_UpdateRotationSetting then pcall(Minimap_UpdateRotationSetting) end
  return ok
end

-- Ruft eine Methode geschützt auf, Rückgabe wie pcall ohne das erste true
local function rufe(obj, methode, ...)
  if not (obj and obj[methode]) then return nil end
  local erg = { pcall(obj[methode], obj, ...) }
  if not erg[1] then return nil end
  return unpack(erg, 2)
end

local function punkte(obj)
  local t = {}
  for i = 1, (rufe(obj, "GetNumPoints") or 0) do
    t[i] = { rufe(obj, "GetPoint", i) }
  end
  return t
end

-- Punkte neu setzen; Bezüge auf "von" zeigen danach auf "nach"
local function punkteSetzen(obj, liste, von, nach)
  rufe(obj, "ClearAllPoints")
  for _, p in ipairs(liste) do
    local rel = p[2]
    if von and rel == von then rel = nach end
    rufe(obj, "SetPoint", p[1], rel, p[3], p[4], p[5])
  end
end

-- Gelände der Minikarte ----------------------------------------------------------------------

-- Kann das Spiel den Boden weglassen? Erst C_Minimap, sonst als Methode der Minikarte.
local function funktion(t, name) return t ~= nil and type(t[name]) == "function" end

function R.BodenMoeglich()
  return funktion(C_Minimap, "SetDrawGroundTextures") or funktion(Minimap, "SetDrawGroundTextures")
end

local function bodenSetzen(an)
  if funktion(C_Minimap, "SetDrawGroundTextures") then return (pcall(C_Minimap.SetDrawGroundTextures, an)) end
  if funktion(Minimap, "SetDrawGroundTextures") then return (pcall(Minimap.SetDrawGroundTextures, Minimap, an)) end
  return false
end

-- Zeichnet das Spiel den Boden gerade? nil: unbekannt
local function bodenLesen()
  local ok, w
  if funktion(C_Minimap, "GetDrawGroundTextures") then ok, w = pcall(C_Minimap.GetDrawGroundTextures)
  elseif funktion(Minimap, "GetDrawGroundTextures") then ok, w = pcall(Minimap.GetDrawGroundTextures, Minimap) end
  if ok and type(w) == "boolean" then return w end
end

-- Deckkraft der Minikarte im Radar: im Test voll, ohne Gelände fast voll, sonst wie eingestellt
local function deckkraft()
  if R.maskeTest then return 1 end
  if R.ohneBoden then return R.DECKKRAFT_OHNE_BODEN end
  return ns.db.radarDeckkraft or 0.6
end

-- Maske der Minikarte: Wer sie setzt (das Spiel, ein Add-on für eckige Karten), merken wir uns, damit
-- der Test sie zurückgeben kann. War sie vorher schon gesetzt: nach der Form der Karte.
if Minimap and Minimap.SetMaskTexture and hooksecurefunc then
  hooksecurefunc(Minimap, "SetMaskTexture", function(_, textur)
    if not R.eigeneMaske then R.maske = textur end
  end)
end

local function maskeSetzen(textur)
  R.eigeneMaske = true
  rufe(Minimap, "SetMaskTexture", textur)
  R.eigeneMaske = nil
end

local function maskeZurueck()
  local form = GetMinimapShape and select(2, pcall(GetMinimapShape))
  maskeSetzen(R.maske or (form == "SQUARE" and "Interface\\Buttons\\WHITE8X8") or "Textures\\MinimapMask")
end

-- Hilfen für die Klammern -------------------------------------------------------------------

-- Halbmesser der Minikarte in Metern: vom Spiel (C_Minimap.GetViewRadius), sonst aus der Zoomstufe
function R.SichtRadius()
  if C_Minimap and C_Minimap.GetViewRadius then
    local ok, r = pcall(C_Minimap.GetViewRadius)
    if ok and zahl(r) and r > 0 then return r end
  end
  local zoom = rufe(Minimap, "GetZoom")
  local d = type(zoom) == "number" and ((IsIndoors and IsIndoors()) and DRINNEN or DRAUSSEN)[zoom]
  return (d or DRAUSSEN[0]) / 2
end

-- Blickrichtung, wenn das Radar mitdreht (0 ohne Drehen). nil: dreht, aber das Spiel nennt sie nicht.
local function blick()
  if not R.dreht then return 0 end
  if not GetPlayerFacing then return nil end
  local ok, b = pcall(GetPlayerFacing)
  if ok and zahl(b) then return b end
end

-- Tempo in Metern pro Sekunde: so schnell, wie man gerade läuft oder reitet; im Stehen das Lauftempo
local function tempo()
  if not GetUnitSpeed then return nil end
  local ok, jetzt, lauf = pcall(GetUnitSpeed, "player")
  if not ok then return nil end
  if zahl(jetzt) and jetzt > 0.5 then return jetzt end
  if zahl(lauf) and lauf > 0.5 then return lauf end
end

function R.DauerText(s)
  s = math.floor(s + 0.5)
  if s < 60 then return string.format(L.RADAR_SECONDS, s) end
  return string.format(L.RADAR_MINUTES, math.floor(s / 60), s % 60)
end

-- Dreht sich die Minikarte des Spiels mit dem Blick? (Einstellung rotateMinimap; MiniKarte.lua)
function R.MinikarteDreht() return cvar("rotateMinimap") == "1" end

-- Lage einer Stelle auf einer runden Karte um den Char: Bildpunkte vom Mittelpunkt (x nach rechts,
-- y nach oben), Meter und Winkel auf dem Bildschirm (0 oben, gegen den Uhrzeigersinn). b: Drehung der
-- Karte (Blickrichtung oder 0), g: Größe der Karte in Metern, skala: Bildpunkte je Meter.
function R.Lage(e, px, py, g, b, skala)
  local ost, nord = (e.x - px) * g[1], (py - e.y) * g[2]
  local d = math.sqrt(ost * ost + nord * nord)
  local w = atan2(-ost, nord) - b
  return -math.sin(w) * d * skala, math.cos(w) * d * skala, d, w
end

-- Wo steht der Mauszeiger, gemessen vom Mittelpunkt des Rahmens f (in dessen Bildpunkten)? nil beim
-- Umsehen mit gedrückter Maustaste, dann ist der Zeiger weg.
function R.MausAuf(f)
  if not (f and GetCursorPosition) or (IsMouselooking and IsMouselooking()) then return nil end
  local mx, my = GetCursorPosition()
  local fx, fy = f:GetCenter()
  local s = f:GetEffectiveScale()
  if not (zahl(mx) and zahl(my) and fx and fy and s and s > 0) then return nil end
  return mx / s - fx, my / s - fy
end

-- Name dessen, was an einer Stelle meist wächst, in der Sprache des Spiels; sonst der Name aus dem
-- Tooltip, mit dem das Radar die Stelle gelernt hat
function R.Name(k)
  local n = k.id and C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(k.id)
  if type(n) == "string" and n ~= "" and not geheim(n) then return n end
  return k.e and k.e.name
end

-- Rahmen --------------------------------------------------------------------------------------

local function rahmenBauen()
  if R.rahmen then return R.rahmen end
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetFrameStrata("BACKGROUND")
  f:SetFrameLevel(1)
  f:SetPoint("CENTER")
  if f.EnableMouse then f:EnableMouse(false) end
  f:Hide()
  -- Ebenen: der Rahmen selbst (Stufe 1) trägt die Symbole der Stellen, darüber die Minikarte (3) mit den
  -- Punkten des Spiels, darüber (8) Richtungen, Klammern und Schrift. Nichts davon nimmt die Maus an.
  local o = CreateFrame("Frame", nil, f)
  o:SetAllPoints(f)
  if o.EnableMouse then o:EnableMouse(false) end
  o.ziele = {}
  f.oben = o
  -- Hinweis unter dem Radar, bis Alt einmal benutzt wurde
  f.hinweis = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.hinweis:SetText(L.RADAR_ALT_HINT)
  f.hinweis:Hide()
  f.richtung = {}
  for i, r in ipairs(RICHTUNGEN) do
    local t = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetText(L[r[1]])
    t:SetTextColor(1, 0.82, 0.25, 0.9)
    f.richtung[i] = { text = t, winkel = r[2] }
  end
  -- Pfeil zur nächsten Stelle und die Punkte der Linie dorthin
  local c = R.FARBE_PFEIL
  f.pfeil = o:CreateTexture(nil, "OVERLAY")
  f.pfeil:SetTexture(R.PFEIL_TEXTUR)
  f.pfeil:SetSize(26, 26)
  f.pfeil:SetVertexColor(c[1], c[2], c[3])
  f.pfeil:Hide()
  f.punkte = {}
  f.zielKlammer = o:CreateTexture(nil, "ARTWORK")
  f.zielKlammer:SetTexture(R.ZIEL_TEXTUR)
  f.zielKlammer:SetSize(28, 28)
  f.zielKlammer:SetVertexColor(c[1], c[2], c[3])
  f.zielKlammer:Hide()
  f.zielText = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  f.zielText:SetTextColor(c[1], c[2], c[3])
  f.zielText:Hide()
  -- Jedes Bild: Richtungen und Klammern mitdrehen; welche Stellen in Reichweite sind, alle halbe Sekunde
  f:SetScript("OnUpdate", function(_, dt)
    local ok, fehler = pcall(R.Bild, R, dt)
    if not ok and not R.fehlerGemeldet then
      R.fehlerGemeldet = true
      ns.melde(string.format(L.ERR_EVENT, "Radar", tostring(fehler)))
    end
  end)
  R.rahmen = f
  return f
end

function R:Bild(dt)
  self:Richtungen()
  local f = self.rahmen
  local h = f.hinweis
  if h:IsShown() and (ns.db.radarNamenGesehen or ns.jetzt() > (self.hinweisBis or 0)) then h:Hide() end
  -- Mit Alt: Hat das Spiel einen Namen gezeigt, braucht es den Hinweis nicht mehr
  if self.maus and self:TooltipLesen(f, (f.durchmesser or 300) / 2, blick()) then ns.db.radarNamenGesehen = true end
  self.suchen = (self.suchen or 0) - (dt or 0)
  if self.suchen <= 0 then
    self.suchen = 0.5
    self:StellenSuchen()
  end
  self:Ziele()
end

function R:Richtungen()
  local f = self.rahmen
  if not (f and f:IsShown()) then return end
  local r = (f.durchmesser or 300) / 2 + 14
  local b = blick() or 0
  for _, e in ipairs(f.richtung) do
    local w = e.winkel - b
    e.text:ClearAllPoints()
    e.text:SetPoint("CENTER", f.oben, "CENTER", -math.sin(w) * r, math.cos(w) * r)
  end
end

-- Welche gemerkten Stellen liegen im Umkreis (Meter) um den Char? Die nächsten zuerst, höchstens max
-- (sonst ZIELE_MAX), nur Arten, deren Beruf der Char hat. Bis zu 600 je Karte, deshalb fragen Radar
-- und Minikarte nur alle halbe Sekunde, mit etwas Rand für den Weg bis zum nächsten Mal.
-- Rückgabe: Liste { e, d, id, icon, farbe, stufe }, Karte, Größe der Karte
function R.Stellen(radius, max)
  local K = ns.SammelKarte
  local karte, px, py = K.Position()
  local g = karte and K.Groesse(karte)
  local liste = karte and ns.db.knotenKarte[karte]
  local kandidaten = {}
  if not (g and liste) then return kandidaten, karte, g end
  local passt = K.Arten()
  for _, e in ipairs(liste) do
    if passt[e.art] then
      local ost, nord = (e.x - px) * g[1], (py - e.y) * g[2]
      local d = ost * ost + nord * nord
      if d <= radius * radius then kandidaten[#kandidaten + 1] = { e = e, d = d } end
    end
  end
  table.sort(kandidaten, function(a, b) return a.d < b.d end)
  for i = #kandidaten, (max or R.ZIELE_MAX) + 1, -1 do kandidaten[i] = nil end
  -- Was wächst dort meist, und gibt es dafür noch Punkte? Stellen, die nur das Radar kennt (noch nie
  -- dort gesammelt), haben ihren Fund aus dem Tooltip.
  local B = ns.Berufe
  for _, k in ipairs(kandidaten) do
    local id = K.Haupt(k.e) or k.e.fund
    k.id = id
    if id and C_Item and C_Item.GetItemIconByID then
      local ok, icon = pcall(C_Item.GetItemIconByID, id)
      if ok and icon then k.icon = icon end
    end
    local fund = B and (B.KnotenFund(k.e) or (k.e.fund and B.STUFE[k.e.fund] and k.e.fund))
    local stufe = B and B.Schwierigkeit(k.e.art, fund)
    k.farbe = stufe and B.FARBEN[stufe] or R.FARBE_UNBEKANNT
    k.stufe = stufe
  end
  return kandidaten, karte, g
end

function R:StellenSuchen()
  self.kandidaten, self.karte, self.groesse = R.Stellen(R.SichtRadius() + 60)
end

local function ziel(i)
  local o = R.rahmen.oben
  local z = o.ziele[i]
  if z then return z end
  z = {}
  z.t = o:CreateTexture(nil, "ARTWORK")
  z.t:SetTexture(R.ZIEL_TEXTUR)
  z.t:SetSize(22, 22)
  z.s = o:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  z.s:SetPoint("TOP", z.t, "BOTTOM", 0, 1)
  -- Symbol auf dem Rahmen unter der Minikarte: der Punkt des Spiels liegt darüber
  z.i = R.rahmen:CreateTexture(nil, "ARTWORK")
  z.i:SetSize(14, 14)
  z.i:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  o.ziele[i] = z
  return z
end

-- Pfeil auf Abruf (Patrick, 21. Nov, über den Pfeil zur nächsten Stelle: „der hat mich da auch im Kreis
-- geführt, nur weil es die nächste Node war, und das war ein Endlosloop“). Forever verrät Add-ons nicht,
-- wo seine Punkte liegen (MapUtils hat das Abtasten der Minikarte für Forever abgeschaltet: „the game no
-- longer allows scanning the minimap“). Ein Pfeil zur nächsten gemerkten Stelle rät also und zeigt oft
-- auf leere. Jetzt wählt der Spieler das Ziel: Alt halten und auf einen Punkt im Radar klicken. Liegt
-- dort eine Klammer, gilt ihre Stelle mit Namen, sonst genau der Ort des Klicks. Angekommen (unter 8
-- Metern), mit Alt und Rechtsklick oder beim Ausschalten ist das Ziel weg.

-- Klick auf die Minikarte im Radar (sie nimmt die Maus nur mit Alt an): Linksklick setzt das Ziel,
-- Rechtsklick löscht es. Gepingt wird dabei nicht, sonst sähe die Gruppe jeden Klick. Ist der Pfeil im
-- Fenster ausgeschaltet, macht der Klick, was er im Spiel immer macht.
function R:MausKlick(minikarte, taste)
  if not (self.an and ns.db.radarPfeil) then
    local alt = self.stand and self.stand.klick
    if alt then alt(minikarte, taste) end
    return
  end
  if taste == "RightButton" then
    self.ziel = nil
    return
  end
  local f = self.rahmen
  local karte, x, y, r = self:PunktUnterMaus(f, (f.durchmesser or 300) / 2, blick())
  if not karte or r > R.SichtRadius() then return end
  -- Eine Klammer unter dem Zeiger, oder eine gemerkte Stelle gleich daneben (etwa eben mit Alt gelernt)
  local e = self.zeigt and self.zeigt.e
  if not e then
    local nah = ns.SammelKarte.NAH
    local abstand
    for _, s in ipairs(ns.db.knotenKarte[karte] or {}) do
      local d = (s.x - x) * (s.x - x) + (s.y - y) * (s.y - y)
      if d <= nah * nah and (not abstand or d < abstand) then e, abstand = s, d end
    end
  end
  self.ziel = { karte = karte, x = e and e.x or x, y = e and e.y or y, e = e }
  if ns.Stil and ns.Stil.klick then ns.Stil.klick() end
end

-- Pfeil am Char in Richtung des Ziels, dazu Punkte bis kurz davor: der gerade Weg. bis: Bildpunkte bis
-- zum Ziel oder bis zum Rand des Radars.
local function pfeilSetzen(f, w, bis)
  local punkte = f.punkte
  local n = 0
  if w then
    local sx, sy = -math.sin(w), math.cos(w)
    -- Nah am Ziel rückt der Pfeil an den Char, damit er nicht über die Klammer hinausragt
    local r = math.max(18, math.min(R.PFEIL_ABSTAND, bis - 26))
    f.pfeil:ClearAllPoints()
    f.pfeil:SetPoint("CENTER", f.oben, "CENTER", sx * r, sy * r)
    if f.pfeil.SetRotation then f.pfeil:SetRotation(w) end
    f.pfeil:Show()
    local c = R.FARBE_PFEIL
    local a = r + 18
    while a < bis - 16 and n < R.PUNKTE_MAX do
      n = n + 1
      local t = punkte[n]
      if not t then
        t = f.oben:CreateTexture(nil, "ARTWORK")
        t:SetTexture(R.PUNKT_TEXTUR)
        t:SetSize(4, 4)
        t:SetVertexColor(c[1], c[2], c[3])
        t:SetAlpha(0.7)
        punkte[n] = t
      end
      t:ClearAllPoints()
      t:SetPoint("CENTER", f.oben, "CENTER", sx * a, sy * a)
      t:Show()
      a = a + R.PUNKTE_ABSTAND
    end
  else
    f.pfeil:Hide()
  end
  for i = n + 1, #punkte do punkte[i]:Hide() end
end

-- Meter und Zeit, mit Namen davor, wenn er bekannt ist
local function beschriftung(name, d, v)
  local teile = {}
  if name then teile[1] = name end
  if d >= 10 then
    local text = string.format(L.RADAR_YARDS, math.floor(d + 0.5))
    if v then text = text .. "  " .. R.DauerText(d / v) end
    teile[#teile + 1] = text
  end
  return table.concat(teile, "  ")
end

-- Klammern setzen, jedes Bild: Lage auf dem Radar (gedreht wie die Minikarte), Entfernung, Zeit. Zeigt
-- die Maus auf eine Klammer, steht ihr Name davor. Das Ziel des Pfeils hat seinen Namen immer, in Gold,
-- und eine größere Klammer; ein Ziel ohne gemerkte Stelle bekommt eine eigene goldene Klammer.
function R:Ziele()
  local f = self.rahmen
  local o = f.oben
  local karte, px, py = ns.SammelKarte.Position()
  local b = blick()
  local radius = R.SichtRadius()
  local skala = (f.durchmesser or 300) / 2 / radius
  local sichtbar = {}
  if self.kandidaten and karte and karte == self.karte and self.groesse and b then
    local jetzt = zeit()
    for _, k in ipairs(self.kandidaten) do
      local x, y, d, w = R.Lage(k.e, px, py, self.groesse, b, skala)
      if d <= radius * 0.96 then
        k.x, k.y, k.dist, k.winkel = x, y, d, w
        k.frisch = k.e.zuletzt ~= nil and jetzt - k.e.zuletzt < ns.SammelKarte.NACHWACHSEN
        sichtbar[#sichtbar + 1] = k
      end
    end
  end
  -- Unter der Maus: die Klammer, die dem Zeiger am nächsten ist, wenn er nah genug ist
  local zeig
  if #sichtbar > 0 then
    local mx, my = R.MausAuf(f)
    if mx then
      local best = R.ZEIGEN_NAH * R.ZEIGEN_NAH
      for _, k in ipairs(sichtbar) do
        local dx, dy = k.x - mx, k.y - my
        if dx * dx + dy * dy <= best then zeig, best = k, dx * dx + dy * dy end
      end
    end
  end
  -- Ziel des Pfeils: auf einer anderen Karte weg, angekommen weg
  local pfeilZiel = ns.db.radarPfeil and self.ziel or nil
  local zx, zy, zd, zw
  if pfeilZiel and karte and karte ~= pfeilZiel.karte then
    self.ziel, pfeilZiel = nil, nil
  elseif pfeilZiel and karte and b then
    local g = ns.SammelKarte.Groesse(pfeilZiel.karte)
    if g then
      zx, zy, zd, zw = R.Lage(pfeilZiel, px, py, g, b, skala)
      if zd < R.ANGEKOMMEN then self.ziel, pfeilZiel, zd = nil, nil, nil end
    end
  end
  local v = tempo()
  local gold = R.FARBE_PFEIL
  local zielSichtbar = false
  for i, k in ipairs(sichtbar) do
    local z = ziel(i)
    local c = k.farbe or R.FARBE_UNBEKANNT
    local alpha = k.frisch and 0.35 or 0.9
    local gross = zd ~= nil and pfeilZiel.e ~= nil and k.e == pfeilZiel.e
    if gross then zielSichtbar = true end
    z.t:ClearAllPoints()
    z.t:SetPoint("CENTER", o, "CENTER", k.x, k.y)
    z.t:SetSize(gross and 28 or 22, gross and 28 or 22)
    z.t:SetVertexColor(c[1], c[2], c[3])
    z.t:SetAlpha(gross and 1 or alpha)
    z.t:Show()
    if k.icon then
      z.i:SetTexture(k.icon)
      z.i:ClearAllPoints()
      z.i:SetPoint("CENTER", f, "CENTER", k.x, k.y)
      z.i:SetAlpha(alpha)
      z.i:Show()
    else
      z.i:Hide()
    end
    local name = (gross or k == zeig) and R.Name(k) or nil
    local text = beschriftung(name, k.dist, v)
    if text ~= "" then
      z.s:SetText(text)
      if gross then z.s:SetTextColor(gold[1], gold[2], gold[3]) else z.s:SetTextColor(1, 1, 1) end
      z.s:SetAlpha(name and 1 or alpha)
      z.s:Show()
    else
      z.s:Hide()
    end
  end
  for i = #sichtbar + 1, #o.ziele do
    o.ziele[i].t:Hide()
    o.ziele[i].s:Hide()
    o.ziele[i].i:Hide()
  end
  -- Ziel ohne sichtbare Klammer: eigene goldene Klammer; jenseits des Rands nur Pfeil, Linie und Meter
  local rand = (f.durchmesser or 300) / 2 - 20
  local bis = zd and math.min(zd * skala, rand) or nil
  local zk, zt = f.zielKlammer, f.zielText
  if zd and not zielSichtbar then
    local e = pfeilZiel.e
    local name = e and R.Name({ e = e, id = ns.SammelKarte.Haupt(e) or e.fund }) or nil
    zt:SetText(beschriftung(name, zd, v))
    zt:ClearAllPoints()
    if zd <= radius * 0.96 then
      zk:ClearAllPoints()
      zk:SetPoint("CENTER", o, "CENTER", zx, zy)
      zk:Show()
      zt:SetPoint("TOP", zk, "BOTTOM", 0, 1)
    else
      zk:Hide()
      zt:SetPoint("CENTER", o, "CENTER", -math.sin(zw) * rand, math.cos(zw) * rand)
    end
    zt:Show()
  else
    zk:Hide()
    zt:Hide()
  end
  pfeilSetzen(f, zd and zw or nil, bis)
  self.anzahlZiele = #sichtbar
  self.zeigt = zeig
  self.zielDist = zd
end

-- Neue Punkte lernen ----------------------------------------------------------------------------
-- Mit Alt zeigt das Spiel den Namen eines Punkts. Ist es ein Kraut oder eine Ader und kennt Hop & Seek
-- dort noch keine Stelle, merkt es sie sich, wo die Maus steht (auf ein paar Meter genau): ab jetzt mit
-- Klammer, Metern und Zeit. Kräuter heißen wie ihr Kraut (Name des Gegenstands vom Spiel, in jeder
-- Sprache), Adern kennt Hop & Seek über die Zielhilfe (SammelKarte, knotenNamen). Keine Namen im Code.

-- Name im Tooltip: Art und Fund (Gegenstand) oder nil
local krautNamen
local function knotenNachName(name)
  local obj = ns.db.knotenNamen[name]
  if obj then
    local art = ns.db.knotenObjekte[obj] or (ns.Lichtsaeule and ns.Lichtsaeule.OBJEKTE[obj])
    local funde = ns.db.objektFunde[obj]
    if art == "kraut" or art == "erz" then return art, funde and ns.Berufe.KnotenFund({ inhalt = funde }) end
  end
  if not krautNamen or not krautNamen.fertig then
    krautNamen = { fertig = true }
    local buch = ns.Erfolge and ns.Erfolge.BUCH
    for _, gruppe in ipairs(buch or {}) do
      if gruppe.schluessel == "kraut" then
        for _, id in ipairs(gruppe.ids) do
          local n = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
          if n then krautNamen[n] = id else krautNamen.fertig = false end
        end
      end
    end
  end
  local id = krautNamen[name]
  if id and id ~= true then return "kraut", id end
end
R.KnotenNachName = knotenNachName

local function sauber(text)
  text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
  text = string.gsub(text, "|r", "")
  text = string.gsub(text, "|T.-|t", "")
  return (string.match(text, "^%s*(.-)%s*$"))
end

-- Wo auf der Karte liegt der Punkt unter der Maus? f: Rahmen, dessen Mitte der Char ist, halb: halber
-- Durchmesser der Karte in Bildpunkten, b: Drehung (Blickrichtung oder 0). Karte, x, y, Meter vom Char;
-- nil ohne Kartengröße, Drehung oder Mauszeiger.
function R:PunktUnterMaus(f, halb, b)
  local K = ns.SammelKarte
  local karte, px, py = K.Position()
  local g = karte and K.Groesse(karte)
  if not (g and b and halb and halb > 0) then return nil end
  local sx, sy = R.MausAuf(f)
  if not sx then return nil end
  local skala = halb / R.SichtRadius()
  local r = math.sqrt(sx * sx + sy * sy) / skala
  local w = atan2(-sx, sy) + b
  return karte, px + (-math.sin(w) * r) / g[1], py - (math.cos(w) * r) / g[2], r
end

-- Zeigt das Spiel gerade den Tooltip eines Punkts der Minikarte, und steht darin ein Kraut oder eine
-- Ader, die Hop & Seek dort noch nicht kennt? Im Radar jedes Bild, solange Alt gedrückt ist, auf der
-- Minikarte in der Ecke immer (MiniKarte.lua). f, halb, b wie bei PunktUnterMaus.
-- Rückgabe: true, solange ein solcher Tooltip mit Text zu sehen ist.
function R:TooltipLesen(f, halb, b)
  local tt = GameTooltip
  if not (tt and tt:IsShown() and (rufe(tt, "GetOwner") == Minimap or rufe(Minimap, "IsMouseOver"))) then
    self.letzterTooltip = nil
    return false
  end
  local zeilen = {}
  for i = 1, (rufe(tt, "NumLines") or 0) do
    local z = _G["GameTooltipTextLeft" .. i]
    local text = z and z.GetText and z:GetText()
    if type(text) == "string" and not geheim(text) then zeilen[#zeilen + 1] = text end
  end
  local alles = table.concat(zeilen, "\n")
  if alles == "" then return false end
  if alles == self.letzterTooltip then return true end
  self.letzterTooltip = alles
  local karte, x, y, r = self:PunktUnterMaus(f, halb, b)
  if not karte or r > R.SichtRadius() then return true end
  for teil in string.gmatch(alles, "[^\n]+") do
    local name = sauber(teil)
    local art, fund = knotenNachName(name)
    if art and ns.SammelKarte:Gesehen(karte, x, y, art, name, fund) then
      ns.melde(string.format(L.RADAR_LEARNED, name))
      self.suchen = 0
      if ns.MiniKarte then ns.MiniKarte.suchen = 0 end
    end
  end
  return true
end

-- Umbau -------------------------------------------------------------------------------------

-- Was bleibt an der Minikarte und kommt mit ins Radar? Symbole anderer Add-ons, die Orte auf der Karte
-- zeigen: Pins über HereBeDragons (Zygor, Questie, Spy), Rahmen mit "Pin" im Namen und Ebenen ohne Namen
-- (Mastercraft, Blackthornes Farmer zeichnen ihre Symbole darauf). Sie rechnen mit der Größe der Minikarte
-- und stehen im Radar an der richtigen Stelle. Alles andere (Knöpfe am Rand, Zoom, Uhr, Post) kommt auf
-- den Platzhalter in der Ecke.
local function bleibt(obj, hbd)
  if obj.hopRadarBleibt or (hbd and hbd[obj]) then return true end
  local typ = rufe(obj, "GetObjectType")
  if typ == "Line" then return true end
  local name = rufe(obj, "GetName")
  if type(name) == "string" and string.find(name, "[Pp]in") then return true end
  return typ == "Frame" and name == nil
end

-- Maus nur mit Alt: dann zeigt das Spiel beim Draufzeigen, was ein Punkt ist
local function mausPruefen()
  if not R.an then return end
  local alt = (IsAltKeyDown and IsAltKeyDown()) and true or false
  if alt == R.maus then return end
  R.maus = alt
  rufe(Minimap, "EnableMouse", alt)
  if not alt and GameTooltip and rufe(GameTooltip, "IsOwned", Minimap) then rufe(GameTooltip, "Hide") end
end
R.MausPruefen = mausPruefen

local function anschalten()
  local m = Minimap
  if not m then return false end
  local f = rahmenBauen()
  local s = {
    parent = rufe(m, "GetParent"), punkte = punkte(m), breite = rufe(m, "GetWidth"), hoehe = rufe(m, "GetHeight"),
    scale = rufe(m, "GetScale"), strata = rufe(m, "GetFrameStrata"), ebene = rufe(m, "GetFrameLevel"),
    alpha = rufe(m, "GetAlpha"), zoom = rufe(m, "GetZoom"), maus = rufe(m, "IsMouseEnabled"),
    rad = rufe(m, "IsMouseWheelEnabled"), drehen = cvar("rotateMinimap"), bewegt = {},
  }
  -- Platzhalter an der alten Stelle, mit derselben Größe: Dort warten Knöpfe und Rahmen der Minikarte
  local p = R.platz or CreateFrame("Frame", nil, UIParent)
  R.platz = p
  rufe(p, "SetParent", s.parent or UIParent)
  rufe(p, "SetScale", s.scale or 1)
  rufe(p, "SetSize", s.breite or 140, s.hoehe or 140)
  punkteSetzen(p, s.punkte)
  p:Show()
  -- Kinder und Flächen der Minikarte auf den Platzhalter, Bezüge auf die Minikarte auch
  local objekte = {}
  for _, k in ipairs({ rufe(m, "GetChildren") }) do objekte[#objekte + 1] = k end
  for _, k in ipairs({ rufe(m, "GetRegions") }) do objekte[#objekte + 1] = k end
  local hbdLib = LibStub and select(2, pcall(LibStub, "HereBeDragons-Pins-2.0", true))
  local hbd = type(hbdLib) == "table" and hbdLib.minimapPins or nil
  local breite = s.breite or 140
  s.maeuse = {}
  for _, obj in ipairs(objekte) do
    if obj ~= f and bleibt(obj, hbd) then
      -- Bleibt im Radar. Eine Ebene so groß wie die Karte darf keine Klicks abfangen, solange es läuft.
      if rufe(obj, "IsMouseEnabled") and (rufe(obj, "GetWidth") or 0) >= breite * 0.5 then
        rufe(obj, "EnableMouse", false)
        s.maeuse[#s.maeuse + 1] = obj
      end
    elseif obj ~= f then
      local alt = { obj = obj, parent = m, punkte = punkte(obj) }
      rufe(obj, "SetParent", p)
      if rufe(obj, "GetParent") == p then
        punkteSetzen(obj, alt.punkte, m, p)
        s.bewegt[#s.bewegt + 1] = alt
      end
    end
  end
  -- Benannte Rahmen, die an der Minikarte hängen, ohne ihre Kinder zu sein
  for _, name in ipairs(ANGEHAENGT) do
    local obj = _G[name]
    if type(obj) == "table" and obj ~= m and rufe(obj, "GetParent") ~= p then
      local liste = punkte(obj)
      local haengt = false
      for _, q in ipairs(liste) do if q[2] == m then haengt = true end end
      if haengt then
        punkteSetzen(obj, liste, m, p)
        s.bewegt[#s.bewegt + 1] = { obj = obj, punkte = liste }
      end
    end
  end
  -- Die Minikarte selbst ins Radar
  local durchmesser = math.floor(math.min(UIParent:GetWidth(), UIParent:GetHeight()) * (ns.db.radarGroesse or 0.6))
  f.durchmesser = durchmesser
  f:SetSize(durchmesser, durchmesser)
  f:SetAlpha(imKampf() and R.KAMPF_ANTEIL or 1)
  f:Show()
  rufe(m, "SetParent", f)
  rufe(m, "ClearAllPoints")
  -- Manchmal lehnt das Spiel den Anker ab („anchor family“, so steht es auch bei FarmHud): dann den
  -- ganzen Rahmen nehmen
  if not pcall(m.SetPoint, m, "CENTER", f, "CENTER", 0, 0) then
    rufe(m, "ClearAllPoints")
    rufe(m, "SetAllPoints", f)
  end
  rufe(m, "SetScale", 1)
  rufe(m, "SetSize", durchmesser, durchmesser)
  rufe(m, "SetFrameStrata", "BACKGROUND")
  rufe(f, "SetFrameLevel", 1)
  rufe(m, "SetFrameLevel", 3)
  rufe(f.oben, "SetFrameLevel", 8)
  -- Hinweis auf Alt unter dem Radar (Patrick hatte ihn im Chat übersehen), bei jedem Einschalten, bis
  -- das Spiel mit Alt einmal einen Namen gezeigt hat. Alt allein zählt nicht, das drückt man auch für
  -- Alt+Tab.
  f.hinweis:ClearAllPoints()
  f.hinweis:SetPoint("TOP", f.oben, "CENTER", 0, -(durchmesser / 2 + 34))
  f.hinweis:SetShown(not ns.db.radarNamenGesehen)
  R.hinweisBis = ns.jetzt() + R.HINWEIS_DAUER
  rufe(m, "SetZoom", 0)
  rufe(m, "EnableMouse", false)
  rufe(m, "EnableMouseWheel", false)
  -- Klick mit Alt setzt das Ziel des Pfeils statt zu pingen (R:MausKlick), beim Ausschalten zurück
  s.klick = rufe(m, "GetScript", "OnMouseUp")
  rufe(m, "SetScript", "OnMouseUp", function(selbst, taste) R:MausKlick(selbst, taste) end)
  -- Gelände weg, wenn das Spiel das kann und es so eingestellt ist (Standard)
  R.ohneBoden = nil
  if not ns.db.radarGelaende and R.BodenMoeglich() then
    s.boden = bodenLesen()
    if bodenSetzen(false) then R.ohneBoden = true end
  end
  rufe(m, "SetAlpha", deckkraft())
  if ns.db.radarDrehen and s.drehen ~= "1" then cvarSetzen("rotateMinimap", "1") end
  R.dreht = cvar("rotateMinimap") == "1"
  R.stand = s
  R.maus = false
  R.suchen = 0
  R:Richtungen()
  return true
end

local function ausschalten()
  local m, s = Minimap, R.stand
  if not (m and s) then return end
  if R.maskeTest then
    R.maskeTest = nil
    maskeZurueck()
  end
  if R.ohneBoden then
    bodenSetzen(s.boden ~= false)
    R.ohneBoden = nil
  end
  if s.drehen ~= nil and cvar("rotateMinimap") ~= s.drehen then cvarSetzen("rotateMinimap", s.drehen) end
  rufe(m, "SetParent", s.parent)
  punkteSetzen(m, s.punkte)
  rufe(m, "SetScale", s.scale or 1)
  if s.breite and s.hoehe then rufe(m, "SetSize", s.breite, s.hoehe) end
  if s.strata then rufe(m, "SetFrameStrata", s.strata) end
  if s.ebene then rufe(m, "SetFrameLevel", s.ebene) end
  if s.zoom then rufe(m, "SetZoom", s.zoom) end
  if s.maus ~= nil then rufe(m, "EnableMouse", s.maus) end
  rufe(m, "SetScript", "OnMouseUp", s.klick)
  if s.rad ~= nil then rufe(m, "EnableMouseWheel", s.rad) end
  rufe(m, "SetAlpha", s.alpha or 1)
  for _, obj in ipairs(s.maeuse or {}) do rufe(obj, "EnableMouse", true) end
  for i = #s.bewegt, 1, -1 do
    local b = s.bewegt[i]
    if b.parent then rufe(b.obj, "SetParent", b.parent) end
    punkteSetzen(b.obj, b.punkte)
  end
  if R.platz then R.platz:Hide() end
  if R.rahmen then R.rahmen:Hide() end
  R.stand, R.maus, R.kandidaten, R.ziel = nil, nil, nil, nil
end

-- Ein- und Ausschalten: Taste, /hop radar, Knopf. Im Kampf erst danach.
function R:Umschalten(an)
  if an == nil then an = not self.an end
  if an == self.an and not self.wartet then return end
  if imKampf() then
    self.wartet = an
    ns.melde(L.RADAR_AFTER_COMBAT)
    return
  end
  self.wartet = nil
  if an then
    if not anschalten() then return end
    self.an = true
    mausPruefen()
    ns.melde(L.RADAR_ON)
    -- Einmal je Sitzung: Kann das Spiel das Gelände nicht weglassen, gibt es den Test
    if not self.ohneBoden and not ns.db.radarGelaende and not self.hinweisGegeben then
      self.hinweisGegeben = true
      ns.melde(L.RADAR_NO_GROUND)
    end
  else
    ausschalten()
    self.an = false
    ns.melde(L.RADAR_OFF)
  end
  ns.aktualisieren()
end

-- /hop radar terrain: Gelände zeigen oder weglassen, gemerkt für das nächste Mal
function R:GelaendeUmschalten()
  ns.db.radarGelaende = not ns.db.radarGelaende
  if self.an and self.stand then
    if ns.db.radarGelaende and self.ohneBoden then
      bodenSetzen(self.stand.boden ~= false)
      self.ohneBoden = nil
    elseif not ns.db.radarGelaende and not self.ohneBoden and R.BodenMoeglich() then
      self.stand.boden = bodenLesen()
      if bodenSetzen(false) then self.ohneBoden = true end
    end
    rufe(Minimap, "SetAlpha", deckkraft())
  end
  ns.melde(ns.db.radarGelaende and L.RADAR_TERRAIN_ON or L.RADAR_TERRAIN_OFF)
end

-- /hop radar test: durchsichtige Maske statt des Geländes, die Karte voll sichtbar. Zeigt das Spiel
-- die Punkte dann noch, ist das der Weg für Forever. Zurück mit /hop radar test, beim Ausschalten
-- oder Ausloggen.
function R:MaskeTesten()
  if not self.an then
    ns.melde(L.RADAR_TEST_NEEDS_RADAR)
    return
  end
  if self.maskeTest then
    self.maskeTest = nil
    maskeZurueck()
    ns.melde(L.RADAR_TEST_OFF)
  else
    self.maskeTest = true
    maskeSetzen(R.MASKE_LEER)
    ns.melde(L.RADAR_TEST_ON)
  end
  rufe(Minimap, "SetAlpha", deckkraft())
end

-- Taste für das Radar, wie das Spiel sie schreibt; nil, solange keine belegt ist
function R.Taste()
  if not GetBindingKey then return nil end
  local ok, taste = pcall(GetBindingKey, R.TASTE)
  if not ok or type(taste) ~= "string" or taste == "" then return nil end
  if GetBindingText then
    local ok2, text = pcall(GetBindingText, taste)
    if ok2 and type(text) == "string" and text ~= "" then return text end
  end
  return taste
end

function R.TastenText()
  local t = R.Taste()
  return t and string.format(L.RADAR_KEY, t) or L.RADAR_KEY_NONE
end

-- Taste direkt im Fenster belegen (Patrick, 20. Nov: „den Radar-Hotkey-Button habe ich noch nicht
-- gesehen“). Klick auf den Knopf, dann die Taste drücken: Hop & Seek belegt sie wie die Tastaturbelegung
-- des Spiels (SetBinding, SaveBindings). Esc bricht ab, Rechtsklick löst die Taste. Maustasten 3 bis 5:
-- den Knopf damit anklicken. Nicht im Kampf. Nach 10 Sekunden ohne Taste hört er von selbst auf, damit
-- die Tastatur nie hängen bleibt.
local MODIFIKATOR = { LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LALT = true, RALT = true,
  LMETA = true, RMETA = true, UNKNOWN = true }
local MAUSTASTE = { MiddleButton = "BUTTON3", Button4 = "BUTTON4", Button5 = "BUTTON5" }

local function sicher(f, ...)
  if type(f) ~= "function" then return nil end
  local ok, w = pcall(f, ...)
  if ok then return w end
end

local function belegteTasten()
  if not GetBindingKey then return {} end
  local t = { pcall(GetBindingKey, R.TASTE) }
  if not t[1] then return {} end
  table.remove(t, 1)
  return t
end

local function speichern()
  local satz = sicher(GetCurrentBindingSet)
  if SaveBindings and satz then pcall(SaveBindings, satz) end
end

local function modifikatoren()
  return ((IsAltKeyDown and IsAltKeyDown()) and "ALT-" or "") .. ((IsControlKeyDown and IsControlKeyDown()) and "CTRL-" or "")
    .. ((IsShiftKeyDown and IsShiftKeyDown()) and "SHIFT-" or "")
end

function R:TasteSetzen(kombi)
  if imKampf() or not SetBinding then
    ns.melde(L.RADAR_KEY_COMBAT)
    return false
  end
  local vorher = sicher(GetBindingAction, kombi)
  for _, alt in ipairs(belegteTasten()) do pcall(SetBinding, alt) end
  local ok, gesetzt = pcall(SetBinding, kombi, R.TASTE)
  if not ok or gesetzt == false then
    ns.melde(L.RADAR_KEY_FAILED)
    return false
  end
  speichern()
  local text = sicher(GetBindingText, kombi) or kombi
  if type(vorher) == "string" and vorher ~= "" and vorher ~= R.TASTE then
    ns.melde(string.format(L.RADAR_KEY_SET_REPLACED, text, _G["BINDING_NAME_" .. vorher] or vorher))
  else
    ns.melde(string.format(L.RADAR_KEY_SET, text))
  end
  return true
end

function R:TasteLoesen()
  if imKampf() or not SetBinding then
    ns.melde(L.RADAR_KEY_COMBAT)
    return false
  end
  for _, alt in ipairs(belegteTasten()) do pcall(SetBinding, alt) end
  speichern()
  ns.melde(L.RADAR_KEY_REMOVED)
  return true
end

local function knopfText(k)
  local t = R.Taste()
  local text = k.fangen and L.RADAR_KEY_PRESS or (t and string.format(L.RADAR_KEY, t) or L.RADAR_KEY_SET_BUTTON)
  if k.text and k.text.SetText then k.text:SetText(text) elseif k.SetText then k:SetText(text) end
end

local function fangenEnde(k)
  k.fangen = nil
  rufe(k, "EnableKeyboard", false)
  knopfText(k)
end

local function fangen(k)
  if imKampf() then
    ns.melde(L.RADAR_KEY_COMBAT)
    return
  end
  k.fangen = ns.jetzt()
  rufe(k, "EnableKeyboard", true)
  rufe(k, "SetPropagateKeyboardInput", false)
  knopfText(k)
end

function R.TastenKnopf(k)
  rufe(k, "RegisterForClicks", "AnyUp")
  k:SetScript("OnClick", function(self, maus)
    if ns.Stil and ns.Stil.klick then ns.Stil.klick() end
    if self.fangen then
      local taste = MAUSTASTE[maus]
      if taste then R:TasteSetzen(modifikatoren() .. taste) end
      fangenEnde(self)
    elseif maus == "RightButton" then
      R:TasteLoesen()
      knopfText(self)
    else
      fangen(self)
    end
  end)
  k:SetScript("OnKeyDown", function(self, taste)
    if not self.fangen or MODIFIKATOR[taste] then return end
    if taste ~= "ESCAPE" then pcall(R.TasteSetzen, R, modifikatoren() .. taste) end
    fangenEnde(self)
  end)
  k:SetScript("OnUpdate", function(self)
    if self.fangen and ns.jetzt() - self.fangen > 10 then fangenEnde(self) end
  end)
  k:HookScript("OnHide", function(self) if self.fangen then fangenEnde(self) end end)
  k.Aktualisieren = knopfText
  knopfText(k)
end

-- Für /hop debug: was das Radar sieht
function R.Diagnose()
  local namen = 0
  for _ in pairs(ns.db.knotenNamen or {}) do namen = namen + 1 end
  local z = R.ziel
  local pfeil = z and string.format("%s %.0f yd", tostring(z.e and R.Name({ e = z.e, id = ns.SammelKarte.Haupt(z.e) or z.e.fund })),
    R.zielDist or 0) or "none"
  local mk = ns.MiniKarte
  return string.format("radar %s, ground api %s, ground hidden %s, mask test %s, view radius %.0f, spots %d, arrow %s, minimap spots %s, key %s, node names %d, names seen %s, last tooltip %s",
    tostring(R.an), tostring(R.BodenMoeglich()), tostring(R.ohneBoden or false), tostring(R.maskeTest or false),
    R.SichtRadius(), R.anzahlZiele or 0, pfeil, mk and tostring(mk.anzahl or 0) or "-", tostring(R.Taste()), namen,
    tostring(ns.db.radarNamenGesehen or false), tostring(R.letzterTooltip))
end

-- Im Kampf blass, danach wieder ganz. Ein gewartetes Umschalten kommt jetzt.
ns.Ereignis("PLAYER_REGEN_DISABLED", function()
  if R.an and R.rahmen then R.rahmen:SetAlpha(R.KAMPF_ANTEIL) end
end)
ns.Ereignis("PLAYER_REGEN_ENABLED", function()
  if R.wartet ~= nil then
    local an = R.wartet
    R.wartet = nil
    R:Umschalten(an)
  elseif R.an and R.rahmen then
    R.rahmen:SetAlpha(1)
  end
end)
ns.Ereignis("MODIFIER_STATE_CHANGED", mausPruefen)
-- Beim Ausloggen (und bei /reload) die Minikarte zurück, sonst bliebe sie gedreht und ohne Gelände
ns.Ereignis("PLAYER_LOGOUT", function()
  if R.an then ausschalten() R.an = false end
end)

-- Taste (Bindings.xml): ein Klick auf diesen unsichtbaren Knopf schaltet das Radar. Wie bei Campfire
-- Buddy nach ActionButtonUseKeyDown beim Drücken oder beim Loslassen.
local taste = CreateFrame("Button", "HopAndSeekRadar", UIParent)
taste:RegisterForClicks(((GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")) and "AnyDown") or "AnyUp")
taste:SetScript("OnClick", function() R:Umschalten() end)
taste:Hide()
R.taste = taste
BINDING_HEADER_HOPANDSEEK = L.ADDON_NAME
_G["BINDING_NAME_CLICK HopAndSeekRadar:LeftButton"] = L.BIND_RADAR
