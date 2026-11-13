-- Hauptfenster: Status, Gathered, Journal, Settings, Help. Öffnen mit /hop, Minikarten-Knopf, Rechtsklick aufs Symbol
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
  { schluessel = "sammeln", text = L.TAB_GATHERED },
  { schluessel = "journal", text = L.TAB_JOURNAL },
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

-- Seite: Gathered (Sammelzähler, Sammeln.lua) --------------------------------------------------

local function bauenSammeln()
  local f = seite("sammeln")
  local Z = ns.Sammeln
  S.ueberschrift(f, L.GATHER_SESSION):SetPoint("TOPLEFT", 0, 0)
  f.seit = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.seit:SetPoint("TOPLEFT", 120, -2)
  f.neu = S.textKnopf(f, L.BTN_GATHER_RESET, 110, function() Z:Neu() end)
  f.neu:SetHeight(20)
  f.neu:SetPoint("TOPRIGHT", 0, 2)
  S.tooltip(f.neu, L.BTN_GATHER_RESET, L.BTN_GATHER_RESET_HELP)
  f.summe = S.absatz(f, B, F.text, "GameFontHighlight")
  f.summe:SetPoint("TOPLEFT", 0, -24)
  f.rate = S.absatz(f, B, F.leise)
  f.rate:SetPoint("TOPLEFT", 0, -44)

  f.liste = S.liste(f, B, 24 * 5, 24, function(l)
    local z = S.zeile(l)
    z.icon = z:CreateTexture(nil, "ARTWORK")
    z.icon:SetSize(20, 20)
    z.icon:SetPoint("LEFT", 4, 0)
    z.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    z.name = S.schrift(z, "GameFontHighlight", F.text)
    z.name:SetPoint("LEFT", 30, 0)
    z.name:SetWidth(B - 190)
    z.name:SetJustifyH("LEFT")
    z.name:SetWordWrap(false)
    z.anzahl = S.schrift(z, "GameFontHighlight", F.text)
    z.anzahl:SetPoint("RIGHT", -100, 0)
    z.wert = S.schrift(z, "GameFontHighlightSmall", F.erfolg)
    z.wert:SetPoint("RIGHT", -10, 0)
    z:SetScript("OnEnter", function(self)
      if not self.eintrag then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if not pcall(GameTooltip.SetItemByID, GameTooltip, self.eintrag.id) then GameTooltip:SetText(tostring(self.eintrag.id)) end
      GameTooltip:Show()
    end)
    z:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return z
  end)
  f.liste:SetPoint("TOPLEFT", 0, -72)

  S.ueberschrift(f, L.GATHER_TOTAL):SetPoint("TOPLEFT", 0, -206)
  f.gesamt = S.absatz(f, B, F.text, "GameFontHighlight")
  f.gesamt:SetPoint("TOPLEFT", 0, -226)

  f.zaehlen = S.haken(f, B, L.SET_GATHER, L.SET_GATHER_HELP, function(_, an)
    ns.db.zaehlen = an
    ns.aktualisieren()
  end)
  f.zaehlen:SetPoint("TOPLEFT", 0, -260)
  f.zeigen = S.haken(f, B, L.SET_GATHER_ICON, L.SET_GATHER_ICON_HELP, function(_, an)
    ns.db.zaehlerZeigen = an
    ns.aktualisieren()
  end)
  f.zeigen:SetPoint("TOPLEFT", 0, -284)
  f.leiste = S.haken(f, B, L.SET_GATHER_BAR, L.SET_GATHER_BAR_HELP, function(_, an)
    ns.db.sammelLeisteZeigen = an
    if an then ns.SammelLeiste.zuBis = nil end
    ns.aktualisieren()
  end)
  f.leiste:SetPoint("TOPLEFT", 0, -308)
  f.karte = S.haken(f, B, L.SET_GATHER_MAP, L.SET_GATHER_MAP_HELP, function(_, an)
    ns.db.karteZeigen = an
    if ns.SammelKarte then ns.SammelKarte:Zeichnen(true) end
    ns.aktualisieren()
  end)
  f.karte:SetPoint("TOPLEFT", 0, -332)
  -- Preisquelle (Patrick, 13. Nov: Auctionator als Standard, Midas nur auf Wunsch)
  local preise = S.schrift(f, "GameFontHighlightSmall", F.leise)
  preise:SetPoint("TOPLEFT", 0, -364)
  preise:SetText(L.PRICES)
  f.preis = S.segmente(f, B - 50, {
    { wert = "auctionator", text = L.PRICE_AUCTIONATOR, hilfe = L.PRICE_HELP },
    { wert = "midas", text = L.PRICE_MIDAS, hilfe = L.PRICE_HELP },
    { wert = "beide", text = L.PRICE_BOTH, hilfe = L.PRICE_HELP },
  }, function(wert)
    ns.db.preisQuelle = wert
    ns.aktualisieren()
  end)
  f.preis:SetPoint("TOPLEFT", 50, -359)
  f.hinweis = S.absatz(f, B, F.leise)
  f.hinweis:SetPoint("TOPLEFT", 0, -384)

  function f:Aktualisieren()
    local st = Z:Stand()
    self.seit:SetText(st.start and string.format(L.GATHER_SINCE, date("%H:%M", st.start)) or "")
    if st.alle == 0 then
      self.summe:SetText(L.GATHER_NONE)
      -- Zuletzt beendete Sitzung, solange noch keine neue läuft
      self.rate:SetText(Z.LetzteBilanz() or "")
    else
      self.summe:SetText(Z.Text(st))
      local teile = {}
      if st.proStunde then table.insert(teile, string.format(L.GATHER_RATE, st.proStunde)) end
      if st.wert then
        table.insert(teile, string.format(L.GATHER_WORTH, ns.geld(st.wert)))
        if st.wertProStunde then table.insert(teile, string.format(L.GATHER_WORTH_RATE, ns.geld(st.wertProStunde))) end
      end
      self.rate:SetText(table.concat(teile, "  \194\183  "))
    end
    self.liste:Setzen(st.liste, function(z, e)
      local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.id)
      local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(e.id)
      z.icon:SetTexture(icon or 134400)
      z.name:SetText(name or tostring(e.id))
      z.anzahl:SetText(tostring(e.anzahl))
      z.wert:SetText(e.wert and ns.geld(e.wert) or "")
    end, "")
    local g = Z.Summe(ns.db.gesamt.menge)
    local k = ns.db.gesamt.knoten
    local gesamt = Z.Text(g, (k.kraut or 0) + (k.erz or 0), k.leder or 0)
    if g.wert then gesamt = gesamt .. "\n" .. string.format(L.GATHER_WORTH, ns.geld(g.wert)) end
    self.gesamt:SetText(gesamt)
    self.zaehlen:Setzen(ns.db.zaehlen)
    self.zeigen:Setzen(ns.db.zaehlerZeigen)
    self.leiste:Setzen(ns.db.sammelLeisteZeigen)
    self.karte:Setzen(ns.db.karteZeigen)
    self.karte.menge:SetText(string.format(L.GATHER_MAP_COUNT, ns.SammelKarte and ns.SammelKarte.Anzahl() or 0))
    self.preis:Setzen(ns.db.preisQuelle or "auctionator")
    local fehlt = Z.FehlendeQuelle()
    self.hinweis:SetText(fehlt and string.format(L.PRICE_MISSING, fehlt) or "")
  end
