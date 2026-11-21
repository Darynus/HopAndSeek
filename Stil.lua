-- Stil: gemeinsame Bausteine für Anzeige und Hauptfenster (Vorlage: Pigeon Post).
-- Alles selbst gezeichnet (nur BackdropTemplate), damit nichts von Blizzard-Vorlagen abhängt,
-- die es in Forever vielleicht nicht gibt.
local ADDON, ns = ...

local S = {}
ns.Stil = S

S.WEISS = "Interface\\Buttons\\WHITE8x8"
S.ICON = "Interface\\AddOns\\HopAndSeek\\Media\\Icon"

-- Das eine Symbol von Hop & Seek im Spiel, aus den echten Symbolen von Find Herbs und Find Minerals
-- (Patricks Idee, 18. Okt): Kreis diagonal geteilt, oben links Kräuter, unten rechts Erz, goldener
-- Ring und Strich. Ohne Feder (Patrick: "sieht blöd aus"). Steht überall gleich: Minikarte, Porträt,
-- Reiter Status und Anzeige, solange keine Suche aktiv ist. Die Spielgrafik kommt aus dem Client und
-- wird nicht mitgeliefert, im Paket liegen nur Masken und Ring (grafik/hopandseek/). Die Texturen
-- kommen direkt auf den Rahmen f, so nimmt nichts davon Mausklicks an. Rückgabe: alle Texturen.
local MEDIA = "Interface\\AddOns\\HopAndSeek\\Media\\"
S.KRAUT_SYMBOL = "Interface\\Icons\\INV_Misc_Flower_02"
S.ERZ_SYMBOL = "Interface\\Icons\\Spell_Nature_Earthquake"
function S.symbol(f, groesse, anker, x, y)
  local teile = {}
  local function textur(ebene, stufe)
    local t = f:CreateTexture(nil, ebene, nil, stufe)
    t:SetSize(groesse, groesse)
    t:SetPoint("CENTER", anker or f, "CENTER", x or 0, y or 0)
    table.insert(teile, t)
    return t
  end
  -- Maske über eine eigene Maskentextur mit schwarzem Rand außen (CLAMPTOBLACKADDITIVE). Das alte
  -- SetMask zog zusammen mit dem Zuschnitt der Symbole die Randpixel zu Streifen (Patricks
  -- Screenshot, 18. Okt). SetMask bleibt nur als Rückfall.
  local function maskieren(t, datei)
    if t.AddMaskTexture and f.CreateMaskTexture then
      local ok, m = pcall(f.CreateMaskTexture, f)
      if ok and m then
        m:SetTexture(datei, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        m:SetAllPoints(t)
        t:AddMaskTexture(m)
        return
      end
    end
    if t.SetMask then pcall(t.SetMask, t, datei) end
  end
  local function haelfte(id, ersatz, maske)
    local t = textur("ARTWORK", 1)
    local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
    t:SetTexture(icon or ersatz)
    t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    maskieren(t, MEDIA .. maske)
    return t
  end
  teile.kraut = haelfte(2383, S.KRAUT_SYMBOL, "MaskeOben")
  teile.erz = haelfte(2580, S.ERZ_SYMBOL, "MaskeUnten")
  teile.rahmen = textur("OVERLAY", 5)
  teile.rahmen:SetTexture(MEDIA .. "Rahmen")
  return teile
end

-- Symbol ein- oder ausblenden, grau (pausiert) oder bunt
function S.symbolZeigen(teile, an, grau)
  for _, t in ipairs(teile) do
    t:SetShown(an and true or false)
    if t.SetDesaturated and t ~= teile.rahmen then t:SetDesaturated(grau and true or false) end
  end
end
S.STERN = "Interface\\Common\\FavoritesIcon"
S.PFEIL = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

-- Grund und Rand passen zu den Kästen des Spiels (Tooltip-Rand), Blattgrün ist der Akzent
S.F = {
  grund   = { 0.03, 0.03, 0.05, 0.95 },
  kopf    = { 0.10, 0.15, 0.09, 1 },
  seite   = { 0.07, 0.11, 0.07, 1 },
  flaeche = { 0.06, 0.06, 0.09, 0.92 },
  rand    = { 0.62, 0.64, 0.70, 1 },
  akzent  = { 0.50, 0.84, 0.35, 1 },
  text    = { 0.92, 0.94, 0.97, 1 },
  leise   = { 0.56, 0.62, 0.72, 1 },
  erfolg  = { 0.40, 0.84, 0.56, 1 },
  fehler  = { 0.94, 0.38, 0.35, 1 },
  hinweis = { 0.96, 0.77, 0.32, 1 },
  stern   = { 1.00, 0.82, 0.20, 1 },
}
local F = S.F

-- Hauptfenster seit 1.3.0 (Patrick, 20. Nov: „modern sieht es so nicht aus ... altbacken“, Vorschau
-- mit zwei Richtungen, gewählt: dunkel mit feiner Goldkante): dunkler Grund, Karten, 1 Pixel Rand in
-- Gold, Text in Gold auf den Knöpfen, Schalter statt Haken. Alles flach selbst gezeichnet, nur
-- BackdropTemplate und zwei schlichte Formen (Media/Pille, Media/Kreis), keine Deko-Texturen.
S.M = {
  grund      = { 0.086, 0.086, 0.106, 0.97 },
  kopf       = { 0.114, 0.114, 0.141, 1 },
  karte      = { 0.118, 0.118, 0.145, 1 },
  karteHell  = { 0.160, 0.155, 0.170, 1 },
  kartenRand = { 0.204, 0.188, 0.165, 1 },
  gold       = { 0.949, 0.788, 0.420, 1 },
  goldRand   = { 0.541, 0.427, 0.231, 1 },
  goldText   = { 0.914, 0.851, 0.706, 1 },
  linie      = { 0.231, 0.200, 0.149, 1 },
  aktiv      = { 0.227, 0.192, 0.133, 1 },
  aus        = { 0.260, 0.255, 0.290, 1 },
  text       = { 0.910, 0.902, 0.882, 1 },
  leise      = { 0.604, 0.592, 0.561, 1 },
}
local M = S.M

function S.rgba(f) return f[1], f[2], f[3], f[4] or 1 end
local rgba = S.rgba

-- Fläche mit 1 Pixel Rand (Karten, Knöpfe, Felder im Hauptfenster)
S.FLACH = { bgFile = S.WEISS, edgeFile = S.WEISS, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } }
function S.karte(parent, typ, grund, rand, name)
  local f = CreateFrame(typ or "Frame", name, parent, "BackdropTemplate")
  if f.SetBackdrop then
    f:SetBackdrop(S.FLACH)
    f:SetBackdropColor(rgba(grund or M.karte))
    f:SetBackdropBorderColor(rgba(rand or M.kartenRand))
  end
  return f
