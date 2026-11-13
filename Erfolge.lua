-- Erfolge: was beim Sammeln motiviert (Patricks Wunsch, 13. Nov: „irgendwas, was motiviert, das
-- zu sammeln“). Jeder Knoten bringt Sammelpunkte, die Punkte ergeben einen Rang. Dazu ein
-- Tagesziel mit Serie, Rekorde (Gold pro Stunde, Knoten und Wert einer Sitzung, längste Sitzung),
-- Abzeichen und ein Sammelbuch mit allem, was es in Forever aus Kräutern und Adern gibt.
-- Accountweit wie die Gesamtzahlen des Sammelzählers. Nur zählen und anzeigen: es zählt, was der
-- Spieler selbst einsammelt, nichts geschieht von selbst, nichts geht an andere.
-- Erkannt wird über Gegenstands-ID und Qualität, nie über Namen.
local ADDON, ns = ...
local L, S = ns.L, ns.Stil
local F = S.F

local E = { neu = {} }
ns.Erfolge = E

local function zeit() return (GetServerTime and GetServerTime()) or time() end

-- Punkte je Ereignis
E.PUNKTE = { knoten = 10, neu = 50, selten = 15, tag = 100 }

-- Ränge ab so vielen Punkten (Namen in L.RANKS). Nach dem letzten geht es alle E.WEITER Punkte
-- eine Stufe weiter („Legend of the Wilds 2“), damit der Balken nie stehen bleibt.
E.RAENGE = { 0, 150, 500, 1200, 2500, 4500, 7500, 12000, 18000, 26000 }
E.WEITER = 10000

E.ZIELE = { 10, 25, 50, 100 }   -- Tagesziel in Knoten, für alle Chars zusammen
E.GOLD_AB = 15 * 60             -- Gold pro Stunde gilt erst nach 15 Minuten Sitzung (sonst Zufall)
E.KNOTEN_AB = 10                -- „Knoten in einer Sitzung“ meldet einen neuen Rekord erst über 10
E.SELTEN = 2                    -- ab dieser Qualität (grün) ist ein Fund selten

-- Gespeichert in HopAndSeekDB.erfolge. Fehlt ein Feld (neu in einer späteren Version), kommt es
-- beim Start dazu.
E.VORLAGE = {
  punkte = 0,
  abzeichen = {},   -- [Schlüssel] = Zeit, zu der es erreicht wurde
  funde = {},       -- [Gegenstands-ID] = Zeit des ersten Funds (Sammelbuch)
  selten = 0,       -- seltene Funde (Stück)
  rekord = {},      -- [art] = { wert, zeit, sitzung }, art: gold, knoten, wert, dauer
  tag = {},         -- { datum = "2026-11-13", knoten, erreicht }
  ziel = 25,
  serie = 0,        -- Tage in Folge mit erreichtem Ziel
  serieBest = 0,
  serieTag = nil,   -- Datum, an dem das Ziel zuletzt erreicht wurde
  tage = 0,         -- Tage mit erreichtem Ziel
}

-- Sammelbuch: was es in Forever aus Kräutern und Adern gibt (Wowhead Forever, 13. Nov 2026),
-- je Gruppe nach Stufe sortiert. Neu in Forever: Frilled Lichen, Rosecap, Stranglevine, Demonsage,
-- Marefoil, Death Lotus, Pyrite, Bauxite, Heavy Thorium Ore, Pitchblende, Fel Crystal, Torbernite.
-- Wird etwas gesammelt, das hier fehlt, kommt es ans Ende seiner Gruppe.
E.BUCH = {
  { schluessel = "kraut", ids = {
    2447, 765, 2449, 785, 2450, 2452, 3820, 2453, 3355, 3369, 3356, 249399, 3357, 3818, 3821, 3358,
    3819, 8153, 4625, 8831, 8836, 249424, 8838, 8839, 8845, 8846, 13464, 13463, 13465, 13466, 13467,
    13468, 249274, 248821, 248823, 248822 } },
  { schluessel = "erz", ids = {
    2770, 2771, 2775, 249391, 2772, 2776, 3858, 249425, 7911, 11370, 10620, 248815, 249426,
    2835, 2836, 2838, 7912, 12365 } },
  { schluessel = "edel", ids = {
    774, 818, 1210, 1206, 1705, 1529, 3864, 7909, 7910, 12361, 12799, 12364, 12800, 12363, 11382,
    248819, 248820 } },
}