end

-- Seite: Journal (Erfolge.lua): Rang, Tagesziel, Rekorde, Abzeichen und Sammelbuch ----------------

local FELD, LUECKE, TITEL, ABSATZ = 19, 2, 12, 3

-- Fortschritt eines Abzeichens als Text: "37 / 100", "3g 20s / 10g 0s", "42 / 60 min"
local function fortschritt(e)
  local E = ns.Erfolge
  local w = math.min(e.wert, e.ziel)
  if e.art == "gold" then return ns.geld(w) .. " / " .. ns.geld(e.ziel) end
  if e.art == "dauer" then return string.format(L.JOURNAL_MINUTES_OF, math.floor(w / 60), math.floor(e.ziel / 60)) end
  return E.Zahl(w) .. " / " .. E.Zahl(e.ziel)
end

local function abzeichenZeile(z, e)
  local t = L.BADGES[e.key] or {}
  z.icon:SetTexture(ns.Erfolge.Icon(e.icon))
  z.icon:SetDesaturated(not e.erhalten)
  z.icon:SetAlpha(e.erhalten and 1 or 0.5)
  z.name:SetText(t[1] or e.key)
  z.name:SetTextColor(rgba(e.erhalten and F.stern or F.leise))
  z.text:SetText(t[2] or "")
  if e.erhalten then
    z.rechts:SetText(date("%Y-%m-%d", e.erhalten))
    z.rechts:SetTextColor(rgba(F.erfolg))
    z.fort:Hide()
  else
    z.rechts:SetText(e.ziel > 1 and fortschritt(e) or "")
    z.rechts:SetTextColor(rgba(F.leise))
    z.fort:SetShown(e.ziel > 1)
    z.fort:Setzen(math.min(e.wert, e.ziel) / e.ziel)
  end
