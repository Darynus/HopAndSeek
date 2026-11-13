-- Sammelfenster: kleines, flaches Fenster wie die Leiste von Campfire Buddy (Patricks Wunsch,
-- 13. Nov): Gold pro Stunde, Menge pro Stunde, Knoten und die wertvollsten Funde dieser Sitzung,
-- unten Rang und Tagesziel (Erfolge.lua). Es erscheint mit dem ersten Knoten einer Sitzung und
-- verschwindet, wenn die Sitzung endet (30 Minuten ohne Sammeln, Start over). Ziehen verschiebt es,
-- Rechtsklick öffnet den Reiter Gathered, das x blendet es bis zur nächsten Sitzung aus.
-- Nur lesen und anzeigen.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F, rgba = S.F, S.rgba

local G = { funde = {} }
ns.SammelLeiste = G

local BREITE, RAND, FUND = 280, 6, 18
local MAX_FUNDE = 3
local KOPF, GROSS, INFO, UNTEN, BERUF = 18, 22, 16, 22, 14
local INNEN = BREITE - 2 * RAND - 8

-- Nadel des Spiels für den Wegweiser (Wegweiser.lua): blass, solange er aus ist. Fehlt der Atlas,
-- eine Karte als Symbol.
local PIN = { [false] = "Waypoint-MapPin-Untracked", [true] = "Waypoint-MapPin-Tracked" }
local function pinZeigen(b, an)
  if b.mitAtlas then b.icon:SetAtlas(PIN[an]) else b.icon:SetDesaturated(not an) end
  b.icon:SetAlpha(an and 1 or 0.75)
end

local function merken(f)
  local punkt, _, relativ, x, y = f:GetPoint()
  ns.db.sammelLeiste = { punkt = punkt, relativ = relativ, x = x, y = y }
end

-- Tooltip: Sitzung, Rang, Tagesziel, Rekorde, dann die Bedienung
local function tooltip(self)
  GameTooltip:SetOwner(self, "ANCHOR_LEFT")
  GameTooltip:SetText(L.GATHER_BAR_TITLE, 1, 1, 1)
  if ns.Erfolge then ns.Erfolge:Tooltip(GameTooltip) end
  -- Sammelberufe mit Stufe, rot am Ende der gelernten Stufe
  local berufe = ns.Berufe and ns.Berufe.Liste() or {}
  if #berufe > 0 then
    GameTooltip:AddLine(" ")
    for _, p in ipairs(berufe) do
      local farbe = ns.Berufe.AmLimit(p) and F.fehler or F.text
      GameTooltip:AddLine(string.format(L.SKILL_LEVEL, ns.Berufe.Name(p), p.rang, p.max), farbe[1], farbe[2], farbe[3])
    end
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(L.GATHER_BAR_HELP, F.leise[1], F.leise[2], F.leise[3], true)
  GameTooltip:Show()
end

