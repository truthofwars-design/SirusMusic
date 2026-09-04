SirusMusicNS = SirusMusicNS or {}
local NS = SirusMusicNS

-- Размеры
local W, H      = 620, 596
local PAD       = 12
local HEAD_H    = 30
local ROWS      = 14
local ROW_H     = 21
local LIST_W    = W - PAD * 2
local LIST_H    = ROWS * ROW_H + 8
local PANEL_H   = 152
local SBAR_W    = 6
local VOL_W     = 280

-- Палитра
local AC        = { 0.31, 0.76, 0.97 }
local BG        = { 0.055, 0.055, 0.06, 0.95 }
local HEADBG    = { 0.09, 0.09, 0.10, 1 }
local PANELBG   = { 0.08, 0.08, 0.09, 1 }
local CTRLBG    = { 0.13, 0.13, 0.14, 1 }
local TRACKBG   = { 0.17, 0.17, 0.185, 1 }
local ROWBG     = { 1, 1, 1, 0.025 }
local TXT       = { 0.82, 0.82, 0.82 }
local DIM       = { 0.45, 0.45, 0.45 }
local GOLD      = { 1, 0.82, 0.2 }
local BORDER    = { 0, 0, 0, 1 }

local WHITE     = "Interface\\Buttons\\WHITE8X8"
local FONT      = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"

local BD = {
    bgFile = WHITE, edgeFile = WHITE,
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

local ui = {}
NS.ui = ui

local function skin(f, color, borderColor)
    f:SetBackdrop(BD)
    local c = color or CTRLBG
    f:SetBackdropColor(c[1], c[2], c[3], c[4] or 1)
    local b = borderColor or BORDER
    f:SetBackdropBorderColor(b[1], b[2], b[3], b[4] or 1)
    return f
end

local function text(parent, size, flag, color)
    local t = parent:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, size or 12, flag or "OUTLINE")
    local c = color or TXT
    t:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    return t
end

local function tip(frame, builder, anchor)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_TOP")
        builder(GameTooltip, self)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function button(parent, w, h, caption)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w); b:SetHeight(h)
    skin(b, CTRLBG)

    b.label = text(b, 12, "OUTLINE")
    b.label:SetPoint("CENTER", 0, 0)
    b.label:SetText(caption or "")

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
        self.label:SetTextColor(AC[1], AC[2], AC[3])
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
        self.label:SetTextColor(TXT[1], TXT[2], TXT[3])
    end)
    b.SetCaption = function(self, s) self.label:SetText(s) end
    return b
end

-- Кнопка с подсказкой: наведение красит рамку и показывает GameTooltip.
local function buttonWithTip(parent, w, h, caption, builder)
    local b = button(parent, w, h, caption)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
        self.label:SetTextColor(AC[1], AC[2], AC[3])
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        builder(GameTooltip, self)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
        self.label:SetTextColor(TXT[1], TXT[2], TXT[3])
        GameTooltip:Hide()
    end)
    return b
end

local function dropdown(parent, w, buildItems, onSelect)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(w); b:SetHeight(22)
    skin(b, CTRLBG)

    b.text = text(b, 12, "OUTLINE")
    b.text:SetPoint("LEFT", 7, 0)
    b.text:SetPoint("RIGHT", -16, 0)
    b.text:SetJustifyH("LEFT")

    local arrow = text(b, 10, "OUTLINE", DIM)
    arrow:SetPoint("RIGHT", -7, -1)
    arrow:SetText("v")

    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end)
    b:SetScript("OnClick", function(self) NS.OpenMenu(self, buildItems(), onSelect) end)
    return b
end

-- Свой чекбокс: подпись входит в кликабельную область.
local function checkbox(parent, caption)
    local c = CreateFrame("Button", nil, parent)
    c:SetHeight(16)

    local box = CreateFrame("Frame", nil, c)
    box:SetWidth(16); box:SetHeight(16)
    box:SetPoint("LEFT", 0, 0)
    skin(box, CTRLBG)

    local mark = box:CreateTexture(nil, "OVERLAY")
    mark:SetPoint("TOPLEFT", 3, -3)
    mark:SetPoint("BOTTOMRIGHT", -3, 3)
    mark:SetTexture(WHITE)
    mark:SetVertexColor(AC[1], AC[2], AC[3], 1)
    mark:Hide()

    c.label = text(c, 12, "OUTLINE")
    c.label:SetPoint("LEFT", box, "RIGHT", 6, 0)
    c.label:SetText(caption or "")
    c:SetWidth(24 + c.label:GetStringWidth())

    c.SetChecked = function(_, v) if v then mark:Show() else mark:Hide() end end
    c.GetChecked = function() return mark:IsShown() end

    c:SetScript("OnEnter", function()
        box:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
        c.label:SetTextColor(AC[1], AC[2], AC[3])
    end)
    c:SetScript("OnLeave", function()
        box:SetBackdropBorderColor(0, 0, 0, 1)
        c.label:SetTextColor(TXT[1], TXT[2], TXT[3])
    end)
    return c
end

-- Меню
local menuFrame, menuItems, menuOnSelect

local function pick(value)
    CloseDropDownMenus()
    if menuOnSelect then menuOnSelect(value) end
end