-- Abzeichen: art sagt, welcher Wert zählt (E.Wert), ziel, ab wann es gilt. icon ist ein Gegenstand,
-- dessen Symbol das Spiel liefert. Namen und Texte stehen in Locale.lua (L.BADGES).
E.ABZEICHEN = {
  { key = "knoten1", art = "knoten", ziel = 1, icon = 2447 },
  { key = "knoten100", art = "knoten", ziel = 100, icon = 2770 },
  { key = "knoten500", art = "knoten", ziel = 500, icon = 2772 },
  { key = "knoten1000", art = "knoten", ziel = 1000, icon = 3858 },
  { key = "knoten5000", art = "knoten", ziel = 5000, icon = 10620 },
  { key = "kraut250", art = "kraut", ziel = 250, icon = 8838 },
  { key = "erz250", art = "erz", ziel = 250, icon = 2771 },
  { key = "selten1", art = "selten", ziel = 1, icon = 818 },
  { key = "selten50", art = "selten", ziel = 50, icon = 7910 },
  { key = "arten10", art = "arten", ziel = 10, icon = 785 },
  { key = "arten25", art = "arten", ziel = 25, icon = 3358 },
  { key = "arten50", art = "arten", ziel = 50, icon = 13465 },
  { key = "lotus", art = "fund", ziel = 1, item = 13468, icon = 13468 },
  { key = "sitzung50", art = "sitzung", ziel = 50, icon = 3355 },
  { key = "sitzung100", art = "sitzung", ziel = 100, icon = 8846 },
  { key = "stunde", art = "dauer", ziel = 3600, icon = 2838 },
  { key = "gold1", art = "gold", ziel = 10000, icon = 2775 },
  { key = "gold10", art = "gold", ziel = 100000, icon = 2776 },
  { key = "gold25", art = "gold", ziel = 250000, icon = 7911 },
  { key = "tag1", art = "tage", ziel = 1, icon = 2449 },
  { key = "serie7", art = "serie", ziel = 7, icon = 1705 },
  { key = "serie30", art = "serie", ziel = 30, icon = 12800 },
}

-- Töne des Spiels je Meldung (wie bei Campfire Buddy), fehlt einer, bleibt es still. Neuer Fund:
-- eine Seite im Sammelbuch blättert um. Nicht der Ton der Warteschlange (PVP_THROUGH_QUEUE), den
-- hielte man draußen in der Welt für eine aufgegangene Warteschlange.
local TOENE = {
  beruf = "READY_CHECK",
  fund = "IG_ABILITY_PAGE_TURN",
  abzeichen = "UI_70_CHALLENGE_MODE_COMPLETE_NO_UPGRADE",
  rang = "UI_70_CHALLENGE_MODE_COMPLETE_NO_UPGRADE",
  rekord = "MONEY_FRAME_OPEN",
  tag = "UI_VOID_STORAGE_UNLOCK",
}
local MUENZE = "Interface\\Icons\\INV_Misc_Coin_01"

function E.Ton(art)
  if not (ns.db and ns.db.erfolgTon and PlaySound and SOUNDKIT) then return end
  local kit = TOENE[art] and SOUNDKIT[TOENE[art]]
  if kit then pcall(PlaySound, kit, "SFX") end
end

function E.Icon(itemID)
  return (itemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or 134400
end

function E.Name(itemID)
  return (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)) or ("#" .. tostring(itemID))
end

