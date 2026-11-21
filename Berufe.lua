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

-- Nötige Stufe zum Sammeln, nach dem Fund einer Stelle (Kraut, Erz oder der Stein der Ader). Für das
-- Radar (Patrick, 20. Nov: „Gemessen an meinem Skill dürfte ich hier keine Punkte mehr bekommen ...
-- dürfte der Kasten nicht grün sein“). Werte wie in Classic, in Forever unverändert (Wowhead Forever,
-- Leitfäden Kräuterkunde und Bergbau, 20. Nov nachgesehen), dazu die neuen Knoten am Hyjal: Demonsage,
-- Marefoil und Heavy Thorium Vein, je 300. Seltene Zugaben ohne eigenen Knoten (Frilled Lichen, Rosecap,
-- Stranglevine, Death Lotus, Pyrite, Bauxite, Pitchblende) fehlen mit Absicht: Sie fallen aus vielen
-- Knoten und sagen nichts über die Stufe der Stelle.
B.STUFE = {
  -- Kräuter
  [2447] = 1, [765] = 1, [2449] = 15, [785] = 50, [2450] = 70, [3820] = 85, [2453] = 100, [3355] = 115,
  [3369] = 120, [3356] = 125, [3357] = 150, [3818] = 160, [3821] = 170, [3358] = 185, [3819] = 195,
  [4625] = 205, [8831] = 210, [8836] = 220, [8838] = 230, [8839] = 235, [8845] = 245, [8846] = 250,
  [13464] = 260, [13463] = 270, [13465] = 280, [13466] = 285, [13467] = 290, [13468] = 300,
  [248821] = 300, [248823] = 300,
  -- Erz, dazu die Steine für die Ader ihrer Stufe
  [2770] = 1, [2835] = 1, [2771] = 65, [2836] = 65, [2775] = 75, [2772] = 125, [2838] = 125, [2776] = 155,
  [3858] = 175, [7912] = 175, [7911] = 230, [11370] = 230, [10620] = 245, [12365] = 245, [248815] = 300,
}

-- Welcher Knoten stand an der Stelle? Ihr häufigster Fund mit bekannter Stufe, bei Gleichstand der
-- höhere. Zugaben ohne Stufe zählen nicht. nil: nichts Bekanntes.
function B.KnotenFund(e)
  local beste, menge
  for id, n in pairs(e and e.inhalt or {}) do
    local s = B.STUFE[id]
    if s and (not menge or n > menge or (n == menge and s > B.STUFE[beste])) then beste, menge = id, n end
  end
  return beste
end

-- Farbe wie im Spiel beim Sammeln: rot (noch zu niedrig), orange (sicher ein Punkt), gelb, grün
-- (vielleicht), grau (keine Punkte mehr). In Forever ab der nötigen Stufe orange, ab +25 gelb, ab +65
-- grün (in Classic schon ab +50) und ab +100 grau. Knoten ab Stufe 1 rechnen von 0 aus (Kupfer:
-- 1, 25, 65, 100). Quelle: Wowhead Forever, Leitfäden Kräuterkunde (9. Nov) und Bergbau (16. Nov).
-- nil: Stufe oder Beruf unbekannt.
B.FARBEN = {
  rot = { 1, 0.1, 0.1 }, orange = { 1, 0.5, 0.25 }, gelb = { 1, 1, 0 }, gruen = { 0.25, 0.75, 0.25 }, grau = { 0.5, 0.5, 0.5 },
}
function B.Schwierigkeit(art, itemID)
  local stufe = itemID and B.STUFE[itemID]
  if not stufe then return nil end
  local rang
  for _, p in ipairs(B.Liste()) do if p.art == art then rang = p.rang end end
  if not rang then return nil end
  local basis = stufe == 1 and 0 or stufe
  if rang < stufe then return "rot" end
  if rang < basis + 25 then return "orange" end
  if rang < basis + 65 then return "gelb" end
  if rang < basis + 100 then return "gruen" end
  return "grau"
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