local function addItem(it, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = it.text
    if it.title then
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        return
    end
    info.notCheckable = not it.checkable
    if it.checkable then
        info.checked    = it.checked
        info.isNotRadio = not it.radio
    end
    info.func = function() pick(it.value) end
    UIDropDownMenu_AddButton(info, level)
end

local function menuInit(_, level, menuList)
    if not menuItems then return end
    level = level or 1

    if level == 1 then
        for i = 1, #menuItems do
            local it = menuItems[i]
            if it.children then
                local info = UIDropDownMenu_CreateInfo()
                info.text         = it.text
                info.notCheckable = true
                info.hasArrow     = true
                info.menuList     = i
                UIDropDownMenu_AddButton(info, level)
            else
                addItem(it, level)
            end
        end
    elseif level == 2 and menuList then
        local group = menuItems[tonumber(menuList)]
        if not group or not group.children then return end
        for i = 1, #group.children do addItem(group.children[i], level) end
    end
end

function NS.OpenMenu(anchor, items, onSelect)
    if not menuFrame then
        menuFrame = CreateFrame("Frame", "SirusMusicMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    menuItems, menuOnSelect = items, onSelect
    UIDropDownMenu_Initialize(menuFrame, menuInit, "MENU")
    ToggleDropDownMenu(1, nil, menuFrame, anchor, 0, 0)
end

local function simpleItems(order, names)
    local t = {}
    for _, key in ipairs(order) do t[#t + 1] = { text = names[key], value = key } end
    return t
end

local ZONE_CHUNK = 14

local function zoneItems()
    local items = { { text = "Все локации", value = "all" } }
    local list = {}
    for _, key in ipairs(NS.S.zones) do
        list[#list + 1] = { text = key, value = key }
    end
    if #list == 0 then return items end
    if #list <= ZONE_CHUNK then
        for i = 1, #list do items[#items + 1] = list[i] end
        return items
    end
    local i = 1
    while i <= #list do
        local last = math.min(i + ZONE_CHUNK - 1, #list)
        local group = {}
        for j = i, last do group[#group + 1] = list[j] end
        items[#items + 1] = {
            text = NS.Cut(list[i].text, 5) .. " - " .. NS.Cut(list[last].text, 5),
            children = group,
        }
        i = last + 1
    end
    return items
end

-- Копирование
local function copyBox(caption, value)
    if not ui.copy then
        local f = CreateFrame("Frame", "SirusMusicCopyFrame", UIParent)
        f:SetWidth(430); f:SetHeight(92)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
        skin(f, BG)
        f:SetFrameStrata("DIALOG")
        f:SetToplevel(true)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        f.title = text(f, 12, "OUTLINE", AC)
        f.title:SetPoint("TOPLEFT", 12, -11)

        local wrap = CreateFrame("Frame", nil, f)
        wrap:SetPoint("TOPLEFT", 12, -32)
        wrap:SetPoint("TOPRIGHT", -12, -32)
        wrap:SetHeight(24)
        skin(wrap, CTRLBG)

        local eb = CreateFrame("EditBox", nil, wrap)
        eb:SetPoint("TOPLEFT", 6, -1)
        eb:SetPoint("BOTTOMRIGHT", -6, 1)
        eb:SetFont(FONT, 12, "OUTLINE")
        eb:SetTextColor(1, 1, 1)
        eb:SetAutoFocus(true)
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        eb:SetScript("OnEnterPressed", function() f:Hide() end)
        f.eb = eb

        local hint = text(f, 11, "OUTLINE", DIM)
        hint:SetPoint("BOTTOMLEFT", 12, 11)
        hint:SetText("Ctrl+C - скопировать, Esc - закрыть")

        tinsert(UISpecialFrames, "SirusMusicCopyFrame")
        ui.copy = f
    end
    ui.copy.title:SetText(caption)
    ui.copy:Show()
    ui.copy.eb:SetText(value or "")
    ui.copy.eb:SetFocus()
    ui.copy.eb:HighlightText()
end
NS.CopyBox = copyBox

-- Меню трека по правому клику
local function trackMenu(t)
    local chat = { { text = "Сказать", value = "chat:SAY" } }
    if GetNumPartyMembers and GetNumPartyMembers() > 0 then
        chat[#chat + 1] = { text = "В группу", value = "chat:PARTY" }
    end
    if IsInGuild and IsInGuild() then
        chat[#chat + 1] = { text = "В гильдию", value = "chat:GUILD" }
    end
    chat[#chat + 1] = { text = "В поле ввода чата", value = "chat:EDIT" }

    return {
        { text = NS.Trim(t.n, 28), title = true },
        { text = "Играть",                 value = "play" },
        { text = NS.IsFav(t) and "Убрать из избранного" or "В избранное", value = "fav" },
        { text = "Скопировать название",   value = "copy:name" },
        { text = "Скопировать имя файла",  value = "copy:file" },
        { text = "Скопировать полный путь", value = "copy:path" },
        { text = "Отправить в чат",        children = chat },
    }
end

local function trackMenuSelect(t, viewIndex)
    return function(v)
        if v == "play" then
            if viewIndex then NS.PlayFromView(viewIndex) end
        elseif v == "fav" then
            NS.ToggleFav(t)
        elseif v == "copy:name" then
            copyBox("Название трека", t.n)
        elseif v == "copy:file" then
            copyBox("Имя файла", NS.FileName(t))
        elseif v == "copy:path" then
            copyBox("Полный путь", t.f)
        elseif v == "chat:EDIT" then
            local eb = (ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend())
                       or ChatFrame1EditBox
            if eb then
                if ChatEdit_ActivateChat then ChatEdit_ActivateChat(eb) else eb:Show() end
                eb:SetText((eb:GetText() or "") .. NS.TrackPlain(t))
                eb:SetFocus()
            end
        elseif string.sub(v, 1, 5) == "chat:" then
            NS.SendToChat(t, string.sub(v, 6))
        end
    end
end

-- Прокрутка
local offset = 0
local rows = {}
local refreshList, refreshState

local function maxOffset()
    return math.max(0, #NS.View() - ROWS)
end

local function setOffset(v, fromBar)
    local mx = maxOffset()
    if v < 0 then v = 0 elseif v > mx then v = mx end
    if v == offset then return end
    offset = v
    if not fromBar and ui.sbar then
        ui.sbarLock = true
        ui.sbar:SetValue(offset)
        ui.sbarLock = false
    end
    refreshList()
end
NS.SetScroll = setOffset

local function syncScrollBar()
    local sb = ui.sbar
    if not sb then return end
    local mx = maxOffset()

    if mx <= 0 then
        offset = 0
        ui.sbarLock = true
        sb:SetMinMaxValues(0, 0)
        sb:SetValue(0)
        ui.sbarLock = false
        sb:Hide()
        return
    end

    sb:Show()
    ui.sbarLock = true
    sb:SetMinMaxValues(0, mx)
    sb:SetValue(offset)
    ui.sbarLock = false

    local track = sb:GetHeight() or LIST_H
    local h = math.max(20, math.floor(track * (ROWS / (mx + ROWS))))
    if sb.thumb then sb.thumb:SetHeight(h) end
end

-- Строка списка
local function trackTooltip(tt, t)
    if not t then return end
    local folder = string.match(t.f, "^(.*)\\[^\\]+$") or ""
    local file   = string.match(t.f, "([^\\]+)$") or t.f

    tt:AddLine("#" .. (t.id or 0) .. "  " .. t.n, 1, 1, 1)
    tt:AddDoubleLine("Раздел",       NS.CatName(t.c),  0.5, 0.5, 0.5, AC[1], AC[2], AC[3])
    tt:AddDoubleLine("Локация",      NS.ZoneName(t.z), 0.5, 0.5, 0.5, AC[1], AC[2], AC[3])
    tt:AddDoubleLine("Дополнение",   NS.ExpName(t.e),  0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
    tt:AddDoubleLine("Фракция",      NS.FacName(t.fa), 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
    tt:AddDoubleLine("Длительность", NS.Time(t.d or NS.DB().defaultLength),
                     0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
    tt:AddLine(" ")
    tt:AddLine(NS.Trim(folder, 46), 0.35, 0.35, 0.35)
    tt:AddLine(file, 0.45, 0.45, 0.45)
end

local function createRow(parent, i)
    local r = CreateFrame("Button", nil, parent)
    r:SetWidth(LIST_W - 10 - SBAR_W - 8); r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 5, -(i - 1) * ROW_H - 4)

    local stripe = r:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints()
    stripe:SetTexture(ROWBG[1], ROWBG[2], ROWBG[3], ROWBG[4])
    if i % 2 == 1 then stripe:Hide() end

    local sel = r:CreateTexture(nil, "BORDER")
    sel:SetAllPoints()
    sel:SetTexture(AC[1], AC[2], AC[3], 0.13)
    sel:Hide()
    r.sel = sel

    local mark = r:CreateTexture(nil, "ARTWORK")
    mark:SetWidth(2)
    mark:SetPoint("TOPLEFT", 0, 0)
    mark:SetPoint("BOTTOMLEFT", 0, 0)
    mark:SetTexture(AC[1], AC[2], AC[3], 1)
    mark:Hide()
    r.mark = mark

    local hl = r:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture(1, 1, 1, 0.05)

    local star = CreateFrame("Button", nil, r)
    star:SetWidth(14); star:SetHeight(14)
    star:SetPoint("LEFT", 6, 0)
    local st = star:CreateTexture(nil, "ARTWORK")
    st:SetAllPoints()
    st:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    star.tex = st
    star:SetScript("OnClick", function() NS.ToggleFav(r.track) end)
    star:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(NS.IsFav(r.track) and "Убрать из избранного" or "В избранное")
        GameTooltip:Show()
    end)
    star:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.star = star

    r.num = text(r, 11, "OUTLINE", DIM)
    r.num:SetPoint("LEFT", 24, 0)
    r.num:SetWidth(34)
    r.num:SetJustifyH("RIGHT")

    r.name = text(r, 12, "OUTLINE")
    r.name:SetPoint("LEFT", 64, 0)
    r.name:SetWidth(346)
    r.name:SetJustifyH("LEFT")

    r.tag = text(r, 11, "OUTLINE", DIM)
    r.tag:SetPoint("LEFT", 418, 0)
    r.tag:SetWidth(104)
    r.tag:SetJustifyH("LEFT")

    r.dur = text(r, 11, "OUTLINE", DIM)
    r.dur:SetPoint("RIGHT", -6, 0)
    r.dur:SetWidth(40)
    r.dur:SetJustifyH("RIGHT")

    r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    r:SetScript("OnClick", function(self, btn)
        ui.flashTrack = nil
        if not self.track then return end
        if btn == "RightButton" then
            NS.OpenMenu(self, trackMenu(self.track),
                        trackMenuSelect(self.track, self.viewIndex))
        elseif self.viewIndex then
            NS.PlayFromView(self.viewIndex)
        end
    end)
    r:SetScript("OnEnter", function(self)
        if not self.track then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        trackTooltip(GameTooltip, self.track)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Клик - играть", 0.4, 0.85, 0.4)
        GameTooltip:AddLine("Правый клик - меню: копировать, отправить в чат", 0.4, 0.85, 0.4)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
end

refreshList = function()
    if not ui.frame then return end
    local view    = NS.View()
    local total   = #view
    local playing = NS.Current()

    local mx = maxOffset()
    if offset > mx then offset = mx end
    syncScrollBar()

    for i = 1, ROWS do
        local r   = rows[i]
        local idx = offset + i
        local t   = view[idx]
        if t then
            r.track, r.viewIndex = t, idx
            r.num:SetText(t.id or idx)
            r.name:SetText(NS.Trim(t.n, 52))
            r.tag:SetText(NS.CatName(t.c))
            r.dur:SetText(NS.Time(t.d or NS.DB().defaultLength))

            if NS.IsFav(t) then
                r.star.tex:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1)
            else
                r.star.tex:SetVertexColor(0.3, 0.3, 0.3, 0.5)
            end

            if t == playing then
                r.name:SetTextColor(AC[1], AC[2], AC[3])
                r.sel:SetTexture(AC[1], AC[2], AC[3], 0.13)
                r.sel:Show()
                r.mark:SetTexture(AC[1], AC[2], AC[3], 1)
                r.mark:Show()
            elseif t == ui.flashTrack then
                r.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
                r.sel:SetTexture(GOLD[1], GOLD[2], GOLD[3], 0.12)
                r.sel:Show()
                r.mark:SetTexture(GOLD[1], GOLD[2], GOLD[3], 1)
                r.mark:Show()
            else
                r.name:SetTextColor(TXT[1], TXT[2], TXT[3])
                r.sel:Hide()
                r.mark:Hide()
            end
            r:Show()
        else
            r.track, r.viewIndex = nil, nil
            r:Hide()
        end
    end

    if ui.status then
        ui.status:SetText(string.format("Показано %d из %d      Избранное %d",
            total, NS.Total(), NS.FavCount()))
    end
    if ui.queueText then
        local q = #NS.Playlist()
        ui.queueText:SetText(q > 0
            and string.format("Очередь: %s - %d из %d",
                              NS.Trim(NS.QueueLabel(), 22), NS.Index(), q)
            or "Очередь пуста")
    end
    if ui.emptyText then
        if total == 0 then
            ui.emptyText:SetText(NS.Total() == 0
                and "База треков пуста.\nФайл Tracks.lua не загрузился\nили лежит не в папке аддона."
                or "Ничего не найдено.\nПопробуй сбросить фильтры.")
            ui.emptyText:Show()
        else
            ui.emptyText:Hide()
        end
    end
end

-- Подсветка найденного трека гаснет сама, чтобы не висеть до следующего клика.
local flashToken = 0
local function scrollToTrack(t)
    if not (t and ui.frame) then return end
    local view = NS.View()
    local pos
    for i = 1, #view do
        if view[i] == t then pos = i break end
    end
    if not pos then return end

    setOffset(pos - math.floor(ROWS / 2))
    ui.flashTrack = t
    refreshList()

    flashToken = flashToken + 1
    local token = flashToken
    NS.After(4, function()
        if token ~= flashToken then return end
        ui.flashTrack = nil
        refreshList()
    end)
end
NS.ScrollToTrack = scrollToTrack

-- Громкость
local volLocked = false

function NS.SyncVolume()
    if volLocked or not ui.vol then return end
    local v = tonumber(NS.DB().volume) or 0.6
    volLocked = true
    if math.abs((ui.vol:GetValue() or 0) - v) > 0.001 then ui.vol:SetValue(v) end
    if ui.volFill then ui.volFill:SetWidth(math.max(1, (VOL_W - 2) * v)) end
    if ui.volText then
        ui.volText:SetText("Громкость музыки  " .. math.floor(v * 100 + 0.5) .. "%")
    end
    volLocked = false
end

NS.OnVolume = function() NS.SyncVolume() end

-- Настройки
local function settingsItems()
    local d = NS.DB()
    local resume = {}
    for _, key in ipairs(NS.RESUME_ORDER) do
        resume[#resume + 1] = {
            text = NS.RESUME[key], value = "resume:" .. key,
            checkable = true, radio = true, checked = (d.resumeMode == key),
        }
    end
    local s = NS.SoundState()
    return {
        { text = "Настройки SirusMusic", title = true },
        { text = "Удерживать трек при смене зоны", value = "hold",
          checkable = true, checked = d.holdOnZone },
        { text = "Звук при свёрнутом окне", value = "bgsound",
          checkable = true, checked = s.bg },
        { text = "Кнопка на миникарте", value = "minimap",
          checkable = true, checked = d.minimapShow },
        { text = "Если музыка оборвалась", children = resume },
        { text = "Убрать лишнее из избранного", value = "clean" },
        { text = "Вернуть окно в центр", value = "recenter" },
    }
end

local function settingsSelect(v)
    local d = NS.DB()
    if v == "announce" then
        d.announce = not d.announce
        NS.Say("объявление трека в чат: " .. (d.announce and "вкл" or "выкл"))
    elseif v == "hold" then
        d.holdOnZone = not d.holdOnZone
        NS.Say("удерживать трек при смене зоны: " .. (d.holdOnZone and "вкл" or "выкл"))
    elseif v == "bgsound" then
        NS.ToggleBackgroundSound()
    elseif v == "minimap" then
        NS.ToggleMinimap()
    elseif v == "clean" then
        local n = NS.CleanFavorites()
        NS.Say(n > 0 and ("убрано записей: " .. n) or "в избранном нет лишних записей.")
    elseif v == "recenter" then
        d.posX, d.posY = 0, 0
        ui.frame:ClearAllPoints()
        ui.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    elseif string.sub(v, 1, 7) == "resume:" then
        d.resumeMode = string.sub(v, 8)
        NS.Say("если музыка оборвалась: " .. NS.RESUME[d.resumeMode])
    end
    refreshState()
end

-- Обновление панели
refreshState = function()
    if not ui.frame then return end
    local d = NS.DB()

    if ui.catBtn  then ui.catBtn.text:SetText(NS.CatName(d.catFilter)) end
    if ui.facBtn  then ui.facBtn.text:SetText(NS.FacName(d.facFilter)) end
    if ui.expBtn  then ui.expBtn.text:SetText(NS.ExpName(d.expFilter)) end
    if ui.zoneBtn then
        ui.zoneBtn.text:SetText(d.zoneFilter == "all" and "Все локации" or NS.Trim(d.zoneFilter, 16))
    end
    if ui.favCheck   then ui.favCheck:SetChecked(d.onlyFav) end
    if ui.annCheck   then ui.annCheck:SetChecked(d.announce) end
    if ui.repeatBtn  then ui.repeatBtn:SetCaption(NS.REPEAT[d.repeatMode]) end
    if ui.shuffleBtn then
        ui.shuffleBtn:SetCaption(d.shuffle and "Вперемешку: вкл" or "Вперемешку: выкл")
    end
    if ui.playBtn then ui.playBtn:SetCaption(NS.IsPlaying() and "Стоп" or "Играть") end
    NS.SyncVolume()

    local t = NS.Current()
    if ui.nowText then
        local caption = t and NS.Trim(t.n, 50) or "Ничего не играет"
        if t and not NS.IsPlaying() then
            caption = caption .. "  |cff707070(остановлен)|r"
        end
        ui.nowText:SetText(caption)
        if t then ui.nowText:SetTextColor(AC[1], AC[2], AC[3])
        else ui.nowText:SetTextColor(DIM[1], DIM[2], DIM[3]) end
    end
    if ui.nowSub then
        ui.nowSub:SetText(t and NS.Trim(NS.CatName(t.c) .. " - " .. NS.ZoneName(t.z), 24) or "")
    end
    if ui.bar then
        ui.bar:SetMinMaxValues(0, NS.Length() > 0 and NS.Length() or 1)
        ui.bar:SetValue(NS.Elapsed())
    end
    if ui.timeText then
        ui.timeText:SetText(NS.Time(NS.Elapsed()) .. " / " .. NS.Time(NS.Length()))
    end
    refreshList()
end

local function onTick()
    if not (ui.frame and ui.frame:IsShown()) then return end
    if ui.bar then ui.bar:SetValue(NS.Elapsed()) end
    if ui.timeText then
        ui.timeText:SetText(NS.Time(NS.Elapsed()) .. " / " .. NS.Time(NS.Length()))
    end
end

-- Сборка окна
function NS.BuildUI()
    if ui.frame then return end
    local d = NS.DB()

    local f = CreateFrame("Frame", "SirusMusicFrame", UIParent)
    f:SetWidth(W); f:SetHeight(H)
    f:SetPoint("CENTER", UIParent, "CENTER", d.posX or 0, d.posY or 0)
    skin(f, BG)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetScale(d.scale or 1)
    f:Hide()
    ui.frame = f
    tinsert(UISpecialFrames, "SirusMusicFrame")

    -- шапка
    local head = CreateFrame("Frame", nil, f)
    head:SetPoint("TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", -1, -1)
    head:SetHeight(HEAD_H)
    head:SetBackdrop(BD)
    head:SetBackdropColor(HEADBG[1], HEADBG[2], HEADBG[3], 1)
    head:SetBackdropBorderColor(0, 0, 0, 0)
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", function() f:StartMoving() end)
    head:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local cx, cy = f:GetCenter()
        local ux, uy = UIParent:GetCenter()
        if cx and ux then d.posX, d.posY = cx - ux, cy - uy end
    end)

    local accentLine = head:CreateTexture(nil, "OVERLAY")
    accentLine:SetHeight(1)
    accentLine:SetPoint("BOTTOMLEFT", 0, 0)
    accentLine:SetPoint("BOTTOMRIGHT", 0, 0)
    accentLine:SetTexture(AC[1], AC[2], AC[3], 0.5)

    local ico = head:CreateTexture(nil, "ARTWORK")
    ico:SetWidth(16); ico:SetHeight(16)
    ico:SetPoint("LEFT", 10, 0)
    ico:SetTexture(d.icon)
    ico:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ui.titleIcon = ico

    local title = text(head, 13, "OUTLINE", AC)
    title:SetPoint("LEFT", ico, "RIGHT", 7, 0)
    title:SetText("SirusMusic")

    local ver = text(head, 10, "OUTLINE", DIM)
    ver:SetPoint("LEFT", title, "RIGHT", 6, -1)
    ver:SetText(NS.VERSION)

    local close = CreateFrame("Button", nil, head)
    close:SetWidth(18); close:SetHeight(18)
    close:SetPoint("RIGHT", -7, 0)
    skin(close, CTRLBG)
    local xs = text(close, 13, "OUTLINE", TXT)
    xs:SetPoint("CENTER", 0, 0)
    xs:SetText("x")
    close:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.9, 0.25, 0.25, 1)
        xs:SetTextColor(0.9, 0.35, 0.35)
    end)
    close:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
        xs:SetTextColor(TXT[1], TXT[2], TXT[3])
    end)
    close:SetScript("OnClick", function()
        CloseDropDownMenus()
        f:Hide()
    end)

    local setBtn = buttonWithTip(head, 96, 18, "Настройки", function(tt)
        tt:AddLine("Настройки плеера", 1, 1, 1)
        tt:AddLine("Объявление трека, поведение при смене зоны", 0.7, 0.7, 0.7, true)
        tt:AddLine("и после загрузочного экрана.", 0.7, 0.7, 0.7, true)
    end)
    setBtn:SetPoint("RIGHT", close, "LEFT", -6, 0)
    setBtn:SetScript("OnClick", function(self)
        NS.OpenMenu(self, settingsItems(), settingsSelect)
    end)

    -- поиск
    local searchWrap = CreateFrame("Frame", nil, f)
    searchWrap:SetWidth(280); searchWrap:SetHeight(22)
    searchWrap:SetPoint("TOPLEFT", PAD, -(HEAD_H + 10))
    skin(searchWrap, CTRLBG)

    local searchBox = CreateFrame("EditBox", "SirusMusicSearchBox", searchWrap)
    searchBox:SetPoint("TOPLEFT", 6, -1)
    searchBox:SetPoint("BOTTOMRIGHT", -6, 1)
    searchBox:SetFont(FONT, 12, "OUTLINE")
    searchBox:SetTextColor(1, 1, 1)
    searchBox:SetAutoFocus(false)
    searchBox:SetMaxLetters(60)
    searchBox:SetScript("OnTextChanged", function(self)
        NS.searchText = self:GetText() or ""
        if ui.searchHint then
            if NS.searchText == "" then ui.searchHint:Show() else ui.searchHint:Hide() end
        end
        offset = 0
        NS.Rebuild()
    end)
    searchBox:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
    searchBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    searchBox:SetScript("OnEditFocusGained", function()
        searchWrap:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        searchWrap:SetBackdropBorderColor(0, 0, 0, 1)
    end)
    ui.searchBox = searchBox

    ui.searchHint = text(searchWrap, 11, "OUTLINE", DIM)
    ui.searchHint:SetPoint("LEFT", 7, 0)
    ui.searchHint:SetText("Поиск по названию, локации, файлу")

    local favCheck = checkbox(f, "Только избранное")
    favCheck:SetPoint("LEFT", searchWrap, "RIGHT", 14, 0)
    favCheck:SetScript("OnClick", function(self)
        NS.DB().onlyFav = not NS.DB().onlyFav
        self:SetChecked(NS.DB().onlyFav)
        offset = 0
        NS.Rebuild()
    end)
    ui.favCheck = favCheck

    local resetBtn = buttonWithTip(f, 84, 22, "Сбросить", function(tt)
        tt:AddLine("Сбросить фильтры", 1, 1, 1)
        tt:AddLine("Поиск, категория, локация, фракция,", 0.7, 0.7, 0.7, true)
        tt:AddLine("дополнение и «только избранное».", 0.7, 0.7, 0.7, true)
        tt:AddLine("Очередь и текущий трек не меняются.", 0.5, 0.5, 0.5, true)
    end)
    resetBtn:SetPoint("TOPRIGHT", -PAD, -(HEAD_H + 10))
    resetBtn:SetScript("OnClick", function()
        offset = 0
        NS.ResetFilters()
        refreshState()
    end)

    -- фильтры
    local function applyFilter(field)
        return function(v)
            NS.DB()[field] = v
            offset = 0
            NS.Rebuild()
            refreshState()
        end
    end

    ui.catBtn = dropdown(f, 140, function() return simpleItems(NS.CAT_ORDER, NS.CAT) end,
                         applyFilter("catFilter"))
    ui.catBtn:SetPoint("TOPLEFT", PAD, -(HEAD_H + 40))

    ui.zoneBtn = dropdown(f, 152, zoneItems, applyFilter("zoneFilter"))
    ui.zoneBtn:SetPoint("LEFT", ui.catBtn, "RIGHT", 8, 0)

    ui.facBtn = dropdown(f, 132, function() return simpleItems(NS.FAC_ORDER, NS.FAC) end,
                         applyFilter("facFilter"))
    ui.facBtn:SetPoint("LEFT", ui.zoneBtn, "RIGHT", 8, 0)

    ui.expBtn = dropdown(f, 140, function() return simpleItems(NS.EXP_ORDER, NS.EXP) end,
                         applyFilter("expFilter"))
    ui.expBtn:SetPoint("LEFT", ui.facBtn, "RIGHT", 8, 0)

    -- список
    local listBox = CreateFrame("Frame", nil, f)
    listBox:SetWidth(LIST_W); listBox:SetHeight(LIST_H)
    listBox:SetPoint("TOPLEFT", PAD, -(HEAD_H + 70))
    skin(listBox, PANELBG)
    listBox:EnableMouse(true)
    listBox:EnableMouseWheel(true)
    listBox:SetScript("OnMouseWheel", function(_, delta)
        setOffset(offset - delta * 3)
    end)
    ui.listBox = listBox

    local sbarTrack = CreateFrame("Frame", nil, listBox)
    sbarTrack:SetWidth(SBAR_W); sbarTrack:SetHeight(LIST_H - 12)
    sbarTrack:SetPoint("TOPRIGHT", -5, -6)
    skin(sbarTrack, { 0.04, 0.04, 0.045, 1 })

    local sbar = CreateFrame("Slider", nil, sbarTrack)
    sbar:SetOrientation("VERTICAL")
    sbar:SetAllPoints()
    sbar:SetMinMaxValues(0, 0)
    sbar:SetValueStep(1)
    sbar:SetValue(0)

    local thumb = sbar:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(AC[1], AC[2], AC[3], 0.7)
    thumb:SetWidth(SBAR_W); thumb:SetHeight(40)
    sbar:SetThumbTexture(thumb)
    sbar.thumb = thumb

    sbar:SetScript("OnValueChanged", function(_, value)
        if ui.sbarLock then return end
        setOffset(math.floor(value + 0.5), true)
    end)
    sbar:SetScript("OnEnter", function() thumb:SetTexture(AC[1], AC[2], AC[3], 1) end)
    sbar:SetScript("OnLeave", function() thumb:SetTexture(AC[1], AC[2], AC[3], 0.7) end)
    sbar:EnableMouseWheel(true)
    sbar:SetScript("OnMouseWheel", function(_, delta) setOffset(offset - delta * 3) end)
    sbar:Hide()
    ui.sbar = sbar

    for i = 1, ROWS do rows[i] = createRow(listBox, i) end

    ui.emptyText = text(listBox, 13, "OUTLINE", DIM)
    ui.emptyText:SetPoint("CENTER", 0, 0)
    ui.emptyText:SetJustifyH("CENTER")
    ui.emptyText:Hide()

    -- плеер
    local player = CreateFrame("Frame", nil, f)
    player:SetWidth(LIST_W); player:SetHeight(PANEL_H)
    player:SetPoint("TOPLEFT", listBox, "BOTTOMLEFT", 0, -8)
    skin(player, PANELBG)

    local nowLabel = text(player, 11, "OUTLINE", DIM)
    nowLabel:SetPoint("TOPLEFT", 10, -9)
    nowLabel:SetText("Сейчас играет")

    local annCheck = checkbox(player, "писать трек в чат")
    annCheck:SetPoint("LEFT", nowLabel, "RIGHT", 14, 0)
    annCheck:SetScript("OnClick", function(self)
        NS.DB().announce = not NS.DB().announce
        self:SetChecked(NS.DB().announce)
    end)
    ui.annCheck = annCheck

    local annHover = CreateFrame("Frame", nil, player)
    annHover:SetAllPoints(annCheck)
    annHover:EnableMouse(false)

    ui.queueText = text(player, 11, "OUTLINE", DIM)
    ui.queueText:SetPoint("TOPRIGHT", -10, -9)
    ui.queueText:SetJustifyH("RIGHT")
    ui.queueText:SetWidth(300)

    local queueHover = CreateFrame("Frame", nil, player)
    queueHover:SetPoint("TOPRIGHT", -10, -7)
    queueHover:SetWidth(300); queueHover:SetHeight(14)
    queueHover:EnableMouse(true)
    tip(queueHover, function(tt)
        tt:AddLine("Очередь воспроизведения", 1, 1, 1)
        tt:AddLine("Собирается в момент клика по треку из того, что тогда было в списке.",
                   0.7, 0.7, 0.7, true)
        tt:AddLine("Смена фильтров её не меняет, иначе воспроизведение рвалось бы.",
                   0.7, 0.7, 0.7, true)
        tt:AddLine("Чтобы собрать заново - кликни по любому треку в новом списке.",
                   0.4, 0.85, 0.4, true)
    end)

    local nowBtn = CreateFrame("Button", nil, player)
    nowBtn:SetPoint("TOPLEFT", 10, -24)
    nowBtn:SetWidth(400); nowBtn:SetHeight(18)

    ui.nowText = text(nowBtn, 13, "OUTLINE", AC)
    ui.nowText:SetPoint("LEFT", 0, 0)
    ui.nowText:SetWidth(400)
    ui.nowText:SetJustifyH("LEFT")

    nowBtn:SetScript("OnClick", function()
        local t = NS.Current()
        if t then NS.Reveal(t) end
    end)
    nowBtn:SetScript("OnEnter", function(self)
        local t = NS.Current()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        if t then
            trackTooltip(GameTooltip, t)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Клик - найти этот трек в списке", 0.4, 0.85, 0.4)
            GameTooltip:AddLine("Если он скрыт фильтрами, они сбросятся.", 0.5, 0.5, 0.5, true)
        else
            GameTooltip:AddLine("Ничего не играет", 1, 1, 1)
            GameTooltip:AddLine("Выбери трек в списке выше.", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
        ui.nowText:SetTextColor(1, 1, 1)
    end)
    nowBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        local t = NS.Current()
        if t then ui.nowText:SetTextColor(AC[1], AC[2], AC[3])
        else ui.nowText:SetTextColor(DIM[1], DIM[2], DIM[3]) end
    end)
    ui.nowBtn = nowBtn

    ui.nowSub = text(player, 11, "OUTLINE", DIM)
    ui.nowSub:SetPoint("TOPRIGHT", -10, -26)
    ui.nowSub:SetWidth(180)
    ui.nowSub:SetJustifyH("RIGHT")

    -- прогресс
    local barBack = CreateFrame("Frame", nil, player)
    barBack:SetWidth(LIST_W - 20 - 78); barBack:SetHeight(10)
    barBack:SetPoint("TOPLEFT", 10, -50)
    skin(barBack, TRACKBG)

    local bar = CreateFrame("StatusBar", nil, barBack)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMRIGHT", -1, 1)
    bar:SetStatusBarTexture(WHITE)
    bar:SetStatusBarColor(AC[1], AC[2], AC[3], 0.85)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    ui.bar = bar

    barBack:EnableMouse(true)
    barBack:SetScript("OnMouseUp", function() NS.Restart() end)
    tip(barBack, function(tt)
        tt:AddLine("Клик - начать трек заново", 1, 1, 1)
        tt:AddLine("Перемотки в 3.3.5 нет: движок умеет только", 0.6, 0.6, 0.6, true)
        tt:AddLine("запускать файл с начала и останавливать его.", 0.6, 0.6, 0.6, true)
    end)

    ui.timeText = text(player, 11, "OUTLINE")
    ui.timeText:SetPoint("LEFT", barBack, "RIGHT", 10, 0)
    ui.timeText:SetText("0:00 / 0:00")

    -- управление
    local prevBtn = button(player, 66, 22, "Назад")
    prevBtn:SetPoint("TOPLEFT", 10, -72)
    prevBtn:SetScript("OnClick", function() NS.Prev() end)

    local playBtn = button(player, 78, 22, "Играть")
    playBtn:SetPoint("LEFT", prevBtn, "RIGHT", 5, 0)
    playBtn:SetScript("OnClick", function() NS.TogglePlay() end)
    ui.playBtn = playBtn

    local nextBtn = button(player, 66, 22, "Вперёд")
    nextBtn:SetPoint("LEFT", playBtn, "RIGHT", 5, 0)
    nextBtn:SetScript("OnClick", function() NS.Next(true) end)

    local repeatBtn = buttonWithTip(player, 116, 22, "Повтор: список", function(tt)
        tt:AddLine("Режим повтора", 1, 1, 1)
        tt:AddLine("выкл - доиграть очередь и остановиться", 0.7, 0.7, 0.7)
        tt:AddLine("список - после последнего трека снова первый", 0.7, 0.7, 0.7)
        tt:AddLine("трек - крутить один трек по кругу", 0.7, 0.7, 0.7)
    end)
    repeatBtn:SetPoint("LEFT", nextBtn, "RIGHT", 12, 0)
    repeatBtn:SetScript("OnClick", function() NS.CycleRepeat(); refreshState() end)
    ui.repeatBtn = repeatBtn

    local shuffleBtn = buttonWithTip(player, 134, 22, "Вперемешку: выкл", function(tt)
        tt:AddLine("Случайный порядок", 1, 1, 1)
        tt:AddLine("Очередь проигрывается вперемешку, пока не кончится,", 0.7, 0.7, 0.7, true)
        tt:AddLine("потом перемешивается заново. Повторов внутри круга нет.", 0.7, 0.7, 0.7, true)
    end)
    shuffleBtn:SetPoint("LEFT", repeatBtn, "RIGHT", 5, 0)
    shuffleBtn:SetScript("OnClick", function() NS.ToggleShuffle(); refreshState() end)
    ui.shuffleBtn = shuffleBtn

    -- громкость
    local volBack = CreateFrame("Frame", nil, player)
    volBack:SetWidth(VOL_W); volBack:SetHeight(10)
    volBack:SetPoint("BOTTOMLEFT", 10, 18)
    skin(volBack, TRACKBG)

    local volFill = volBack:CreateTexture(nil, "ARTWORK")
    volFill:SetTexture(AC[1], AC[2], AC[3], 0.55)
    volFill:SetPoint("TOPLEFT", 1, -1)
    volFill:SetPoint("BOTTOMLEFT", 1, 1)
    volFill:SetWidth(1)
    ui.volFill = volFill

    local vol = CreateFrame("Slider", nil, volBack)
    vol:SetAllPoints()
    vol:SetOrientation("HORIZONTAL")
    vol:SetMinMaxValues(0, 1)
    vol:SetValueStep(0.01)
    vol:SetValue(d.volume or 0.6)

    local volThumb = vol:CreateTexture(nil, "OVERLAY")
    volThumb:SetTexture(AC[1], AC[2], AC[3], 1)
    volThumb:SetWidth(10); volThumb:SetHeight(18)
    vol:SetThumbTexture(volThumb)

    vol:SetScript("OnValueChanged", function(_, value)
        if volLocked then return end
        NS.SetVolume(value)
    end)
    vol:EnableMouseWheel(true)
    vol:SetScript("OnMouseWheel", function(_, delta)
        NS.SetVolume((tonumber(NS.DB().volume) or 0.6) + delta * 0.05)
    end)
    vol:SetScript("OnEnter", function(self)
        volThumb:SetTexture(1, 1, 1, 1)
        volBack:SetBackdropBorderColor(AC[1], AC[2], AC[3], 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Громкость музыки", 1, 1, 1)
        GameTooltip:AddLine("Это общая громкость музыки в игре: та же ручка,", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("что в настройках звука. Отдельной громкости", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("для аддона в 3.3.5 нет.", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Пока плеер молчит, ваше значение игры не трогается", 0.5, 0.5, 0.5, true)
        GameTooltip:AddLine("и возвращается обратно при остановке.", 0.5, 0.5, 0.5, true)
        GameTooltip:AddLine("Колесо мыши - шаг 5%.", 0.4, 0.85, 0.4)
        GameTooltip:Show()
    end)
    vol:SetScript("OnLeave", function()
        volThumb:SetTexture(AC[1], AC[2], AC[3], 1)
        volBack:SetBackdropBorderColor(0, 0, 0, 1)
        GameTooltip:Hide()
    end)
    ui.vol = vol

    ui.volText = text(player, 11, "OUTLINE", DIM)
    ui.volText:SetPoint("LEFT", volBack, "RIGHT", 12, 0)
    ui.volText:SetText("Громкость музыки  60%")

    local soundBtn = buttonWithTip(player, 140, 22, "Проверить звук", function(tt)
        local s = NS.SoundState()
        local function yn(v) return v and "|cff60c060вкл|r" or "|cffff8080выкл|r" end
        tt:AddLine("Проверка звука", 1, 1, 1)
        tt:AddLine(" ")
        tt:AddDoubleLine("Звук в игре",      yn(s.all),   0.6, 0.6, 0.6, 1, 1, 1)
        tt:AddDoubleLine("Музыка в игре",    yn(s.music), 0.6, 0.6, 0.6, 1, 1, 1)
        tt:AddDoubleLine("Громкость музыки", math.floor(s.vol * 100 + 0.5) .. "%",
                         0.6, 0.6, 0.6, 1, 1, 1)
        if s.hasBg then
            tt:AddDoubleLine("Звук в свёрнутом окне", yn(s.bg), 0.6, 0.6, 0.6, 1, 1, 1)
        end
        tt:AddLine(" ")
        tt:AddLine("Клик - включить всё, что выключено, и поднять", 0.4, 0.85, 0.4, true)
        tt:AddLine("нулевую громкость. Меняются настройки игры,", 0.4, 0.85, 0.4, true)
        tt:AddLine("а не аддона. Что именно изменилось - напишет в чат.", 0.4, 0.85, 0.4, true)
        if not s.bg and s.hasBg then
            tt:AddLine(" ")
            tt:AddLine("Звук в свёрнутом окне включается в «Настройках».",
                       0.5, 0.5, 0.5, true)
        end
    end)
    soundBtn:SetPoint("BOTTOMRIGHT", -10, 14)
    soundBtn:SetScript("OnClick", function() NS.FixSound() end)

    -- строка состояния
    ui.status = text(f, 11, "OUTLINE", DIM)
    ui.status:SetPoint("BOTTOMLEFT", PAD + 2, 10)
    ui.status:SetWidth(420)
    ui.status:SetJustifyH("LEFT")

    NS.OnListChanged  = refreshList
    NS.OnStateChanged = refreshState
    NS.OnTick         = onTick
    NS.OnFiltersReset = function()
        if ui.searchBox and ui.searchBox:GetText() ~= "" then ui.searchBox:SetText("") end
    end
    NS.OnReveal = function(t)
        if not ui.frame:IsShown() then ui.frame:Show() end
        refreshState()
        scrollToTrack(t)
    end

    refreshState()
end

function NS.Toggle()
    if not ui.frame then NS.BuildUI() end
    if ui.frame:IsShown() then
        CloseDropDownMenus()
        ui.frame:Hide()
    else
        ui.frame:Show()
        NS.Rebuild()
        refreshState()
    end
end