-- 2500 -> "2,500" (Texte sind Englisch, deshalb Komma)
function E.Zahl(n)
  local s = tostring(math.floor((n or 0) + 0.5))
  local k
  repeat s, k = string.gsub(s, "^(%-?%d+)(%d%d%d)", "%1,%2") until k == 0
  return s
end

function E.Datum(t) return date("%Y-%m-%d", t) end

-- Gestern, gerechnet von der Mittagszeit aus: so stimmt es auch an Tagen mit Zeitumstellung
function E.Gestern(t)
  local mittag = t
  local ok, d = pcall(date, "*t", t)
  if ok and type(d) == "table" then
    mittag = t - ((d.hour or 0) * 3600 + (d.min or 0) * 60 + (d.sec or 0)) + 12 * 3600
  end
  return date("%Y-%m-%d", mittag - 86400)
end

-- Rang zu einer Punktzahl: Nummer, Name, ab wie vielen Punkten er gilt und ab wann der nächste
function E.Rang(p)
  p = math.max(0, p or 0)
  local n = #E.RAENGE
  local letzter = E.RAENGE[n]
  if p >= letzter then
    local stufe = math.floor((p - letzter) / E.WEITER)
    local von = letzter + stufe * E.WEITER
    local name = stufe == 0 and L.RANKS[n] or string.format(L.RANK_MORE, L.RANKS[n], stufe + 1)
    return n + stufe, name, von, von + E.WEITER
  end
  for i = n - 1, 1, -1 do
    if p >= E.RAENGE[i] then return i, L.RANKS[i], E.RAENGE[i], E.RAENGE[i + 1] end
  end
end

-- Meldung: kleines Fenster (Meldung.lua) oder, wenn ausgeschaltet, eine Zeile im Chat
local function melden(m)
  if ns.db.meldungen and ns.Meldung then
    ns.Meldung:Zeigen(m)
  else
    ns.melde(m.titel .. ": " .. m.text)
    E.Ton(m.art)
  end
end
E.Melden = melden

local function rekordWert(art)
  local r = ns.db.erfolge.rekord[art]
  return r and r.wert or 0
end

function E.Arten()
  local n = 0
  for _ in pairs(ns.db.erfolge.funde) do n = n + 1 end
  return n
end

-- Wert, an dem sich ein Abzeichen misst
function E.Wert(a)
  local d, k = ns.db.erfolge, ns.db.gesamt.knoten
  local art = a.art
  if art == "knoten" then return (k.kraut or 0) + (k.erz or 0) end
  if art == "kraut" or art == "erz" then return k[art] or 0 end
  if art == "selten" then return d.selten or 0 end
  if art == "arten" then return E.Arten() end
  if art == "fund" then return d.funde[a.item] and 1 or 0 end
  if art == "sitzung" then return rekordWert("knoten") end
  if art == "dauer" then return rekordWert("dauer") end
  if art == "gold" then return rekordWert("gold") end
  if art == "tage" then return d.tage or 0 end
  if art == "serie" then return d.serieBest or 0 end
  return 0
end

-- Punkte gutschreiben, beim Aufstieg eine Meldung
function E:Punkte(n)
  if not n or n <= 0 then return end
  local d = ns.db.erfolge
  local vorher = E.Rang(d.punkte)
  d.punkte = d.punkte + n
  local nr, name, _, bis = E.Rang(d.punkte)
  if nr > vorher then
    local _, naechster = E.Rang(bis)
    melden({ art = "rang", titel = L.TOAST_RANK, text = string.format(L.RANK_TITLE, nr, name),
      unter = string.format(L.TOAST_RANK_NEXT, naechster, E.Zahl(bis)) })
  end
end