end

-- Kachel mit kleiner Beschriftung (Symbol davor) und großer Zahl darunter
function S.kachel(parent, breite, hoehe, beschriftung, icon)
  local k = S.karte(parent, "Frame")
  k:SetSize(breite, hoehe)
  local x = 8
  if icon then
    k.icon = k:CreateTexture(nil, "ARTWORK")
    k.icon:SetSize(14, 14)
    k.icon:SetPoint("TOPLEFT", 8, -7)
    k.icon:SetTexture(icon)
    k.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    x = 26
  end
  k.name = S.schrift(k, "GameFontHighlightSmall", M.leise)
  k.name:SetPoint("TOPLEFT", x, -8)
  k.name:SetPoint("RIGHT", -6, 0)
  k.name:SetJustifyH("LEFT")
  k.name:SetWordWrap(false)
  k.name:SetText(beschriftung)
  k.zahl = S.schrift(k, "GameFontHighlightLarge", M.text)
  k.zahl:SetPoint("BOTTOMLEFT", 8, 7)
  k.zahl:SetPoint("RIGHT", -6, 0)
  k.zahl:SetJustifyH("LEFT")
  k.zahl:SetWordWrap(false)
  return k
end

function S.heller(f)
  return { f[1] + (1 - f[1]) * 0.2, f[2] + (1 - f[2]) * 0.2, f[3] + (1 - f[3]) * 0.2, f[4] or 1 }
