-- Lichtsäule: ein Lichtstrahl über dem Kraut, der Erzader oder dem Kadaver zum Kürschnern direkt vor
-- dir (Patricks Wunsch, 13. Nov; bisher kam so etwas aus einem anderen Add-on). Eigene Umsetzung
-- über die Zielhilfe des Spiels („Soft Targeting“): Forever wählt das Objekt, mit dem die
-- Interaktionstaste gerade arbeiten würde (Einheit "softinteract"), und zeigt darüber eine
-- Namensplakette. An ihr hängt die Säule, grün für Kräuter, gold für Erz, braun für Leder.
-- Was es ist, sagt die Objekt-ID aus der GUID: Kräuter und Adern aus der Liste unten (Wowhead
-- Forever, 13. Nov 2026) und alles, was dieser Account schon gesammelt hat (Sammeln.lua lernt beim
-- Plündern). Ein Kadaver bekommt die Säule, wenn er tot ist, keine Beute mehr hat und der Char
-- Kürschnern kann. Nie über Namen oder Tooltip-Texte.
-- Die Zielhilfe braucht Einstellungen des Spiels (CVars). Hop & Seek setzt sie nur, solange die
-- Säule an ist, merkt sich die alten Werte und stellt sie beim Ausschalten zurück. Die Säule zeigt
-- nur an, gesammelt wird weiter nur mit Taste oder Klick.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil

local Li = {}
ns.Lichtsaeule = Li

local HOEHE = 380
Li.FARBEN = { kraut = { 0.35, 1.00, 0.45 }, erz = { 1.00, 0.76, 0.32 }, leder = { 0.92, 0.58, 0.32 } }

-- Kräuter und Adern als Objekte der Welt (Objekt-ID -> Art)
Li.OBJEKTE = {}
for _, id in ipairs({
  1617, 1618, 1619, 1620, 1621, 1622, 1623, 1624, 1628, 2041, 2042, 2043, 2044, 2045, 2046, 2866, 3724,
  3725, 3726, 3727, 3729, 3730, 13891, 141853, 142140, 142141, 142142, 142143, 142144, 142145, 175566,
  175928, 176583, 176584, 176586, 176587, 176588, 176589, 176636, 176637, 176638, 176639, 176640,
  176641, 176642, 176753, 180164, 180165, 180166, 180167, 180168, 439557, 439627, 439762, 439810,
  566786, 618987, 654624, 656160, 656161, 694732,
}) do Li.OBJEKTE[id] = "kraut" end
for _, id in ipairs({
  324, 1610, 1667, 1731, 1732, 1733, 1734, 1735, 2040, 2047, 2054, 2055, 2653, 3763, 3764, 19903,
  73940, 73941, 103711, 103713, 105569, 123309, 123310, 123848, 150079, 150080, 150081, 150082,
  165658, 175404, 176643, 176645, 177388, 180215, 181068, 181069, 181108, 181109, 439558, 439628,
  439778, 439815, 562111, 566779, 656332, 656333,
}) do Li.OBJEKTE[id] = "erz" end

-- Einstellungen der Zielhilfe: immer an (auch mit Maus und Tastatur), Plakette über dem Objekt,
-- rundherum suchen, etwas weiter (nie kürzer machen, als es war), das Symbol des Spiels darüber
local CVARS = {
  { name = "SoftTargetInteract", wert = "3" },
  { name = "SoftTargetNameplateInteract", wert = "1" },
  { name = "SoftTargetInteractArc", wert = "2" },
  { name = "SoftTargetInteractRange", wert = "15", mindestens = true },
  { name = "SoftTargetIconGameObject", wert = "1" },
  { name = "SoftTargetIconInteract", wert = "1" },
}

local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end

local function cvarLesen(name)
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
  if C_CVar and C_CVar.SetCVar then return pcall(C_CVar.SetCVar, name, wert) end
  if SetCVar then return pcall(SetCVar, name, wert) end
  return false
end