-- Tagesziel: erreicht? Dann Serie weiterzählen (gestern erreicht) oder neu beginnen.
local function tagesziel(d, heute, jetzt)
  if d.tag.erreicht or (d.tag.knoten or 0) < d.ziel then return end
  d.tag.erreicht = true
  d.tage = d.tage + 1
  if d.serieTag == E.Gestern(jetzt) then
    d.serie = d.serie + 1
  elseif d.serieTag ~= heute then
    d.serie = 1
  end
  d.serieTag = heute
  d.serieBest = math.max(d.serieBest, d.serie)
  melden({ art = "tag", titel = L.TOAST_DAILY, text = string.format(L.TODAY_NODES, d.tag.knoten, d.ziel),
    unter = d.serie == 1 and L.STREAK_ONE or string.format(L.STREAK_DAYS, d.serie) })
  E:Punkte(E.PUNKTE.tag)
end

local function heuteZaehlen(d)
  local jetzt = zeit()
  local heute = E.Datum(jetzt)
  if d.tag.datum ~= heute then d.tag = { datum = heute, knoten = 0 } end
  d.tag.knoten = d.tag.knoten + 1
  tagesziel(d, heute, jetzt)
end

-- Stand von heute: Knoten, Ziel, erreicht, laufende Serie (0, wenn sie gerissen ist)
function E:Heute()
  local d = ns.db.erfolge
  local jetzt = zeit()
  local heute = E.Datum(jetzt)
  local t = d.tag.datum == heute and d.tag or {}
  local serie = (d.serieTag == heute or d.serieTag == E.Gestern(jetzt)) and d.serie or 0
  return t.knoten or 0, d.ziel, t.erreicht and true or false, serie
end

function E:ZielSetzen(n)
  local d = ns.db.erfolge
  d.ziel = n
  local jetzt = zeit()
  local heute = E.Datum(jetzt)
  if d.tag.datum == heute then tagesziel(d, heute, jetzt) end
  self:Pruefen(true)
  ns.aktualisieren()
end

-- Rekorde der laufenden Sitzung. Jeder meldet sich höchstens einmal je Sitzung und nur, wenn es
-- schon einen alten gab (der allererste Wert ist noch kein Rekord, den man schlägt).
function E:Rekorde()
  local st = ns.Sammeln:Stand()
  if not st.start then return end
  local d, s = ns.db.erfolge, ns.db.sitzung
  s.gemeldet = s.gemeldet or {}
  local function pruefen(art, wert, ab, meldung)
    local r = d.rekord[art]
    local alt = r and r.wert or 0
    if not wert or wert <= alt then return end
    d.rekord[art] = { wert = wert, zeit = zeit(), sitzung = st.start }
    if meldung and alt >= ab and not s.gemeldet[art] then
      s.gemeldet[art] = true
      melden(meldung(alt))
    end
  end
  pruefen("knoten", st.knoten, E.KNOTEN_AB, function(alt)
    return { art = "rekord", titel = L.TOAST_RECORD, text = string.format(L.RECORD_NODES_TEXT, st.knoten),
      unter = string.format(L.TOAST_RECORD_OLD, E.Zahl(alt)) }
  end)
  pruefen("dauer", st.dauer, 0)
  if st.wert then
    pruefen("wert", st.wert, 1, function(alt)
      return { art = "rekord", icon = MUENZE, titel = L.TOAST_RECORD, text = string.format(L.RECORD_HAUL_TEXT, ns.geld(st.wert)),
        unter = string.format(L.TOAST_RECORD_OLD, ns.geld(alt)) }
    end)
  end
  if st.wertProStunde and st.dauer >= E.GOLD_AB then
    pruefen("gold", st.wertProStunde, 1, function(alt)
      return { art = "rekord", icon = MUENZE, titel = L.TOAST_RECORD,
        text = string.format(L.GATHER_BAR_GOLD_RATE, ns.geld(st.wertProStunde)),
        unter = string.format(L.TOAST_RECORD_OLD, ns.geld(alt)) }
    end)
  end
end

