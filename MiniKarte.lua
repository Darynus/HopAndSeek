-- Gemerkte Stellen auf der Minikarte in der Ecke (Patrick, 20. Nov: „Es wird mir das Icon zwar
-- angezeigt, aber nur in der Radaransicht“; beim Radar zugesagt: Klammern auf Radar und Minikarte).
-- Wie im Radar eine Klammer in der Farbe der Fertigkeit, die Mitte bleibt frei: Steht der Knoten,
-- liegt der Punkt des Spiels in der Klammer, sonst ist sie leer. Nie darüber zeichnen (Patrick, 13. Nov,
-- über die Bilder von Mastercraft: „dann sehe ich nur noch das Icon und nicht die Minimap-Anzeige“).
-- Das Symbol dessen, was dort meist wächst, klein oben rechts an der Klammer, nicht über dem Punkt.
-- Frisch gesammelt (unter 10 Minuten): blass.
-- Lernen: Zeigt das Spiel beim Draufzeigen den Namen eines Punkts (Tooltip der Minikarte), merkt sich
-- Hop & Seek die Stelle wie im Radar mit Alt (Radar.lua, TooltipLesen).
-- Solange das Radar läuft, zeichnet es selbst; die Minikarte ist dann ja das Radar.
-- Nur Anzeige: nichts nimmt die Maus an, Klicks und Tooltips der Minikarte bleiben, wie sie sind.
local ADDON, ns = ...

local MK = {}
ns.MiniKarte = MK

MK.KLAMMER = 16   -- Bildpunkte: Klammer um den Punkt des Spiels
MK.SYMBOL = 11    -- Bildpunkte: Symbol oben rechts an der Klammer
MK.VERSATZ = 10   -- so weit sitzt das Symbol rechts oben neben der Mitte
MK.RAND = 2       -- so weit bleiben Klammern vom Rand der Minikarte weg
MK.MAX = 60       -- höchstens so viele Klammern, die nächsten zuerst

local function geheim(v) return issecretvalue ~= nil and issecretvalue(v) end
local function zahl(v) return type(v) == "number" and not geheim(v) end
local function zeit() return (GetServerTime and GetServerTime()) or time() end

-- Drehung der Minikarte: die Blickrichtung, wenn sie sich mitdreht (Einstellung des Spiels), sonst 0.
-- nil: dreht, aber das Spiel nennt die Richtung nicht (in Instanzen).
local function drehung()
  if not MK.dreht then return 0 end
  if not GetPlayerFacing then return nil end
  local ok, b = pcall(GetPlayerFacing)
  if ok and zahl(b) then return b end
end

-- Eckige Minikarte (Add-ons wie Leatrix Plus melden das über GetMinimapShape)? Sonst rund.
local function eckig()
  if not GetMinimapShape then return false end
  local ok, form = pcall(GetMinimapShape)
  return ok and form == "SQUARE"
end

local function breite()
  local ok, b = pcall(Minimap.GetWidth, Minimap)
  if ok and zahl(b) and b > 0 then return b end
  return 140
end

local function stift(f, i)
  local s = f.stifte[i]
  if s then return s end
  s = {}
  s.t = f:CreateTexture(nil, "ARTWORK")
  s.t:SetTexture(ns.Radar.ZIEL_TEXTUR)
  s.t:SetSize(MK.KLAMMER, MK.KLAMMER)
  s.i = f:CreateTexture(nil, "OVERLAY")
  s.i:SetSize(MK.SYMBOL, MK.SYMBOL)
  s.i:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  f.stifte[i] = s
  return s
end

local function bauen()
  if MK.rahmen then return MK.rahmen end
  if not Minimap then return nil end
  local f = CreateFrame("Frame", nil, Minimap)
  f:SetAllPoints(Minimap)
  local ebene = Minimap.GetFrameLevel and Minimap:GetFrameLevel()
  f:SetFrameLevel((type(ebene) == "number" and ebene or 1) + 5)
  if f.EnableMouse then f:EnableMouse(false) end
  f.stifte = {}
  f:SetScript("OnUpdate", function(_, dt)
    local ok, fehler = pcall(MK.Bild, MK, dt)
    if not ok and not MK.fehlerGemeldet then
      MK.fehlerGemeldet = true
      ns.melde(string.format(ns.L.ERR_EVENT, "MiniKarte", tostring(fehler)))
    end
  end)
  f:Hide()
  MK.rahmen = f
  return f
end

-- Jedes Bild: Klammern mitführen. Welche Stellen in Reichweite sind und ob die Karte sich dreht, nur
-- alle halbe Sekunde. Dazu: Zeigt das Spiel den Namen eines neuen Punkts, die Stelle merken.
function MK:Bild(dt)
  self.suchen = (self.suchen or 0) - (dt or 0)
  if self.suchen <= 0 then
    self.suchen = 0.5
    self.dreht = ns.Radar.MinikarteDreht()
    self.kandidaten, self.karte, self.groesse = ns.Radar.Stellen(ns.Radar.SichtRadius() * 1.5 + 30, MK.MAX)
  end
  self:Stifte()
  ns.Radar:TooltipLesen(Minimap, breite() / 2, drehung())
end

function MK:Stifte()
  local f = self.rahmen
  local n = 0
  local karte, px, py = ns.SammelKarte.Position()
  local b = drehung()
  if self.kandidaten and karte and karte == self.karte and self.groesse and b then
    local halb = breite() / 2
    local skala = halb / ns.Radar.SichtRadius()
    local grenze = halb - MK.RAND - MK.KLAMMER / 2
    local quadrat = eckig()
    local jetzt = zeit()
    for _, k in ipairs(self.kandidaten) do
      local x, y = ns.Radar.Lage(k.e, px, py, self.groesse, b, skala)
      local drin
      if quadrat then drin = math.abs(x) <= grenze and math.abs(y) <= grenze
      else drin = x * x + y * y <= grenze * grenze end
      if drin then
        n = n + 1
        local s = stift(f, n)
        local c = k.farbe or ns.Radar.FARBE_UNBEKANNT
        local alpha = (k.e.zuletzt and jetzt - k.e.zuletzt < ns.SammelKarte.NACHWACHSEN) and 0.35 or 0.9
        s.t:ClearAllPoints()
        s.t:SetPoint("CENTER", f, "CENTER", x, y)
        s.t:SetVertexColor(c[1], c[2], c[3])
        s.t:SetAlpha(alpha)
        s.t:Show()
        if k.icon then
          s.i:SetTexture(k.icon)
          s.i:ClearAllPoints()
          s.i:SetPoint("CENTER", f, "CENTER", x + MK.VERSATZ, y + MK.VERSATZ)
          s.i:SetAlpha(alpha)
          s.i:Show()
        else
          s.i:Hide()
        end
      end
    end
  end
  for i = n + 1, #f.stifte do
    f.stifte[i].t:Hide()
    f.stifte[i].i:Hide()
  end
  self.anzahl = n
end

-- An, wenn eingeschaltet und das Radar aus ist
function MK:Aktualisieren()
  if not ns.db then return end
  local f = bauen()
  if not f then return end
  local an = ns.db.minikarteStellen and not ns.Radar.an
  if an and not f:IsShown() then self.suchen = 0 end
  f:SetShown(an and true or false)
  if not an then self.anzahl = 0 end
end

ns.beimStart(function() MK:Aktualisieren() end)
ns.beimAktualisieren(function() MK:Aktualisieren() end)
