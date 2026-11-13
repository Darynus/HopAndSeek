-- Berufe: Kräuterkunde, Bergbau und Kürschnern mit Stufe (Vorschlag vom 13. Nov). Ist die Höchststufe der
-- gelernten Stufe erreicht (75, 150, 225), sagt Hop & Seek einmal Bescheid: ab zum Lehrer. Beim
-- Leveln vieler Chars vergisst man das leicht. Erkannt über die Fertigkeitslinie (182 Kräuterkunde,
-- 186 Bergbau, 393 Kürschnern), nie über den Namen. Direkt beim Login liefert GetProfessions in Forever noch nichts
-- (Beta, 13. Okt), deshalb nach SKILL_LINES_CHANGED, nach dem Sammeln oder ein paar Sekunden später.
-- Nur Anzeige.
local ADDON, ns = ...
local L = ns.L

local B = {}
ns.Berufe = B

B.LINIEN = { [182] = "kraut", [186] = "erz", [393] = "leder" }
B.ENDE = 300   -- ab hier gibt es in Classic keinen Lehrer mehr

local function charSchluessel()
  local name = UnitName and UnitName("player") or "?"
  local realm = GetRealmName and GetRealmName() or "?"
  return name .. "-" .. realm
end

-- Sammelberufe dieses Chars: { linie, art, rang, max }. Das Sammelfenster fragt jede Sekunde,
-- deshalb gilt die Liste 5 Sekunden lang (frisch nach SKILL_LINES_CHANGED und Levelaufstieg).
local gemerkt, gemerktZeit
function B.Liste()
  if gemerkt and ns.jetzt() - gemerktZeit < 5 then return gemerkt end
  local liste = B.Lesen()
  gemerkt, gemerktZeit = liste, ns.jetzt()
  return liste
end
function B.Vergessen() gemerkt = nil end

function B.Lesen()
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

local NAMEN = { kraut = "SKILL_HERBALISM", erz = "SKILL_MINING", leder = "SKILL_SKINNING" }
function B.Name(p) return L[NAMEN[p.art]] end

-- Hat dieser Char den Beruf? (für die Lichtsäule über Kadavern). Liefert Forever die
-- Fertigkeitslinie nicht, hilft der Zauber des Berufs (Kürschnern in Classic: 8613 bis 10768).
local ZAUBER = { leder = { 8613, 8617, 8618, 10768 }, kraut = { 2366, 2368, 3570, 11993 }, erz = { 2575, 2576, 3564, 10248 } }
function B.Hat(art)
  if art == "leder" and ns.db and ns.db.kuerschner[ns.Sammeln.Char()] then return true end
  for _, p in ipairs(B.Liste()) do if p.art == art then return true end end
  if IsPlayerSpell then
    for _, id in ipairs(ZAUBER[art] or {}) do
      local ok, hat = pcall(IsPlayerSpell, id)
      if ok and hat then return true end
    end
  end
  return false
end

-- Alle Berufe so, wie das Spiel sie liefert (für /hop debug): Name, Stufe, Höchststufe, Linie
function B.Roh()
  local liste = {}
  if not (GetProfessions and GetProfessionInfo) then return liste end
  local ok, a, b, c, d, e = pcall(GetProfessions)
  if not ok then return liste end
  for _, i in ipairs({ a or false, b or false, c or false, d or false, e or false }) do
    if i then
      local ok2, name, _, rang, max, _, _, linie = pcall(GetProfessionInfo, i)
      if ok2 then table.insert(liste, string.format("%s %s/%s line %s", tostring(name), tostring(rang), tostring(max), tostring(linie))) end
    end
  end
  return liste
end

-- Am Ende der gelernten Stufe (und noch nicht ganz oben)?
function B.AmLimit(p) return p.max < B.ENDE and p.rang >= p.max end

-- Nächste Stufe beim Lehrer und das Level, das der Char dafür braucht (Classic: 150 ab Level 10,
-- 225 ab Level 20, 300 ab Level 35; Patrick, 13. Nov)
B.LEVEL = { [150] = 10, [225] = 20, [300] = 35 }
B.BALD = 10   -- so viele Punkte vor dem Limit erinnert das Sammelfenster schon leise
function B.Naechste(p)
  local naechste = p.max + 75
  return naechste, B.LEVEL[naechste] or 1
end

-- Darf der Char die nächste Stufe schon lernen?
function B.Bereit(p)
  local _, level = B.Naechste(p)
  local ok, stufe = pcall(UnitLevel or function() return 0 end, "player")
  return ok and type(stufe) == "number" and stufe >= level
end

-- Einmal je Char, Beruf und Stufe melden: am Limit und alt genug für die nächste Stufe. Wer noch zu
-- jung ist, bekommt die Meldung, sobald er das Level erreicht.
function B:Pruefen()
  if not ns.db then return end
  local schluessel = charSchluessel()
  ns.db.berufGemeldet[schluessel] = ns.db.berufGemeldet[schluessel] or {}
  local gemeldet = ns.db.berufGemeldet[schluessel]
  local neu = false
  for _, p in ipairs(B.Liste()) do
    if B.AmLimit(p) and B.Bereit(p) and gemeldet[p.linie] ~= p.max then
      gemeldet[p.linie] = p.max
      neu = true
      if ns.Erfolge and ns.Erfolge.Melden then
        ns.Erfolge.Melden({ art = "beruf", titel = L.SKILL_CAPPED_TITLE,
          text = string.format(L.SKILL_LEVEL, B.Name(p), p.rang, p.max),
          unter = string.format(L.SKILL_CAPPED_HELP, (B.Naechste(p))) })
      end
    end
  end
  if neu then ns.aktualisieren() end
end

-- Hinweis für das Sammelfenster: Text, ob es dringend ist (am Limit) und die Art des Berufs (für den
-- Lehrer-Finder), sonst nil.
-- Am Limit: zum Lehrer, oder ab welchem Level es weitergeht. Kurz davor: bald zum Lehrer.
function B.Warnung()
  local bald, baldArt
  for _, p in ipairs(B.Liste()) do
    if B.AmLimit(p) then
      if B.Bereit(p) then return string.format(L.SKILL_CAPPED_SHORT, B.Name(p), p.rang, p.max), true, p.art end
      local _, level = B.Naechste(p)
      return string.format(L.SKILL_CAPPED_LEVEL, B.Name(p), p.rang, p.max, level), true, p.art
    elseif p.max < B.ENDE and p.rang >= p.max - B.BALD and B.Bereit(p) and not bald then
      bald, baldArt = string.format(L.SKILL_SOON, B.Name(p), p.rang, p.max), p.art
    end
  end
  if bald then return bald, false, baldArt end
end

ns.Ereignis("SKILL_LINES_CHANGED", function() B.Vergessen() B:Pruefen() end)
ns.Ereignis("PLAYER_LEVEL_UP", function()
  B.Vergessen()
  if C_Timer and C_Timer.After then C_Timer.After(1, function() B:Pruefen() end) else B:Pruefen() end
end)
ns.beimSammeln(function(_, _, _, knotenArt) if knotenArt then B:Pruefen() end end)
ns.beimStart(function()
  if C_Timer and C_Timer.After then C_Timer.After(8, function() B:Pruefen() end) end
end)
