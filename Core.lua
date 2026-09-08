SirusMusicNS = SirusMusicNS or {}
local NS = SirusMusicNS

NS.VERSION = "1.1"
local PREFIX = "|cff4fc3f7SirusMusic|r: "

local DEFAULTS = {
    volume        = 0.60,
    repeatMode    = "list",   
    resumeMode    = "off",    
    shuffle       = false,
    catFilter     = "all",
    zoneFilter    = "all",
    facFilter     = "all",
    expFilter     = "all",
    onlyFav       = false,
    favorites     = {},
    defaultLength = 150,
    minimapAngle  = 200,
    minimapShow   = true,
    icon          = "Interface\\Icons\\INV_Misc_Flute_01",
    posX          = 0,
    posY          = 0,
    scale         = 1.0,
    holdOnZone    = true,
    combatRestart = false,
    debug         = false,
    announce      = false,
    lastTrack     = "",
    lastQueue     = {},
    wasPlaying    = false,
}
NS.DEFAULTS = DEFAULTS

local S = {
    view      = {},
    playlist  = {},
    label     = "все треки",
    index     = 0,
    playing   = false,
    elapsed   = 0,
    length    = 0,
    bag       = {},
    zones     = {},
    byPath    = {},
}
NS.S = S

local TRACKS = {}
NS.Tracks = TRACKS

local function DB() return SirusMusicDB end
NS.DB = DB

local function say(msg) DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg) end
NS.Say = say

function NS.Debug(msg)
    if not (SirusMusicDB and SirusMusicDB.debug) then return end
    DEFAULT_CHAT_FRAME:AddMessage("|cff707070[SMP " ..
        string.format("%.1f", GetTime() % 1000) .. "]|r " .. msg)
end

NS.OnListChanged, NS.OnStateChanged, NS.OnTick = nil, nil, nil
local function fireList()  if NS.OnListChanged  then NS.OnListChanged()  end end
local function fireState() if NS.OnStateChanged then NS.OnStateChanged() end end

-- Отложенный вызов 
local timerFrame = CreateFrame("Frame")
local pending = {}

local function timerTick()
    local now = GetTime()
    for i = #pending, 1, -1 do
        if now >= pending[i].at then
            local fn = pending[i].fn
            table.remove(pending, i)
            fn()
        end
    end
    if #pending == 0 then timerFrame:SetScript("OnUpdate", nil) end
end