-- Kann dieser Client die Zielhilfe? (die erste Einstellung muss es geben)
function Li.Moeglich() return cvarLesen("SoftTargetInteract") ~= nil end

-- Einstellungen setzen, alte Werte merken (nur einmal: beim zweiten Mal stehen schon unsere drin)
function Li:Setzen()
  if InCombatLockdown and InCombatLockdown() then return false end
  local alt = ns.db.lichtsaeuleAlt
  for _, c in ipairs(CVARS) do
    local jetzt = cvarLesen(c.name)
    local genug = c.mindestens and tonumber(jetzt) and tonumber(jetzt) >= tonumber(c.wert)
    if jetzt ~= nil and jetzt ~= c.wert and not genug then
      if alt[c.name] == nil then alt[c.name] = jetzt end
      cvarSetzen(c.name, c.wert)
    end
  end
  return true
end

-- Alte Werte zurück
function Li:Zuruecksetzen()
  local alt = ns.db.lichtsaeuleAlt
  for name, wert in pairs(alt) do cvarSetzen(name, wert) end
  ns.db.lichtsaeuleAlt = {}
end

-- Schalter in den Einstellungen und /hop pillar
function Li:Schalten(an)
  if InCombatLockdown and InCombatLockdown() then
    ns.db.lichtsaeule = not an
    ns.aktualisieren()
    return ns.melde(L.PILLAR_COMBAT)
  end
  if an and not Li.Moeglich() then
    ns.db.lichtsaeule = false
    return ns.melde(L.PILLAR_UNSUPPORTED)
  end
  ns.db.lichtsaeule = an and true or false
  if an then self:Setzen() else self:Zuruecksetzen() end
  ns.melde(an and L.PILLAR_ON or L.PILLAR_OFF)
  self:Aktualisieren()
  ns.aktualisieren()
end

-- Stile (Patrick, 13. Nov: eigene Visuals, verschiedene zur Auswahl):
--   strahl  drei Lagen mit Verlauf (schmal und hell, mittel, breit und schwach), ohne Grafik
--   schein  weiche Lichtsäule mit Schwaden, in Blender gerendert (Media/Schein)
--   funken  Lichtfunken steigen um den Knoten auf, dazu ein schwacher Schein (Media/Funke)
-- Alle Grafiken sind weiß, die Farbe kommt von SetVertexColor, das Licht addiert sich zur Welt.
local MEDIA = "Interface\\AddOns\\HopAndSeek\\Media\\"
Li.STILE = {
  { wert = "schein", text = "PILLAR_STYLE_GLOW" },
  { wert = "funken", text = "PILLAR_STYLE_FIREFLIES" },
  { wert = "strahl", text = "PILLAR_STYLE_BEAM" },
}
local LAGEN = { { breite = 3, alpha = 0.95 }, { breite = 11, alpha = 0.42 }, { breite = 28, alpha = 0.16 } }
local FUNKEN, FUNKEN_HOEHE = 12, 260

local function zufall(a, b) return a + math.random() * (b - a) end

-- Ein Funke beginnt unten am Knoten, etwas zur Seite versetzt, mit eigenem Tempo und Pendeln
local function funkeNeu(p, irgendwo)
  p.y = irgendwo and zufall(0, FUNKEN_HOEHE) or zufall(-10, 10)
  p.x0 = zufall(-12, 12)
  p.tempo = zufall(38, 82)
  p.weite = zufall(4, 12)
  p.takt = zufall(1.2, 2.6)
  p.phase = zufall(0, 6.28)
  p.groesse = zufall(7, 14)
  p.t:SetSize(p.groesse, p.groesse)
end