end

-- Ein Feld im Sammelbuch: Symbol des Gegenstands, grau, solange es noch nicht gefunden ist
local function feld(buch, i)
  local b = buch.felder[i]
  if b then return b end
  b = CreateFrame("Button", nil, buch)
  b:SetSize(FELD, FELD)
  b.rand = b:CreateTexture(nil, "BACKGROUND")
  b.rand:SetPoint("TOPLEFT", -1, 1)
  b.rand:SetPoint("BOTTOMRIGHT", 1, -1)
  b.rand:SetColorTexture(0, 0, 0, 0.8)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b:SetScript("OnEnter", function(self)
    local e = self.eintrag
    if not e then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if not pcall(GameTooltip.SetItemByID, GameTooltip, e.id) then GameTooltip:SetText(ns.Erfolge.Name(e.id)) end
    if e.gefunden then
      GameTooltip:AddLine(string.format(L.BOOK_FOUND, ns.Erfolge.Zahl(e.menge), date("%Y-%m-%d", e.gefunden)),
        F.erfolg[1], F.erfolg[2], F.erfolg[3])
    else
      GameTooltip:AddLine(L.BOOK_MISSING, F.leise[1], F.leise[2], F.leise[3])
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  buch.felder[i] = b
  return b
end

-- Gruppen untereinander: Überschrift mit Zahl, darunter die Felder in Reihen
local function buchZeichnen(buch, gruppen)
  local pro = math.floor((B + LUECKE) / (FELD + LUECKE))
  local y, n = 0, 0
  for gi, gr in ipairs(gruppen) do
    local t = buch.titel[gi]
    if not t then
      t = S.schrift(buch, "GameFontNormalSmall")
      buch.titel[gi] = t
    end
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", 0, -y)
    t:SetText(string.format(L.BOOK_GROUP, gr.name, gr.gefunden, #gr.eintraege))
    y = y + TITEL
    for i, e in ipairs(gr.eintraege) do
      n = n + 1
      local b = feld(buch, n)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", ((i - 1) % pro) * (FELD + LUECKE), -(y + math.floor((i - 1) / pro) * (FELD + LUECKE)))
      b.eintrag = e
      b.icon:SetTexture(ns.Erfolge.Icon(e.id))
      b.icon:SetDesaturated(not e.gefunden)
      b.icon:SetAlpha(e.gefunden and 1 or 0.35)
      b:Show()
    end
    y = y + math.ceil(#gr.eintraege / pro) * (FELD + LUECKE) + ABSATZ
  end
  for i = n + 1, #buch.felder do buch.felder[i]:Hide() end
end

local function bauenJournal()
  local f = seite("journal")
  local E = ns.Erfolge
  local HALB = math.floor(B / 2)

  -- Rang: Titel, Punkte und Balken bis zum nächsten
  f.rang = S.schrift(f, "GameFontNormalLarge")
  f.rang:SetPoint("TOPLEFT", 0, 0)
  f.teilen = S.textKnopf(f, L.SHARE_BUTTON, 70, function() ns.Teilen:Senden() end)
  f.teilen:SetHeight(20)
  f.teilen:SetPoint("TOPRIGHT", 0, 3)
  S.tooltip(f.teilen, L.SHARE_BUTTON, L.SHARE_BUTTON_HELP)
  f.punkte = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.punkte:SetPoint("RIGHT", f.teilen, "LEFT", -8, 0)
  f.balken = S.balken(f, B, 14, true)
  f.balken:SetPoint("TOPLEFT", 0, -24)
  S.tooltip(f.balken, L.JOURNAL_POINTS, L.JOURNAL_POINTS_HELP)

  -- Freunde: was die Gruppe zuletzt geteilt hat (Teilen.lua), Einzelheiten im Tooltip
  f.freundeFeld = CreateFrame("Frame", nil, f)
  f.freundeFeld:SetSize(B, 14)
  f.freundeFeld:SetPoint("TOPLEFT", 0, -42)
  f.freundeFeld:EnableMouse(true)
  f.freunde = S.schrift(f.freundeFeld, "GameFontHighlightSmall", F.leise)
  f.freunde:SetPoint("LEFT", 0, 0)
  f.freunde:SetWidth(B)
  f.freunde:SetJustifyH("LEFT")
  f.freunde:SetWordWrap(false)
  f.freundeFeld:SetScript("OnEnter", function(self)
    local liste = ns.Teilen.Freunde()
    local l = F.leise
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(L.FRIENDS_TITLE, 1, 0.82, 0)
    if #liste == 0 then GameTooltip:AddLine(L.FRIENDS_NONE, l[1], l[2], l[3], true) end
    for _, fr in ipairs(liste) do
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine(fr.name, string.format(L.RANK_TITLE, fr.rang, fr.rangName), 1, 1, 1, F.akzent[1], F.akzent[2], F.akzent[3])
      GameTooltip:AddLine(string.format(L.FRIEND_POINTS, E.Zahl(fr.punkte), fr.serie, fr.serieBest), l[1], l[2], l[3])
      GameTooltip:AddLine(string.format(L.FRIEND_KINDS, fr.arten, fr.abzeichen), l[1], l[2], l[3])
      if (fr.gold or 0) > 0 then GameTooltip:AddLine(string.format(L.FRIEND_GOLD, ns.geld(fr.gold)), l[1], l[2], l[3]) end
      if (fr.knoten or 0) > 0 then GameTooltip:AddLine(string.format(L.FRIEND_NODES, fr.knoten), l[1], l[2], l[3]) end
      GameTooltip:AddLine(string.format(L.FRIEND_SHARED, date("%Y-%m-%d %H:%M", fr.zeit or 0)), l[1], l[2], l[3])
    end
    GameTooltip:Show()
  end)
  f.freundeFeld:SetScript("OnLeave", function() GameTooltip:Hide() end)

  -- Heute: Knoten zum Tagesziel, Serie, Wahl des Ziels
  S.ueberschrift(f, L.JOURNAL_TODAY):SetPoint("TOPLEFT", 0, -62)
  f.tag = S.balken(f, 110, 12, true)
  f.tag:SetPoint("TOPLEFT", 0, -82)
  S.tooltip(f.tag, L.JOURNAL_TODAY, L.JOURNAL_GOAL_HELP)
  f.tagText = S.schrift(f, "GameFontHighlightSmall", F.text)
  f.tagText:SetPoint("LEFT", f.tag, "RIGHT", 8, 0)
  f.serie = S.schrift(f, "GameFontHighlightSmall", F.leise)
  f.serie:SetPoint("TOPLEFT", 0, -100)
  local ziel = S.schrift(f, "GameFontHighlightSmall", F.leise)
  ziel:SetPoint("TOPLEFT", 0, -122)
  ziel:SetText(L.JOURNAL_GOAL)
  local optionen = {}
  for _, n in ipairs(E.ZIELE) do table.insert(optionen, { wert = n, text = tostring(n), hilfe = L.JOURNAL_GOAL_HELP }) end
  f.ziel = S.segmente(f, HALB - 44, optionen, function(n) E:ZielSetzen(n) end)
  f.ziel:SetPoint("TOPLEFT", 34, -117)

  -- Rekorde
  local rx = HALB + 12
  S.ueberschrift(f, L.JOURNAL_RECORDS):SetPoint("TOPLEFT", rx, -62)
  f.rekorde = {}
  for i, art in ipairs({ "gold", "knoten", "wert", "dauer" }) do
    local y = -82 - (i - 1) * 16
    local name = S.schrift(f, "GameFontHighlightSmall", F.leise)
    name:SetPoint("TOPLEFT", rx, y)
    name:SetText(L.RECORDS[art])
    local wert = S.schrift(f, "GameFontHighlightSmall", F.text)
    wert:SetPoint("TOPRIGHT", 0, y)
    f.rekorde[art] = wert
  end

  -- Abzeichen oder Sammelbuch, rechts daneben die Schalter für die Meldungen
  f.zeige = "abzeichen"
  f.ansicht = S.segmente(f, 270, {
    { wert = "abzeichen", text = L.JOURNAL_BADGES, hilfe = L.JOURNAL_BADGES_HELP },
    { wert = "buch", text = L.JOURNAL_BOOK, hilfe = L.JOURNAL_BOOK_HELP },
  }, function(w)
    f.zeige = w
    f:Aktualisieren()
  end)
  f.ansicht:SetPoint("TOPLEFT", 0, -146)
  f.meldungen = S.haken(f, 80, L.SET_POPUPS, L.SET_POPUPS_HELP, function(_, an)
    ns.db.meldungen = an
    ns.aktualisieren()
  end)
  f.meldungen:SetPoint("TOPLEFT", B - 152, -146)
  f.ton = S.haken(f, 64, L.SET_POPUP_SOUND, L.SET_POPUP_SOUND_HELP, function(_, an)
    ns.db.erfolgTon = an
    ns.aktualisieren()
  end)
  f.ton:SetPoint("TOPLEFT", B - 64, -146)

  local Y, ZEILE = -174, 38
  f.liste = S.liste(f, B, ZEILE * 5, ZEILE, function(l)
    local z = S.zeile(l)
    z.icon = z:CreateTexture(nil, "ARTWORK")
    z.icon:SetSize(30, 30)
    z.icon:SetPoint("LEFT", 4, 0)
    z.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    z.name = S.schrift(z, "GameFontNormal")
    z.name:SetPoint("TOPLEFT", 42, -4)
    z.text = S.schrift(z, "GameFontHighlightSmall", F.leise)
    z.text:SetPoint("TOPLEFT", 42, -21)
    for _, s in ipairs({ z.name, z.text }) do
      s:SetWidth(B - 160)
      s:SetJustifyH("LEFT")
      s:SetWordWrap(false)
    end
    z.rechts = S.schrift(z, "GameFontHighlightSmall", F.leise)
    z.rechts:SetPoint("TOPRIGHT", -12, -5)
    z.fort = S.balken(z, 96, 6)
    z.fort:SetPoint("BOTTOMRIGHT", -12, 9)
    z:HookScript("OnEnter", function(self)
      local e = self.eintrag
      if not e then return end
      local t = L.BADGES[e.key] or {}
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(t[1] or e.key, 1, 0.82, 0)
      GameTooltip:AddLine(t[2] or "", 1, 1, 1, true)
      if e.erhalten then
        GameTooltip:AddLine(string.format(L.BADGE_EARNED, date("%Y-%m-%d", e.erhalten)), F.erfolg[1], F.erfolg[2], F.erfolg[3])
      else
        GameTooltip:AddLine(fortschritt(e), F.leise[1], F.leise[2], F.leise[3])
        if e.art == "gold" and not ns.Sammeln.MitPreisen() then
          GameTooltip:AddLine(L.BADGE_NEEDS_PRICES, F.hinweis[1], F.hinweis[2], F.hinweis[3], true)
        end
      end
      GameTooltip:Show()
    end)
    z:HookScript("OnLeave", function() GameTooltip:Hide() end)
    return z
  end)
  f.liste:SetPoint("TOPLEFT", 0, Y)
  f.buch = CreateFrame("Frame", nil, f)
  f.buch:SetPoint("TOPLEFT", 0, Y)
  f.buch:SetSize(B, HOEHE + OBEN - UNTEN + Y)
  f.buch.titel, f.buch.felder = {}, {}

  function f:Aktualisieren()
    local st = E:Stand()
    self.rang:SetText(string.format(L.RANK_TITLE, st.rang, st.name))
    self.punkte:SetText(string.format(L.JOURNAL_POINTS_TEXT, E.Zahl(st.punkte)))
    local freunde = ns.Teilen.Freunde()
    if #freunde == 0 then
      self.freunde:SetText(L.FRIENDS_NONE)
    else
      local teile = {}
      for i, fr in ipairs(freunde) do
        if i > 3 then break end
        table.insert(teile, string.format(L.FRIEND_LINE, fr.name, fr.rangName, E.Zahl(fr.punkte)))
      end
      self.freunde:SetText(table.concat(teile, "   "))
    end
    self.balken:Setzen((st.punkte - st.von) / (st.bis - st.von),
      string.format(L.RANK_TO_NEXT, E.Zahl(st.bis - st.punkte), st.naechster))
    self.tag:Setzen(st.heute / st.ziel, nil, st.erreicht and F.erfolg or F.akzent)
    self.tagText:SetText(string.format(L.JOURNAL_TODAY_SHORT, st.heute, st.ziel))
    self.tagText:SetTextColor(rgba(st.erreicht and F.erfolg or F.text))
    self.serie:SetText(E.SerieText(st))
    self.ziel:Setzen(st.ziel)
    local r = ns.db.erfolge.rekord
    local ohne = ns.Sammeln.MitPreisen() and L.RECORD_NONE or L.RECORD_NEEDS_PRICES
    self.rekorde.gold:SetText(r.gold and ns.geld(r.gold.wert) or ohne)
    self.rekorde.knoten:SetText(r.knoten and E.Zahl(r.knoten.wert) or L.RECORD_NONE)
    self.rekorde.wert:SetText(r.wert and ns.geld(r.wert.wert) or ohne)
    self.rekorde.dauer:SetText(r.dauer and ns.dauer(r.dauer.wert) or L.RECORD_NONE)
    local gruppen, gesamt = E:Buch()
    self.ansicht:Setzen(self.zeige)
    self.ansicht.knoepfe[1].text:SetText(string.format(L.JOURNAL_BADGES_COUNT, st.abzeichen, st.abzeichenAlle))
    self.ansicht.knoepfe[2].text:SetText(string.format(L.JOURNAL_BOOK_COUNT, E.Arten(), gesamt))
    self.meldungen:Setzen(ns.db.meldungen)
    self.ton:Setzen(ns.db.erfolgTon)
    self.liste:SetShown(self.zeige == "abzeichen")
    self.buch:SetShown(self.zeige == "buch")
    if self.zeige == "buch" then
      buchZeichnen(self.buch, gruppen)
    else
      self.liste:Setzen(E:AbzeichenListe(), abzeichenZeile, "")
    end
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
    haken("lichtsaeule", L.SET_PILLAR, L.SET_PILLAR_HELP, -372, function(an) if ns.Lichtsaeule then ns.Lichtsaeule:Schalten(an) end end),
  }
  -- Stil der Lichtsäule rechts in ihrer Zeile (Patrick: verschiedene zur Auswahl)
  local saeulenZeile = f.unten[#f.unten]
  f.saeulenStil = S.auswahl(f, 104, function()
    local liste = {}
    for _, s in ipairs(ns.Lichtsaeule and ns.Lichtsaeule.STILE or {}) do
      table.insert(liste, { wert = s.wert, text = L[s.text], farbe = s.wert == ns.db.saeulenStil and F.akzent or F.text })
    end
    return liste
  end, function(wert)
    ns.db.saeulenStil = wert
    if ns.Lichtsaeule then ns.Lichtsaeule:StilSetzen(wert) end
    ns.aktualisieren()
  end)
  f.saeulenStil:SetPoint("RIGHT", saeulenZeile, "RIGHT", 0, 0)
  S.tooltip(f.saeulenStil, L.PILLAR_STYLE_GLOW .. ", " .. L.PILLAR_STYLE_FIREFLIES .. ", " .. L.PILLAR_STYLE_BEAM, L.PILLAR_STYLE_HELP)

  function f:Aktualisieren()
    self.ausloeser:Setzen(ns.db.ausloeser)
    if ns.Lichtsaeule then
      for _, s in ipairs(ns.Lichtsaeule.STILE) do
        if s.wert == ns.Lichtsaeule.Stil() then self.saeulenStil:Setzen(L[s.text]) end
      end
    end
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
    local b = S.textKnopf(r, t.text, 86, function() S.klick() W:Zeigen(t.schluessel) end)
    b:SetPoint("TOPLEFT", r, "BOTTOMLEFT", 10 + (i - 1) * 89, -2)
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
  bauenSammeln()
  bauenJournal()
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
