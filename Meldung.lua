-- Meldungen: kleines, flaches Fenster oben in der Mitte für Abzeichen, Rang, Rekorde, Tagesziel und
-- neue Funde (Erfolge.lua). Eine nach der anderen, jede ein paar Sekunden, dann blendet sie aus.
-- Unter der Maus bleibt sie stehen. Linksklick öffnet das Journal, Rechtsklick schließt sie.
-- Zeigt nur an, sendet nichts.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F, rgba = S.F, S.rgba

local M = { warten = {} }
ns.Meldung = M

local BREITE, HOEHE, ICON = 300, 58, 40
local EIN, DAUER, KURZ, AUS = 0.25, 4, 2.5, 0.6

function M:Bauen()
  if self.rahmen then return end
  local f = S.kasten(UIParent, "Button", F.grund, F.rand, "HopAndSeekToast")
  self.rahmen = f
  f:SetSize(BREITE, HOEHE)
  -- Oben in der Mitte, über den roten Fehlermeldungen des Spiels
  f:SetPoint("TOP", UIParent, "TOP", 0, -64)
  f:SetFrameStrata("HIGH")
  f:SetClampedToScreen(true)
  f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  f:SetScript("OnClick", function(_, taste)
    if taste == "LeftButton" and ns.Fenster then ns.Fenster:Zeigen("journal") end
    M:Weiter()
  end)
  S.tooltip(f, L.ADDON_NAME, L.TOAST_HELP)
  S.schatten(f)
  -- Streifen in der Akzentfarbe links, wie beim Sammelfenster
  local streifen = f:CreateTexture(nil, "ARTWORK")
  streifen:SetPoint("TOPLEFT", 1, -1)
  streifen:SetPoint("BOTTOMLEFT", 1, 1)
  streifen:SetWidth(2)
  streifen:SetColorTexture(rgba(F.akzent))

  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(ICON, ICON)
  f.icon:SetPoint("LEFT", 12, 0)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- Ohne eigenes Bild (Rang, Tagesziel) das Symbol von Hop & Seek
  f.logo = S.symbol(f, ICON, f.icon)
  f.titel = S.schrift(f, "GameFontNormalSmall", F.akzent)
  f.titel:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 10, 1)
  f.text = S.schrift(f, "GameFontHighlight", F.text)
  f.text:SetPoint("TOPLEFT", f.titel, "BOTTOMLEFT", 0, -3)
  f.unter = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.unter:SetPoint("TOPLEFT", f.text, "BOTTOMLEFT", 0, -3)
  for _, s in ipairs({ f.titel, f.text, f.unter }) do
    s:SetWidth(BREITE - ICON - 34)
    s:SetJustifyH("LEFT")
    s:SetWordWrap(false)
  end
  -- Lange Erklärungen (Abzeichen) dürfen zweizeilig sein, statt abgeschnitten (Patricks Screenshot)
  f.unter:SetWordWrap(true)
  if f.unter.SetMaxLines then f.unter:SetMaxLines(2) end

  f.zeit, f.dauer = 0, DAUER
  f:SetScript("OnUpdate", function(self, dt)
    self.zeit = self.zeit + (dt or 0)
    if self.zeit > EIN and self:IsMouseOver() then self.zeit = math.min(self.zeit, EIN + self.dauer - 0.01) end
    local t = self.zeit
    if t < EIN then
      self:SetAlpha(t / EIN)
    elseif t < EIN + self.dauer then
      self:SetAlpha(1)
    elseif t < EIN + self.dauer + AUS then
      self:SetAlpha(1 - (t - EIN - self.dauer) / AUS)
    else
      M:Weiter()
    end
  end)
  f:Hide()
end

-- m = { art, titel, text, unter, icon (sonst das Symbol), farbe (Farbe des Texts) }
function M:Zeigen(m)
  table.insert(self.warten, m)
  if not (self.rahmen and self.rahmen:IsShown()) then self:Weiter() end
end

-- Nächste Meldung zeigen, ohne weitere ausblenden
function M:Weiter()
  self:Bauen()
  local f = self.rahmen
  local m = table.remove(self.warten, 1)
  self.aktuell = m
  if not m then
    f:Hide()
    return
  end
  local logo = m.icon == nil
  S.symbolZeigen(f.logo, logo)
  f.icon:SetShown(not logo)
  if not logo then f.icon:SetTexture(m.icon) end
  f.titel:SetText(m.titel or "")
  f.text:SetText(m.text or "")
  f.text:SetTextColor(rgba(m.farbe or F.text))
  f.unter:SetText(m.unter or "")
  -- Höhe nach dem Text: eine Zeile Untertitel passt in die Grundhöhe, eine zweite macht sie höher
  local zeile = 12
  local unter = math.min(2 * zeile + 2, math.max(zeile, (m.unter and m.unter ~= "") and (f.unter:GetStringHeight() or zeile) or zeile))
  f:SetHeight(HOEHE + unter - zeile)
  f.zeit = 0
  -- Warten noch weitere, ist jede etwas kürzer zu sehen
  f.dauer = #self.warten > 0 and KURZ or DAUER
  f:SetAlpha(0)
  f:Show()
  ns.Erfolge.Ton(m.art)
end