function Li:Bauen()
  if self.rahmen then return end
  local f = CreateFrame("Frame", "HopAndSeekPillar", UIParent)
  self.rahmen = f
  f:SetSize(48, HOEHE)
  f:SetFrameStrata("BACKGROUND")
  f:EnableMouse(false)
  -- Strahl
  f.lagen = {}
  for i, d in ipairs(LAGEN) do
    local t = f:CreateTexture(nil, "ARTWORK", nil, 4 - i)
    t:SetTexture(S.WEISS)
    if t.SetBlendMode then t:SetBlendMode("ADD") end
    t:SetSize(d.breite, HOEHE)
    t:SetPoint("BOTTOM")
    t.alpha = d.alpha
    f.lagen[i] = t
  end
  -- Schein aus Blender
  f.schein = f:CreateTexture(nil, "ARTWORK", nil, 1)
  f.schein:SetTexture(MEDIA .. "Schein")
  if f.schein.SetBlendMode then f.schein:SetBlendMode("ADD") end
  f.schein:SetSize(48, HOEHE)
  f.schein:SetPoint("BOTTOM")
  -- Funken
  f.funken = {}
  for i = 1, FUNKEN do
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetTexture(MEDIA .. "Funke")
    if t.SetBlendMode then t:SetBlendMode("ADD") end
    local p = { t = t }
    funkeNeu(p, true)
    f.funken[i] = p
  end
  -- Atmen (Strahl, Schein) und Aufsteigen (Funken), nur solange die Säule zu sehen ist
  local zeit = 0
  f:SetScript("OnUpdate", function(self, dt)
    dt = dt or 0
    zeit = zeit + dt
    if self.stil ~= "funken" then
      self:SetAlpha(0.82 + 0.18 * math.sin(zeit * 2.6))
      return
    end
    self:SetAlpha(1)
    for _, p in ipairs(self.funken) do
      p.y = p.y + p.tempo * dt
      if p.y > FUNKEN_HOEHE then funkeNeu(p) end
      local anteil = math.max(0, p.y) / FUNKEN_HOEHE
      -- unten einblenden, oben ausblenden
      local alpha = math.min(1, anteil * 6) * math.min(1, (1 - anteil) * 2.5)
      p.t:SetAlpha(alpha * 0.95)
      p.t:ClearAllPoints()
      p.t:SetPoint("CENTER", self, "BOTTOM", p.x0 + math.sin(zeit * p.takt + p.phase) * p.weite, math.max(0, p.y))
    end
  end)
  f:Hide()
end

-- Stil zeigen: nur die Teile des gewählten Stils, alle in der Farbe der Art
local function faerben(f, farbe, stil)
  local r, g, b = farbe[1], farbe[2], farbe[3]
  for _, t in ipairs(f.lagen) do
    t:SetShown(stil == "strahl")
    if stil == "strahl" then
      if t.SetGradient and CreateColor then
        t:SetVertexColor(1, 1, 1, 1)
        local ok = pcall(t.SetGradient, t, "VERTICAL", CreateColor(r, g, b, t.alpha), CreateColor(r, g, b, 0))
        if not ok then t:SetVertexColor(r, g, b, t.alpha * 0.6) end
      else
        t:SetVertexColor(r, g, b, t.alpha * 0.6)
      end
    end
  end
  f.schein:SetShown(stil == "schein" or stil == "funken")
  f.schein:SetVertexColor(r, g, b, stil == "funken" and 0.35 or 1)
  for _, p in ipairs(f.funken) do
    p.t:SetShown(stil == "funken")
    p.t:SetVertexColor(math.min(1, r + 0.25), math.min(1, g + 0.25), math.min(1, b + 0.25), 1)
  end
  f.stil = stil
end

function Li.Stil()
  local s = ns.db and ns.db.saeulenStil
  for _, e in ipairs(Li.STILE) do if e.wert == s then return s end end
  return "schein"
end

-- Stil gewechselt: sofort neu färben
function Li:StilSetzen(wert)
  if wert then ns.db.saeulenStil = wert end
  if self.rahmen then self.rahmen.art = nil end
  self:Aktualisieren()
end

