-- Suche: liest die Minikarten-Suchen des Chars und wechselt beim Springen zur nächsten im Kreis.
-- Der Sprung des Spiels läuft über JumpOrAscendStart (Taste "Springen"). hooksecurefunc hängt sich
-- dahinter, ohne den Sprung zu verändern. Der Wechsel läuft also immer in einem echten Tastendruck
-- des Spielers, ein Druck ist höchstens ein Wechsel. Gewechselt wird über die Minikarten-Suche des
-- Spiels (C_Minimap.SetTracking), nicht über einen Zauber. Erkannt wird jede Suche an ihrer
-- Zauber-ID, nie am Namen.
local ADDON, ns = ...
local L = ns.L

local SU = { liste = {} }
ns.Suche = SU

-- Bekannte Suchen in der Reihenfolge des Kreises. name nur als Ersatz, sonst nennt das Spiel ihn.
SU.BEKANNT = {
  { id = 2383, name = L.TRACK_HERBS },     -- Find Herbs (Kräuterkunde)
  { id = 2580, name = L.TRACK_MINERALS },  -- Find Minerals (Bergbau)
  { id = 2481, name = L.TRACK_TREASURE },  -- Find Treasure (Zwerge)
  { id = 1494 },                           -- Track Beasts (Jäger)
  { id = 19883 },                          -- Track Humanoids (Jäger)
  { id = 19884 },                          -- Track Undead (Jäger)
  { id = 19885 },                          -- Track Hidden (Jäger)
  { id = 19880 },                          -- Track Elementals (Jäger)
  { id = 19878 },                          -- Track Demons (Jäger)
  { id = 19882 },                          -- Track Giants (Jäger)
  { id = 19879 },                          -- Track Dragonkin (Jäger)
  { id = 5225 },                           -- Track Humanoids (Druide in Katzengestalt)
  { id = 5500 },                           -- Sense Demons (Hexenmeister)
  { id = 5502 },                           -- Sense Undead (Paladin)
}

local DOPPEL = 0.6        -- Sekunden zwischen zwei Sprüngen für den Doppelsprung
local GCD = 61304         -- Zauber-ID der globalen Abklingzeit
-- Zwischen zwei Wechseln wartet Hop & Seek ns.db.abstand Sekunden (1, 2 oder 3). In Forever hat
-- der Wechsel etwa eine Sekunde Abklingzeit, ein Sprung darin brachte "Ability is not ready yet"
-- (Patrick, 18. Okt). Zusätzlich wird vor jedem Wechsel die Abklingzeit selbst geprüft.
-- Gestalten, die wie ein Reittier zählen: Reisegestalt, Geisterwolf, Fluggestalten
local REISEN = { [3] = true, [16] = true, [27] = true, [29] = true }

local function api(neu, alt) return ns.api(neu) or ns.api(alt) end

-- Suchen des Chars aus dem Spiel: [Zauber-ID] = { nr, name, icon, aktiv }. Die neue Schnittstelle
-- liefert eine Tabelle, ältere mehrere Werte (Name, Symbol, aktiv, Art, Unterart, Zauber-ID).
function SU:Lesen()
  local t = {}
  local anzahl = api("C_Minimap.GetNumTrackingTypes", "GetNumTrackingTypes")
  local info = api("C_Minimap.GetTrackingInfo", "GetTrackingInfo")
  if anzahl and info then
    local ok, n = pcall(anzahl)
    for i = 1, (ok and tonumber(n)) or 0 do
      local ok2, a, b, c, _, _, f = pcall(info, i)
      local name, icon, aktiv, id
      if ok2 and type(a) == "table" then
        name, icon, aktiv, id = a.name, a.texture, a.active, a.spellID
      elseif ok2 then
        name, icon, aktiv, id = a, b, c, f
      end
      if type(id) == "number" and id > 0 then
        t[id] = { nr = i, name = name, icon = icon, aktiv = aktiv and true or false }
      end
    end
  end
  self.liste = t
  return t
end

function SU.Name(id)
  local e = SU.liste[id]
  if e and type(e.name) == "string" and e.name ~= "" then return e.name end
  local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
  if n then return n end
  for _, b in ipairs(SU.BEKANNT) do
    if b.id == id and b.name then return b.name end
  end
  return string.format(L.TRACK_OTHER, id)
end

function SU.Icon(id)
  local e = SU.liste[id]
  if e and e.icon then return e.icon end
  local i = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
  return i or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Kreis: Zauber-IDs, die eingeschaltet sind und die der Char hat, in fester Reihenfolge
