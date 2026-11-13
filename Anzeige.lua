-- Anzeige: kleines Symbol der aktiven Suche, verschiebbar. Grau, solange Hop & Seek pausiert.
-- Klick wechselt einmal (ein Klick, ein Wechsel), Rechtsklick öffnet das Fenster.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F, rgba = S.F, S.rgba
local SU = ns.Suche

local A = {}
ns.Anzeige = A

local GROESSE = 36

local function merken(f)
  local punkt, _, relativ, x, y = f:GetPoint()
  ns.db.anzeige = { punkt = punkt, relativ = relativ, x = x, y = y }
end

local function tooltip(f)
  GameTooltip:SetOwner(f, "ANCHOR_BOTTOMLEFT")
  local jetzt, naechste, kreis = SU:Vorschau()
  GameTooltip:SetText(jetzt and SU.Name(jetzt) or L.STATUS_NONE, 1, 0.82, 0)
  local pause = SU:Pause("sprung")
  if #kreis == 1 then
    local an = jetzt ~= nil
    local c = an and F.erfolg or F.hinweis
    GameTooltip:AddLine(an and L.ICON_KEPT_ON or string.format(L.STATUS_KEEP_OFF, SU.Name(kreis[1])), c[1], c[2], c[3], true)
  elseif pause then
    GameTooltip:AddLine(string.format(L.STATUS_PAUSED, pause), F.hinweis[1], F.hinweis[2], F.hinweis[3])
  elseif naechste and #kreis >= 2 then
    local vorlage = ({ doppel = L.STATUS_DOUBLE, reiten = L.STATUS_MOUNTED })[ns.db.ausloeser] or L.STATUS_NEXT
    GameTooltip:AddLine(string.format(vorlage, SU.Name(naechste)), F.erfolg[1], F.erfolg[2], F.erfolg[3])
  end
  if #kreis > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L.ICON_TOOLTIP_CYCLE, F.leise[1], F.leise[2], F.leise[3])
    for _, id in ipairs(kreis) do
      local an = id == jetzt
      GameTooltip:AddLine("|T" .. tostring(SU.Icon(id)) .. ":14:14|t " .. SU.Name(id), an and 1 or 0.8, an and 1 or 0.8, an and 1 or 0.8)
    end
  end
  -- Sammelzähler dieser Sitzung
  if ns.db.zaehlen and ns.Sammeln then
    local st = ns.Sammeln:Stand()
    if st.alle > 0 then
      GameTooltip:AddLine(" ")
      GameTooltip:AddLine(L.GATHER_SESSION, 1, 0.82, 0)
      GameTooltip:AddLine(ns.Sammeln.Text(st), 1, 1, 1, true)
      if st.proStunde then
        GameTooltip:AddLine(string.format(L.GATHER_RATE, st.proStunde), F.leise[1], F.leise[2], F.leise[3])
      end
      if st.wert then
        local wert = string.format(L.GATHER_WORTH, ns.geld(st.wert))
        if st.wertProStunde then wert = wert .. "  " .. string.format(L.GATHER_WORTH_RATE, ns.geld(st.wertProStunde)) end
        GameTooltip:AddLine(wert, F.erfolg[1], F.erfolg[2], F.erfolg[3])
      end
    end
  end
  -- Rang und Tagesziel (Erfolge.lua)
  if ns.db.zaehlen and ns.Erfolge and ns.db.erfolge and ns.db.erfolge.punkte then
    GameTooltip:AddLine(" ")
    ns.Erfolge:Tooltip(GameTooltip, true)
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(L.ICON_TOOLTIP_HELP, F.leise[1], F.leise[2], F.leise[3], true)
  GameTooltip:Show()
end

function A:Bauen()
  if self.rahmen then return end
  local f = S.kasten(UIParent, "Button", F.grund, F.rand, "HopAndSeekIcon")
  self.rahmen = f
  f:SetSize(GROESSE, GROESSE)
  local pos = ns.db.anzeige
  if pos and pos.punkt then
    f:SetPoint(pos.punkt, UIParent, pos.relativ or pos.punkt, pos.x, pos.y)
  else
    f:SetPoint("CENTER", UIParent, "CENTER", 260, -120)
  end
  f:SetFrameStrata("MEDIUM")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetPoint("TOPLEFT", 4, -4)
  f.icon:SetPoint("BOTTOMRIGHT", -4, 4)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- Ohne aktive Suche das Symbol von Hop & Seek an derselben Stelle
  f.symbol = S.symbol(f, GROESSE - 8, f.icon)
  f:SetScript("OnDragStart", function(self) if not ns.db.gesperrt then self:StartMoving() end end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    merken(self)
  end)
  f:SetScript("OnClick", function(_, taste)
    if taste == "RightButton" then
      ns.Fenster:Zeigen()
    else
      SU:Wechseln("klick")
    end
  end)
  f:SetScript("OnEnter", tooltip)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  -- Sammelzähler: Anzahl dieser Sitzung klein unter dem Symbol
  f.zahl = S.schrift(f, "NumberFontNormal", F.text)
  f.zahl:SetPoint("TOP", f, "BOTTOM", 0, -2)
  self:Aktualisieren()
end

function A:Aktualisieren()
  local f = self.rahmen
  if not f then return end
  local jetzt, _, kreis = SU:Vorschau()
  f:SetShown(ns.db.anzeigeZeigen and #kreis >= 1 and true or false)
  local pause = SU:Pause("sprung")
  if jetzt then f.icon:SetTexture(SU.Icon(jetzt)) end
  f.icon:SetShown(jetzt ~= nil)
  f.icon:SetDesaturated(pause and true or false)
  f.icon:SetAlpha(pause and 0.6 or 1)
  S.symbolZeigen(f.symbol, jetzt == nil, pause)
  S.randFarbe(f, pause and F.rand or F.akzent)
  local zahl = ""
  if ns.db.zaehlen and ns.db.zaehlerZeigen and ns.Sammeln then
    local st = ns.Sammeln:Stand()
    if st.alle > 0 then zahl = tostring(st.alle) end
  end
  f.zahl:SetText(zahl)
  if GameTooltip:GetOwner() == f then tooltip(f) end
end

ns.beimStart(function() A:Bauen() end)
ns.beimAktualisieren(function() A:Aktualisieren() end)