function G:Bauen()
  if self.rahmen then return end
  local f = S.kasten(UIParent, "Button", F.grund, F.rand, "HopAndSeekGathering")
  self.rahmen = f
  f:SetSize(BREITE, 100)
  local pos = ns.db.sammelLeiste
  if pos and pos.punkt then
    f:SetPoint(pos.punkt, UIParent, pos.relativ or pos.punkt, pos.x, pos.y)
  else
    f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -250, -230)
  end
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:RegisterForClicks("RightButtonUp")
  f:SetScript("OnDragStart", function(self) if not ns.db.gesperrt then self:StartMoving() end end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    merken(self)
  end)
  f:SetScript("OnClick", function() ns.Fenster:Zeigen("sammeln") end)
  f:HookScript("OnEnter", tooltip)
  f:HookScript("OnLeave", function() GameTooltip:Hide() end)
  S.schatten(f)
  -- Streifen in der Akzentfarbe links, wie bei der Leiste von Campfire Buddy
  local streifen = f:CreateTexture(nil, "ARTWORK")
  streifen:SetPoint("TOPLEFT", 1, -1)
  streifen:SetPoint("BOTTOMLEFT", 1, 1)
  streifen:SetWidth(2)
  streifen:SetColorTexture(rgba(F.akzent))

  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(16, 16)
  f.icon:SetPoint("TOPLEFT", RAND + 4, -RAND)
  f.icon:SetTexture(S.ERZ_SYMBOL)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.titel = S.schrift(f, "GameFontNormalSmall", F.akzent)
  f.titel:SetPoint("LEFT", f.icon, "RIGHT", 6, 0)
  f.titel:SetText(L.GATHER_BAR_TITLE)
  f.zu = S.zeichenKnopf(f, "x", function()
    local s = ns.Sammeln:Sitzung()
    G.zuBis = s.start
    G:Aktualisieren()
  end)
  f.zu:SetSize(18, 18)
  f.zu:SetPoint("TOPRIGHT", -2, -2)
  S.tooltip(f.zu, L.GATHER_BAR_CLOSE, L.GATHER_BAR_CLOSE_HELP)
  -- Wegweiser zur nächsten bekannten Stelle: Linksklick die nächste, Rechtsklick aus
  f.weiter = CreateFrame("Button", nil, f)
  f.weiter:SetSize(16, 16)
  f.weiter:SetPoint("RIGHT", f.zu, "LEFT", -2, 0)
  f.weiter:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  f.weiter.icon = f.weiter:CreateTexture(nil, "ARTWORK")
  f.weiter.icon:SetAllPoints()
  f.weiter.mitAtlas = f.weiter.icon.SetAtlas and C_Texture and C_Texture.GetAtlasInfo
    and C_Texture.GetAtlasInfo(PIN[false]) ~= nil or false
  if not f.weiter.mitAtlas then
    f.weiter.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    f.weiter.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  pinZeigen(f.weiter, false)
  f.weiter:SetScript("OnClick", function(_, knopf)
    S.klick()
    if knopf == "RightButton" then ns.Wegweiser:Aus() else ns.Wegweiser:Weiter() end
  end)
  S.tooltip(f.weiter, L.NEXT_BUTTON, L.NEXT_BUTTON_HELP)
  f.zeit = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.zeit:SetPoint("RIGHT", f.weiter, "LEFT", -4, 0)

  -- Groß: Gold pro Stunde (oder bisheriger Wert, oder Hinweis auf Auctionator)
  f.gold = S.schrift(f, "GameFontHighlightLarge", F.erfolg)
  f.gold:SetPoint("TOPLEFT", RAND + 4, -RAND - KOPF - 2)
  f.gold:SetWidth(INNEN)
  f.gold:SetJustifyH("LEFT")
  f.gold:SetWordWrap(false)
  -- Klein: Menge, Knoten, pro Stunde, Wert
  f.info = S.schrift(f, "GameFontHighlightSmall", F.text)
  f.info:SetPoint("TOPLEFT", RAND + 4, -RAND - KOPF - GROSS - 2)
  f.info:SetWidth(INNEN)
  f.info:SetJustifyH("LEFT")
  -- Lange Zeilen (Kräuter, Erz und Leder) dürfen zweizeilig sein, statt abgeschnitten (Patricks
  -- Screenshot, 13. Nov)
  f.info:SetWordWrap(true)
  if f.info.SetMaxLines then f.info:SetMaxLines(2) end
  -- Hinweis, wenn ein Sammelberuf einen Lehrer braucht (Berufe.lua)
  f.beruf = S.schrift(f, "GameFontHighlightSmall", F.hinweis)
  f.beruf:SetWidth(INNEN)
  f.beruf:SetJustifyH("LEFT")
  f.beruf:SetWordWrap(false)
  f.beruf:Hide()
  -- Klick auf den Hinweis: Wegpunkt zum nächsten Lehrer (Lehrer.lua)
  f.lehrer = CreateFrame("Button", nil, f)
  f.lehrer:SetAllPoints(f.beruf)
  f.lehrer:SetScript("OnClick", function()
    S.klick()
    ns.Lehrer:Zeigen(f.berufArt)
  end)
  S.tooltip(f.lehrer, L.TRAINER_BUTTON, L.TRAINER_BUTTON_HELP)
  f.lehrer:Hide()

  -- Die wertvollsten Funde (oder die häufigsten, ohne Preise)
  for i = 1, MAX_FUNDE do
    local z = CreateFrame("Frame", nil, f)
    z:SetSize(INNEN, FUND)
    z:SetPoint("TOPLEFT", RAND + 4, -RAND - KOPF - GROSS - INFO - 4 - (i - 1) * FUND)
    z.icon = z:CreateTexture(nil, "ARTWORK")
    z.icon:SetSize(14, 14)
    z.icon:SetPoint("LEFT", 0, 0)
    z.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    z.name = S.schrift(z, "GameFontHighlightSmall", F.text)
    z.name:SetPoint("LEFT", 20, 0)
    z.name:SetWidth(BREITE - 140)
    z.name:SetJustifyH("LEFT")
    z.name:SetWordWrap(false)
    z.anzahl = S.schrift(z, "GameFontHighlightSmall", F.text)
    z.anzahl:SetPoint("RIGHT", -64, 0)
    z.wert = S.schrift(z, "GameFontHighlightSmall", F.erfolg)
    z.wert:SetPoint("RIGHT", 0, 0)
    z:Hide()
    self.funde[i] = z
  end

  -- Unten: Rang mit Fortschritt zum nächsten und das Tagesziel (Erfolge.lua)
  local linie = f:CreateTexture(nil, "ARTWORK")
  linie:SetPoint("BOTTOMLEFT", RAND + 4, RAND + UNTEN - 2)
  linie:SetPoint("BOTTOMRIGHT", -RAND - 4, RAND + UNTEN - 2)
  linie:SetHeight(1)
  linie:SetColorTexture(F.rand[1], F.rand[2], F.rand[3], 0.25)
  f.rang = S.schrift(f, "GameFontHighlightSmall", F.akzent)
  f.rang:SetPoint("BOTTOMLEFT", RAND + 4, RAND + 6)
  f.heute = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.heute:SetPoint("BOTTOMRIGHT", -RAND - 4, RAND + 6)
  f.balken = S.balken(f, INNEN, 3)
  f.balken:SetPoint("BOTTOMLEFT", RAND + 4, RAND)

  -- Laufende Zeit einmal pro Sekunde, nur solange das Fenster sichtbar ist
  local warten = 0
  f:SetScript("OnUpdate", function(_, dt)
    warten = warten + dt
    if warten < 1 then return end
    warten = 0
    G:Aktualisieren()
  end)
  f:Hide()