function SU:Kreis()
  local t = {}
  for _, b in ipairs(self.BEKANNT) do
    if ns.db.kreis[b.id] and self.liste[b.id] then table.insert(t, b.id) end
  end
  return t
end

-- Aktive Suche im Kreis (erste aktive) oder nil
function SU:Aktuell(kreis)
  for _, id in ipairs(kreis or self:Kreis()) do
    if self.liste[id] and self.liste[id].aktiv then return id end
  end
end

function SU:Naechste(kreis)
  kreis = kreis or self:Kreis()
  if #kreis == 0 then return nil end
  local jetzt = self:Aktuell(kreis)
  for i, id in ipairs(kreis) do
    if id == jetzt then return kreis[i % #kreis + 1] end
  end
  return kreis[1]
end

function SU:Beritten()
  if IsMounted and IsMounted() then return true end
  local form = GetShapeshiftFormID and GetShapeshiftFormID()
  return form and REISEN[form] or false
end

-- Warum gerade nicht gewechselt wird, als Text, sonst nil. Ein Klick (Knopf, Symbol) ist ein
-- ausdrücklicher Wunsch und überspringt Hauptschalter, Stadt und Reittier.
function SU:Pause(quelle)
  local db = ns.db
  local klick = quelle == "klick"
  if db.probe.gesperrt then return L.PAUSE_BLOCKED end
  if not klick and not db.an then return L.PAUSE_OFF end
  if InCombatLockdown and InCombatLockdown() then return L.PAUSE_COMBAT end
  if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then return L.PAUSE_DEAD end
  if UnitOnTaxi and UnitOnTaxi("player") then return L.PAUSE_TAXI end
  if klick then return nil end
  if IsSwimming and IsSwimming() then return L.PAUSE_SWIM end
  if IsFlying and IsFlying() then return L.PAUSE_FLY end
  if IsInInstance then
    local drin, art = IsInInstance()
    if drin and art ~= "none" then return L.PAUSE_INSTANCE end
  end
  if db.pauseRuhe and IsResting and IsResting() then return L.PAUSE_REST end
  if (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")) then
    return L.PAUSE_CAST
  end
  if db.ausloeser == "reiten" and not self:Beritten() then return L.PAUSE_NOT_MOUNTED end
end

local function gcdLaeuft()
  if C_Spell and C_Spell.GetSpellCooldown then
    local ok, cd = pcall(C_Spell.GetSpellCooldown, GCD)
    if ok and type(cd) == "table" and type(cd.duration) == "number" then return cd.duration > 0 end
  end
  if GetSpellCooldown then
    local ok, _, dauer = pcall(GetSpellCooldown, GCD)
    if ok and type(dauer) == "number" then return dauer > 0 end
  end
  return nil
end

-- Restliche Abklingzeit eines Zaubers in Sekunden (0, wenn keine läuft oder das Spiel nichts sagt)
local function rest(id)
  if not (C_Spell and C_Spell.GetSpellCooldown) then return 0 end
  local ok, cd = pcall(C_Spell.GetSpellCooldown, id)
  if not ok or type(cd) ~= "table" then return 0 end
  local start, dauer = cd.startTime, cd.duration
  if type(start) ~= "number" or type(dauer) ~= "number" then return 0 end
  if issecretvalue and (issecretvalue(start) or issecretvalue(dauer)) then return 0 end
  if dauer <= 0 then return 0 end
  return math.max(0, start + dauer - ns.jetzt())
end
SU.Rest = rest

local function setzen(nr, an)
  local f = api("C_Minimap.SetTracking", "SetTracking")
  if not f then return false end
  return pcall(f, nr, an)
end

-- Nach dem Wechsel nachsehen: Hat es geklappt? Lief eine globale Abklingzeit? Sind jetzt mehrere
-- Suchen gleichzeitig an (dann kann das Spiel das, und Springen ist unnötig)?
local function nachsehen(von, nach, gcdVorher)
  local p = ns.db.probe
  SU:Lesen()
  local neu = SU.liste[nach]
  if neu then p.geht = neu.aktiv end
  -- Wie lange der Wechsel gesperrt ist (Abklingzeit der Suche oder global), für den Reiter Status
  local sperre = math.max(rest(nach), rest(GCD))
  if sperre > 0 then p.abklingzeit = math.floor((sperre + 0.25) * 10 + 0.5) / 10 end
  if gcdVorher == false then
    local g = gcdLaeuft()
    if g ~= nil then p.gcd = g end
  end
  if von and neu and neu.aktiv and SU.liste[von] and SU.liste[von].aktiv and not p.mehrere then
    p.mehrere = true
    for _, id in ipairs(SU:Kreis()) do
      if not SU.liste[id].aktiv then setzen(SU.liste[id].nr, true) end
    end
    ns.melde(L.MSG_BOTH)
    SU:Lesen()
  end
  ns.aktualisieren()
end

-- Ein Wechsel zur nächsten Suche. quelle: "sprung" oder "klick". Rückgabe: true, wenn gewechselt
function SU:Wechseln(quelle)
  if not ns.db then return false end
  self:Lesen()
  if self:Pause(quelle) then return false end
  local kreis = self:Kreis()
  if #kreis < 2 then
    if quelle == "klick" then ns.melde(L.MSG_NOTHING) end
    return false
  end
  if ns.db.probe.mehrere then
    -- Das Spiel kann mehrere Suchen gleichzeitig: alle aus dem Kreis bleiben an
    for _, id in ipairs(kreis) do
      if not self.liste[id].aktiv then setzen(self.liste[id].nr, true) end
    end
    return false
  end
  local von, nach = self:Aktuell(kreis), self:Naechste(kreis)
  -- Läuft noch eine Abklingzeit, gar nicht erst versuchen: sonst meldet das Spiel "not ready yet"
  if rest(nach) > 0 or rest(GCD) > 0 then return false end
  local gcdVorher = gcdLaeuft()
  if not setzen(self.liste[nach].nr, true) then return false end
  self.zuletzt = { zeit = ns.jetzt(), von = von, nach = nach }
  if ns.db.ton and PlaySound and SOUNDKIT then
    pcall(PlaySound, SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856)
  end
  if ns.db.chat then ns.melde(string.format(L.MSG_SWITCHED, SU.Name(nach))) end
  if C_Timer and C_Timer.After then
    C_Timer.After(0.25, function() nachsehen(von, nach, gcdVorher) end)
  else
    nachsehen(von, nach, gcdVorher)
  end
  return true
end

-- Sprungtaste gedrückt (nach dem Sprung des Spiels)
local letzterSprung, letzterWechsel = -10, -10
function SU:Sprung()
  local db = ns.db
  if not (db and db.an) then return end
  local t = ns.jetzt()
  if db.ausloeser == "doppel" then
    if t - letzterSprung > DOPPEL then
      letzterSprung = t
      return
    end
    letzterSprung = -10
  end
  if t - letzterWechsel < (db.abstand or 2) then return end
  if self:Wechseln("sprung") then letzterWechsel = t end
end

-- Was der nächste Sprung tut, für Status und Symbol
function SU:Vorschau()
  local kreis = self:Kreis()
  return self:Aktuell(kreis), self:Naechste(kreis), kreis
end

local gemeldet = false
ns.beimStart(function()
  SU:Lesen()
  if hooksecurefunc and JumpOrAscendStart then
    hooksecurefunc("JumpOrAscendStart", function()
      local ok, fehler = pcall(SU.Sprung, SU)
      if not ok and not gemeldet then
        gemeldet = true
        ns.melde(string.format(L.ERR_EVENT, "JumpOrAscendStart", tostring(fehler)))
      end
    end)
  end
end)

local function neuLesen()
  SU:Lesen()
  ns.aktualisieren()
end
for _, e in ipairs({ "MINIMAP_UPDATE_TRACKING", "SPELLS_CHANGED", "SKILL_LINES_CHANGED", "PLAYER_ENTERING_WORLD",
  "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_UPDATE_RESTING", "UPDATE_SHAPESHIFT_FORM" }) do
  ns.Ereignis(e, neuLesen)
end

-- Sperrt das Spiel den Aufruf für Add-ons, steht hier der Name der Funktion. Dann bleibt Hop & Seek
-- aus, statt bei jedem Sprung eine Meldung des Spiels auszulösen.
local function gesperrt(addon, funktion)
  if addon ~= ADDON then return end
  ns.db.probe.gesperrt = tostring(funktion or "?")
  ns.melde(L.MSG_BLOCKED)
  ns.aktualisieren()
end
ns.Ereignis("ADDON_ACTION_BLOCKED", gesperrt)
ns.Ereignis("ADDON_ACTION_FORBIDDEN", gesperrt)
