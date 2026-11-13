-- Berufe: Kräuterkunde und Bergbau mit Stufe (Vorschlag vom 13. Nov). Ist die Höchststufe der
-- gelernten Stufe erreicht (75, 150, 225), sagt Hop & Seek einmal Bescheid: ab zum Lehrer. Beim
-- Leveln vieler Chars vergisst man das leicht. Erkannt über die Fertigkeitslinie (182 Kräuterkunde,
-- 186 Bergbau), nie über den Namen. Direkt beim Login liefert GetProfessions in Forever noch nichts
-- (Beta, 13. Okt), deshalb nach SKILL_LINES_CHANGED, nach dem Sammeln oder ein paar Sekunden später.
-- Nur Anzeige.
local ADDON, ns = ...
local L = ns.L

local B = {}
ns.Berufe = B

B.LINIEN = { [182] = "kraut", [186] = "erz" }
B.ENDE = 300   -- ab hier gibt es in Classic keinen Lehrer mehr

local function charSchluessel()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or "?"
  return name .. "-" .. realm
end

-- Sammelberufe dieses Chars: { linie, art, rang, max }
function B.Liste()
  local liste = {}
  if not (GetProfessions and GetProfessionInfo) then return liste end
  -- GetProfessions kann Lücken liefern, deshalb die ersten fünf einzeln
  local ok, a, b, c, d, e = pcall(GetProfessions)
  if not ok then return liste end
  for _, i in ipairs({ a or false, b or false, c or false, d or false, e or false }) do
    if i then
      local ok2, _, _, rang, max, _, _, linie = pcall(GetProfessionInfo, i)
      if ok2 and B.LINIEN[linie] and type(rang) == "number" and type(max) == "number" then
        table.insert(liste, { linie = linie, art = B.LINIEN[linie], rang = rang, max = max })
      end
    end
  end
  table.sort(liste, function(x, y) return x.linie < y.linie end)
  return liste
end

function B.Name(p) return p.art == "kraut" and L.SKILL_HERBALISM or L.SKILL_MINING end

-- Am Ende der gelernten Stufe (und noch nicht ganz oben)?
function B.AmLimit(p) return p.max < B.ENDE and p.rang >= p.max end

-- Einmal je Char, Beruf und Stufe melden
function B:Pruefen()
  if not ns.db then return end
  local schluessel = charSchluessel()
  ns.db.berufGemeldet[schluessel] = ns.db.berufGemeldet[schluessel] or {}
  local gemeldet = ns.db.berufGemeldet[schluessel]
  local neu = false
  for _, p in ipairs(B.Liste()) do
    if B.AmLimit(p) and gemeldet[p.linie] ~= p.max then
      gemeldet[p.linie] = p.max
      neu = true
      if ns.Erfolge and ns.Erfolge.Melden then
        ns.Erfolge.Melden({ art = "beruf", titel = L.SKILL_CAPPED_TITLE,
          text = string.format(L.SKILL_LEVEL, B.Name(p), p.rang, p.max), unter = L.SKILL_CAPPED_HELP })
      end
    end
  end
  if neu then ns.aktualisieren() end
end

-- Warnung für das Sammelfenster: Text, wenn ein Beruf am Limit ist, sonst nil
function B.Warnung()
  for _, p in ipairs(B.Liste()) do
    if B.AmLimit(p) then return string.format(L.SKILL_CAPPED_SHORT, B.Name(p), p.rang, p.max) end
  end
end

ns.Ereignis("SKILL_LINES_CHANGED", function() B:Pruefen() end)
ns.beimSammeln(function(_, _, _, knotenArt) if knotenArt then B:Pruefen() end end)
ns.beimStart(function()
  if C_Timer and C_Timer.After then C_Timer.After(8, function() B:Pruefen() end) end
end)
