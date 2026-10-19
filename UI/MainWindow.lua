-------------------------------------------------------------------------------
--  UI\MainWindow.lua -- 独立管理器主窗口、固定分类侧边栏与瀑布流卡片架构
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = ns.DuoUI
local C_AddOns = ns.C_AddOns or _G.C_AddOns or {}
local L = ns.L or {}

local uiContainer = {}
ns.uiContainer = uiContainer
local catNavButtons = {}
local cardPool = {}
local drawerPool = {}
local drawerExpanded = {}
local searchQuery = ""
local managerWindow = nil

local RebuildAddonWorkspace

-- -----------------------------------------------------------------------------
-- 零闭包静态事件处理架构 (极速运行、零内存垃圾生成)
-- -----------------------------------------------------------------------------
local function ProfileButton_OnClick(self, button)
    local name = self._profileName
    if not name then return end
    if button == "RightButton" then
        ns.ToggleProfileMenu(self, name)
    else
        ns.CloseAllDropdowns()
        ns.ResetSessionSortOrder()
        DuoUI.ApplyAddonProfile(name)
    end
end

local function ProfileButton_OnEnter(self)
    local name = self._profileName
    if not name then return end
    local isCur = self._isCur
    if not isCur then
        self._border:SetColorTexture(1, 1, 1, 0.20)
        self._bg:SetColorTexture(0.14, 0.16, 0.20, 0.90)
        self._fs:SetTextColor(1, 1, 1, 1)
    end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:ClearLines()
    local displayProfileName = name
    if name == "默认方案" then
        displayProfileName = L["DEFAULT_PROFILE"] or name
    end
    GameTooltip:AddLine(string.format(L["PROFILE_PRESET"] or "预设方案: %s", displayProfileName), 1, 1, 1)
    if isCur then
        GameTooltip:AddLine(L["PROFILE_ACTIVE_TIP"] or "● 当前激活方案（改动实时自动保存）", 0.35, 1.0, 0.55)
    else
        GameTooltip:AddLine(L["PROFILE_SWITCH_TIP"] or "左键：切换应用此方案", 0.4, 0.8, 1)
    end
    GameTooltip:AddLine(L["PROFILE_MANAGE_TIP"] or "右键：另存覆盖 / 删除此方案", 0.70, 0.75, 0.85)
    GameTooltip:Show()
end

local function ProfileButton_OnLeave(self)
    if not self._isCur then
        self._border:SetColorTexture(1, 1, 1, 0.08)
        self._bg:SetColorTexture(0.08, 0.09, 0.12, 0.70)
        self._fs:SetTextColor(0.65, 0.70, 0.78, 1)
    end
    GameTooltip:Hide()
end

local function CatButton_OnClick(self)
    if not self._catName then return end
    local db = ns.GetDB()
    db.selectedCategory = self._catName
    ns.ResetSessionSortOrder()
    if managerWindow and managerWindow._scrollFrame then
        managerWindow._scrollFrame:SetVerticalScroll(0)
    end
    RebuildAddonWorkspace()
end

local function CatButton_OnEnter(self)
    local db = ns.GetDB()
    if self._catName ~= db.selectedCategory then
        self._bg:SetColorTexture(1, 1, 1, 0.05)
        self._title:SetTextColor(1, 1, 1, 1)
        self._count:SetTextColor(0.75, 0.80, 0.85, 1)
    end
end

local function CatButton_OnLeave(self)
    local db = ns.GetDB()
    if self._catName ~= db.selectedCategory then
        self._bg:SetColorTexture(0, 0, 0, 0)
        self._title:SetTextColor(0.70, 0.73, 0.78, 1)
        self._count:SetTextColor(0.40, 0.44, 0.50, 1)
    end
end

local function CardToggle_Execute(card)
    local entry = card and card._entry
    if not entry or entry.isProtected then return end
    local want = not card._cb:GetChecked()
    card._cb:SetChecked(want)
    ns.SetAddonState(entry.index, want)
    ns.SetAddonState(entry.name, want)
    if entry.children then
        for _, child in ipairs(entry.children) do
            ns.SetAddonState(child.index, want)
            ns.SetAddonState(child.name, want)
        end
    end
    ns.SaveAddonConfig()
    if ns.SyncActiveProfileState then
        ns.SyncActiveProfileState()
    end
    DuoUI.hasAddonChange = true
    RebuildAddonWorkspace()
end

local function Card_OnClick(self)
    CardToggle_Execute(self)
end

local function CardCheckbox_OnClick(self)
    CardToggle_Execute(self._card or self:GetParent())
end

local function CardGear_OnClick(self)
    local card = self._card or self:GetParent()
    local entry = card and card._entry
    if entry then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
        ns.OpenAddonConfig(entry.name, entry.cleanTitle or entry.title)
    end
end

local function CardGear_OnEnter(self)
    local ar, ag, ab = ns.GetThemeAccent()
    self:SetAlpha(1.0)
    self._bg:SetColorTexture(ar, ag, ab, 0.18)
    self._tex:SetVertexColor(ar, ag, ab, 1.0)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(L["OPEN_SETTINGS"] or "打开该插件设置", 1, 1, 1)
    GameTooltip:Show()
end

local function CardGear_OnLeave(self)
    local card = self._card or self:GetParent()
    local ar, ag, ab = ns.GetThemeAccent()
    self._bg:SetColorTexture(1, 1, 1, 0)
    self._tex:SetVertexColor(ar, ag, ab, 0.70)
    GameTooltip:Hide()
    if card and not card:IsMouseOver() then
        self:SetAlpha(0)
    else
        self:SetAlpha(0.60)
    end
end

local function CardBadge_OnClick(self)
    local card = self._card or self:GetParent()
    local entry = card and card._entry
    if not entry or entry.isProtected then return end
    if entry.children and #entry.children > 0 then
        drawerExpanded[entry.name] = not (drawerExpanded[entry.name] == true)
        RebuildAddonWorkspace()
    end
end

local function CardBadge_OnEnter(self)
    local card = self._card or self:GetParent()
    local entry = card and card._entry
    if not entry or not entry.children or #entry.children == 0 then return end
    local ar, ag, ab = ns.GetThemeAccent()
    self._border:SetColorTexture(ar, ag, ab, 1.0)
    self._bg:SetColorTexture(ar * 0.45, ag * 0.45, ab * 0.45, 0.95)
end

local function CardBadge_OnLeave(self)
    local card = self._card or self:GetParent()
    local entry = card and card._entry
    if not entry or not entry.children or #entry.children == 0 then return end
    local ar, ag, ab = ns.GetThemeAccent()
    local isDrawerOpen = (drawerExpanded[entry.name] == true)
    if isDrawerOpen then
        self._bg:SetColorTexture(ar * 0.35, ag * 0.35, ab * 0.35, 0.95)
        self._border:SetColorTexture(ar, ag, ab, 0.90)
    elseif entry.enabled then
        self._bg:SetColorTexture(ar * 0.15, ag * 0.15, ab * 0.15, 0.80)
        self._border:SetColorTexture(ar, ag, ab, 0.40)
    else
        self._bg:SetColorTexture(0.08, 0.09, 0.12, 0.60)
        self._border:SetColorTexture(1, 1, 1, 0.08)
    end
end

