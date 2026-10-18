-- Hauptfenster: Status, Settings, Help. Öffnen mit /hop, Minikarten-Knopf, Rechtsklick aufs Symbol
-- oder Optionen-Menü. Aussehen wie die Fenster des Spiels (Vorlage Campfire Buddy): Porträtrahmen,
-- versenkte Innenfläche, Reiter unten. Fehlt eine Vorlage, baut sich das Fenster flach selbst.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F, rgba = S.F, S.rgba
local SU = ns.Suche

local W = { seiten = {} }
ns.Fenster = W

local BREITE, HOEHE = 470, 480
local X, OBEN, UNTEN = 18, -72, 18
local B = BREITE - X - 20

local REITER = {
  { schluessel = "status", text = L.TAB_STATUS },
  { schluessel = "einstellungen", text = L.TAB_SETTINGS },
  { schluessel = "hilfe", text = L.TAB_HELP },
}

local function seite(schluessel)
  local f = CreateFrame("Frame", nil, W.rahmen)
  f:SetPoint("TOPLEFT", X, OBEN)
  f:SetSize(B, HOEHE + OBEN - UNTEN)
  if W.echt then f:SetFrameLevel((W.rahmen:GetFrameLevel() or 1) + 4) end
  f:Hide()
  W.seiten[schluessel] = f
  return f
end

local function jaNein(wert)
  if wert == nil then return L.UNKNOWN end
  return wert and L.YES or L.NO
end

-- Seite: Status --------------------------------------------------------------------------------