end

-- Soll das Fenster zu sehen sein? Nur mit einer Sitzung, die schon etwas gesammelt hat
function G:Gewollt()
  if not (ns.db.zaehlen and ns.db.sammelLeisteZeigen) then return false end
  local s = ns.Sammeln:Sitzung()
  if not s.start then return false end
  return self.zuBis ~= s.start
end

function G:Aktualisieren()
  if not self.rahmen then return end
  local zeigen = self:Gewollt()
  if self.rahmen:IsShown() ~= zeigen then self.rahmen:SetShown(zeigen) end
  if not zeigen then return end
  local Z = ns.Sammeln
  local st = Z:Stand()
  local f = self.rahmen
  f.zeit:SetText(ns.dauer(st.dauer))
  if f.weiter.an ~= ns.Wegweiser.Laeuft() then
    f.weiter.an = ns.Wegweiser.Laeuft()
    pinZeigen(f.weiter, f.weiter.an)
  end
  if st.wertProStunde then
    f.gold:SetText(string.format(L.GATHER_BAR_GOLD_RATE, ns.geld(st.wertProStunde)))
    f.gold:SetTextColor(rgba(F.erfolg))
  elseif st.wert then
    f.gold:SetText(string.format(L.GATHER_BAR_WORTH, ns.geld(st.wert)))
    f.gold:SetTextColor(rgba(F.erfolg))
  else
    f.gold:SetText(Z.MitPreisen() and L.GATHER_BAR_NO_VALUE or L.GATHER_BAR_NO_PRICES)
    f.gold:SetTextColor(rgba(F.leise))
  end
  local teile = { Z.Text(st) }
  table.insert(teile, st.proStunde and string.format(L.GATHER_RATE, st.proStunde) or L.GATHER_BAR_MEASURING)
  if st.wertProStunde and st.wert then table.insert(teile, string.format(L.GATHER_WORTH, ns.geld(st.wert))) end
  f.info:SetText(table.concat(teile, "  \194\183  "))

  -- Funde: mit Preisen die wertvollsten, sonst die häufigsten
  local liste = {}
  for _, e in ipairs(st.liste) do table.insert(liste, e) end
  if st.wert then
    table.sort(liste, function(a, b)
      if (a.wert or 0) ~= (b.wert or 0) then return (a.wert or 0) > (b.wert or 0) end
      return a.anzahl > b.anzahl
    end)
  end
  -- Infozeile ein- oder zweizeilig. Braucht ein Beruf den Lehrer, steht das darunter (dringend in
  -- Gelb, bald in Grau), die Funde rücken nach unten.
  local info = math.min(2 * 12 + 2, math.max(INFO, (f.info:GetStringHeight() or 12) + 4))
  local warnung, dringend, berufArt
  if ns.Berufe then warnung, dringend, berufArt = ns.Berufe.Warnung() end
  f.beruf:SetShown(warnung ~= nil)
  f.lehrer:SetShown(warnung ~= nil)
  f.berufArt = berufArt
  f.beruf:SetText(warnung or "")
  f.beruf:SetTextColor(rgba(dringend and F.hinweis or F.leise))
  f.beruf:ClearAllPoints()
  f.beruf:SetPoint("TOPLEFT", RAND + 4, -RAND - KOPF - GROSS - info - 2)
  local extra = (info - INFO) + (warnung and BERUF or 0)
  local n = 0
  for i, z in ipairs(self.funde) do
    local e = liste[i]
    z:ClearAllPoints()
    z:SetPoint("TOPLEFT", RAND + 4, -RAND - KOPF - GROSS - INFO - 4 - extra - (i - 1) * FUND)
    z:SetShown(e ~= nil)
    if e then
      n = n + 1
      z.icon:SetTexture((C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id)) or 134400)
      z.name:SetText((C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.id)) or tostring(e.id))
      z.anzahl:SetText(tostring(e.anzahl))
      z.wert:SetText(e.wert and ns.geld(e.wert) or "")
    end
  end

  -- Rang und heute
  local E = ns.Erfolge
  if E and ns.db.erfolge and ns.db.erfolge.punkte then
    local r = E:Stand()
    f.rang:SetText(string.format(L.BAR_RANK, r.name, E.Zahl(r.punkte), E.Zahl(r.bis)))
    f.balken:Setzen((r.punkte - r.von) / (r.bis - r.von))
    f.heute:SetText(string.format(L.BAR_TODAY, r.heute, r.ziel))
    f.heute:SetTextColor(rgba(r.erreicht and F.erfolg or F.leise))
  end
  f:SetHeight(2 * RAND + KOPF + GROSS + INFO + 4 + extra + n * FUND + UNTEN)
end

ns.beimStart(function()
  G:Bauen()
  G:Aktualisieren()
end)
ns.beimAktualisieren(function() G:Aktualisieren() end)