end

-- Kasten mit dem Rand der Tooltips und Auswahllisten des Spiels (gibt es in jedem Client).
-- Der Rand lässt sich einfärben (Überfahren: Akzentfarbe).
S.KASTEN = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
function S.kasten(parent, typ, grund, rand, name)
  local f = CreateFrame(typ or "Frame", name, parent, "BackdropTemplate")
  if f.SetBackdrop then
    f:SetBackdrop(S.KASTEN)
    f:SetBackdropColor(rgba(grund or F.flaeche))
    f:SetBackdropBorderColor(rgba(rand or F.rand))
  end
  return f
end

-- Baustein des Spiels (Vorlage aus dem Client). nil, wenn es die Vorlage in diesem Client nicht gibt.
-- Seit 1.3.0 zeichnet Hop & Seek seine Fenster selbst; bleibt für Fälle, in denen nur das Spiel es kann.
function S.vorlage(typ, parent, vorlage, name)
  local ok, f = pcall(CreateFrame, typ, name, parent, vorlage)
  if ok and f then return f end
end

function S.grundFarbe(f, farbe) if f.SetBackdropColor then f:SetBackdropColor(rgba(farbe)) end end
function S.randFarbe(f, farbe) if f.SetBackdropBorderColor then f:SetBackdropBorderColor(rgba(farbe)) end end

function S.schrift(parent, vorlage, farbe)
  local s = parent:CreateFontString(nil, "OVERLAY", vorlage or "GameFontHighlightSmall")
  if farbe then s:SetTextColor(rgba(farbe)) end
  return s
end

-- Mehrzeiliger Text mit fester Breite
function S.absatz(parent, breite, farbe, vorlage)
  local s = S.schrift(parent, vorlage or "GameFontHighlightSmall", farbe or F.leise)
  s:SetWidth(breite)
  s:SetJustifyH("LEFT")
  s:SetJustifyV("TOP")
  s:SetWordWrap(true)
  return s
end

-- Tooltip mit Titel und Erklärung. titel und text dürfen Funktionen sein.
function S.tooltip(rahmen, titel, text)
  rahmen:HookScript("OnEnter", function(self)
    local t = type(titel) == "function" and titel(self) or titel
    local x = type(text) == "function" and text(self) or text
    if not t then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(t, 1, 1, 1)
    if x then GameTooltip:AddLine(x, F.leise[1], F.leise[2], F.leise[3], true) end
    GameTooltip:Show()
  end)
  rahmen:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Überschrift in Gold, in der Schrift des Spiels
function S.ueberschrift(parent, text)
  local s = S.schrift(parent, "GameFontNormal", M.gold)
  s:SetText(text)
  return s
end

function S.klassenFarbe(klasse)
  local c = RAID_CLASS_COLORS and klasse and RAID_CLASS_COLORS[klasse]
  if c then return { c.r, c.g, c.b, 1 } end
  return F.text
end

function S.qualitaetsFarbe(q)
  if q and q >= 2 then
    local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c then return { c.r, c.g, c.b, 1 } end
  end
  return F.rand
end

function S.klick()
  if PlaySound and SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

-- Kleiner Pfeil nach unten (v), aus zwei gedrehten Strichen. Farbe(f) ändert die Farbe.
function S.winkel(parent, farbe)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(12, 8)
  f.links = f:CreateTexture(nil, "OVERLAY")
  f.links:SetSize(8, 2)
  f.links:SetPoint("CENTER", -2.6, 0)
  f.links:SetRotation(math.rad(-40))
  f.rechts = f:CreateTexture(nil, "OVERLAY")
  f.rechts:SetSize(8, 2)
  f.rechts:SetPoint("CENTER", 2.6, 0)
  f.rechts:SetRotation(math.rad(40))
  function f:Farbe(c)
    self.links:SetColorTexture(rgba(c))
    self.rechts:SetColorTexture(rgba(c))
  end
  f:Farbe(farbe or F.leise)
  return f