local function Card_OnEnter(self)
    local entry = self._entry
    if not entry then return end
    local ar, ag, ab = ns.GetThemeAccent()
    self._bg:SetColorTexture(0.10, 0.12, 0.16, 0.92)
    self._border:SetColorTexture(ar, ag, ab, 0.45)
    if self._gearBtn then
        self._gearBtn:SetAlpha(0.60)
    end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 6, 0)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(entry.title or entry.name, 1, 1, 1)
    GameTooltip:AddLine((L["FOLDER_NAME"] or "目录名: ") .. entry.name, 0.55, 0.60, 0.70)
    if entry.version and entry.version ~= "" then
        GameTooltip:AddLine((L["VERSION_LABEL"] or "版本: ") .. entry.version, 0.40, 0.80, 1.0)
    end
    if entry.author and entry.author ~= "" then
        GameTooltip:AddLine((L["AUTHOR_LABEL"] or "作者: ") .. entry.author, 0.70, 0.75, 0.85)
    end
    if entry.notes and entry.notes ~= "" then
        GameTooltip:AddLine(entry.notes, 0.9, 0.85, 0.6, true)
    end
    if entry.deps and #entry.deps > 0 then
        GameTooltip:AddLine(string.format(L["TOOLTIP_DEPS"] or "依赖: %s", table.concat(entry.deps, ", ")), 0.4, 0.75, 1, true)
    end
    if entry.children and #entry.children > 0 then
        local subNames = {}
        for _, c in ipairs(entry.children) do subNames[#subNames + 1] = c.cleanTitle or c.name end
        GameTooltip:AddLine(string.format(L["TOOLTIP_EXPAND_FINE_TUNE"] or "点击展开微调 (%d): %s", #entry.children, table.concat(subNames, ", ")), ar, ag, ab, true)
    end
    GameTooltip:AddLine(string.format(L["TOOLTIP_MEM"] or "内存占用: %s", ns.FormatMemory(entry.groupMem, false)), 0.5, 0.9, 0.5)
    GameTooltip:Show()
end

local function Card_OnLeave(self)
    local entry = self._entry
    if not entry then return end
    local ar, ag, ab = ns.GetThemeAccent()
    if self._gearBtn and not self._gearBtn:IsMouseOver() then
        self._gearBtn:SetAlpha(0)
    end
    if entry.enabled or entry.isProtected then
        self._border:SetColorTexture(ar, ag, ab, 0.22)
        self._bg:SetColorTexture(0.07, 0.08, 0.11, 0.85)
    else
        self._border:SetColorTexture(1, 1, 1, 0.03)
        self._bg:SetColorTexture(0.04, 0.05, 0.07, 0.45)
    end
    GameTooltip:Hide()
end

local function SubRowCheckbox_OnClick(self)
    local subRow = self._subRow or self:GetParent()
    local child = subRow and subRow._child
    if not child then return end
    local want = not self:GetChecked()
    self:SetChecked(want)
    ns.SetAddonState(child.index, want)
    ns.SetAddonState(child.name, want)
    ns.SaveAddonConfig()
    if ns.SyncActiveProfileState then
        ns.SyncActiveProfileState()
    end
    DuoUI.hasAddonChange = true
    RebuildAddonWorkspace()
end

-- 顶部方案预设条刷新
local function RefreshProfilesBar()
    if not uiContainer or not uiContainer.pillsContainer then return end
    local bar = uiContainer.pillsContainer
    local db = ns.GetDB()
    local profiles = db.profiles
    local active = ns.GetActiveProfile()
    local ar, ag, ab = ns.GetThemeAccent()

    if not next(profiles) then
        profiles["默认方案"] = ns.CaptureCurrentState()
    end

    bar._buttons = bar._buttons or {}
    for _, btn in ipairs(bar._buttons) do btn:Hide() end

    local x = 0
    local btnIdx = 0

    local names = {}
    for name in pairs(profiles) do names[#names + 1] = name end
    table.sort(names, function(a, b)
        if a == "默认方案" then return true end
        if b == "默认方案" then return false end
        return a < b
    end)

    for _, name in ipairs(names) do
        btnIdx = btnIdx + 1
        local btn = bar._buttons[btnIdx]
        if not btn then
            btn = CreateFrame("Button", nil, bar)
            btn:SetHeight(22)

            local border = btn:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints()
            btn._border = border

            local bg = btn:CreateTexture(nil, "BORDER")
            bg:SetPoint("TOPLEFT", 1, -1)
            bg:SetPoint("BOTTOMRIGHT", -1, 1)
            btn._bg = bg

            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("CENTER", 0, 0)
            btn._fs = fs

            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            btn:SetScript("OnClick", ProfileButton_OnClick)
            btn:SetScript("OnEnter", ProfileButton_OnEnter)
            btn:SetScript("OnLeave", ProfileButton_OnLeave)

            bar._buttons[btnIdx] = btn
        end

        local isCur = (name == active)
        btn._profileName = name
        btn._isCur = isCur
        local displayName = name
        if name == "默认方案" then
            displayName = L["DEFAULT_PROFILE"] or name
        end
        btn._fs:SetText(displayName)
        local textWidth = btn._fs:GetStringWidth() or 40
        btn:SetWidth(textWidth + 16)
        btn:ClearAllPoints()
        btn:SetPoint("LEFT", bar, "LEFT", x, 0)
        x = x + (textWidth + 20)

        if isCur then
            btn._border:SetColorTexture(ar, ag, ab, 0.80)
            btn._bg:SetColorTexture(ar * 0.18 + 0.04, ag * 0.18 + 0.04, ab * 0.18 + 0.04, 0.90)
            btn._fs:SetTextColor(1, 1, 1, 1)
        else
            btn._border:SetColorTexture(1, 1, 1, 0.08)
            btn._bg:SetColorTexture(0.08, 0.09, 0.12, 0.70)
            btn._fs:SetTextColor(0.65, 0.70, 0.78, 1)
        end

        btn:Show()
    end

    -- 紧跟在方案胶囊末尾的“＋”添加新方案按钮
    if not bar._addBtn then
        local addBtn = ns.CreateFrostButton(bar, "＋", 22, 22, false, function()
            ns.CloseAllDropdowns()
            StaticPopup_Show("DUOUI_SAVE_ADDON_PROFILE")
        end)
        addBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L["SAVE_NEW_PROFILE"] or "另存为新方案", 1, 1, 1)
            GameTooltip:AddLine(L["SAVE_NEW_PROFILE_DESC"] or "以当前插件启用状态创建新预设", 0.65, 0.70, 0.80)
            GameTooltip:Show()
        end)
        addBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        bar._addBtn = addBtn
    end
    bar._addBtn:ClearAllPoints()
    bar._addBtn:SetPoint("LEFT", bar, "LEFT", x, 0)
    bar._addBtn:Show()
end

RebuildAddonWorkspace = function(forceMemory)
    if not uiContainer or not uiContainer.rootFrame then return end
    local parent = uiContainer.rootFrame
    local search = (searchQuery or ""):lower():trim()
    local db = ns.GetDB()
    local activeCat = db.selectedCategory or "全部插件"
    local ar, ag, ab = ns.GetThemeAccent()
    local hex = ns.GetThemeAccentHex()

    -- 检测当前方案是否在其他角色上被改动过，若有差异则自动对齐底层并激活重载提示
    local activeProfile = ns.GetActiveProfile()
    local profileUpdatedFromOther = false
    local diffCountNum = 0
    if activeProfile and ns.CheckProfileDiff then
        local hasDiff, diffCount = ns.CheckProfileDiff(activeProfile)
        if hasDiff then
            ns.AlignProfileToCharacter(activeProfile)
            DuoUI.hasAddonChange = true
            profileUpdatedFromOther = true
            diffCountNum = diffCount
        end
    end

    RefreshProfilesBar()

    -- 动态更新顶部指示器颜色
    if uiContainer.profLabel then
        uiContainer.profLabel:SetText(string.format("|cff8899aa%s|r", L["PROFILES_LABEL"] or "方案:"))
    end
    if uiContainer.searchIcon then
        if uiContainer.searchIcon.SetVertexColor then
            uiContainer.searchIcon:SetVertexColor(ar, ag, ab, 0.85)
        elseif uiContainer.searchIcon.SetTextColor then
            uiContainer.searchIcon:SetTextColor(ar, ag, ab, 0.75)
        end
    end

    local categories, allEntries, totalMemory, totalEnabled, totalCount, rawEnabled, rawTotal = ns.ScanAddonsData(forceMemory)

    if uiContainer.statusBadge then
        uiContainer.statusBadge:SetText(string.format("%s |cffffffff%d|r / %d", L["STATUS_ENABLED"] or "已启用", totalEnabled, totalCount))
        uiContainer.statusBadge:SetTextColor(0.65, 0.70, 0.78, 1)
    end
    if uiContainer.memBadge then
        uiContainer.memBadge:SetText(string.format("%s |cff%s%s|r", L["STATUS_TOTAL_MEM"] or "总内存", hex, ns.FormatMemory(totalMemory)))
        uiContainer.memBadge:SetTextColor(0.65, 0.70, 0.78, 1)
    end
    if uiContainer.statusBadgeFrame then
        uiContainer.statusBadgeFrame._totalEnabled = totalEnabled
        uiContainer.statusBadgeFrame._totalCount = totalCount
        uiContainer.statusBadgeFrame._rawTotal = rawTotal
        uiContainer.statusBadgeFrame._rawEnabled = rawEnabled
        uiContainer.statusBadgeFrame._totalMemory = totalMemory
    end

    local reloadBtn = (uiContainer and uiContainer.reloadBtn) or (managerWindow and managerWindow._reloadBtn)
    local themeBtn = (uiContainer and uiContainer.themeBtn) or (managerWindow and managerWindow._themeBtn)
    local tipFS = uiContainer and uiContainer.tipFS

    if reloadBtn then
        local rawActiveName = ns.GetActiveProfile() or "当前方案"
        local activeName = rawActiveName == "默认方案" and (L["DEFAULT_PROFILE"] or rawActiveName) or rawActiveName
        if DuoUI.hasAddonChange then
            reloadBtn:Show()
            reloadBtn:SetText(L["SAVE_AND_RELOAD"] or "保存并重载")
            local rw = (reloadBtn._fs and reloadBtn._fs:GetStringWidth() or 80) + 24
            reloadBtn:SetWidth(math.max(100, math.floor(rw)))
            reloadBtn:Enable()
            reloadBtn._inner:SetColorTexture(ar * 0.35 + 0.04, ag * 0.35 + 0.04, ab * 0.35 + 0.04, 0.90)
            reloadBtn._border:SetColorTexture(ar, ag, ab, 0.85)
            reloadBtn._fs:SetTextColor(1.0, 1.0, 1.0, 1)

            if tipFS then
                tipFS:ClearAllPoints()
                tipFS:SetPoint("RIGHT", reloadBtn, "LEFT", -14, 0)
                if profileUpdatedFromOther then
                    tipFS:SetText(string.format("|cffffcc00" .. (L["SYNCED_CHANGES"] or "已自动同步【%s】最新改动") .. "|r • " .. (L["RELOAD_NEEDED"] or "需重载生效"), activeName))
                else
                    tipFS:SetText(string.format("|cff55ff88" .. (L["AUTO_SAVED_TO"] or "已自动保存至【%s】") .. "|r • " .. (L["RELOAD_NEEDED"] or "需重载生效"), activeName))
                end
            end
        else
            reloadBtn:Hide()

            if tipFS then
                tipFS:ClearAllPoints()
                tipFS:SetPoint("RIGHT", uiContainer.bottomPanel or parent, "RIGHT", -14, 0)
                tipFS:SetText(string.format("|cff8899aa" .. (L["PROFILE_PREFIX"] or "方案【%s】") .. " " .. (L["STATUS_AUTO_SAVED"] or "实时自动保存") .. "|r   |cff445060•|r   |cff6b778c[|r|cffe2e8f0ESC|r|cff6b778c]|r |cff8899aa" .. (L["STATUS_ESC_CLOSE_TEXT"] or "关闭") .. "|r", activeName))
            end
        end
    end

    if themeBtn then
        local activeKey = db.themeKey or "gold"
        local t = ns.COLOR_THEMES[activeKey]
        local tr, tg, tb
        if t and t.isClass then tr, tg, tb = ns.GetClassColor() elseif t then tr, tg, tb = t.r, t.g, t.b else tr, tg, tb = 0.96, 0.65, 0.14 end
        if themeBtn._dot then themeBtn._dot:SetColorTexture(tr, tg, tb, 1.0) end
        if themeBtn._fs then themeBtn._fs:SetText(t and t.name or (L["THEME_GOLD"] or "暗金尊享")) end
    end

    -- 动态更新主窗口边框与标题色
    if managerWindow and managerWindow:IsShown() then
        if managerWindow._winBorder then
            managerWindow._winBorder:SetColorTexture(ar, ag, ab, 0.45)
        end
        if managerWindow._titleFS then
            managerWindow._titleFS:SetText(string.format("|cff%sDuo|r |cffffffff%s|r", hex, L["TITLE_SUFFIX"] or "插件管理"))
        end
        if managerWindow._thumbTex then
            managerWindow._thumbTex:SetColorTexture(ar, ag, ab, 0.45)
        end
    end

    -- 1. 左侧分类导航栏 (永久固定在侧边栏容器中，绝不随卡片列表滚动)
    for _, btn in ipairs(catNavButtons) do btn:Hide() end

    local navItems = {}
    navItems[1] = { name = "全部插件", count = #allEntries }
    for _, bucket in ipairs(categories) do
        navItems[#navItems + 1] = { name = bucket.name, count = #bucket.entries }
    end

    local isFixedSidebar = (uiContainer and uiContainer.sidebar) and true or false
    local navParent = isFixedSidebar and uiContainer.sidebar or parent

    local navY = -10
    local NAV_HEIGHT = 30

    for i, item in ipairs(navItems) do
        local btn = catNavButtons[i]
        if not btn then
            btn = CreateFrame("Button", nil, navParent)
            btn:SetHeight(NAV_HEIGHT)

            local border = btn:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints()
            border:SetColorTexture(0, 0, 0, 0)
            btn._border = border

            local bg = btn:CreateTexture(nil, "BORDER")
            bg:SetAllPoints()
            btn._bg = bg

            local indicator = btn:CreateTexture(nil, "ARTWORK")
            indicator:SetPoint("TOPLEFT", 0, 0)
            indicator:SetPoint("BOTTOMLEFT", 0, 0)
            indicator:SetWidth(3)
            btn._indicator = indicator

            local title = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            title:SetPoint("LEFT", btn, "LEFT", 10, 0)
            btn._title = title

            local countFS = btn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            countFS:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
            btn._count = countFS

            btn:SetScript("OnClick", CatButton_OnClick)
            btn:SetScript("OnEnter", CatButton_OnEnter)
            btn:SetScript("OnLeave", CatButton_OnLeave)

            catNavButtons[i] = btn
        end

        btn:SetParent(navParent)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", navParent, "TOPLEFT", 6, navY)
        btn:SetPoint("RIGHT", navParent, "RIGHT", -6, 0)
        navY = navY - NAV_HEIGHT - 3

        local isCur = (item.name == activeCat)
        btn._catName = item.name
        btn._title:SetText(ns.GetCategoryDisplayName(item.name))
        btn._count:SetText(item.count)
        btn._indicator:SetColorTexture(ar, ag, ab, 1)

        if isCur then
            btn._bg:SetColorTexture(ar, ag, ab, 0.14)
            btn._indicator:Show()
            btn._title:SetTextColor(1, 1, 1, 1)
            btn._count:SetTextColor(ar, ag, ab, 0.9)
        else
            btn._bg:SetColorTexture(0, 0, 0, 0)
            btn._indicator:Hide()
            btn._title:SetTextColor(0.70, 0.73, 0.78, 1)
            btn._count:SetTextColor(0.40, 0.44, 0.50, 1)
        end

        btn:Show()
    end

    if not isFixedSidebar then
        if not uiContainer.sidebarBg then
            local sbg = parent:CreateTexture(nil, "BACKGROUND")
            sbg:SetPoint("TOPLEFT", parent, "TOPLEFT", 6, -6)
            sbg:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 6, 10)
            sbg:SetWidth(130)
            sbg:SetColorTexture(0.04, 0.05, 0.07, 0.6)
            uiContainer.sidebarBg = sbg
        end

        if not uiContainer.sidebarDivider then
            local div = parent:CreateTexture(nil, "BACKGROUND")
            div:SetWidth(1)
            div:SetPoint("TOPLEFT", parent, "TOPLEFT", 136, -6)
            div:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 136, 10)
            div:SetColorTexture(1, 1, 1, 0.06)
            uiContainer.sidebarDivider = div
        end
    end

    -- 2. 筛选右侧插件列表
    local targetList = allEntries
    if activeCat ~= "全部插件" then
        for _, bucket in ipairs(categories) do
            if bucket.name == activeCat then
                targetList = bucket.entries
                break
            end
        end
    end

    local displayEntries = {}
    for _, entry in ipairs(targetList) do
        local hasChildren = (#entry.children > 0)
        local matchSelf = (search == "")
            or (entry.cleanTitle:lower():find(search, 1, true))
            or (entry.name:lower():find(search, 1, true))
            or (entry.notes:lower():find(search, 1, true))

        local matchChildren = false
        if hasChildren and search ~= "" then
            for _, child in ipairs(entry.children) do
                if (child.cleanTitle:lower():find(search, 1, true))
                    or (child.name:lower():find(search, 1, true))
                    or (child.notes:lower():find(search, 1, true)) then
                    matchChildren = true
                    break
                end
            end
        end

        if matchSelf or matchChildren then
            displayEntries[#displayEntries + 1] = entry
        end
    end

    -- 3. 渲染右侧双列瀑布流卡片 (顶级 UI/UX 规范：增大列间距与内边距，动态跟随主题色)
    for _, card in ipairs(cardPool) do card:Hide() end
    for _, drawer in ipairs(drawerPool) do drawer:Hide() end

    local TOTAL_WIDTH = (parent:GetWidth() and parent:GetWidth() > 50) and parent:GetWidth() or 800
    local RIGHT_START_X = isFixedSidebar and 6 or (10 + 125 + 14)
    local RIGHT_WIDTH = isFixedSidebar and (TOTAL_WIDTH - 12) or (TOTAL_WIDTH - 125 - 14)
    local CARD_COL_GAP = 12   -- 黄金列间距：彻底解决两列贴脸拥挤感
    local CARD_ROW_GAP = 8    -- 垂直行间距设为 8px，视觉层次分明
    local CARD_WIDTH = math.floor((RIGHT_WIDTH - CARD_COL_GAP) / 2)
    local CARD_HEIGHT = 38    -- 卡片高度 38px，提供充分垂直居中空间

    local rightStartY = -10
    local colY = { [0] = rightStartY, [1] = rightStartY }
    local cardIndex = 0
    local drawerIndex = 0

    local function AcquireCard()
        cardIndex = cardIndex + 1
        local card = cardPool[cardIndex]
        if not card then
            card = CreateFrame("Button", nil, parent)
            card:SetSize(CARD_WIDTH, CARD_HEIGHT)

            local border = card:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints()
            border:SetColorTexture(1, 1, 1, 0.05)
            card._border = border

            local bg = card:CreateTexture(nil, "BORDER")
            bg:SetPoint("TOPLEFT", 1, -1)
            bg:SetPoint("BOTTOMRIGHT", -1, 1)
            bg:SetColorTexture(0.06, 0.07, 0.09, 0.88)
            card._bg = bg

            local hl = card:CreateTexture(nil, "HIGHLIGHT")
            hl:SetPoint("TOPLEFT", 1, -1)
            hl:SetPoint("BOTTOMRIGHT", -1, 1)
            card._hl = hl

            -- 复选框
            local cb = ns.CreateModernCheckbox(card, 16)
            cb:SetPoint("LEFT", card, "LEFT", 10, 0)
            cb:SetFrameLevel(card:GetFrameLevel() + 5)
            cb._card = card
            cb:SetScript("OnClick", CardCheckbox_OnClick)
            card._cb = cb

            -- 固定图标槽位 (无论有无独立图标均占据固定宽度，保证文字严格垂直对齐)
            local iconContainer = CreateFrame("Frame", nil, card)
            iconContainer:SetSize(18, 18)
            iconContainer:SetPoint("LEFT", cb, "RIGHT", 8, 0)

            local iconBorder = iconContainer:CreateTexture(nil, "BACKGROUND")
            iconBorder:SetAllPoints()
            iconBorder:SetColorTexture(1, 1, 1, 0.08)
            card._iconBorder = iconBorder

            local iconTex = iconContainer:CreateTexture(nil, "ARTWORK")
            iconTex:SetPoint("TOPLEFT", 1, -1)
            iconTex:SetPoint("BOTTOMRIGHT", -1, 1)
            iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            card._iconContainer = iconContainer
            card._icon = iconTex

            local avatarFS = iconContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            avatarFS:SetPoint("CENTER", iconContainer, "CENTER", 0, 0)
            avatarFS:Hide()
            card._avatarFS = avatarFS

            -- 齿轮设置按钮 (悬停浮现)
            local gearBtn = CreateFrame("Button", nil, card)
            gearBtn:SetSize(22, 22)
            gearBtn:SetPoint("RIGHT", card, "RIGHT", -6, 0)
            gearBtn:SetFrameLevel(card:GetFrameLevel() + 5)

            local gearBg = gearBtn:CreateTexture(nil, "BACKGROUND")
            gearBg:SetAllPoints()
            gearBg:SetColorTexture(1, 1, 1, 0)
            gearBtn._bg = gearBg

            local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
            gearTex:SetSize(14, 14)
            gearTex:SetPoint("CENTER", 0, 0)
            gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
            gearTex:SetVertexColor(0.55, 0.60, 0.70, 0.55)
            gearBtn._tex = gearTex
            gearBtn._card = card
            gearBtn:SetScript("OnEnter", CardGear_OnEnter)
            gearBtn:SetScript("OnLeave", CardGear_OnLeave)
            gearBtn:SetScript("OnClick", CardGear_OnClick)
            card._gearBtn = gearBtn

            -- 内存占用显示
            local memFS = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            memFS:SetPoint("RIGHT", gearBtn, "LEFT", -6, 0)
            memFS:SetJustifyH("RIGHT")
            card._mem = memFS

            -- 微胶囊徽章 (子项展开 / 按需)
            local badgeBtn = CreateFrame("Button", nil, card)
            badgeBtn:SetSize(46, 18)
            badgeBtn:SetPoint("RIGHT", memFS, "LEFT", -6, 0)
            badgeBtn:SetFrameLevel(card:GetFrameLevel() + 5)

            local badgeBorder = badgeBtn:CreateTexture(nil, "BACKGROUND")
            badgeBorder:SetAllPoints()
            badgeBtn._border = badgeBorder

            local badgeBg = badgeBtn:CreateTexture(nil, "BORDER")
            badgeBg:SetPoint("TOPLEFT", 1, -1)
            badgeBg:SetPoint("BOTTOMRIGHT", -1, 1)
            badgeBtn._bg = badgeBg

            local badgeArrow = badgeBtn:CreateTexture(nil, "OVERLAY")
            badgeArrow:SetSize(8, 8)
            badgeArrow:SetPoint("RIGHT", badgeBtn, "RIGHT", -6, 0)
            badgeArrow:Hide()
            badgeBtn._arrow = badgeArrow

            local badgeFS = badgeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            badgeFS:SetPoint("CENTER", 0, 0)
            badgeBtn._fs = badgeFS
            badgeBtn._card = card
            badgeBtn:SetScript("OnEnter", CardBadge_OnEnter)
            badgeBtn:SetScript("OnLeave", CardBadge_OnLeave)
            badgeBtn:SetScript("OnClick", CardBadge_OnClick)
            card._badgeBtn = badgeBtn

            -- 插件主标题
            local titleFS = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            titleFS:SetPoint("LEFT", iconContainer, "RIGHT", 8, 0)
            titleFS:SetPoint("RIGHT", memFS, "LEFT", -8, 0)
            titleFS:SetJustifyH("LEFT")
            titleFS:SetWordWrap(false)
            card._title = titleFS

            local subFS = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            subFS:Hide()
            card._sub = subFS

            card:SetScript("OnClick", Card_OnClick)
            card:SetScript("OnEnter", Card_OnEnter)
            card:SetScript("OnLeave", Card_OnLeave)

            cardPool[cardIndex] = card
        end

        card:SetParent(parent)
        card:SetSize(CARD_WIDTH, CARD_HEIGHT)
        card._cb:SetFrameLevel(card:GetFrameLevel() + 5)
        card._gearBtn:SetFrameLevel(card:GetFrameLevel() + 5)
        card._badgeBtn:SetFrameLevel(card:GetFrameLevel() + 5)
        card._hl:SetColorTexture(ar, ag, ab, 0.04)
        return card
    end

    local function AcquireDrawer()
        drawerIndex = drawerIndex + 1
        local drawer = drawerPool[drawerIndex]
        if not drawer then
            drawer = CreateFrame("Frame", nil, parent)

            local border = drawer:CreateTexture(nil, "BACKGROUND")
            border:SetAllPoints()
            border:SetColorTexture(1, 1, 1, 0.08)
            drawer._border = border

            local bg = drawer:CreateTexture(nil, "BORDER")
            bg:SetPoint("TOPLEFT", 1, -1)
            bg:SetPoint("BOTTOMRIGHT", -1, 1)
            bg:SetColorTexture(0.04, 0.05, 0.07, 0.95)
            drawer._bg = bg

            local ind = drawer:CreateTexture(nil, "OVERLAY")
            ind:SetPoint("TOPLEFT", drawer, "TOPLEFT", 0, 0)
            ind:SetPoint("BOTTOMLEFT", drawer, "BOTTOMLEFT", 0, 0)
            ind:SetWidth(2.5)
            drawer._ind = ind

            drawer._rows = {}
            drawerPool[drawerIndex] = drawer
        end

        drawer:SetParent(parent)
        drawer._ind:SetColorTexture(ar, ag, ab, 0.5)
        drawer._border:SetColorTexture(ar, ag, ab, 0.15)
        return drawer
    end

    for i, entry in ipairs(displayEntries) do
        local hasChildren = (#entry.children > 0)
        local isDrawerOpen = (drawerExpanded[entry.name] == true)

        local targetCol = (colY[0] >= colY[1]) and 0 or 1
        local posX = RIGHT_START_X + targetCol * (CARD_WIDTH + CARD_COL_GAP)
        local posY = colY[targetCol]

        local card = AcquireCard()
        card._entry = entry
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)

        local hasValidIcon = false
        if entry.icon and type(entry.icon) == "string" and entry.icon ~= "" then
            local lowerIcon = entry.icon:lower()
            if not lowerIcon:find("interface\\icons\\temp") and not lowerIcon:find("black") then
                card._icon:SetTexture(entry.icon)
                if card._icon:GetTexture() then
                    hasValidIcon = true
                end
            end
        elseif entry.icon and type(entry.icon) == "number" and entry.icon > 0 then
            card._icon:SetTexture(entry.icon)
            if card._icon:GetTexture() then
                hasValidIcon = true
            end
        end

        if hasValidIcon then
            card._icon:Show()
            if card._avatarFS then card._avatarFS:Hide() end
            if entry.enabled or entry.isProtected then
                card._icon:SetVertexColor(1, 1, 1, 1)
                if card._iconBorder then card._iconBorder:SetColorTexture(1, 1, 1, 0.15) end
            else
                card._icon:SetVertexColor(0.55, 0.58, 0.65, 0.60)
                if card._iconBorder then card._iconBorder:SetColorTexture(1, 1, 1, 0.05) end
            end
        else
            local clean = (entry.cleanTitle or entry.title or entry.name):gsub("^%s+", "")
            local letter = clean:match("[%z\1-\127]") or clean:sub(1, 3)
            if letter and #letter == 1 then
                letter = letter:upper()
            end
            if letter and letter ~= "" then
                card._icon:Hide()
                if card._avatarFS then
                    card._avatarFS:SetText(letter)
                    if entry.enabled or entry.isProtected then
                        card._avatarFS:SetTextColor(ar, ag, ab, 1.0)
                        if card._iconBorder then card._iconBorder:SetColorTexture(ar, ag, ab, 0.35) end
                    else
                        card._avatarFS:SetTextColor(0.50, 0.55, 0.62, 0.70)
                        if card._iconBorder then card._iconBorder:SetColorTexture(1, 1, 1, 0.06) end
                    end
                    card._avatarFS:Show()
                end
            else
                if card._avatarFS then card._avatarFS:Hide() end
                card._icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
                card._icon:Show()
                if entry.enabled or entry.isProtected then
                    card._icon:SetVertexColor(0.75, 0.80, 0.90, 0.85)
                    if card._iconBorder then card._iconBorder:SetColorTexture(ar, ag, ab, 0.35) end
                else
                    card._icon:SetVertexColor(0.40, 0.44, 0.50, 0.50)
                    if card._iconBorder then card._iconBorder:SetColorTexture(1, 1, 1, 0.06) end
                end
            end
        end
        card._iconContainer:Show()

        local displayTitle = ns.HighlightSearch(entry.cleanTitle or entry.name, search)
        card._title:SetText(displayTitle)
        card._sub:Hide()

        local isCurrentActive = entry.enabled or entry.isProtected
        card._mem:SetText(ns.FormatMemory(entry.groupMem, isCurrentActive))

        card._gearBtn:EnableMouse(true)
        card._gearBtn:SetAlpha(0)
        card._gearBtn._tex:SetVertexColor(ar, ag, ab, 0.70)
        card._gearBtn._bg:SetColorTexture(1, 1, 1, 0)

        if entry.isProtected then
            card._cb:SetChecked(true)
            card._cb:Disable()
            card:SetAlpha(1.0)
            card._border:SetColorTexture(ar, ag, ab, 0.25)
            card._bg:SetColorTexture(0.07, 0.08, 0.11, 0.90)
            card._title:SetTextColor(0.96, 0.97, 1, 1)

            card._badgeBtn._bg:SetColorTexture(ar, ag, ab, 0.12)
            card._badgeBtn._border:SetColorTexture(ar, ag, ab, 0.35)
            card._badgeBtn._fs:SetText(string.format("|cff%s%s|r", hex, L["BADGE_CORE"] or "核心"))
            local textW = card._badgeBtn._fs:GetStringWidth() or 24
            card._badgeBtn:SetWidth(math.max(38, textW + 12))
            card._badgeBtn:Show()
        else
            card._cb:Enable()
            card._cb:SetChecked(entry.enabled)

            if entry.enabled then
                card:SetAlpha(1.0)
                card._border:SetColorTexture(ar, ag, ab, 0.20)
                card._bg:SetColorTexture(0.07, 0.08, 0.11, 0.88)
                card._title:SetTextColor(0.95, 0.97, 1.0, 1)
            else
                card:SetAlpha(0.85)
                card._border:SetColorTexture(1, 1, 1, 0.04)
                card._bg:SetColorTexture(0.04, 0.05, 0.07, 0.50)
                card._title:SetTextColor(0.60, 0.64, 0.70, 1)
            end

            if hasChildren then
                local numChildren = #entry.children
                if card._badgeBtn._arrow then card._badgeBtn._arrow:Hide() end

                card._badgeBtn._fs:ClearAllPoints()
                card._badgeBtn._fs:SetPoint("CENTER", 0, 0)

                if isDrawerOpen then
                    card._badgeBtn._bg:SetColorTexture(ar * 0.35, ag * 0.35, ab * 0.35, 0.95)
                    card._badgeBtn._border:SetColorTexture(ar, ag, ab, 0.90)
                    card._badgeBtn._fs:SetText(string.format("|cffffffff%s %d|r", L["BADGE_COLLAPSE"] or "收起", numChildren))
                else
                    if entry.enabled then
                        card._badgeBtn._bg:SetColorTexture(ar * 0.15, ag * 0.15, ab * 0.15, 0.80)
                        card._badgeBtn._border:SetColorTexture(ar, ag, ab, 0.40)
                        card._badgeBtn._fs:SetText(string.format("|cff%s%d %s|r", hex, numChildren, L["BADGE_ITEMS"] or "项"))
                    else
                        card._badgeBtn._bg:SetColorTexture(0.08, 0.09, 0.12, 0.60)
                        card._badgeBtn._border:SetColorTexture(1, 1, 1, 0.08)
                        card._badgeBtn._fs:SetText(string.format("|cff606875%d %s|r", numChildren, L["BADGE_ITEMS"] or "项"))
                    end
                end

                local textW = card._badgeBtn._fs:GetStringWidth() or 24
                local pillWidth = math.max(38, math.floor(textW + 12))
                card._badgeBtn:SetWidth(pillWidth)
                card._badgeBtn:Show()
            elseif entry.isLOD and not entry.isLoaded then
                if card._badgeBtn._arrow then card._badgeBtn._arrow:Hide() end
                card._badgeBtn._bg:SetColorTexture(0.20, 0.14, 0.04, 0.55)
                card._badgeBtn._border:SetColorTexture(0.85, 0.55, 0.15, 0.40)
                card._badgeBtn._fs:ClearAllPoints()
                card._badgeBtn._fs:SetPoint("CENTER", 0, 0)
                card._badgeBtn._fs:SetText(string.format("|cffffaa33%s|r", L["BADGE_LOD"] or "按需"))
                local textW = card._badgeBtn._fs:GetStringWidth() or 24
                card._badgeBtn:SetWidth(math.max(38, textW + 14))
                card._badgeBtn:Show()
            else
                card._badgeBtn:Hide()
                if card._badgeBtn._arrow then card._badgeBtn._arrow:Hide() end
            end
        end

        card._title:ClearAllPoints()
        card._title:SetPoint("LEFT", card._iconContainer, "RIGHT", 8, 0)
        if card._badgeBtn:IsShown() then
            card._title:SetPoint("RIGHT", card._badgeBtn, "LEFT", -7, 0)
        else
            card._title:SetPoint("RIGHT", card._mem, "LEFT", -8, 0)
        end

        if card:IsMouseOver() then
            card._bg:SetColorTexture(0.10, 0.12, 0.16, 0.92)
            card._border:SetColorTexture(ar, ag, ab, 0.45)
            if card._gearBtn then card._gearBtn:SetAlpha(0.60) end
        else
            if entry.enabled or entry.isProtected then
                card._border:SetColorTexture(ar, ag, ab, 0.22)
                card._bg:SetColorTexture(0.07, 0.08, 0.11, 0.85)
            else
                card._border:SetColorTexture(1, 1, 1, 0.03)
                card._bg:SetColorTexture(0.04, 0.05, 0.07, 0.45)
            end
            if card._gearBtn then card._gearBtn:SetAlpha(0) end
        end

        card:Show()

        local itemHeight = CARD_HEIGHT

        if hasChildren and isDrawerOpen then
            local drawer = AcquireDrawer()
            local rowH = 24
            local drawerH = #entry.children * rowH + 4
            drawer:ClearAllPoints()
            drawer:SetPoint("TOPLEFT", card, "BOTTOMLEFT", 0, -1)
            drawer:SetSize(CARD_WIDTH, drawerH)

            for _, r in ipairs(drawer._rows) do r:Hide() end

            for subIdx, child in ipairs(entry.children) do
                local subRow = drawer._rows[subIdx]
                if not subRow then
                    subRow = CreateFrame("Frame", nil, drawer)
                    subRow:SetSize(CARD_WIDTH - 8, rowH)

                    local subCb = ns.CreateModernCheckbox(subRow, 12)
                    subCb:SetPoint("LEFT", subRow, "LEFT", 10, 0)
                    subCb._subRow = subRow
                    subCb:SetScript("OnClick", SubRowCheckbox_OnClick)
                    subRow._cb = subCb

                    local subTitle = subRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    subTitle:SetPoint("LEFT", subCb, "RIGHT", 5, 0)
                    subTitle:SetPoint("RIGHT", subRow, "RIGHT", -55, 0)
                    subTitle:SetJustifyH("LEFT")
                    subTitle:SetWordWrap(false)
                    subRow._title = subTitle

                    local subMem = subRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                    subMem:SetPoint("RIGHT", subRow, "RIGHT", -8, 0)
                    subRow._mem = subMem

                    drawer._rows[subIdx] = subRow
                end

                subRow._child = child
                subRow:ClearAllPoints()
                subRow:SetPoint("TOPLEFT", drawer, "TOPLEFT", 4, -2 - (subIdx - 1) * rowH)

                subRow._cb:SetChecked(child.enabled)
                if child.enabled then
                    subRow._title:SetText("|cff" .. hex .. "•|r |cffd8e0ea" .. (child.cleanTitle or child.name) .. "|r")
                else
                    subRow._title:SetText("|cff4a5260•|r |cff5c6674" .. (child.cleanTitle or child.name) .. "|r")
                end
                subRow._mem:SetText(ns.FormatMemory(child.mem, child.enabled))
                subRow:Show()
            end

            drawer:Show()
            itemHeight = itemHeight + drawerH + 2
        end

        colY[targetCol] = colY[targetCol] - itemHeight - CARD_ROW_GAP
    end

    local rightHeight = math.abs(math.min(colY[0], colY[1])) + 36
    local totalHeight
    if isFixedSidebar then
        totalHeight = rightHeight
    else
        local leftHeight = math.abs(navY) + 40
        totalHeight = math.max(rightHeight, leftHeight)
    end
    parent:SetHeight(totalHeight)
    if managerWindow and managerWindow._updateScrollBar then
        managerWindow._updateScrollBar()
    end
    collectgarbage("step", 50)
    return totalHeight
end

ns.RebuildAddonWorkspace = RebuildAddonWorkspace
DuoUI.RefreshAddonManagerUI = RebuildAddonWorkspace

-- 工作区构建入口
function DuoUI.BuildAddonManagerPage(parent, yOffset)
    local EUI = _G.EllesmereUI
    if EUI and EUI.ClearContentHeader then EUI:ClearContentHeader() end

    uiContainer.rootFrame = parent
    local totalContentHeight = RebuildAddonWorkspace()
    return totalContentHeight
end

-- 独立浮动窗口 (960 x 650，一体化现代单顶栏)
local function EnsureAddonManagerWindow()
    if managerWindow then return managerWindow end

    local ar, ag, ab = ns.GetThemeAccent()
    local hex = ns.GetThemeAccentHex()

    local win = CreateFrame("Frame", "DuoAddonManagerWindow", UIParent)
    win:Hide()
    win:SetSize(960, 650)
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true)
    win:SetMovable(true)

    local winBorder = win:CreateTexture(nil, "BACKGROUND")
    winBorder:SetAllPoints()
    winBorder:SetColorTexture(ar, ag, ab, 0.4)
    win._winBorder = winBorder

    local winBg = win:CreateTexture(nil, "BORDER")
    winBg:SetPoint("TOPLEFT", 1, -1)
    winBg:SetPoint("BOTTOMRIGHT", -1, 1)
    winBg:SetColorTexture(0.06, 0.07, 0.09, 0.96)
    win._winBg = winBg

    -- 一体化顶级单顶栏 (40px)
    local titleBar = CreateFrame("Frame", nil, win)
    titleBar:SetHeight(40)
    titleBar:SetPoint("TOPLEFT", win, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", win, "TOPRIGHT", 0, 0)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() win:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() win:StopMovingOrSizing() end)

    local titleBarBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBarBg:SetAllPoints()
    titleBarBg:SetColorTexture(0.04, 0.05, 0.07, 0.95)

    local titleBarDiv = titleBar:CreateTexture(nil, "BORDER")
    titleBarDiv:SetHeight(1)
    titleBarDiv:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    titleBarDiv:SetPoint("BOTTOMRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
    titleBarDiv:SetColorTexture(1, 1, 1, 0.08)

    -- 1. 标题文字
    local titleFS = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    titleFS:SetPoint("LEFT", titleBar, "LEFT", 14, 0)
    titleFS:SetText(string.format("|cff%sDuo|r |cffffffff%s|r", hex, L["TITLE_SUFFIX"] or "插件管理"))
    win._titleFS = titleFS

    -- 2. 搜索框 (150px)
    local searchContainer = CreateFrame("Frame", nil, titleBar)
    searchContainer:SetSize(150, 24)
    searchContainer:SetPoint("LEFT", titleFS, "RIGHT", 14, 0)

    local searchBorder = searchContainer:CreateTexture(nil, "BACKGROUND")
    searchBorder:SetAllPoints()
    searchBorder:SetColorTexture(1, 1, 1, 0.08)

    local searchBg = searchContainer:CreateTexture(nil, "BORDER")
    searchBg:SetPoint("TOPLEFT", 1, -1)
    searchBg:SetPoint("BOTTOMRIGHT", -1, 1)
    searchBg:SetColorTexture(0.02, 0.03, 0.05, 0.8)

    local sTex = searchContainer:CreateTexture(nil, "ARTWORK")
    sTex:SetSize(13, 13)
    sTex:SetPoint("LEFT", searchContainer, "LEFT", 7, 0)
    sTex:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    sTex:SetVertexColor(ar, ag, ab, 0.85)

    local searchBox = CreateFrame("EditBox", nil, searchContainer)
    searchBox:SetPoint("TOPLEFT", searchContainer, "TOPLEFT", 24, 0)
    searchBox:SetPoint("BOTTOMRIGHT", searchContainer, "BOTTOMRIGHT", -24, 0)
    if _G.GameFontHighlightSmall then
        pcall(searchBox.SetFontObject, searchBox, _G.GameFontHighlightSmall)
    end
    searchBox:SetAutoFocus(false)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 0, 0)
    placeholder:SetText(L["SEARCH_PLACEHOLDER"] or "搜索插件...")

    local clearBtn = CreateFrame("Button", nil, searchContainer)
    clearBtn:SetSize(20, 20)
    clearBtn:SetPoint("RIGHT", searchContainer, "RIGHT", -2, 0)
    clearBtn:SetFrameLevel(searchBox:GetFrameLevel() + 10)
    clearBtn:RegisterForClicks("AnyUp", "AnyDown")
    clearBtn:Hide()

    local clearTex = clearBtn:CreateTexture(nil, "ARTWORK")
    clearTex:SetSize(14, 14)
    clearTex:SetPoint("CENTER", 0, 0)
    clearTex:SetTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearTex:SetAlpha(0.65)
    clearBtn._tex = clearTex

    local function ClearSearchText()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        searchBox:SetText("")
        searchBox:ClearFocus()
    end

    clearBtn:SetScript("OnEnter", function()
        clearTex:SetAlpha(1.0)
    end)
    clearBtn:SetScript("OnLeave", function()
        clearTex:SetAlpha(0.65)
    end)
    clearBtn:SetScript("OnClick", ClearSearchText)
    clearBtn:SetScript("OnMouseDown", ClearSearchText)

    searchBox:SetScript("OnEscapePressed", function(self)
        local t = self:GetText()
        if t and t ~= "" then
            ClearSearchText()
        else
            self:ClearFocus()
        end
    end)
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained", function()
        local ar, ag, ab = ns.GetThemeAccent()
        searchBorder:SetColorTexture(ar, ag, ab, 0.50)
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        searchBorder:SetColorTexture(1, 1, 1, 0.08)
    end)

    local searchDebounceTimer = nil
    searchBox:SetScript("OnTextChanged", function(self)
        local t = self:GetText()
        if t and t ~= "" then
            placeholder:Hide()
            clearBtn:Show()
        else
            placeholder:Show()
            clearBtn:Hide()
        end
        searchQuery = t or ""
        if searchDebounceTimer then
            searchDebounceTimer:Cancel()
            searchDebounceTimer = nil
        end
        if C_Timer and C_Timer.NewTimer then
            searchDebounceTimer = C_Timer.NewTimer(0.12, function()
                searchDebounceTimer = nil
                ns.ResetSessionSortOrder()
                if managerWindow and managerWindow._scrollFrame then
                    managerWindow._scrollFrame:SetVerticalScroll(0)
                end
                RebuildAddonWorkspace()
            end)
        else
            ns.ResetSessionSortOrder()
            if managerWindow and managerWindow._scrollFrame then
                managerWindow._scrollFrame:SetVerticalScroll(0)
            end
            RebuildAddonWorkspace()
        end
    end)

    -- 3. 批量管理按钮 (72px)
    local batchBtn = ns.CreateFrostButton(titleBar, L["BATCH_BTN"] or "批量管理", 72, 24, false, function(self)
        ns.ToggleBatchMenu(self)
    end)
    batchBtn:SetPoint("LEFT", searchContainer, "RIGHT", 8, 0)
    batchBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["BATCH_TOOLTIP_TITLE"] or "批量操作", 1, 1, 1)
        GameTooltip:AddLine(L["BATCH_TOOLTIP_DESC"] or "点击展开批量控制菜单：", 0.8, 0.85, 0.9)
        GameTooltip:AddLine(L["BATCH_TOOLTIP_ENABLE"] or "• 全部启用插件", 0.5, 0.9, 0.5)
        GameTooltip:AddLine(L["BATCH_TOOLTIP_DISABLE"] or "• 全部停用插件", 0.9, 0.5, 0.5)
        GameTooltip:AddLine(L["BATCH_TOOLTIP_MEM"] or "• 刷新内存占用", 0.6, 0.7, 0.9)
        GameTooltip:Show()
    end)
    batchBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- 4. 垂直微隔离线
    local div1 = titleBar:CreateTexture(nil, "OVERLAY")
    div1:SetSize(1, 14)
    div1:SetPoint("LEFT", batchBtn, "RIGHT", 10, 0)
    div1:SetColorTexture(1, 1, 1, 0.12)

    -- 5. 方案预设标签
    local profLabel = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profLabel:SetPoint("LEFT", div1, "RIGHT", 10, 0)
    profLabel:SetText(string.format("|cff8899aa%s|r", L["PROFILES_LABEL"] or "方案:"))

    -- 6. 右侧：关闭按钮 (对称边距 14px，优化击中区)
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(26, 26)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -14, 0)
    closeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 10)

    local closeBtnBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBtnBg:SetAllPoints()
    closeBtnBg:SetColorTexture(1, 1, 1, 0)
    closeBtn._bg = closeBtnBg

    local closeFS = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    closeFS:SetPoint("CENTER", 0, 0)
    closeFS:SetText("×")
    closeFS:SetTextColor(0.65, 0.70, 0.78, 0.85)
    closeBtn._fs = closeFS

    closeBtn:SetScript("OnEnter", function(self)
        self._bg:SetColorTexture(0.90, 0.22, 0.22, 0.35)
        self._fs:SetTextColor(1, 0.45, 0.45, 1)
    end)
    closeBtn:SetScript("OnLeave", function(self)
        self._bg:SetColorTexture(1, 1, 1, 0)
        self._fs:SetTextColor(0.65, 0.70, 0.78, 0.85)
    end)
    closeBtn:SetScript("OnClick", function()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        win:Hide()
    end)

    -- 7. 右侧：主题配色切换器 (24px 统一规格)
    local themeBtn = ns.CreateFrostButton(titleBar, L["THEME_GOLD"] or "暗金尊享", 82, 24, false, function(self)
        ns.ToggleThemeMenu(self)
    end)
    themeBtn:SetPoint("RIGHT", closeBtn, "LEFT", -14, 0)

    local themeDot = themeBtn:CreateTexture(nil, "ARTWORK")
    themeDot:SetSize(7, 7)
    themeDot:SetPoint("LEFT", themeBtn, "LEFT", 8, 0)
    themeDot:SetColorTexture(ar, ag, ab, 1.0)
    themeBtn._dot = themeDot

    if themeBtn._fs then
        themeBtn._fs:ClearAllPoints()
        themeBtn._fs:SetPoint("LEFT", themeDot, "RIGHT", 4, 0)
    end

    -- 8. 方案胶囊容器 (弹性自适应宽度，充分利用 profLabel 与 themeBtn 之间的空间)
    local pillsContainer = CreateFrame("Frame", nil, titleBar)
    pillsContainer:SetPoint("LEFT", profLabel, "RIGHT", 6, 0)
    pillsContainer:SetPoint("RIGHT", themeBtn, "LEFT", -14, 0)
    pillsContainer:SetHeight(24)

    themeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["THEME_MENU_TITLE"] or "界面配色方案", 1, 1, 1)
        local curKey = ns.GetDB().themeKey or "gold"
        local curTheme = ns.COLOR_THEMES[curKey]
        local tar, tag, tab = ns.GetThemeAccent()
        GameTooltip:AddLine((L["THEME_CURRENT"] or "当前配色: ") .. (curTheme and curTheme.name or (L["THEME_GOLD"] or "暗金尊享")), tar, tag, tab)
        GameTooltip:AddLine(L["THEME_DESC"] or "点击展开 4 款专业暗黑定制配色", 0.70, 0.75, 0.85)
        GameTooltip:Show()
    end)
    themeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    win._themeBtn = themeBtn

    -- 8. 现代化底部状态栏 (32px)
    local bottomBar = CreateFrame("Frame", nil, win)
    bottomBar:SetHeight(32)
    bottomBar:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", 0, 0)

    local bottomBarBg = bottomBar:CreateTexture(nil, "BACKGROUND")
    bottomBarBg:SetAllPoints()
    bottomBarBg:SetColorTexture(0.04, 0.05, 0.07, 0.95)

    local bottomBarDiv = bottomBar:CreateTexture(nil, "BORDER")
    bottomBarDiv:SetHeight(1)
    bottomBarDiv:SetPoint("TOPLEFT", bottomBar, "TOPLEFT", 0, 0)
    bottomBarDiv:SetPoint("TOPRIGHT", bottomBar, "TOPRIGHT", 0, 0)
    bottomBarDiv:SetColorTexture(1, 1, 1, 0.08)

    local statPill = CreateFrame("Frame", nil, bottomBar)
    statPill:SetSize(240, 22)
    statPill:SetPoint("LEFT", bottomBar, "LEFT", 14, 0)
    statPill:EnableMouse(true)
    statPill:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["TOOLTIP_STATUS_TITLE"] or "插件运行状态", 1, 1, 1)
        local te = self._totalEnabled or 0
        local tc = self._totalCount or 0
        GameTooltip:AddLine(string.format(L["TOOLTIP_MAIN_ADDONS"] or "主插件: %d / %d 已启用", te, tc), 0.4, 0.8, 1)
        local rt = self._rawTotal
        if rt and rt > tc then
            GameTooltip:AddLine(string.format(L["TOOLTIP_SUB_MODULES"] or "底层模块总数: %d 款 (已启用 %d 款)", rt, self._rawEnabled or te), 0.6, 0.65, 0.75)
        end
        GameTooltip:AddLine(string.format(L["TOOLTIP_MEM_USAGE"] or "占用总内存: %s", ns.FormatMemory(self._totalMemory or 0)), 0.5, 0.9, 0.5)
        GameTooltip:Show()
    end)
    statPill:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local statusBadge = statPill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusBadge:SetPoint("LEFT", statPill, "LEFT", 0, 0)
    statusBadge:SetTextColor(0.65, 0.70, 0.78, 1)

    local divLine = statPill:CreateTexture(nil, "OVERLAY")
    divLine:SetSize(1, 12)
    divLine:SetPoint("LEFT", statusBadge, "RIGHT", 8, 0)
    divLine:SetColorTexture(1, 1, 1, 0.15)

    local memBadge = statPill:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    memBadge:SetPoint("LEFT", divLine, "RIGHT", 8, 0)
    memBadge:SetTextColor(0.65, 0.70, 0.78, 1)

    local reloadBtn = ns.CreateFrostButton(bottomBar, L["SAVE_AND_RELOAD"] or "保存并重载", 100, 22, true, function()
        if ns.SyncActiveProfileState then
            ns.SyncActiveProfileState()
        end
        ns.SaveAddonConfig()
        ReloadUI()
    end)
    reloadBtn:SetPoint("RIGHT", bottomBar, "RIGHT", -14, 0)
    reloadBtn:Hide()
    win._reloadBtn = reloadBtn

    local tipFS = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    tipFS:SetPoint("RIGHT", reloadBtn, "LEFT", -14, 0)
    tipFS:SetText(L["CARD_TOGGLE_TIP"] or "点击插件卡片切换启用/停用")

    -- 左侧固定分类导航侧边栏 (绝对固定在主窗口左侧，不随右侧插件卡片滚动)
    local sidebar = CreateFrame("Frame", "DuoAddonManagerSidebar", win)
    sidebar:SetPoint("TOPLEFT", win, "TOPLEFT", 6, -42)
    sidebar:SetPoint("BOTTOMLEFT", win, "BOTTOMLEFT", 6, 34)
    sidebar:SetWidth(132)

    local sbg = sidebar:CreateTexture(nil, "BACKGROUND")
    sbg:SetAllPoints()
    sbg:SetColorTexture(0.04, 0.05, 0.07, 0.6)
    sidebar._bg = sbg

    local sdiv = sidebar:CreateTexture(nil, "BORDER")
    sdiv:SetWidth(1)
    sdiv:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", 0, 0)
    sdiv:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", 0, 0)
    sdiv:SetColorTexture(1, 1, 1, 0.08)
    sidebar._div = sdiv

    uiContainer.topPanel         = titleBar
    uiContainer.bottomPanel      = bottomBar
    uiContainer.sidebar          = sidebar
    uiContainer.profLabel        = profLabel
    uiContainer.searchIcon       = sTex
    uiContainer.statusBadge      = statusBadge
    uiContainer.statusBadgeFrame = statPill
    uiContainer.memBadge         = memBadge
    uiContainer.batchBtn         = batchBtn
    uiContainer.pillsContainer   = pillsContainer
    uiContainer.reloadBtn        = reloadBtn
    uiContainer.themeBtn         = themeBtn
    uiContainer.tipFS            = tipFS

    win:SetScript("OnMouseDown", function()
        ns.CloseAllDropdowns()
    end)
    win:HookScript("OnHide", function()
        ns.CloseAllDropdowns()
        ns.ResetSessionSortOrder()
        collectgarbage("collect")
    end)

    _G["DuoAddonManagerWindow"] = win
    _G["DuoUI_AddonManagerWindow"] = win
    tinsert(UISpecialFrames, "DuoAddonManagerWindow")
    tinsert(UISpecialFrames, "DuoUI_AddonManagerWindow")

    -- 内部右侧插件卡片滚动容器 (固定在左侧分类栏右侧，独立顺滑滚动)
    local scrollFrame = CreateFrame("ScrollFrame", "DuoAddonManagerScrollFrame", win)
    scrollFrame:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 8, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -12, 34)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetClipsChildren(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(800, 1)
    scrollFrame:SetScrollChild(scrollChild)

    sidebar:EnableMouseWheel(true)
    sidebar:SetScript("OnMouseWheel", function(self, delta)
        if scrollFrame:GetScript("OnMouseWheel") then
            scrollFrame:GetScript("OnMouseWheel")(scrollFrame, delta)
        end
    end)

    -- 极简细线滚动条
    local scrollTrack = CreateFrame("Frame", nil, scrollFrame)
    scrollTrack:SetWidth(4)
    scrollTrack:SetPoint("TOPRIGHT", win, "TOPRIGHT", -4, -42)
    scrollTrack:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -4, 36)
    scrollTrack:Hide()

    local trackBg = scrollTrack:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(1, 1, 1, 0.04)

    local scrollThumb = CreateFrame("Button", nil, scrollTrack)
    scrollThumb:SetWidth(4)
    scrollThumb:SetHeight(50)
    scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, 0)
    scrollThumb:EnableMouse(true)
    scrollThumb:RegisterForDrag("LeftButton")

    local thumbTex = scrollThumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(ar, ag, ab, 0.45)
    win._thumbTex = thumbTex

    local function UpdateScrollBar()
        local ch = scrollChild:GetHeight()
        local vh = scrollFrame:GetHeight()
        if ch <= vh or ch <= 0 or vh <= 0 then
            scrollTrack:Hide()
            return
        end
        scrollTrack:Show()
        local maxScroll = ch - vh
        local curScroll = scrollFrame:GetVerticalScroll()
        local trackH = scrollTrack:GetHeight()
        local thumbH = math.max(24, math.min(trackH, trackH * (vh / ch)))
        scrollThumb:SetHeight(thumbH)
        local ratio = (maxScroll > 0) and (curScroll / maxScroll) or 0
        local thumbY = -ratio * (trackH - thumbH)
        scrollThumb:ClearAllPoints()
        scrollThumb:SetPoint("TOP", scrollTrack, "TOP", 0, thumbY)
    end

    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        ns.CloseAllDropdowns()
        local ch = scrollChild:GetHeight()
        local vh = self:GetHeight()
        local maxScroll = math.max(0, ch - vh)
        local nextScroll = math.min(maxScroll, math.max(0, self:GetVerticalScroll() - delta * 36))
        self:SetVerticalScroll(nextScroll)
        UpdateScrollBar()
    end)

    scrollThumb:SetScript("OnDragStart", function(self)
        self.isDragging = true
        local _, startY = GetCursorPosition()
        local initialScroll = scrollFrame:GetVerticalScroll()
        self:SetScript("OnUpdate", function()
            if not self.isDragging then return end
            local _, curY = GetCursorPosition()
            local diff = (startY - curY) / self:GetEffectiveScale()
            local ch = scrollChild:GetHeight()
            local vh = scrollFrame:GetHeight()
            local trackH = scrollTrack:GetHeight()
            local thumbH = self:GetHeight()
            local availableTrack = trackH - thumbH
            if availableTrack > 0 then
                local scrollDelta = diff * ((ch - vh) / availableTrack)
                local maxScroll = math.max(0, ch - vh)
                scrollFrame:SetVerticalScroll(math.min(maxScroll, math.max(0, initialScroll + scrollDelta)))
                UpdateScrollBar()
            end
        end)
    end)

    scrollThumb:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
    end)

    win._scrollFrame = scrollFrame
    win._scrollChild = scrollChild
    win._updateScrollBar = UpdateScrollBar
    managerWindow = win
    ns.managerWindow = win

    DuoUI.BuildAddonManagerPage(scrollChild, -4)
    C_Timer.After(0.05, UpdateScrollBar)

    return win