local function bauenStatus()
  local f = seite("status")
  S.ueberschrift(f, L.STATUS_NOW):SetPoint("TOPLEFT", 0, 0)
  f.icon = f:CreateTexture(nil, "ARTWORK")
  f.icon:SetSize(36, 36)
  f.icon:SetPoint("TOPLEFT", 0, -20)
  f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- Ohne aktive Suche das Symbol von Hop & Seek an derselben Stelle
  f.symbol = S.symbol(f, 36, f.icon)
  f.name = S.schrift(f, "GameFontHighlightLarge", F.text)
  f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 10, -2)
  f.zustand = S.absatz(f, B - 50, F.erfolg)
  f.zustand:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -4)

  f.wechseln = S.textKnopf(f, L.BTN_SWITCH, 120, function() SU:Wechseln("klick") end)
  f.wechseln:SetPoint("TOPRIGHT", 0, -22)
  S.tooltip(f.wechseln, L.BTN_SWITCH, L.BTN_SWITCH_HELP)

  S.ueberschrift(f, L.STATUS_CYCLE):SetPoint("TOPLEFT", 0, -78)
  f.kreis = S.absatz(f, B, F.text, "GameFontHighlight")
  f.kreis:SetPoint("TOPLEFT", 0, -98)

  S.ueberschrift(f, L.STATUS_CHECK):SetPoint("TOPLEFT", 0, -170)
  f.pruefung = S.absatz(f, B, F.leise, "GameFontHighlightSmall")
  f.pruefung:SetPoint("TOPLEFT", 0, -190)

  function f:Aktualisieren()
    local jetzt, naechste, kreis = SU:Vorschau()
    if jetzt then self.icon:SetTexture(SU.Icon(jetzt)) end
    self.icon:SetShown(jetzt ~= nil)
    S.symbolZeigen(self.symbol, jetzt == nil)
    self.name:SetText(jetzt and SU.Name(jetzt) or L.STATUS_NONE)
    local pause = SU:Pause("sprung")
    self.wechseln.text:SetText(#kreis == 1 and L.BTN_TURN_ON or L.BTN_SWITCH)
    if #kreis == 1 then
      local an = jetzt ~= nil
      self.zustand:SetText(string.format(an and L.STATUS_KEEP or L.STATUS_KEEP_OFF, SU.Name(kreis[1])))
      self.zustand:SetTextColor(rgba(an and F.erfolg or F.hinweis))
    elseif #kreis < 2 then
      self.zustand:SetText(L.STATUS_CYCLE_EMPTY)
      self.zustand:SetTextColor(rgba(F.hinweis))
    elseif pause then
      self.zustand:SetText(string.format(L.STATUS_PAUSED, pause))
      self.zustand:SetTextColor(rgba(F.hinweis))
    else
      local vorlage = ({ doppel = L.STATUS_DOUBLE, reiten = L.STATUS_MOUNTED })[ns.db.ausloeser] or L.STATUS_NEXT
      self.zustand:SetText(string.format(vorlage, SU.Name(naechste)))
      self.zustand:SetTextColor(rgba(F.erfolg))
    end
    local zeilen = {}
    for _, id in ipairs(kreis) do
      local an = id == jetzt
      table.insert(zeilen, "|T" .. tostring(SU.Icon(id)) .. ":16:16|t " .. (an and "|cffffd100" or "") .. SU.Name(id) .. (an and "|r" or ""))
    end
    self.kreis:SetText(#zeilen > 0 and table.concat(zeilen, "\n") or L.STATUS_CYCLE_EMPTY)
    local p = ns.db.probe
    local t = { string.format(L.STATUS_WORKS, jaNein(p.geht)), string.format(L.STATUS_GCD, jaNein(p.gcd)) }
    if p.abklingzeit then table.insert(t, string.format(L.STATUS_COOLDOWN, p.abklingzeit, ns.db.abstand or 2)) end
    if p.gcd and ns.db.ausloeser == "sprung" then table.insert(t, "|cffffd100" .. L.STATUS_GCD_TIP .. "|r") end
    if p.mehrere then table.insert(t, "|cff66d68f" .. L.STATUS_BOTH .. "|r") end
    if p.gesperrt then table.insert(t, "|cfff06059" .. string.format(L.STATUS_BLOCKED, p.gesperrt) .. "|r") end
    self.pruefung:SetText(table.concat(t, "\n"))
  end
end

-- Seite: Settings -----------------------------------------------------------------------------

local function bauenEinstellungen()
  local f = seite("einstellungen")
  f.schalter = {}
  local function haken(feld, text, hilfe, y, danach)
    local h = S.haken(f, B, text, hilfe, function(self, an)
      ns.db[feld] = an
      if danach then danach(an) end
      ns.aktualisieren()
    end)
    h.feld = feld
    h:SetPoint("TOPLEFT", 0, y)
    table.insert(f.schalter, h)
    return h
  end
  haken("an", L.SET_ON, L.SET_ON_HELP, 0, function(an)
    -- Wieder einschalten heißt: noch einmal versuchen, auch wenn das Spiel einmal gesperrt hat
    if an then ns.db.probe.gesperrt = nil end
  end)

  S.ueberschrift(f, L.SET_TRIGGER):SetPoint("TOPLEFT", 0, -32)
  f.ausloeser = S.segmente(f, B, {
    { wert = "sprung", text = L.TRIGGER_JUMP, hilfe = L.TRIGGER_JUMP_HELP },
    { wert = "doppel", text = L.TRIGGER_DOUBLE, hilfe = L.TRIGGER_DOUBLE_HELP },
    { wert = "reiten", text = L.TRIGGER_MOUNTED, hilfe = L.TRIGGER_MOUNTED_HELP },
  }, function(wert)
    ns.db.ausloeser = wert
    ns.aktualisieren()
  end)
  f.ausloeser:SetPoint("TOPLEFT", 0, -50)

  local warten = S.ueberschrift(f, L.SET_WAIT)
  warten:SetPoint("TOPLEFT", 0, -80)
  f.abstand = S.segmente(f, B * 0.6, {
    { wert = 1, text = L.WAIT_1, hilfe = L.WAIT_HELP },
    { wert = 2, text = L.WAIT_2, hilfe = L.WAIT_HELP },
    { wert = 3, text = L.WAIT_3, hilfe = L.WAIT_HELP },
  }, function(wert)
    ns.db.abstand = wert
    ns.aktualisieren()
  end)
  f.abstand:SetPoint("TOPLEFT", 0, -98)

  S.ueberschrift(f, L.SET_CYCLE):SetPoint("TOPLEFT", 0, -130)
  f.kreisHaken = {}
  for i = 1, 6 do
    local h = S.haken(f, B / 2 - 6, L.SET_CYCLE, L.SET_CYCLE_HELP, function(self, an)
      if self.id then ns.db.kreis[self.id] = an or nil end
      ns.aktualisieren()
    end)
    h:SetPoint("TOPLEFT", ((i - 1) % 2) * (B / 2), -148 - math.floor((i - 1) / 2) * 24)
    f.kreisHaken[i] = h
  end

  -- Die Schalter darunter rücken direkt unter die Suchen, die gerade zur Wahl stehen (sonst klafft
  -- bei zwei Suchen Platz für sechs, Patricks Screenshot 18. Okt). Die Lage setzt f:Aktualisieren.
  f.unten = {
    haken("pauseRuhe", L.SET_PAUSE_REST, L.SET_PAUSE_REST_HELP, -228),
    haken("ton", L.SET_SOUND, L.SET_SOUND_HELP, -252),
    haken("chat", L.SET_CHAT, L.SET_CHAT_HELP, -276),
    haken("anzeigeZeigen", L.SET_ICON, L.SET_ICON_HELP, -300),
    haken("gesperrt", L.SET_LOCK, L.SET_LOCK_HELP, -324),
    haken("minimapZeigen", L.SET_MINIMAP, L.SET_MINIMAP_HELP, -348, function() ns.Minimap:Sichtbarkeit() end),
  }

  function f:Aktualisieren()
    self.ausloeser:Setzen(ns.db.ausloeser)
    self.abstand:Setzen(ns.db.abstand or 2)
    for _, h in ipairs(self.schalter) do h:Setzen(ns.db[h.feld]) end
    -- Kreis: was der Char hat, dazu, was eingeschaltet ist; Kräuter und Erz stehen immer da
    local zeigen = {}
    for _, b in ipairs(SU.BEKANNT) do
      if SU.liste[b.id] or ns.db.kreis[b.id] or b.id == 2383 or b.id == 2580 then table.insert(zeigen, b.id) end
    end
    local reihen = math.max(1, math.ceil(math.min(#zeigen, #self.kreisHaken) / 2))
    for i, h in ipairs(self.unten) do
      h:ClearAllPoints()
      h:SetPoint("TOPLEFT", 0, -148 - reihen * 24 - 14 - (i - 1) * 24)
    end
    for i, h in ipairs(self.kreisHaken) do
      local id = zeigen[i]
      h.id = id
      h:SetShown(id ~= nil)
      if id then
        local hat = SU.liste[id] ~= nil
        h.name:SetText("|T" .. tostring(SU.Icon(id)) .. ":14:14|t " .. SU.Name(id))
        h.name:SetAlpha(hat and 1 or 0.5)
        h:Setzen(ns.db.kreis[id])
      end
    end
  end
end

-- Seite: Help ---------------------------------------------------------------------------------

local function bauenHilfe()
  local f = seite("hilfe")
  S.ueberschrift(f, L.HELP_TITLE):SetPoint("TOPLEFT", 0, 0)
  local text = S.absatz(f, B, F.text, "GameFontHighlight")
  text:SetPoint("TOPLEFT", 0, -20)
  text:SetText(L.HELP_TEXT)
  S.ueberschrift(f, L.HELP_COMMANDS):SetPoint("TOPLEFT", 0, -220)
  local befehle = S.absatz(f, B, F.leise, "GameFontHighlightSmall")
  befehle:SetPoint("TOPLEFT", 0, -240)
  local zeilen = {}
  for _, b in ipairs(ns.BEFEHLE or {}) do
    table.insert(zeilen, "/hop" .. (b[1] ~= "" and (" " .. b[1]) or "") .. "   " .. b[2])
  end
  befehle:SetText(table.concat(zeilen, "\n"))
end

-- Rahmen ---------------------------------------------------------------------------------------

local function bauenEcht(r)
  r:SetSize(BREITE, HOEHE)
  pcall(r.SetTitle, r, L.ADDON_NAME)
  -- Im Porträt das eine Symbol von Hop & Seek (Kräuter und Erz, diagonal geteilt). Das Porträt der
  -- Vorlage selbst bleibt leer, damit nicht noch ein zweites Bild durchscheint. Ohne Porträt der
  -- Vorlage bleibt das gezeichnete Icon.
  local halter = type(r.PortraitContainer) == "table" and r.PortraitContainer or r
  local portrait = halter.portrait or r.portrait
  if type(portrait) == "table" then
    if portrait.SetAlpha then portrait:SetAlpha(0) end
    local deckel = CreateFrame("Frame", nil, halter)
    deckel:SetAllPoints(portrait)
    deckel:SetFrameLevel((halter:GetFrameLevel() or 1) + 5)
    W.symbol = S.symbol(deckel, 58, portrait)
  elseif r.SetPortraitToAsset then
    pcall(r.SetPortraitToAsset, r, S.ICON)
  end
  local unter = S.schrift(r, "GameFontHighlightSmall")
  unter:SetPoint("TOPLEFT", 66, -36)
  unter:SetText(L.SUBTITLE)
  local version = S.schrift(r, "GameFontDisableSmall")
  version:SetPoint("TOPRIGHT", -14, -36)
  version:SetText(L.BY_AUTHOR .. "   v" .. ns.VERSION)
  local innen = S.vorlage("Frame", r, "InsetFrameTemplate")
  if innen then
    innen:SetFrameLevel((r:GetFrameLevel() or 1) + 1)
    innen:SetPoint("TOPLEFT", 4, -60)
    innen:SetPoint("BOTTOMRIGHT", -6, 4)
  end
  r.Tabs = {}
  local vorher
  for i, t in ipairs(REITER) do
    local tab = S.vorlage("Button", r, "PanelTabButtonTemplate", "HopAndSeekFrameTab" .. i)
    if tab then tab:SetText(t.text) else tab = S.textKnopf(r, t.text, 90, function() end) end
    if tab.SetID then tab:SetID(i) end
    if vorher then
      if tab.LeftActive then tab:SetPoint("TOPLEFT", vorher, "TOPRIGHT", 3, 0) else tab:SetPoint("LEFT", vorher, "RIGHT", -15, 0) end
    else
      tab:SetPoint("TOPLEFT", r, "BOTTOMLEFT", 12, 2)
    end
    if PanelTemplates_TabResize then pcall(PanelTemplates_TabResize, tab, 0) end
    tab.schluessel = t.schluessel
    tab:SetScript("OnClick", function()
      if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then pcall(PlaySound, SOUNDKIT.IG_CHARACTER_INFO_TAB) end
      W:Zeigen(t.schluessel)
    end)
    r.Tabs[i] = tab
    vorher = tab
  end
  if PanelTemplates_SetNumTabs then pcall(PanelTemplates_SetNumTabs, r, #REITER) end
  W.reiter = r.Tabs
end

local function bauenFlach(r)
  r:SetSize(BREITE, HOEHE)
  S.schatten(r)
  S.kopf(r, L.SUBTITLE)
  local zu = S.zeichenKnopf(r, "x", function() r:Hide() end)
  zu:SetPoint("TOPRIGHT", -8, -11)
  W.reiter = {}
  for i, t in ipairs(REITER) do
    local b = S.textKnopf(r, t.text, 100, function() S.klick() W:Zeigen(t.schluessel) end)
    b:SetPoint("TOPLEFT", r, "BOTTOMLEFT", 10 + (i - 1) * 104, -2)
    b.schluessel = t.schluessel
    W.reiter[i] = b
  end
end

function W:Bauen()
  local r = S.vorlage("Frame", UIParent, "PortraitFrameTemplate", "HopAndSeekFrame")
  self.echt = r ~= nil and r.SetTitle ~= nil
  if not self.echt then r = S.kasten(UIParent, "Frame", F.grund, F.rand, "HopAndSeekFrame") end
  self.rahmen = r
  local pos = ns.db.fenster
  if pos and pos.punkt then r:SetPoint(pos.punkt, UIParent, pos.punkt, pos.x, pos.y) else r:SetPoint("CENTER") end
  r:SetFrameStrata("HIGH")
  r:SetToplevel(true)
  r:SetClampedToScreen(true)
  r:EnableMouse(true)
  r:SetMovable(true)
  r:RegisterForDrag("LeftButton")
  r:SetScript("OnDragStart", function(self) self:StartMoving() end)
  r:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local punkt, _, _, x, y = self:GetPoint()
    ns.db.fenster = { punkt = punkt, x = x, y = y }
  end)
  if UISpecialFrames then table.insert(UISpecialFrames, "HopAndSeekFrame") end
  if self.echt then bauenEcht(r) else bauenFlach(r) end
  bauenStatus()
  bauenEinstellungen()
  bauenHilfe()
  r:Hide()
end

function W:Zeigen(schluessel)
  if not ns.db then return end
  if not self.rahmen then self:Bauen() end
  self.aktiv = schluessel or self.aktiv or "status"
  for k, f in pairs(self.seiten) do f:SetShown(k == self.aktiv) end
  for i, b in ipairs(self.reiter) do
    if self.echt and b.schluessel == self.aktiv and PanelTemplates_SetTab then pcall(PanelTemplates_SetTab, self.rahmen, i) end
  end
  self.rahmen:Show()
  self:Aktualisieren()
end

function W:Umschalten()
  if self.rahmen and self.rahmen:IsShown() then self.rahmen:Hide() else self:Zeigen() end
end

function W:Aktualisieren()
  if not (self.rahmen and self.rahmen:IsShown()) then return end
  local f = self.seiten[self.aktiv]
  if f and f.Aktualisieren then f:Aktualisieren() end
end

ns.beimAktualisieren(function() W:Aktualisieren() end)