end

-- Stern für den Favoriten. Ohne Textur im Client bleibt ein gelber Punkt.
function S.stern(parent, groesse)
  local t = parent:CreateTexture(nil, "OVERLAY")
  t:SetSize(groesse, groesse)
  t:SetTexture(S.STERN)
  return t
end

-- Schalter mit Text, rechts optional eine Zahl (bis 1.3.0 ein Haken). Spur und Knauf: an in Gold, der
-- Knauf rechts; aus grau, der Knauf links. Die ganze Zeile ist anklickbar.
function S.haken(parent, breite, text, hilfe, beiKlick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(breite, 22)
  b.spur = b:CreateTexture(nil, "ARTWORK")
  b.spur:SetTexture(MEDIA .. "Pille")
  b.spur:SetSize(28, 14)
  b.spur:SetPoint("LEFT", 0, 0)
  b.knauf = b:CreateTexture(nil, "OVERLAY")
  b.knauf:SetTexture(MEDIA .. "Kreis")
  b.knauf:SetSize(10, 10)
  b.name = S.schrift(b, "GameFontHighlightSmall", M.text)
  b.name:SetPoint("LEFT", b.spur, "RIGHT", 8, 0)
  b.name:SetPoint("RIGHT", -30, 0)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.name:SetText(text)
  b.menge = S.schrift(b, "GameFontHighlightSmall", M.leise)
  b.menge:SetPoint("RIGHT", -4, 0)
  function b:Setzen(an)
    self.an = an and true or false
    self.knauf:ClearAllPoints()
    self.knauf:SetPoint("CENTER", self.spur, "CENTER", self.an and 7 or -7, 0)
    self.spur:SetVertexColor(rgba(self.an and M.goldRand or M.aus))
    self.knauf:SetVertexColor(rgba(self.an and M.gold or M.leise))
  end
  b:Setzen(false)
  b:SetScript("OnClick", function(self)
    S.klick()
    beiKlick(self, not self.an)
  end)
  b:HookScript("OnEnter", function(self) self.name:SetTextColor(1, 1, 1, 1) end)
  b:HookScript("OnLeave", function(self) self.name:SetTextColor(rgba(M.text)) end)
  S.tooltip(b, text, hilfe)
  return b
end

-- Auswahl aus mehreren Werten, einer davon aktiv: eine Leiste mit Feldern, feine Goldkante, das
-- gewählte Feld dunkelgolden mit goldener Schrift.
function S.segmente(parent, breite, optionen, beiWahl)
  local f = S.karte(parent, "Frame", M.grund, M.goldRand)
  f:SetSize(breite, 22)
  local teil = (breite - 2) / #optionen
  f.knoepfe = {}
  for i, o in ipairs(optionen) do
    local b = CreateFrame("Button", nil, f)
    b:SetSize(teil, 20)
    b:SetPoint("LEFT", f, "LEFT", 1 + (i - 1) * teil, 0)
    b.grund = b:CreateTexture(nil, "ARTWORK")
    b.grund:SetAllPoints()
    if i > 1 then
      local strich = b:CreateTexture(nil, "OVERLAY")
      strich:SetWidth(1)
      strich:SetPoint("TOPLEFT", 0, 0)
      strich:SetPoint("BOTTOMLEFT", 0, 0)
      strich:SetColorTexture(rgba(M.goldRand))
    end
    b.text = S.schrift(b, "GameFontHighlightSmall")
    b.text:SetPoint("CENTER")
    b.text:SetText(o.text)
    b.wert, b.farbe = o.wert, o.farbe or M.aktiv
    b:SetScript("OnClick", function() S.klick() beiWahl(o.wert) end)
    b:HookScript("OnEnter", function(self) self.text:SetTextColor(rgba(M.text)) end)
    b:HookScript("OnLeave", function() f:Setzen(f.wert) end)
    S.tooltip(b, o.text, o.hilfe)
    f.knoepfe[i] = b
  end
  function f:Setzen(wert)
    self.wert = wert
    for _, b in ipairs(self.knoepfe) do
      local an = b.wert == wert
      if an then b.grund:SetColorTexture(rgba(b.farbe)) else b.grund:SetColorTexture(0, 0, 0, 0) end
      b.text:SetTextColor(rgba(an and M.gold or M.leise))
    end
  end
  return f
end

-- Großer Knopf. Aussehen(text, farbe, an) setzt Text, Rand und ob er klickbar ist. Dunkelgold mit
-- goldener Schrift, die Farbe färbt den Rand.
function S.knopf(parent, breite, hoehe)
  local b = S.karte(parent, "Button", M.aktiv, M.goldRand)
  b:SetSize(breite, hoehe or 30)
  b.text = S.schrift(b, "GameFontNormal", M.gold)
  b.text:SetPoint("CENTER")
  b:HookScript("OnEnter", function(self) if self:IsEnabled() then S.randFarbe(self, M.gold) end end)
  b:HookScript("OnLeave", function(self) if self:IsEnabled() then S.randFarbe(self, self.farbe or M.goldRand) end end)
  function b:Aussehen(text, farbe, an)
    self.text:SetText(text)
    self.farbe = farbe
    if an then
      self:Enable()
      S.grundFarbe(self, M.aktiv)
      S.randFarbe(self, farbe or M.goldRand)
      self.text:SetTextColor(rgba(M.gold))
    else
      self:Disable()
      S.grundFarbe(self, M.karte)
      S.randFarbe(self, M.kartenRand)
      self.text:SetTextColor(rgba(M.leise))
    end
  end
  b:Aussehen("", nil, true)
  return b
end

-- Knopf für Nebenaktionen: dunkel mit feiner Goldkante und heller Goldschrift, beim Überfahren heller
function S.textKnopf(parent, text, breite, beiKlick)
  local b = S.karte(parent, "Button", M.karte, M.goldRand)
  b:SetSize(breite, 22)
  b.text = S.schrift(b, "GameFontNormalSmall", M.goldText)
  b.text:SetPoint("CENTER")
  b.text:SetText(text)
  b:HookScript("OnEnter", function(self)
    if self:IsEnabled() then
      S.randFarbe(self, M.gold)
      S.grundFarbe(self, M.karteHell)
    end
  end)
  b:HookScript("OnLeave", function(self)
    S.randFarbe(self, self.randFarbe or M.goldRand)
    S.grundFarbe(self, M.karte)
  end)
  b:SetScript("OnClick", function(self) S.klick() beiKlick(self) end)
  function b:Aktiv(an)
    if an then self:Enable() self.text:SetTextColor(rgba(M.goldText)) else self:Disable() self.text:SetTextColor(rgba(M.leise)) end
  end
  return b
end

-- Kleiner Knopf mit einem Zeichen (Schließen, Einklappen, Einstellungen)
function S.zeichenKnopf(parent, zeichen, beiKlick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(22, 22)
  b.text = S.schrift(b, "GameFontHighlightLarge", F.leise)
  b.text:SetPoint("CENTER")
  b.text:SetText(zeichen)
  b:HookScript("OnEnter", function() b.text:SetTextColor(rgba(F.text)) end)
  b:HookScript("OnLeave", function() b.text:SetTextColor(rgba(F.leise)) end)
  b:SetScript("OnClick", function() S.klick() beiKlick() end)
  return b
end

-- Kopfzeile mit Icon, Titel und Untertitel. Gibt die Höhe zurück.
function S.kopf(parent, untertitel)
  local kopf = parent:CreateTexture(nil, "BORDER")
  kopf:SetPoint("TOPLEFT", 1, -1)
  kopf:SetPoint("TOPRIGHT", -1, -1)
  kopf:SetHeight(44)
  kopf:SetColorTexture(rgba(F.kopf))
  if CreateColor and kopf.SetGradient then
    pcall(kopf.SetGradient, kopf, "VERTICAL", CreateColor(0.07, 0.10, 0.16, 1), CreateColor(0.12, 0.18, 0.30, 1))
  end
  local linie = parent:CreateTexture(nil, "ARTWORK")
  linie:SetPoint("TOPLEFT", 1, -45)
  linie:SetPoint("TOPRIGHT", -1, -45)
  linie:SetHeight(1)
  linie:SetColorTexture(rgba(F.akzent))
  -- Platzhalter, darauf das eine Symbol von Hop & Seek
  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetSize(28, 28)
  icon:SetPoint("TOPLEFT", 10, -8)
  S.symbol(parent, 28, icon)
  local titel = S.schrift(parent, "GameFontNormalLarge", F.text)
  titel:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
  titel:SetText(ns.TITEL)
  local unter = S.schrift(parent, "GameFontHighlightSmall", F.leise)
  unter:SetPoint("TOPLEFT", titel, "BOTTOMLEFT", 0, -2)
  unter:SetText(untertitel)
  return 46
end

-- Fortschrittsbalken, flach: dunkler Grund mit feinem Rand, Füllung in der Akzentfarbe, Text in der
-- Mitte. Setzen(anteil von 0 bis 1, text, farbe). Mit maus nimmt er die Maus an (für Tooltips).
function S.balken(parent, breite, hoehe, maus)
  local b = CreateFrame("Frame", nil, parent)
  b:SetSize(breite, hoehe)
  if maus then b:EnableMouse(true) end
  b.rand = b:CreateTexture(nil, "BACKGROUND", nil, -1)
  b.rand:SetPoint("TOPLEFT", -1, 1)
  b.rand:SetPoint("BOTTOMRIGHT", 1, -1)
  b.rand:SetColorTexture(F.rand[1], F.rand[2], F.rand[3], 0.35)
  b.grund = b:CreateTexture(nil, "BACKGROUND")
  b.grund:SetAllPoints()
  b.grund:SetColorTexture(0, 0, 0, 0.65)
  b.fuellung = b:CreateTexture(nil, "ARTWORK")
  b.fuellung:SetPoint("TOPLEFT")
  b.fuellung:SetPoint("BOTTOMLEFT")
  b.text = S.schrift(b, "GameFontHighlightSmall", F.text)
  b.text:SetPoint("CENTER", 0, 0)
  function b:Setzen(anteil, text, farbe)
    anteil = math.max(0, math.min(1, anteil or 0))
    self.anteil = anteil
    self.fuellung:SetShown(anteil > 0)
    self.fuellung:SetWidth(math.max(1, breite * anteil))
    self.fuellung:SetColorTexture(rgba(farbe or F.akzent))
    self.text:SetText(text or "")
  end
  b:Setzen(0)
  return b
end

function S.schatten(parent)
  local t = parent:CreateTexture(nil, "BACKGROUND", nil, -8)
  t:SetPoint("TOPLEFT", -4, 4)
  t:SetPoint("BOTTOMRIGHT", 4, -4)
  t:SetColorTexture(0, 0, 0, 0.35)
  return t
end

-- Liste, die mit dem Mausrad rollt. Es gibt nur so viele Zeilen-Rahmen wie sichtbar sind.
-- bauen(liste, i) erzeugt eine Zeile, fuellen(zeile, eintrag) zeigt einen Eintrag darin.
function S.liste(parent, breite, hoehe, zeilenHoehe, bauen)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(breite, hoehe)
  f.zeilen, f.daten, f.versatz = {}, {}, 0
  f.sichtbar = math.floor(hoehe / zeilenHoehe)
  for i = 1, f.sichtbar do
    local z = bauen(f, i)
    z:SetSize(breite - 6, zeilenHoehe)
    z:SetPoint("TOPLEFT", 0, -(i - 1) * zeilenHoehe)
    f.zeilen[i] = z
  end
  f.balken = f:CreateTexture(nil, "OVERLAY")
  f.balken:SetWidth(3)
  f.balken:SetColorTexture(M.goldRand[1], M.goldRand[2], M.goldRand[3], 0.9)
  f.leer = S.absatz(f, breite - 20, F.leise)
  f.leer:SetPoint("TOPLEFT", 4, -6)
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function(self, delta) self:Rollen(-delta) end)

  function f:Setzen(daten, fuellen, leerText)
    self.daten, self.fuellen = daten, fuellen
    self.leer:SetText(#daten == 0 and (leerText or "") or "")
    self:Rollen(0)
  end
  function f:Rollen(schritte)
    local hoechster = math.max(0, #self.daten - self.sichtbar)
    self.versatz = math.min(math.max(self.versatz + schritte, 0), hoechster)
    for i, z in ipairs(self.zeilen) do
      local eintrag = self.daten[i + self.versatz]
      z.eintrag = eintrag
      if eintrag then z:Show() self.fuellen(z, eintrag) else z:Hide() end
    end
    if hoechster > 0 then
      local bh = math.max(12, hoehe * self.sichtbar / #self.daten)
      self.balken:SetHeight(bh)
      self.balken:ClearAllPoints()
      self.balken:SetPoint("TOPRIGHT", 0, -((hoehe - bh) * self.versatz / hoechster))
      self.balken:Show()
    else
      self.balken:Hide()
    end
  end
  return f
end

-- Zeile für Listen: beim Überfahren ein heller Schimmer, ausgewählt dunkelgolden mit Goldstrich links
function S.zeile(parent)
  local z = CreateFrame("Button", nil, parent)
  z.hell = z:CreateTexture(nil, "BACKGROUND")
  z.hell:SetAllPoints()
  z.hell:SetColorTexture(1, 1, 1, 0.06)
  z.hell:Hide()

  z.wahl = z:CreateTexture(nil, "BACKGROUND", nil, 1)
  z.wahl:SetAllPoints()
  z.wahl:SetColorTexture(rgba(M.aktiv))
  z.wahl:Hide()
  z:HookScript("OnEnter", function(self) self.hell:Show() end)
  z:HookScript("OnLeave", function(self) self.hell:Hide() end)
  return z
end


-- Auswahlfeld: Knopf mit Text und Pfeil. Ein Klick öffnet eine Aufklappliste darunter.
-- eintraege(): { { wert, text, farbe, info }, ... }, beiWahl(wert)
function S.auswahl(parent, breite, eintraege, beiWahl)
  local b = S.karte(parent, "Button", M.karte, M.goldRand)
  b:SetSize(breite, 22)
  b.text = S.schrift(b, "GameFontHighlightSmall", M.text)
  b.text:SetPoint("LEFT", 8, 0)
  b.text:SetWidth(breite - 30)
  b.text:SetJustifyH("LEFT")
  b.text:SetWordWrap(false)
  b.pfeil = S.winkel(b, M.leise)
  b.pfeil:SetPoint("RIGHT", -8, 0)
  b:HookScript("OnEnter", function(self) S.randFarbe(self, M.gold) self.pfeil:Farbe(M.gold) end)
  b:HookScript("OnLeave", function(self) S.randFarbe(self, M.goldRand) self.pfeil:Farbe(M.leise) end)
  b:SetScript("OnClick", function(self)
    S.klick()
    S.aufklappen(self, breite, eintraege(), beiWahl)
  end)
  function b:Setzen(text, farbe)
    self.text:SetText(text or "")
    self.text:SetTextColor(rgba(farbe or F.text))
  end
  return b
end

-- Aufklappliste unter einem Knopf, über allem anderen. Höchstens 10 Zeilen sichtbar, der Rest
-- mit dem Mausrad. Schließt bei Auswahl, bei erneutem Klick, mit Esc oder wenn der Knopf verschwindet.
local AUF_ZEILE, AUF_MAX = 22, 10
local auf
function S.aufklappen(anker, breite, eintraege, beiWahl)
  if not auf then
    auf = S.karte(UIParent, "Frame", M.grund, M.goldRand, "HopAndSeekAuswahl")
    auf:SetFrameStrata("FULLSCREEN_DIALOG")
    auf:SetClampedToScreen(true)
    auf:EnableMouse(true)
    auf:EnableMouseWheel(true)
    auf.zeilen = {}
    auf:SetScript("OnMouseWheel", function(self, delta)
      local hoechster = math.max(0, #self.eintraege - AUF_MAX)
      self.versatz = math.min(math.max(self.versatz - delta, 0), hoechster)
      self:Fuellen()
    end)
    function auf:Fuellen()
      for i, z in ipairs(self.zeilen) do
        local e = self.eintraege[i + self.versatz]
        z.eintrag = e
        if e then
          z.text:SetText(e.text)
          z.text:SetTextColor(rgba(e.farbe or F.text))
          z.info:SetText(e.info or "")
          z:Show()
        else
          z:Hide()
        end
      end
    end
    -- Esc schließt nur die Liste (UIMenus kommt vor CloseAllWindows), nicht das Postfenster
    if UIMenus then table.insert(UIMenus, "HopAndSeekAuswahl") end
  end
  if auf:IsShown() and auf.anker == anker then auf:Hide() return end
  auf.anker, auf.eintraege, auf.beiWahl, auf.versatz = anker, eintraege, beiWahl, 0
  local sichtbar = math.min(#eintraege, AUF_MAX)
  for i = 1, sichtbar do
    if not auf.zeilen[i] then
      local z = S.zeile(auf)
      z:SetHeight(AUF_ZEILE)
      z:SetPoint("TOPLEFT", 1, -1 - (i - 1) * AUF_ZEILE)
      z:SetPoint("TOPRIGHT", -1, -1 - (i - 1) * AUF_ZEILE)
      z.text = S.schrift(z, "GameFontHighlightSmall", F.text)
      z.text:SetPoint("LEFT", 8, 0)
      z.info = S.schrift(z, "GameFontHighlightSmall", F.leise)
      z.info:SetPoint("RIGHT", -8, 0)
      z:SetScript("OnClick", function(self)
        S.klick()
        auf:Hide()
        if self.eintrag then auf.beiWahl(self.eintrag.wert) end
      end)
      auf.zeilen[i] = z
    end
  end
  for i = sichtbar + 1, #auf.zeilen do auf.zeilen[i]:Hide() end
  auf:SetWidth(breite)
  auf:SetHeight(math.max(1, sichtbar) * AUF_ZEILE + 2)
  auf:ClearAllPoints()
  auf:SetPoint("TOPLEFT", anker, "BOTTOMLEFT", 0, -2)
  auf:Fuellen()
  auf:Show()
  if not anker.aufklappHaken then
    anker.aufklappHaken = true
    anker:HookScript("OnHide", function() if auf.anker == anker then auf:Hide() end end)
  end
end

-- Eingabefeld für kurze Texte (Profilnamen). beiEnter(text) beim Bestätigen mit Enter. Dunkel mit
-- feinem Rand, im Fokus golden.
function S.eingabe(parent, breite, maxZeichen, beiEnter)
  local e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
  e:SetSize(breite, 22)
  if e.SetBackdrop then
    e:SetBackdrop(S.FLACH)
    e:SetBackdropColor(rgba(M.grund))
    e:SetBackdropBorderColor(rgba(M.kartenRand))
  end
  e:SetAutoFocus(false)
  e:SetMaxLetters(maxZeichen or 24)
  if GameFontHighlightSmall then e:SetFontObject(GameFontHighlightSmall) end
  e:SetTextInsets(8, 8, 0, 0)
  e:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    beiEnter(self:GetText() or "")
  end)
  e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  e:HookScript("OnEditFocusGained", function(self) S.randFarbe(self, M.goldRand) end)
  e:HookScript("OnEditFocusLost", function(self) S.randFarbe(self, M.kartenRand) end)
  return e
end