end
ns.EnsureAddonManagerWindow = EnsureAddonManagerWindow

function DuoUI.ShowAddonManager()
    ns.ResetSessionSortOrder()
    local win = EnsureAddonManagerWindow()
    if not win:IsShown() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPEN)
        win:Show()
        if DuoUI.RefreshAddonManagerUI then
            DuoUI.RefreshAddonManagerUI()
        end
        if win._updateScrollBar then
            win._updateScrollBar()
        end
    end
end

function DuoUI.HideAddonManager()
    if managerWindow and managerWindow:IsShown() then
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
        managerWindow:Hide()
    end
end

function DuoUI.ToggleAddonManager()
    local win = EnsureAddonManagerWindow()
    if win:IsShown() then
        DuoUI.HideAddonManager()
    else
        if InCombatLockdown and InCombatLockdown() then
            DuoUI.Print(string.format("|cffff3030%s|r", L["COMBAT_WARNING"] or "战斗中无法打开插件管理面板！"))
            return
        end
        DuoUI.ShowAddonManager()
    end
end

_G.DuoAddonManager_ToggleAddonManager = DuoUI.ToggleAddonManager
_G.DuoUI_ToggleAddonManager = DuoUI.ToggleAddonManager
if _G.DuoAddonManager and type(_G.DuoAddonManager) == "table" then _G.DuoAddonManager.ToggleAddonManager = DuoUI.ToggleAddonManager end
if _G.DuoUI and type(_G.DuoUI) == "table" then _G.DuoUI.ToggleAddonManager = DuoUI.ToggleAddonManager end
if _G.DuoUIEUI and type(_G.DuoUIEUI) == "table" then _G.DuoUIEUI.ToggleAddonManager = DuoUI.ToggleAddonManager end
if _G.DuoUI_AddonManager and type(_G.DuoUI_AddonManager) == "table" then _G.DuoUI_AddonManager.ToggleAddonManager = DuoUI.ToggleAddonManager end

-- 暴雪系统设置面板集成
local function RegisterBlizzardOptions()
    local panel = CreateFrame("Frame")
    panel.name = L["BLIZZARD_OPTIONS_TITLE"] or "Duo 插件管理"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(string.format("|cff0091edDuo|r %s", L["TITLE_SUFFIX"] or "插件管理"))

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetText(L["BLIZZARD_OPTIONS_DESC"] or "点击下方按钮即可打开独立现代化插件管理面板。\n您也可以在任意聊天框输入 |cff00cfff/am|r 或 |cff00cfff/addons|r 直接呼出。")

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetSize(160, 32)
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    btn:SetText(L["OPEN_MANAGER"] or "打开插件管理器")
    btn:SetScript("OnClick", function()
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        elseif InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            InterfaceOptionsFrame:Hide()
        end
        DuoUI.ToggleAddonManager()
    end)

    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
ns.RegisterBlizzardOptions = RegisterBlizzardOptions

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    RegisterBlizzardOptions()
    self:UnregisterAllEvents()
end)

if IsLoggedIn and IsLoggedIn() then
    RegisterBlizzardOptions()
end