-- Abzeichen prüfen. Ohne melden (beim Start) still eintragen.
function E:Pruefen(meldenJa)
  local d = ns.db.erfolge
  for _, a in ipairs(E.ABZEICHEN) do
    if not d.abzeichen[a.key] and E.Wert(a) >= a.ziel then
      d.abzeichen[a.key] = zeit()
      if meldenJa then
        local t = L.BADGES[a.key] or {}
        melden({ art = "abzeichen", icon = E.Icon(a.icon), titel = L.TOAST_BADGE, text = t[1] or a.key, unter = t[2] })
      end
    end
  end
end

-- Vom Sammelzähler: ein Gegenstand aus einem Kraut oder einer Ader wurde genommen. knotenArt ist
-- gesetzt ("kraut" oder "erz"), wenn damit ein neuer Knoten zählt.
function E:Beute(id, menge, qualitaet, knotenArt)
  local d = ns.db.erfolge
  local plus = 0
  if knotenArt then
    plus = plus + E.PUNKTE.knoten
    heuteZaehlen(d)
  end
  if not d.funde[id] then
    d.funde[id] = zeit()
    plus = plus + E.PUNKTE.neu
    table.insert(self.neu, { id = id, q = qualitaet })
  end
  if (qualitaet or 0) >= E.SELTEN then
    d.selten = d.selten + (menge or 1)
    plus = plus + E.PUNKTE.selten
  end
  self:Punkte(plus)
  self:Rekorde()
  self:Pruefen(true)
end

-- Neue Funde eines Beutefensters als eine Meldung, wenn es sich schließt
local function fundeMelden()
  local neu = E.neu
  if #neu == 0 then return end
  E.neu = {}
  local _, gesamt = E:Buch()
  local namen = {}
  for _, f in ipairs(neu) do table.insert(namen, E.Name(f.id)) end
  local q = #neu == 1 and neu[1].q or nil
  melden({ art = "fund", icon = E.Icon(neu[1].id),
    titel = #neu == 1 and L.TOAST_FIND or string.format(L.TOAST_FINDS, #neu),
    text = table.concat(namen, ", "), farbe = q and q >= E.SELTEN and S.qualitaetsFarbe(q) or nil,
    unter = string.format(L.TOAST_FIND_SUB, E.Arten(), gesamt) })
end

-- Sammelbuch: Gruppen mit Einträgen { id, gefunden (Zeit oder nil), menge (insgesamt) } und die
-- Zahl aller Einträge. Gefundenes, das nicht in der Liste steht, kommt ans Ende seiner Gruppe.
function E:Buch()
  local d, g = ns.db.erfolge, ns.db.gesamt
  local bekannt, gruppen, nach = {}, {}, {}
  for _, gr in ipairs(E.BUCH) do
    local t = { schluessel = gr.schluessel, name = L.BOOK_GROUPS[gr.schluessel], eintraege = {}, gefunden = 0 }
    for _, id in ipairs(gr.ids) do
      bekannt[id] = true
      table.insert(t.eintraege, { id = id, gefunden = d.funde[id], menge = g.menge[id] or 0 })
      if d.funde[id] then t.gefunden = t.gefunden + 1 end
    end
    table.insert(gruppen, t)
    nach[gr.schluessel] = t
  end
  local extra = {}
  for id in pairs(d.funde) do if not bekannt[id] then table.insert(extra, id) end end
  table.sort(extra)
  for _, id in ipairs(extra) do
    local art = ns.Sammeln.Art(id)
    local t = nach[(art == "kraut" or art == "erz") and art or "edel"]
    table.insert(t.eintraege, { id = id, gefunden = d.funde[id], menge = g.menge[id] or 0 })
    t.gefunden = t.gefunden + 1
  end
  local gesamt = 0
  for _, t in ipairs(gruppen) do gesamt = gesamt + #t.eintraege end
  return gruppen, gesamt
end