-- Was ist das Ziel der Zielhilfe? "kraut", "erz", "leder" oder nil
function Li.Art(guid)
  if type(guid) ~= "string" or geheim(guid) then return nil end
  local id = ns.Sammeln.ObjektID(guid)
  if id then return ns.db.knotenObjekte[id] or Li.OBJEKTE[id] end
  if string.find(guid, "^Creature") and UnitIsDead and UnitIsDead("softinteract") then
    -- Kadaver ohne Beute, den man noch benutzen kann: zum Kürschnern. Fehlt CanLootUnit, gilt ein
    -- Kadaver, den der Char schon geplündert hat.
    if not (ns.Berufe and ns.Berufe.Hat("leder")) then return nil end
    if CanLootUnit then
      local ok, beute = pcall(CanLootUnit, guid)
      if ok and beute == false then return "leder" end
      if ok and beute ~= nil then return nil end
    end
    if ns.Sammeln.gepluendert[guid] then return "leder" end
  end
end

-- Plakette der Zielhilfe (direkt oder über die Liste aller Plaketten)
local function plakette(guid)
  if not C_NamePlate then return nil end
  if C_NamePlate.GetNamePlateForUnit then
    local ok, p = pcall(C_NamePlate.GetNamePlateForUnit, "softinteract")
    if ok and p then return p end
    -- Manche Plaketten kommen nur unter ihrer eigenen Kennung ("nameplate12"): die zuletzt
    -- angelegte, die zur Zielhilfe gehört
    if Li.platteToken then
      local ok2, p2 = pcall(C_NamePlate.GetNamePlateForUnit, Li.platteToken)
      if ok2 and p2 and UnitGUID and UnitGUID(Li.platteToken) == guid then return p2 end
    end
  end
  if C_NamePlate.GetNamePlates then
    local ok, alle = pcall(C_NamePlate.GetNamePlates)
    if ok and type(alle) == "table" then
      for _, p in ipairs(alle) do
        local token = p.namePlateUnitToken or (p.UnitFrame and p.UnitFrame.unit)
        if token and UnitGUID and UnitGUID(token) == guid then return p end
      end
    end
  end
end

-- Was die Säule gerade sieht, für /hop debug (steht danach auch in den gespeicherten Daten)
function Li.Diagnose()
  local guid = UnitGUID and UnitGUID("softinteract")
  local sicher = guid and not geheim(guid) and guid or nil
  local beute = "fehlt"
  if CanLootUnit and sicher then
    local ok, a, b = pcall(CanLootUnit, sicher)
    beute = ok and (tostring(a) .. "," .. tostring(b)) or "Fehler"
  end
  local d = {
    zeit = date("%Y-%m-%d %H:%M:%S"),
    an = tostring(ns.db.lichtsaeule), moeglich = tostring(Li.Moeglich()),
    ziel = guid and (geheim(guid) and "geheim" or guid) or "keins",
    art = tostring(Li.Art(guid)),
    tot = tostring(UnitIsDead and UnitIsDead("softinteract")),
    beute = beute,
    gepluendert = tostring(sicher ~= nil and ns.Sammeln.gepluendert[sicher] == true),
    plakette = tostring(plakette(sicher) ~= nil),
    kuerschnern = tostring(ns.Berufe and ns.Berufe.Hat("leder")),
    berufe = ns.Berufe and ns.Berufe.Roh() or {},
    cvars = {},
  }
  for _, c in ipairs(CVARS) do d.cvars[c.name] = tostring(cvarLesen(c.name)) end
  return d
end

function Li:Verstecken()
  if self.rahmen then
    self.rahmen:Hide()
    self.rahmen.platte = nil
  end
end

-- Die letzten 20 Schritte mit allem, was die Säule geprüft hat. Steht nach /reload in den
-- gespeicherten Daten (saeulenLog), so lässt sich nachsehen, warum keine Säule kam.
local zuletztZeile
local function protokoll(zeile)
  if zeile == zuletztZeile then return end
  zuletztZeile = zeile
  ns.db.saeulenLog = type(ns.db.saeulenLog) == "table" and ns.db.saeulenLog or {}
  table.insert(ns.db.saeulenLog, date("%H:%M:%S") .. " " .. zeile)
  while #ns.db.saeulenLog > 20 do table.remove(ns.db.saeulenLog, 1) end
