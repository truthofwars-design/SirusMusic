SirusMusicNS = SirusMusicNS or {}
local NS = SirusMusicNS

NS.CAT_ORDER = { "all", "city", "zone", "race", "dungeon", "raid",
                 "tavern", "battle", "mood", "intro", "holiday", "other" }

NS.CAT = {
    all     = "Все категории",
    city    = "Города",
    zone    = "Локации",
    race    = "Расы",
    dungeon = "Подземелья",
    raid    = "Рейды",
    tavern  = "Таверны",
    battle  = "Битвы",
    mood    = "Атмосфера",
    intro   = "Заставки",
    holiday = "Праздники",
    other   = "Прочее",
}

NS.FAC_ORDER = { "all", "A", "H", "N" }
NS.FAC = {
    all = "Все фракции",
    A   = "Альянс",
    H   = "Орда",
    N   = "Нейтральные",
}

NS.EXP_ORDER = { "all", "C", "BC", "WLK", "S" }
NS.EXP = {
    all = "Все дополнения",
    C   = "Classic",
    BC  = "Burning Crusade",
    WLK = "Wrath of the Lich King",
    S   = "Sirus",
}

NS.REPEAT = { off = "Повтор: выкл", list = "Повтор: список", one = "Повтор: трек" }

NS.RESUME_ORDER = { "off", "next", "same" }
NS.RESUME = {
    off  = "Ничего не делать",
    next = "Играть следующий трек",
    same = "Повторить оборванный трек",
}

-- Ключ мог прийти из старых сохранёнок или из чужой сборки базы,
-- поэтому подпись берётся только через эти три функции.
function NS.CatName(k) return NS.CAT[k] or NS.CAT.other end
function NS.FacName(k) return NS.FAC[k] or k or "-" end
function NS.ExpName(k) return NS.EXP[k] or k or "-" end
function NS.ZoneName(k) if not k or k == "" then return "-" end return k end

local byte, char, sub, len = string.byte, string.char, string.sub, string.len

-- Своя нижняя регистрация: стандартная string.lower не трогает кириллицу в UTF-8.
function NS.Lower(s)
    if not s or s == "" then return "" end
    local out, i, n = {}, 1, len(s)
    while i <= n do
        local b = byte(s, i)
        if b == 0xD0 then
            local c = byte(s, i + 1) or 0
            if c >= 0x90 and c <= 0x9F then
                out[#out + 1] = char(0xD0, c + 0x20)
            elseif c >= 0xA0 and c <= 0xAF then
                out[#out + 1] = char(0xD1, c - 0x20)
            elseif c == 0x81 then
                out[#out + 1] = char(0xD1, 0x91)
            else
                out[#out + 1] = char(b, c)
            end
            i = i + 2
        elseif b >= 0xC0 then
            local extra = (b >= 0xF0 and 3) or (b >= 0xE0 and 2) or 1
            out[#out + 1] = sub(s, i, i + extra)
            i = i + extra + 1
        else
            out[#out + 1] = char(b >= 65 and b <= 90 and b + 32 or b)
            i = i + 1
        end
    end
    return table.concat(out)
end

function NS.Trim(s, maxChars)
    if not s then return "" end
    local i, n, cnt = 1, len(s), 0
    while i <= n do
        local b = byte(s, i)
        local size = (b < 0x80 and 1) or (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or 2
        cnt = cnt + 1
        if cnt > maxChars then return sub(s, 1, i - 1) .. "..." end
        i = i + size
    end
    return s
end

function NS.Cut(s, n)
    if not s then return "" end
    local i, total, cnt = 1, len(s), 0
    while i <= total do
        local b = byte(s, i)
        local size = (b < 0x80 and 1) or (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or 2
        cnt = cnt + 1
        if cnt > n then return sub(s, 1, i - 1) end
        i = i + size
    end
    return s
end

function NS.Time(sec)
    sec = math.floor(tonumber(sec) or 0)
    if sec <= 0 then return "0:00" end
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- «1 запись», «2 записи», «5 записей»
function NS.Plural(n, one, few, many)
    local a, b = n % 10, n % 100
    if b >= 11 and b <= 14 then return many end
    if a == 1 then return one end
    if a >= 2 and a <= 4 then return few end
    return many
end