-- Abzeichen für die Liste im Journal, in fester Reihenfolge
function E:AbzeichenListe()
  local d = ns.db.erfolge
  local liste = {}
  for _, a in ipairs(E.ABZEICHEN) do
    table.insert(liste, { key = a.key, art = a.art, ziel = a.ziel, icon = a.icon, wert = E.Wert(a), erhalten = d.abzeichen[a.key] })
  end
  return liste
end

-- Überblick für Fenster und Tooltips
function E:Stand()
  local d = ns.db.erfolge
  local nr, name, von, bis = E.Rang(d.punkte)
  local _, naechster = E.Rang(bis)
  local heute, ziel, erreicht, serie = self:Heute()
  local erhalten = 0
  for _, a in ipairs(E.ABZEICHEN) do if d.abzeichen[a.key] then erhalten = erhalten + 1 end end
  return { rang = nr, name = name, punkte = d.punkte, von = von, bis = bis, naechster = naechster,
    heute = heute, ziel = ziel, erreicht = erreicht, serie = serie, serieBest = d.serieBest,
    abzeichen = erhalten, abzeichenAlle = #E.ABZEICHEN }
end

function E.SerieText(st)
  local t = st.serie == 0 and L.STREAK_NONE or (st.serie == 1 and L.STREAK_ONE or string.format(L.STREAK_DAYS, st.serie))
  if (st.serieBest or 0) > st.serie then t = string.format(L.STREAK_BEST, t, st.serieBest) end
  return t
end

-- Zeilen für einen Tooltip: Rang, Punkte bis zum nächsten, heute. Ohne kurz auch die Rekorde.
function E:Tooltip(tt, kurz)
  local st = self:Stand()
  local a, l, gruen = F.akzent, F.leise, F.erfolg
  tt:AddLine(string.format(L.RANK_TITLE, st.rang, st.name), a[1], a[2], a[3])
  tt:AddLine(string.format(L.RANK_TO_NEXT, E.Zahl(st.bis - st.punkte), st.naechster), l[1], l[2], l[3])
  local farbe = st.erreicht and gruen or { 1, 1, 1 }
  tt:AddLine(string.format(L.TODAY_NODES, st.heute, st.ziel), farbe[1], farbe[2], farbe[3])
  tt:AddLine(E.SerieText(st), l[1], l[2], l[3])
  if kurz then return end
  local r = ns.db.erfolge.rekord
  if r.gold or r.knoten then
    tt:AddLine(" ")
    tt:AddLine(L.JOURNAL_RECORDS, 1, 0.82, 0)
    if r.gold then tt:AddDoubleLine(L.RECORDS.gold, ns.geld(r.gold.wert), l[1], l[2], l[3], 1, 1, 1) end
    if r.knoten then tt:AddDoubleLine(L.RECORDS.knoten, E.Zahl(r.knoten.wert), l[1], l[2], l[3], 1, 1, 1) end
  end
end

-- Beim ersten Start mit Erfolgen zählt mit, was schon gesammelt ist (Punkte, Sammelbuch,
-- Abzeichen), aber ohne Meldungen. Fehlende Felder kommen dazu.
function E:Einrichten()
  ns.db.erfolge = type(ns.db.erfolge) == "table" and ns.db.erfolge or {}
  local d = ns.db.erfolge
  for k, v in pairs(E.VORLAGE) do
    if d[k] == nil then d[k] = type(v) == "table" and {} or v end
  end
  if d.seit then return end
  d.seit = zeit()
  local g = ns.db.gesamt
  local plus = ((g.knoten.kraut or 0) + (g.knoten.erz or 0)) * E.PUNKTE.knoten
  for id in pairs(g.menge) do
    if not d.funde[id] then
      d.funde[id] = d.seit
      plus = plus + E.PUNKTE.neu
    end
  end
  d.punkte = d.punkte + plus
end

ns.beimSammeln(function(id, menge, q, knotenArt) E:Beute(id, menge, q, knotenArt) end)
ns.Ereignis("LOOT_CLOSED", fundeMelden)
ns.beimStart(function()
  E:Einrichten()
  E:Pruefen(false)
end)