end
Li.Protokoll = protokoll

-- Geprüft wird nur, wenn sich Ziel oder Anzeige ändern: In Städten kommen Plaketten-Ereignisse
-- dutzendweise, die Diagnose fragt jedes Mal Berufe und alle Plaketten ab (Patrick, 13. Nov: die
-- Add-ons dürfen nicht zu viel fressen).
local zuletztGeprueft
local function merken(guid, gezeigt)
  local schluessel = tostring(guid) .. (gezeigt and "+" or "-")
  if schluessel == zuletztGeprueft then return end
  zuletztGeprueft = schluessel
  local ok, d = pcall(Li.Diagnose)
  if not ok then return end
  protokoll(string.format("%s art=%s tot=%s beute=%s plakette=%s kuerschner=%s nameplateCVar=%s gezeigt=%s",
    d.ziel, d.art, d.tot, d.beute, d.plakette, d.kuerschnern, tostring(d.cvars.SoftTargetNameplateInteract), tostring(gezeigt)))
end

function Li:Aktualisieren()
  if not (ns.db and ns.db.lichtsaeule and ns.db.an) then return self:Verstecken() end
  local guid = UnitGUID and UnitGUID("softinteract")
  local art = Li.Art(guid)
  if not art then
    if guid and not geheim(guid) then merken(guid, false) end
    return self:Verstecken()
  end
  local platte = plakette(guid)
  if guid and not geheim(guid) then merken(guid, platte ~= nil) end
  if not platte then return self:Verstecken() end
  self:Bauen()
  local f = self.rahmen
  local stil = Li.Stil()
  if f.platte ~= platte or f.art ~= art or f.stil ~= stil then
    f:ClearAllPoints()
    -- Der Fuß der Säule sitzt am Objekt, die Plakette schwebt darüber
    if not pcall(f.SetPoint, f, "BOTTOM", platte, "BOTTOM", 0, -48) then return self:Verstecken() end
    faerben(f, Li.FARBEN[art], stil)
    f.platte, f.art = platte, art
  end
  f:Show()
end

local function neu() Li:Aktualisieren() end
ns.Ereignis("PLAYER_SOFT_INTERACT_CHANGED", neu)
-- Neue Plakette: gehört sie zur Zielhilfe, merken wir uns ihre Kennung (für plakette())
ns.Ereignis("NAME_PLATE_UNIT_ADDED", function(token)
  if not (ns.db and ns.db.lichtsaeule) then return end
  local zurZielhilfe = false
  if type(token) == "string" and UnitIsUnit then
    local ok, ja = pcall(UnitIsUnit, token, "softinteract")
    zurZielhilfe = ok and ja and true or false
  end
  if zurZielhilfe then Li.platteToken = token end
  local guid = type(token) == "string" and UnitGUID and UnitGUID(token)
  if guid and not geheim(guid) and (zurZielhilfe or not string.find(guid, "^Player")) then
    local ok, p = pcall(C_NamePlate.GetNamePlateForUnit, token)
    local verboten = ok and p and p.IsForbidden and p:IsForbidden()
    protokoll(string.format("plakette neu %s %s zielhilfe=%s gefunden=%s verboten=%s", tostring(token), guid,
      tostring(zurZielhilfe), tostring(ok and p ~= nil), tostring(verboten)))
  end
  Li:Aktualisieren()
end)
ns.Ereignis("NAME_PLATE_UNIT_REMOVED", neu)
ns.Ereignis("LOOT_CLOSED", neu)
ns.beimStart(function()
  -- Wer die Säule an hat, bekommt die Einstellungen beim Login wieder (ein anderes Add-on oder das
  -- Spiel könnte sie zurückgesetzt haben)
  if ns.db.lichtsaeule then Li:Setzen() end
  Li:Aktualisieren()
end)
ns.beimAktualisieren(neu)
