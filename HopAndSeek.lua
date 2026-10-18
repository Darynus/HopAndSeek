-- Hop & Seek: Beim Springen wechselt die Minikarten-Suche (Kräuter, Erz, ...).
-- Grundregeln, die nie gebrochen werden:
--   1. Ein Druck auf die Sprungtaste ist höchstens ein Wechsel. Kein Taktgeber, keine Automatik.
--   2. Nur die Minikarten-Suche des Spiels. Kein Zauber, kein Makro, kein Ziel.
--   3. Nie im Kampf, nie beim Schwimmen oder Fliegen.
--   4. Keine Nachrichten an andere.
local ADDON, ns = ...
local L = ns.L

ns.FARBE = "|cff80d65a"
ns.TITEL = ns.FARBE .. L.TITLE_PART1 .. "|r " .. L.TITLE_PART2
ns.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version")) or "1.1.0"

function ns.melde(text)
  DEFAULT_CHAT_FRAME:AddMessage(ns.FARBE .. L.ADDON_NAME .. ":|r " .. tostring(text))
end

-- Prüft, ob eine Funktion existiert, z. B. ns.api("C_Minimap.SetTracking")
function ns.api(pfad)
  local t = _G
  for teil in string.gmatch(pfad, "[^%.]+") do
    if type(t) ~= "table" then return nil end
    t = t[teil]
  end
  return t
end

function ns.jetzt() return (GetTime and GetTime()) or 0 end

local STANDARD = {
  an = true,            -- Hauptschalter
  ausloeser = "sprung", -- "sprung" (jeder Sprung), "doppel" (Doppelsprung), "reiten" (nur beritten)
  abstand = 2,          -- Sekunden zwischen zwei Wechseln (1, 2 oder 3), wegen der Abklingzeit
  -- Zauber-IDs der Suchen im Kreis, in dieser Reihenfolge. Kräuter und Erz sind Standard.
  kreis = { [2383] = true, [2580] = true },
  pauseRuhe = true,     -- in Städten und Gasthäusern nicht wechseln
  ton = false,
  chat = false,
  anzeigeZeigen = true,
  gesperrt = false,
  anzeige = {},         -- Position der Anzeige
  minimapZeigen = true,
  minimapWinkel = 330,
  -- probe: Ergebnis der Selbstprüfung { geht, gcd, mehrere, gesperrt }
  probe = {},
  -- fenster: Position des Hauptfensters
}

local function ergaenzen(ziel, vorlage)
  for k, v in pairs(vorlage) do
    if type(v) == "table" then
      if type(ziel[k]) ~= "table" then
        ziel[k] = {}
        ergaenzen(ziel[k], v)
      end
    elseif ziel[k] == nil then
      ziel[k] = v
    end
  end
end

-- Ereignisse: mehrere Empfänger pro Ereignis, unbekannte Ereignisse werden still ignoriert
local frame = CreateFrame("Frame")
local empfaenger = {}

function ns.Ereignis(name, funktion)
  if not empfaenger[name] then
    local ok = pcall(frame.RegisterEvent, frame, name)
    if not ok then return false end
    empfaenger[name] = {}
  end
  table.insert(empfaenger[name], funktion)
  return true
end

frame:SetScript("OnEvent", function(_, ereignis, ...)
  local liste = empfaenger[ereignis]
  if not liste then return end
  for _, f in ipairs(liste) do
    local ok, fehler = pcall(f, ...)
    if not ok then ns.melde(string.format(L.ERR_EVENT, ereignis, tostring(fehler))) end
  end
end)

-- Nach dem Laden der SavedVariables, in der Reihenfolge der Anmeldung
local start = {}
function ns.beimStart(f) table.insert(start, f) end

ns.Ereignis("ADDON_LOADED", function(name)
  if name ~= ADDON then return end
  HopAndSeekDB = HopAndSeekDB or {}
  ergaenzen(HopAndSeekDB, STANDARD)
  ns.db = HopAndSeekDB
end)

ns.Ereignis("PLAYER_LOGIN", function()
  if not ns.db then return end
  for _, f in ipairs(start) do
    local ok, fehler = pcall(f)
    if not ok then ns.melde(string.format(L.ERR_EVENT, "PLAYER_LOGIN", tostring(fehler))) end
  end
end)

-- Alle Anzeigen neu zeichnen (Fenster, Symbol)
local beimAktualisieren = {}
function ns.beimAktualisieren(f) table.insert(beimAktualisieren, f) end
function ns.aktualisieren()
  for _, f in ipairs(beimAktualisieren) do pcall(f) end
end