function NS.After(delay, fn)
    pending[#pending + 1] = { at = GetTime() + (delay or 0), fn = fn }
    timerFrame:SetScript("OnUpdate", timerTick)
end

-- База
local function searchKey(t)
    if not t._s then
        t._s = NS.Lower((t.n or "") .. " " .. (t.z or "") .. " " ..
                        NS.CatName(t.c) .. " " .. (t.f or ""))
    end
    return t._s
end

local function prepareDatabase()
    TRACKS = SirusMusic_Tracks or {}
    NS.Tracks = TRACKS

    local seen = {}
    S.zones  = {}
    S.byPath = {}
    for i = 1, #TRACKS do
        local t = TRACKS[i]
        t.f  = string.gsub(t.f or "", "/", "\\")
        t.c  = NS.CAT[t.c] and t.c or "other"
        t.z  = t.z or ""
        t.fa = t.fa or "N"
        t.e  = t.e or "C"
        if not t.n or t.n == "" then
            t.n = string.match(t.f, "([^\\]+)%.%w+$") or t.f
        end
        t.id = i
        t._s = nil
        searchKey(t)
        S.byPath[t.f] = t
        if t.z ~= "" and not seen[t.z] then
            seen[t.z] = true
            S.zones[#S.zones + 1] = t.z
        end
    end
    table.sort(S.zones)
end

function NS.Total() return #TRACKS end

-- Имя файла и путь нужны и для объявления в чат, и для меню копирования.
function NS.FileName(t)
    if not t then return "" end
    return string.match(t.f, "([^\\]+)$") or t.f
end

function NS.TrackLine(t)
    if not t then return "" end
    return "|cff707070№" .. (t.id or 0) .. "|r " .. t.n ..
           " |cff707070(" .. NS.FileName(t) .. ")|r"
end

-- То же самое, но без цветовых кодов: для отправки в чат и копирования.
function NS.TrackPlain(t)
    if not t then return "" end
    return "№" .. (t.id or 0) .. " " .. t.n .. " (" .. NS.FileName(t) .. ")"
end

function NS.SendToChat(t, channel)
    if not t then return end
    local text = NS.TrackPlain(t)
    if channel == "PARTY" and GetNumRaidMembers and GetNumRaidMembers() > 0 then
        channel = "RAID"
    end
    SendChatMessage(text, channel)
end
function NS.ById(id) return TRACKS[id] end

-- Избранное
function NS.IsFav(t) return t and DB().favorites[t.f] and true or false end

function NS.ToggleFav(t)
    if not t then return false end
    if DB().favorites[t.f] then
        DB().favorites[t.f] = nil
    else
        DB().favorites[t.f] = true
    end
    if DB().onlyFav then NS.Rebuild() else fireList() end
    return true
end

function NS.FavCount()
    local n = 0
    for path in pairs(DB().favorites) do
        if S.byPath[path] then n = n + 1 end
    end
    return n
end

function NS.FavOrphans()
    local n = 0
    for path in pairs(DB().favorites) do
        if not S.byPath[path] then n = n + 1 end
    end
    return n
end

function NS.CleanFavorites()
    local removed = 0
    for path in pairs(DB().favorites) do
        if not S.byPath[path] then
            DB().favorites[path] = nil
            removed = removed + 1
        end
    end
    if removed > 0 then NS.Rebuild() end
    return removed
end

-- Фильтры
NS.searchText = ""

local function passes(t, f, q, favs)
    if f.onlyFav and not favs[t.f] then return false end
    if f.catFilter  and f.catFilter  ~= "all" and t.c  ~= f.catFilter  then return false end
    if f.zoneFilter and f.zoneFilter ~= "all" and t.z  ~= f.zoneFilter then return false end
    if f.facFilter  and f.facFilter  ~= "all" and t.fa ~= f.facFilter  then return false end
    if f.expFilter  and f.expFilter  ~= "all" and t.e  ~= f.expFilter  then return false end
    if q and not string.find(searchKey(t), q, 1, true) then return false end
    return true
end

function NS.Rebuild()
    local d = DB()
    local q = NS.Lower(NS.searchText or "")
    if q == "" then q = nil end

    local view = {}
    for i = 1, #TRACKS do
        local t = TRACKS[i]
        if passes(t, d, q, d.favorites) then view[#view + 1] = t end
    end
    S.view = view
    fireList()
    return view
end

function NS.View() return S.view end

function NS.ResetFilters()
    local d = DB()
    d.catFilter, d.zoneFilter, d.facFilter, d.expFilter = "all", "all", "all", "all"
    d.onlyFav = false
    NS.searchText = ""
    if NS.OnFiltersReset then NS.OnFiltersReset() end
    NS.Rebuild()
end

-- Ключи фильтров живут в сохранёнках между сессиями и могут указывать
-- на категорию или локацию, которых после пересборки базы уже нет.
local function validateSettings()
    local d = DB()
    if not NS.CAT[d.catFilter] then d.catFilter = "all" end
    if not NS.FAC[d.facFilter] then d.facFilter = "all" end
    if not NS.EXP[d.expFilter] then d.expFilter = "all" end
    if d.zoneFilter ~= "all" then
        local ok = false
        for i = 1, #S.zones do
            if S.zones[i] == d.zoneFilter then ok = true break end
        end
        if not ok then d.zoneFilter = "all" end
    end
    if not NS.REPEAT[d.repeatMode] then d.repeatMode = "list" end
    if not NS.RESUME[d.resumeMode] then d.resumeMode = "off" end
    local v = tonumber(d.volume)
    d.volume = math.max(0, math.min(1, v or 0.6))
    local sc = tonumber(d.scale)
    d.scale = (sc and sc >= 0.6 and sc <= 1.4) and sc or 1.0
end

-- Звук
function NS.SoundState()
    local bg = GetCVar("Sound_EnableSoundWhenGameIsInBG")
    return {
        all   = GetCVar("Sound_EnableAllSound") ~= "0",
        music = GetCVar("Sound_EnableMusic")    ~= "0",
        vol   = tonumber(GetCVar("Sound_MusicVolume")) or 0,
        bg    = bg and bg ~= "0" or false,
        hasBg = bg ~= nil,
    }
end

function NS.SoundProblem()
    local s = NS.SoundState()
    if not s.all       then return "звук выключен" end
    if not s.music     then return "музыка выключена" end
    if s.vol <= 0.01   then return "громкость музыки на нуле" end
    return nil
end

function NS.FixSound()
    local fixed = {}
    if GetCVar("Sound_EnableAllSound") == "0" then
        SetCVar("Sound_EnableAllSound", 1)
        fixed[#fixed + 1] = "включён звук"
    end
    if GetCVar("Sound_EnableMusic") == "0" then
        SetCVar("Sound_EnableMusic", 1)
        fixed[#fixed + 1] = "включена музыка"
    end
    if (tonumber(GetCVar("Sound_MusicVolume")) or 0) <= 0.01 then
        fixed[#fixed + 1] = "громкость поднята до " .. NS.RaiseGameVolume() .. "%"
    end
    if #fixed == 0 then
        say("со звуком всё в порядке.")
    else
        say(table.concat(fixed, ", ") .. ".")
    end
    fireState()
    return #fixed
end

function NS.ToggleBackgroundSound()
    local on = GetCVar("Sound_EnableSoundWhenGameIsInBG") ~= "0"
    SetCVar("Sound_EnableSoundWhenGameIsInBG", on and 0 or 1)
    say("звук при свёрнутом окне " .. (on and "выключен" or "включён") .. ".")
end

-- Плеер меняет общий Sound_MusicVolume - другого способа управлять
-- громкостью в 3.3.5 нет. Значение игрока запоминается перед первой
-- подменой и возвращается на стопе, чтобы аддон не забирал ползунок
-- игры себе насовсем.
local userVolume, overriding = nil, false

function NS.ApplyVolume()
    if not overriding then
        userVolume = tonumber(GetCVar("Sound_MusicVolume")) or userVolume
        overriding = true
    end
    SetCVar("Sound_MusicVolume", string.format("%.2f", DB().volume))
end

function NS.ReleaseVolume()
    if not overriding then return end
    overriding = false
    if userVolume then
        SetCVar("Sound_MusicVolume", string.format("%.2f", userVolume))
    end
end

function NS.SetVolume(v)
    v = math.max(0, math.min(1, tonumber(v) or 0))
    DB().volume = v
    if S.playing then NS.ApplyVolume() end
    if NS.OnVolume then NS.OnVolume(v) end
end

-- Громкость игры на нуле: поднимаем и её, и свою, иначе «починка звука»
-- отчитается, а слышно по-прежнему ничего не будет. Новое значение
-- становится тем, к которому вернёмся после остановки.
function NS.RaiseGameVolume()
    local v = DB().volume
    if not v or v <= 0.01 then v = 0.5 end
    DB().volume = v
    userVolume  = v
    SetCVar("Sound_MusicVolume", string.format("%.2f", v))
    if NS.OnVolume then NS.OnVolume(v) end
    return math.floor(v * 100 + 0.5)
end

-- Воспроизведение
function NS.Current()   return S.playlist[S.index] end
function NS.IsPlaying() return S.playing end
function NS.Elapsed()   return S.elapsed end
function NS.Length()    return S.length end
function NS.Playlist()  return S.playlist end
function NS.Index()     return S.index end
function NS.QueueLabel() return S.label end

local function filterLabel()
    local d = DB()
    local parts = {}
    if d.onlyFav             then parts[#parts + 1] = "избранное" end
    if d.catFilter  ~= "all" then parts[#parts + 1] = NS.CatName(d.catFilter) end
    if d.zoneFilter ~= "all" then parts[#parts + 1] = d.zoneFilter end
    if d.facFilter  ~= "all" then parts[#parts + 1] = NS.FacName(d.facFilter) end
    if d.expFilter  ~= "all" then parts[#parts + 1] = NS.ExpName(d.expFilter) end
    if NS.searchText ~= ""   then parts[#parts + 1] = "поиск " .. NS.searchText end
    if #parts == 0 then return "все треки" end
    return table.concat(parts, ", ")
end

local function snapshot()
    S.playlist = {}
    for i = 1, #S.view do S.playlist[i] = S.view[i] end
    S.label = filterLabel()
    if S.label == "все треки" and #S.playlist ~= #TRACKS then S.label = "выборка" end
    S.bag = {}

    -- Сохраняем не сам список, а фильтры: по ним очередь соберётся заново.
    local d = DB()
    d.lastQueue = {
        onlyFav    = d.onlyFav,
        catFilter  = d.catFilter,
        zoneFilter = d.zoneFilter,
        facFilter  = d.facFilter,
        expFilter  = d.expFilter,
        search     = NS.searchText or "",
        label      = S.label,
    }
end

function NS.Stop()
    S.playing = false
    S.elapsed = 0
    DB().wasPlaying = false
    StopMusic()
    NS.ReleaseVolume()
    NS.Debug("остановлено, зонная музыка клиента снова разрешена")
    fireState()
end

function NS.PlayIndex(idx)
    local n = #S.playlist
    if n == 0 then return end
    idx = tonumber(idx)
    if not idx then return end
    if idx < 1 then idx = n elseif idx > n then idx = 1 end
    local t = S.playlist[idx]
    if not t then return end

    S.index   = idx
    S.playing = true
    S.elapsed = 0
    S.length  = t.d or DB().defaultLength

    DB().lastTrack  = t.f
    DB().wasPlaying = true

    NS.ApplyVolume()
    StopMusic()
    PlayMusic(t.f)
    NS.Debug("играю №" .. (t.id or 0) .. " " .. NS.FileName(t) ..
             ", длительность " .. S.length .. " сек")

    if DB().announce then say(NS.TrackLine(t)) end
    fireState()
end

function NS.PlayFromView(viewIdx)
    if not S.view[viewIdx] then return end
    snapshot()
    NS.PlayIndex(viewIdx)
end

-- Фильтры сбрасываются только если при них трека не видно.
function NS.Reveal(t)
    if not t then return end
    local visible = false
    for i = 1, #S.view do
        if S.view[i] == t then visible = true break end
    end
    if not visible then NS.ResetFilters() end
    if NS.OnReveal then NS.OnReveal(t, not visible) end
end

function NS.PlayById(id)
    id = tonumber(id)
    if not id then
        say("нужен номер трека, например |cffffd100/smp play 726|r")
        return
    end
    local t = TRACKS[id]
    if not t then
        say("трека с номером " .. id .. " нет. Всего треков: " .. #TRACKS .. ".")
        return
    end
    for i = 1, #S.view do
        if S.view[i] == t then NS.PlayFromView(i) return end
    end
    NS.ResetFilters()
    say("трек был скрыт фильтрами, фильтры сброшены.")
    for i = 1, #S.view do
        if S.view[i] == t then NS.PlayFromView(i) return end
    end
end

function NS.TogglePlay()
    if S.playing then
        NS.Stop()
        return
    end
    if #S.playlist == 0 then snapshot() end
    if #S.playlist == 0 then
        say("список пуст, сбрось фильтры.")
        return
    end
    NS.PlayIndex(S.index > 0 and S.index or 1)
end

-- Круг собирается без текущего трека, иначе он может выпасть вторым подряд.
local function nextShuffle()
    if #S.bag == 0 then
        for i = 1, #S.playlist do
            if i ~= S.index then S.bag[#S.bag + 1] = i end
        end
        if #S.bag == 0 then return S.index end
        for i = #S.bag, 2, -1 do
            local j = math.random(i)
            S.bag[i], S.bag[j] = S.bag[j], S.bag[i]
        end
    end
    return table.remove(S.bag)
end

function NS.Next(manual)
    if #S.playlist == 0 then return end
    if DB().shuffle then
        NS.PlayIndex(nextShuffle())
        return
    end
    if DB().repeatMode == "one" and not manual then
        NS.PlayIndex(S.index)
        return
    end
    local n = S.index + 1
    if n > #S.playlist then
        if DB().repeatMode == "off" and not manual then
            NS.Stop()
            return
        end
        n = 1
    end
    NS.PlayIndex(n)
end

function NS.Prev()
    if #S.playlist == 0 then return end
    NS.PlayIndex(S.index - 1 < 1 and #S.playlist or S.index - 1)
end

function NS.Restart()
    if S.index > 0 then NS.PlayIndex(S.index) end
end

function NS.CycleRepeat()
    local m = DB().repeatMode
    DB().repeatMode = (m == "off" and "list") or (m == "list" and "one") or "off"
    fireState()
end

function NS.ToggleShuffle()
    DB().shuffle = not DB().shuffle
    S.bag = {}
    fireState()
end

-- Клиент не сообщает об окончании трека, поэтому конец считаем по длительности.
local ticker = CreateFrame("Frame")
local acc = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    if not S.playing then return end
    S.elapsed = S.elapsed + elapsed
    acc = acc + elapsed
    if acc >= 0.2 then
        acc = 0
        if NS.OnTick then NS.OnTick() end
    end
    if S.elapsed >= S.length then NS.Next(false) end
end)

-- -- Кнопка на миникарте --------------------------------------
local minimapBtn, iconOwner = nil, "own"

local function iconTooltip(tip)
    tip:AddDoubleLine("|cff4fc3f7SirusMusic|r", "|cff707070" .. NS.VERSION .. "|r")
    local t = NS.Current()
    if t then
        tip:AddLine(t.n, 1, 1, 1)
        tip:AddLine(NS.IsPlaying() and "играет" or "остановлен", 0.5, 0.5, 0.5)
    end
    tip:AddLine(" ")
    tip:AddLine("Левый клик - открыть плеер", 0.7, 0.7, 0.7)
    tip:AddLine("Правый клик - стоп", 0.7, 0.7, 0.7)
    tip:AddLine("Средний клик - следующий трек", 0.7, 0.7, 0.7)
end

local function iconClick(button)
    if button == "RightButton" then
        NS.Stop()
    elseif button == "MiddleButton" then
        NS.Next(true)
    else
        NS.Toggle()
    end
end

local function placeMinimapBtn()
    if not minimapBtn then return end
    local a = math.rad(DB().minimapAngle or 200)
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", 80 * math.cos(a), 80 * math.sin(a))
end

local function createMinimapButton()
    local b = CreateFrame("Button", "SirusMusicMinimapButton", Minimap)
    b:SetWidth(31); b:SetHeight(31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:SetMovable(true)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    b:RegisterForDrag("LeftButton")

    local icon = b:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20); icon:SetHeight(20)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture(DB().icon)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetWidth(53); border:SetHeight(53)
    border:SetPoint("TOPLEFT", 0, 0)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    b:SetScript("OnClick", function(_, button) iconClick(button) end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        iconTooltip(GameTooltip)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local sc = Minimap:GetEffectiveScale()
            DB().minimapAngle = math.deg(math.atan2(cy / sc - my, cx / sc - mx))
            placeMinimapBtn()
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    minimapBtn = b
    placeMinimapBtn()
end

function NS.SetIcon(path)
    DB().icon = path
    if minimapBtn and minimapBtn.icon then minimapBtn.icon:SetTexture(path) end
    if NS.ldb then NS.ldb.icon = path end
    if NS.ui and NS.ui.titleIcon then NS.ui.titleIcon:SetTexture(path) end
end

function NS.MinimapOwner() return iconOwner end

function NS.ToggleMinimap()
    if iconOwner ~= "own" then
        say("кнопкой на миникарте управляет " .. iconOwner ..
            ", настрой её там.")
        return
    end
    DB().minimapShow = not DB().minimapShow
    if minimapBtn then
        if DB().minimapShow then minimapBtn:Show() else minimapBtn:Hide() end
    end
    say("кнопка на миникарте " .. (DB().minimapShow and "показана" or "скрыта") .. ".")
    fireState()
end

local function setupIcon()
    if LibStub then
        local ok, LDB = pcall(LibStub.GetLibrary, LibStub, "LibDataBroker-1.1", true)
        if ok and LDB then
            NS.ldb = LDB:NewDataObject("SirusMusic", {
                type  = "launcher",
                icon  = DB().icon,
                label = "SirusMusic",
                text  = "SirusMusic",
                OnClick = function(_, button) iconClick(button) end,
                OnTooltipShow = function(tip) iconTooltip(tip) end,
            })
            local ok2, DBIcon = pcall(LibStub.GetLibrary, LibStub, "LibDBIcon-1.0", true)
            if ok2 and DBIcon then
                DB().minimapLDB = DB().minimapLDB or {}
                DBIcon:Register("SirusMusic", NS.ldb, DB().minimapLDB)
                iconOwner = "LibDBIcon"
                return
            end
        end
    end

    if SirusMinimap and SirusMinimap.RegisterButton then
        local ok = pcall(SirusMinimap.RegisterButton, SirusMinimap, {
            name    = "SirusMusic",
            icon    = DB().icon,
            tooltip = "SirusMusic",
            onClick = function() NS.Toggle() end,
        })
        if ok then iconOwner = "SirusMinimap" return end
    end

    iconOwner = "own"
    createMinimapButton()
    if not DB().minimapShow then minimapBtn:Hide() end
end

-- Смена зоны
-- Заходя в новую зону, клиент запускает свою музыку поверх нашей.
-- Единственный способ удержать трек - заявить его заново; звук при
-- этом начинается сначала, поэтому счётчик тоже обнуляется.
local zoneToken, lastHold = 0, -100
local zoneFrame = CreateFrame("Frame")
zoneFrame:RegisterEvent("ZONE_CHANGED")
zoneFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneFrame:SetScript("OnEvent", function(_, event)
    NS.Debug(event .. " (" .. (GetRealZoneText and GetRealZoneText() or "?") .. ")")
    if not S.playing then return end
    if not DB().holdOnZone then
        NS.Debug("удержание выключено, зонная музыка клиента не глушится")
        return
    end
    local t = S.playlist[S.index]
    if not t then return end
    if S.length - S.elapsed < 5 then return end
    if GetTime() - lastHold < 3 then
        NS.Debug("перезапуск пропущен: прошло меньше 3 сек")
        return
    end

    zoneToken = zoneToken + 1
    local token = zoneToken
    NS.After(1.0, function()
        if token ~= zoneToken or not S.playing then return end
        lastHold  = GetTime()
        S.elapsed = 0
        NS.ApplyVolume()
        StopMusic()
        PlayMusic(t.f)
        NS.Debug("трек перезапущен поверх зонной музыки")
        fireState()
    end)
end)

-- Бой
-- Клиент может задушить музыкальный поток, когда в бою не хватает
-- звуковых каналов. Узнать об этом из Lua нельзя, поэтому единственная
-- страховка - перезапустить трек по выходе из боя.
local combatFrame = CreateFrame("Frame")
local combatStart = 0
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        combatStart = GetTime()
        NS.Debug("вошёл в бой, каналов: " .. (GetCVar("Sound_NumChannels") or "?"))
        if NS.ui and NS.ui.searchBox then NS.ui.searchBox:ClearFocus() end
        return
    end

    local fought = GetTime() - combatStart
    NS.Debug(string.format("вышел из боя, длился %.0f сек", fought))
    if not (S.playing and DB().combatRestart) then return end
    if fought < 5 then return end

    local t = S.playlist[S.index]
    if not t then return end
    if S.length - S.elapsed < 5 then return end

    S.elapsed = 0
    NS.ApplyVolume()
    StopMusic()
    PlayMusic(t.f)
    NS.Debug("трек перезапущен после боя")
    fireState()
end)

-- -- Очередь с прошлой сессии ---------------------------------
-- Собирается заново по сохранённым фильтрам, курсор встаёт на
-- последний трек. Сама музыка отсюда не запускается.
function NS.RestoreLast()
    local d = DB()
    local path = d.lastTrack
    if not path or path == "" then return nil end

    local t = S.byPath[path]
    if not t then return nil end

    local q = d.lastQueue or {}
    local search = NS.Lower(q.search or "")
    if search == "" then search = nil end

    local list = {}
    for i = 1, #TRACKS do
        local tr = TRACKS[i]
        if passes(tr, q, search, d.favorites) then list[#list + 1] = tr end
    end

    S.index = 0
    for i = 1, #list do
        if list[i] == t then S.index = i break end
    end

    if S.index == 0 then
        list    = { t }
        S.index = 1
        S.label = "последний трек"
    else
        S.label = q.label or "все треки"
    end

    S.playlist = list
    S.bag      = {}
    S.playing  = false
    S.elapsed  = 0
    S.length   = t.d or d.defaultLength
    return t
end

-- Загрузочный экран рвёт поток, и перемотки в 3.3.5 нет: продолжить
-- с середины нельзя. Поэтому есть выбор из трёх вариантов поведения.
local function afterLoadingScreen()
    local d = DB()
    if not d.wasPlaying then return end

    S.playing = false
    S.elapsed = 0
    StopMusic()

    local mode = d.resumeMode
    if mode ~= "next" and mode ~= "same" then
        fireState()
        return
    end

    NS.After(1.5, function()
        if S.playing then return end
        if #S.playlist == 0 then NS.RestoreLast() end
        if #S.playlist == 0 then return end
        if mode == "next" then
            NS.Next(true)
        else
            NS.PlayIndex(S.index > 0 and S.index or 1)
        end
    end)
end

-- Команды
-- Справка печатается из этой же таблицы, поэтому объявить команду
-- и забыть её реализовать больше нельзя.
local SLASH = "/smp"
local CMD, ORDER = {}, {}

local function reg(name, args, group, desc, fn)
    CMD[name] = { args = args, group = group, desc = desc, fn = fn }
    ORDER[#ORDER + 1] = name
end

local function alias(name, target)
    CMD[name] = { alias = target, fn = function(rest) CMD[target].fn(rest) end }
end

local function onOff(v) return v and "|cff60c060вкл|r" or "|cffff8080выкл|r" end

local function printHelp()
    say("команды (" .. #ORDER .. "):")
    local group
    for i = 1, #ORDER do
        local c = CMD[ORDER[i]]
        if c.group ~= group then
            group = c.group
            DEFAULT_CHAT_FRAME:AddMessage("  |cff4fc3f7" .. group .. "|r")
        end
        local line = SLASH .. " " .. ORDER[i]
        if ORDER[i] == "" then line = SLASH end
        if c.args then line = line .. " " .. c.args end
        DEFAULT_CHAT_FRAME:AddMessage("     |cffffd100" .. line .. "|r - " .. c.desc)
    end
end

-- -- Воспроизведение --
reg("", nil, "Плеер", "открыть или закрыть окно", function()
    NS.Toggle()
end)

reg("play", "<номер>", "Плеер", "играть трек по номеру из списка", function(rest)
    NS.PlayById(rest)
end)

reg("stop", nil, "Плеер", "остановить", function()
    NS.Stop()
end)

reg("next", nil, "Плеер", "следующий трек", function()
    NS.Next(true)
end)

reg("prev", nil, "Плеер", "предыдущий трек", function()
    NS.Prev()
end)

reg("again", nil, "Плеер", "начать текущий трек заново", function()
    if NS.Current() then NS.Restart() else say("сейчас ничего не выбрано.") end
end)

reg("repeat", nil, "Плеер", "режим повтора: выкл / список / трек", function()
    NS.CycleRepeat()
    say(NS.REPEAT[DB().repeatMode])
end)

reg("shuffle", nil, "Плеер", "вперемешку вкл или выкл", function()
    NS.ToggleShuffle()
    say("вперемешку: " .. onOff(DB().shuffle))
end)

-- -- Список --
reg("fav", nil, "Список", "добавить или убрать текущий трек из избранного", function()
    local t = NS.Current()
    if not t then
        say("сейчас ничего не выбрано, избранное не изменилось.")
        return
    end
    NS.ToggleFav(t)
    say((NS.IsFav(t) and "в избранное: " or "убрано из избранного: ") .. t.n ..
        " (всего " .. NS.FavCount() .. ")")
end)

reg("clean", nil, "Список", "убрать из избранного записи без файла в базе", function()
    local removed = NS.CleanFavorites()
    say(removed > 0
        and ("убрано записей: " .. removed)
        or  "в избранном нет лишних записей.")
end)

reg("filters", nil, "Список", "сбросить поиск и все фильтры", function()
    NS.ResetFilters()
    say("фильтры сброшены, в списке снова " .. NS.Total() .. " " ..
        NS.Plural(NS.Total(), "трек", "трека", "треков") .. ".")
end)

-- -- Звук --
reg("vol", "<0-100>", "Звук", "громкость музыки", function(rest)
    local v = tonumber(rest)
    if not v or v < 0 or v > 100 then
        say("громкость задаётся числом от 0 до 100, например |cffffd100/smp vol 60|r" ..
            " (сейчас " .. math.floor((DB().volume or 0) * 100 + 0.5) .. "%)")
        return
    end
    NS.SetVolume(v / 100)
    say("громкость музыки: " .. math.floor(v + 0.5) .. "%")
end)

reg("sound", nil, "Звук", "проверить и починить настройки звука игры", function()
    NS.FixSound()
end)

reg("channels", "<32-128>", "Звук", "показать или задать число звуковых каналов", function(rest)
    local cur = tonumber(GetCVar("Sound_NumChannels")) or 0
    if rest == "" then
        say("звуковых каналов сейчас: " .. cur)
        DEFAULT_CHAT_FRAME:AddMessage(
            "     Ползунок в настройках звука игры пишет сюда 32-64")
        DEFAULT_CHAT_FRAME:AddMessage(
            "     и затирает большее значение при любом изменении настроек.")
        DEFAULT_CHAT_FRAME:AddMessage(
            "     Задать: |cffffd100/smp channels 128|r. Значение читается")
        DEFAULT_CHAT_FRAME:AddMessage(
            "     при запуске звука, поэтому нужен перезаход в игру.")
        return
    end
    local v = tonumber(rest)
    if not v or v < 32 or v > 128 then
        say("каналы задаются числом от 32 до 128, например |cffffd100/smp channels 128|r")
        return
    end
    SetCVar("Sound_NumChannels", math.floor(v))
    say("звуковых каналов: " .. cur .. " -> " .. math.floor(v) ..
        ". Применится после перезахода в игру.")
    DEFAULT_CHAT_FRAME:AddMessage(
        "     Аддон это значение не сторожит: если игра его сбросит, задай заново.")
end)

reg("bg", nil, "Звук", "звук при свёрнутом окне игры", function()
    NS.ToggleBackgroundSound()
end)

-- -- Окно --
reg("scale", "<0.6-1.4>", "Окно", "масштаб окна плеера", function(rest)
    local v = tonumber(rest)
    if not v or v < 0.6 or v > 1.4 then
        say("масштаб задаётся числом от 0.6 до 1.4, например |cffffd100/smp scale 0.9|r" ..
            " (сейчас " .. (DB().scale or 1) .. ")")
        return
    end
    DB().scale = v
    if NS.ui and NS.ui.frame then NS.ui.frame:SetScale(v) end
    say("масштаб окна: " .. v)
end)

reg("reset", nil, "Окно", "вернуть окно в центр и масштаб к 1.0", function()
    DB().posX, DB().posY, DB().scale = 0, 0, 1.0
    if NS.ui and NS.ui.frame then
        NS.ui.frame:SetScale(1.0)
        NS.ui.frame:ClearAllPoints()
        NS.ui.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    say("окно возвращено в центр, масштаб 1.0.")
end)

reg("minimap", nil, "Окно", "показать или скрыть кнопку на миникарте", function()
    NS.ToggleMinimap()
end)

reg("icon", "<имя>", "Окно", "сменить иконку кнопки", function(rest)
    if rest == "" then
        say("укажи имя иконки, например |cffffd100/smp icon INV_Misc_Flute_01|r")
        return
    end
    local path = rest
    if not string.find(path, "\\") then path = "Interface\\Icons\\" .. rest end
    NS.SetIcon(path)
    say("иконка: " .. path)
end)

-- -- Настройки --
reg("announce", nil, "Настройки", "писать название трека в чат при запуске", function()
    DB().announce = not DB().announce
    say("объявлять трек в чат: " .. onOff(DB().announce))
end)

reg("hold", nil, "Настройки", "удерживать свой трек при смене зоны", function()
    DB().holdOnZone = not DB().holdOnZone
    say("удерживать трек при смене зоны: " .. onOff(DB().holdOnZone) ..
        (DB().holdOnZone and " |cff707070(трек начнётся заново)|r" or ""))
end)

reg("resume", "<1-3>", "Настройки", "что делать, если музыка оборвалась", function(rest)
    local map = { ["1"] = "off", off = "off", ["2"] = "next", next = "next",
                  ["3"] = "same", same = "same" }
    local mode = map[string.lower(rest or "")]
    if not mode then
        say("если музыка оборвалась (загрузочный экран, /reload) - сейчас: |cff4fc3f7" ..
            NS.RESUME[DB().resumeMode] .. "|r")
        for i = 1, #NS.RESUME_ORDER do
            local key = NS.RESUME_ORDER[i]
            DEFAULT_CHAT_FRAME:AddMessage("     |cffffd100/smp resume " .. i .. "|r - " ..
                NS.RESUME[key] .. (DB().resumeMode == key and "  |cff60c060(текущее)|r" or ""))
        end
        return
    end
    DB().resumeMode = mode
    say("если музыка оборвалась: " .. NS.RESUME[mode])
end)

reg("length", "<сек>", "Настройки", "длительность треков, которых нет в базе", function(rest)
    local v = tonumber(rest)
    if not v or v < 30 or v > 600 then
        say("длительность задаётся числом от 30 до 600 секунд" ..
            " (сейчас " .. (DB().defaultLength or 150) .. ")")
        return
    end
    DB().defaultLength = math.floor(v)
    say("длительность по умолчанию: " .. DB().defaultLength .. " сек.")
end)

reg("combat", nil, "Настройки", "перезапускать трек после боя", function()
    DB().combatRestart = not DB().combatRestart
    say("перезапускать трек после боя: " .. onOff(DB().combatRestart) ..
        (DB().combatRestart and " |cff707070(с начала, только если бой длился дольше 5 сек)|r" or ""))
end)

reg("debug", nil, "Настройки", "лог событий музыки в чат", function()
    DB().debug = not DB().debug
    say("отладочный лог: " .. onOff(DB().debug))
    if DB().debug then
        DEFAULT_CHAT_FRAME:AddMessage("     пишет смену зоны, вход и выход из боя,")
        DEFAULT_CHAT_FRAME:AddMessage("     каждый запуск и остановку трека.")
        DEFAULT_CHAT_FRAME:AddMessage("     Выключить: |cffffd100/smp debug|r")
    end
end)

reg("config", nil, "Настройки", "показать все текущие настройки", function()
    local d, s = DB(), NS.SoundState()
    say("настройки:")
    -- Значения уже несут свою раскраску, вкладывать |c внутрь |c нельзя:
    -- первый же |r закрыл бы оба цвета.
    local function blue(x) return "|cff4fc3f7" .. x .. "|r" end
    local rows = {
        { "громкость",                 blue(math.floor((d.volume or 0) * 100 + 0.5) .. "%") },
        { "повтор",                    blue(NS.REPEAT[d.repeatMode]) },
        { "вперемешку",                onOff(d.shuffle) },
        { "объявлять трек в чат",      onOff(d.announce) },
        { "удерживать при смене зоны", onOff(d.holdOnZone) },
        { "если музыка оборвалась",    blue(NS.RESUME[d.resumeMode]) },
        { "длительность по умолчанию", blue((d.defaultLength or 150) .. " сек.") },
        { "перезапуск после боя",      onOff(d.combatRestart) },
        { "звук при свёрнутом окне",   onOff(s.bg) },
        { "звуковых каналов",          blue(GetCVar("Sound_NumChannels") or "?") },
        { "кнопка на миникарте",       onOff(d.minimapShow) ..
                                       " |cff707070(" .. NS.MinimapOwner() .. ")|r" },
        { "масштаб окна",              blue(tostring(d.scale or 1)) },
        { "в избранном",               blue(NS.FavCount() .. " " ..
                                       NS.Plural(NS.FavCount(), "трек", "трека", "треков")) },
    }
    for i = 1, #rows do
        DEFAULT_CHAT_FRAME:AddMessage("     " .. rows[i][1] .. ": " .. rows[i][2])
    end
end)

reg("help", nil, "Настройки", "этот список команд", printHelp)

alias("?", "help")
alias("volume", "vol")
alias("settings", "config")

SLASH_SIRUSMUSIC1 = "/smp"
SLASH_SIRUSMUSIC2 = "/sirusmusic"
SlashCmdList["SIRUSMUSIC"] = function(msg)
    local raw = string.match(msg or "", "^%s*(.-)%s*$")
    local word, rest = string.match(raw, "^(%S*)%s*(.-)$")
    local c = CMD[string.lower(word or "")]
    if c then
        c.fn(rest or "")
    else
        say("нет команды |cffffd100" .. word .. "|r.")
        printHelp()
    end
end

-- Загрузка
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("PLAYER_LOGOUT")
loader:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "SirusMusic" then
        SirusMusicDB = SirusMusicDB or {}
        for k, v in pairs(DEFAULTS) do
            if SirusMusicDB[k] == nil then
                if type(v) == "table" then SirusMusicDB[k] = {} else SirusMusicDB[k] = v end
            end
        end
        prepareDatabase()
        validateSettings()
		
        if math.randomseed then
            math.randomseed(time())
        else
            -- randomseed нет в клиенте: прокручиваем генератор, чтобы
            -- сессии не начинались с одной и той же последовательности
            for i = 1, time() % 97 do math.random() end
        end

        for _, dead in ipairs({ "combatPause", "combatGuard", "guardDelay",
                                "guardProbe", "guardStep", "guardRev" }) do
            SirusMusicDB[dead] = nil
        end

    elseif event == "PLAYER_LOGIN" then
        if #TRACKS == 0 then prepareDatabase() end
        NS.BuildUI()
        setupIcon()
        NS.Rebuild()

        local last = NS.RestoreLast()
        fireState()

        local problem = NS.SoundProblem()
        if problem then
            say("|cffff8080" .. problem .. "|r. Починить: |cffffd100/smp sound|r")
        end
        if #TRACKS == 0 then
            say("|cffff8080база треков пуста|r")
        else
            say("треков: " .. #TRACKS .. ". Открыть: |cffffd100/smp|r")
            if last then
                say("последний трек: |cff4fc3f7" .. last.n .. "|r")
            end
            local orphans = NS.FavOrphans()
            if orphans > 0 then
                say("в избранном " .. orphans .. " " ..
                    NS.Plural(orphans, "запись", "записи", "записей") ..
                    " без файла в базе. Убрать: |cffffd100/smp clean|r")
            end
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        if SirusMusicDB then afterLoadingScreen() end

    elseif event == "PLAYER_LOGOUT" then
        if SirusMusicDB then SirusMusicDB.wasPlaying = S.playing end
    end
end)