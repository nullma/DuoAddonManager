-------------------------------------------------------------------------------
--  UI\Widgets.lua -- 现代扁平自绘微控件、浮层菜单与插件设置直达引擎
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = ns.DuoUI
local C_AddOns = ns.C_AddOns or _G.C_AddOns or {}
local L = ns.L or {}

-- 搜索关键词发光高亮 (动态主题色)
local function HighlightSearch(text, query)
    if not query or query == "" or not text then return text end
    local s, e = text:lower():find(query:lower(), 1, true)
    if s and e then
        local hex = ns.GetThemeAccentHex()
        local before = text:sub(1, s - 1)
        local match = text:sub(s, e)
        local after = text:sub(e + 1)
        return before .. "|cff" .. hex .. match .. "|r" .. after
    end
    return text
end
ns.HighlightSearch = HighlightSearch

-- 现代自绘扁平复选框
local function CreateModernCheckbox(parent, size)
    size = size or 16
    local cb = CreateFrame("Button", nil, parent)
    cb:SetSize(size, size)

    local border = cb:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    cb._border = border

    local inner = cb:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    inner:SetColorTexture(0.06, 0.08, 0.12, 0.95)
    cb._inner = inner

    local fill = cb:CreateTexture(nil, "ARTWORK", nil, 1)
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", -1, 1)
    cb._fill = fill

    -- 暴雪官方就绪对勾材质 (ReadyCheck-Ready)：高分辨率、自带圆润抗锯齿、纯白高对比
    local checkMark = cb:CreateTexture(nil, "OVERLAY")
    checkMark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkMark:SetDesaturated(true)
    checkMark:SetVertexColor(1, 1, 1, 1)
    local markSize = math.max(10, size - 2)
    checkMark:SetSize(markSize, markSize)
    checkMark:SetPoint("CENTER", 0, 0)
    cb._checkMark = checkMark

    local isChecked = false
    function cb:SetChecked(state)
        isChecked = state and true or false
        local ar, ag, ab = ns.GetThemeAccent()
        if isChecked then
            fill:SetColorTexture(ar * 0.22 + 0.04, ag * 0.22 + 0.04, ab * 0.22 + 0.04, 0.90)
            fill:Show()
            checkMark:SetVertexColor(1, 1, 1, 1)
            checkMark:Show()
            border:SetColorTexture(ar, ag, ab, 0.95)
        else
            fill:Hide()
            checkMark:Hide()
            border:SetColorTexture(0.22, 0.26, 0.33, 0.85)
            inner:SetColorTexture(0.06, 0.08, 0.12, 0.95)
        end
    end
    function cb:GetChecked() return isChecked end

    local origDisable = cb.Disable
    function cb:Disable()
        if origDisable then origDisable(self) end
        border:SetColorTexture(0.18, 0.20, 0.24, 0.6)
        fill:SetColorTexture(0.10, 0.12, 0.15, 0.7)
        checkMark:SetVertexColor(0.5, 0.5, 0.5, 0.6)
    end

    local origEnable = cb.Enable
    function cb:Enable()
        if origEnable then origEnable(self) end
        self:SetChecked(isChecked)
    end

    cb:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            local ar, ag, ab = ns.GetThemeAccent()
            if isChecked then
                border:SetColorTexture(math.min(1, ar * 1.25), math.min(1, ag * 1.25), math.min(1, ab * 1.25), 1.0)
                fill:SetColorTexture(ar * 0.32 + 0.05, ag * 0.32 + 0.05, ab * 0.32 + 0.05, 0.95)
            else
                border:SetColorTexture(ar, ag, ab, 0.75)
                inner:SetColorTexture(0.10, 0.12, 0.16, 0.95)
            end
        end
    end)
    cb:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            local ar, ag, ab = ns.GetThemeAccent()
            if isChecked then
                border:SetColorTexture(ar, ag, ab, 0.95)
                fill:SetColorTexture(ar * 0.22 + 0.04, ag * 0.22 + 0.04, ab * 0.22 + 0.04, 0.90)
            else
                border:SetColorTexture(0.22, 0.26, 0.33, 0.85)
                inner:SetColorTexture(0.06, 0.08, 0.12, 0.95)
            end
        end
    end)

    cb:SetChecked(false)
    return cb
end
ns.CreateModernCheckbox = CreateModernCheckbox

-- 现代自绘磨砂按钮
local function CreateFrostButton(parent, text, width, height, isAccent, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 80, height or 24)

    local ar, ag, ab = ns.GetThemeAccent()
    local border = btn:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints()
    if isAccent then
        border:SetColorTexture(ar, ag, ab, 0.85)
    else
        border:SetColorTexture(1, 1, 1, 0.08)
    end
    btn._border = border

    local inner = btn:CreateTexture(nil, "BORDER")
    inner:SetPoint("TOPLEFT", 1, -1)
    inner:SetPoint("BOTTOMRIGHT", -1, 1)
    if isAccent then
        inner:SetColorTexture(ar * 0.35 + 0.04, ag * 0.35 + 0.04, ab * 0.35 + 0.04, 0.90)
    else
        inner:SetColorTexture(0.12, 0.13, 0.16, 0.8)
    end
    btn._inner = inner

    local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText(text)
    fs:SetTextColor(isAccent and 1 or 0.85, isAccent and 1 or 0.88, isAccent and 1 or 0.92, 1)
    btn._fs = fs

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self)
        if self:IsEnabled() then
            local r, g, b = ns.GetThemeAccent()
            if isAccent then
                inner:SetColorTexture(r * 0.50 + 0.08, g * 0.50 + 0.08, b * 0.50 + 0.08, 0.98)
                border:SetColorTexture(math.min(1, r * 1.25), math.min(1, g * 1.25), math.min(1, b * 1.25), 1.0)
            else
                inner:SetColorTexture(0.16, 0.18, 0.22, 0.95)
                border:SetColorTexture(1, 1, 1, 0.16)
            end
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if self:IsEnabled() then
            local r, g, b = ns.GetThemeAccent()
            if isAccent then
                inner:SetColorTexture(r * 0.35 + 0.04, g * 0.35 + 0.04, b * 0.35 + 0.04, 0.90)
                border:SetColorTexture(r, g, b, 0.85)
            else
                inner:SetColorTexture(0.12, 0.13, 0.16, 0.8)
                border:SetColorTexture(1, 1, 1, 0.08)
            end
        end
    end)

    function btn:SetText(t) self._fs:SetText(t) end
    return btn
end
ns.CreateFrostButton = CreateFrostButton

-- 安全关闭管理器窗口
local function SafeCloseManager()
    local win = ns.managerWindow
    if win and win.Hide then
        pcall(win.Hide, win)
    end
    local EUI = _G.EllesmereUI
    if EUI and EUI.Close then
        pcall(EUI.Close, EUI)
    elseif EUI and EUI._mainFrame and EUI._mainFrame.Hide then
        pcall(EUI._mainFrame.Hide, EUI._mainFrame)
    end
end
ns.SafeCloseManager = SafeCloseManager

-- 插件设置直达引擎
local function OpenAddonConfig(addonName, addonTitle)
    if not addonName then return end
    local lower = addonName:lower()
    local title = addonTitle or addonName
    local hex = ns.GetThemeAccentHex()

    -- 0. 内部模块直达 (保留在 EllesmereUI 内部切换)
    if lower == "duoui" or lower == "duoui_eui" or lower:find("^duoui") then
        local EUI = _G.EllesmereUI
        if EUI and EUI.SelectModule then
            EUI:SelectModule("DuoUI_EUI")
            return
        end
    elseif lower == "ellesmereui" or lower:find("^ellesmere") then
        local EUI = _G.EllesmereUI
        if EUI and EUI.SelectModule then
            EUI:SelectModule("Profiles")
            return
        end
    end

    -- 1. 独立窗口 / 全局对象直达 (先关闭面板避免全屏遮挡)
    local opened = false

    if lower:find("weakauras") then
        SafeCloseManager()
        if _G.WeakAuras and _G.WeakAuras.OpenOptions then
            _G.WeakAuras.OpenOptions()
            opened = true
        elseif SlashCmdList["WEAKAURAS"] then
            SlashCmdList["WEAKAURAS"]("")
            opened = true
        end
    elseif lower:find("details") then
        SafeCloseManager()
        if _G.Details and _G.Details.OpenOptionsWindow then
            _G.Details:OpenOptionsWindow()
            opened = true
        elseif SlashCmdList["DETAILS"] then
            SlashCmdList["DETAILS"]("options")
            opened = true
        end
    elseif lower:find("auctionator") then
        SafeCloseManager()
        if _G.Auctionator and _G.Auctionator.Config and _G.Auctionator.Config.Show then
            _G.Auctionator.Config.Show()
            opened = true
        elseif SlashCmdList["AUCTIONATOR"] then
            SlashCmdList["AUCTIONATOR"]("")
            opened = true
        end
    elseif lower:find("gearinsight") then
        SafeCloseManager()
        if _G.GearInsight and _G.GearInsight.ToggleUI then
            _G.GearInsight:ToggleUI()
            opened = true
        elseif SlashCmdList["GEARINSIGHT"] then
            SlashCmdList["GEARINSIGHT"]("")
            opened = true
        elseif SlashCmdList["GI"] then
            SlashCmdList["GI"]("")
            opened = true
        end
    elseif lower:find("plater") then
        SafeCloseManager()
        if _G.Plater and _G.Plater.OpenOptionsInterface then
            _G.Plater.OpenOptionsInterface()
            opened = true
        elseif SlashCmdList["PLATER"] then
            SlashCmdList["PLATER"]("")
            opened = true
        end
    elseif lower:find("bugsack") then
        SafeCloseManager()
        if _G.BugSack and _G.BugSack.OpenSack then
            _G.BugSack:OpenSack()
            opened = true
        elseif SlashCmdList["BUGSACK"] then
            SlashCmdList["BUGSACK"]("")
            opened = true
        end
    elseif lower:find("cell") then
        SafeCloseManager()
        if _G.Cell and _G.Cell.OpenOptions then
            _G.Cell:OpenOptions()
            opened = true
        end
    elseif lower:find("methodraidtools") or lower:find("mrt") then
        SafeCloseManager()
        if _G.GMRT and _G.GMRT.Open then
            _G.GMRT:Open()
            opened = true
        elseif SlashCmdList["MRTSLASH"] then
            SlashCmdList["MRTSLASH"]("")
            opened = true
        end
    elseif lower:find("omnicd") then
        SafeCloseManager()
        if _G.OmniCD and _G.OmniCD[1] and _G.OmniCD[1].OpenConfig then
            _G.OmniCD[1]:OpenConfig()
            opened = true
        elseif SlashCmdList["OCD"] then
            SlashCmdList["OCD"]("")
            opened = true
        end
    elseif lower:find("bigwigs") then
        SafeCloseManager()
        if _G.BigWigs and _G.BigWigs.OpenConfig then
            _G.BigWigs:OpenConfig()
            opened = true
        elseif SlashCmdList["BIGWIGS"] then
            SlashCmdList["BIGWIGS"]("")
            opened = true
        end
    elseif lower:find("dbm") then
        SafeCloseManager()
        if _G.DBM and _G.DBM.LoadGUI then
            _G.DBM:LoadGUI()
            opened = true
        elseif SlashCmdList["DBM"] then
            SlashCmdList["DBM"]("")
            opened = true
        end
    elseif lower:find("handynotes") then
        SafeCloseManager()
        if SlashCmdList["HANDYNOTES"] then
            SlashCmdList["HANDYNOTES"]("")
            opened = true
        end
    elseif lower:find("blizzhudtweaks") then
        SafeCloseManager()
        if SlashCmdList["BHT"] then
            SlashCmdList["BHT"]("")
            opened = true
        elseif SlashCmdList["BLIZZHUDTWEAKS"] then
            SlashCmdList["BLIZZHUDTWEAKS"]("")
            opened = true
        end
    elseif lower:find("tullarange") then
        SafeCloseManager()
        if SlashCmdList["TULLARANGE"] then
            SlashCmdList["TULLARANGE"]("")
            opened = true
        elseif SlashCmdList["TRANGE"] then
            SlashCmdList["TRANGE"]("")
            opened = true
        end
    elseif lower:find("omnicc") then
        SafeCloseManager()
        if SlashCmdList["OMNICC"] then
            SlashCmdList["OMNICC"]("")
            opened = true
        end
    elseif lower:find("betterblizzframes") then
        SafeCloseManager()
        if SlashCmdList["BETTERBLIZZFRAMES"] then
            SlashCmdList["BETTERBLIZZFRAMES"]("")
            opened = true
        elseif SlashCmdList["BBF"] then
            SlashCmdList["BBF"]("")
            opened = true
        end
    elseif lower:find("editmodeexpanded") then
        SafeCloseManager()
        if SlashCmdList["EDITMODEEXPANDED"] then
            SlashCmdList["EDITMODEEXPANDED"]("")
            opened = true
        elseif SlashCmdList["EME"] then
            SlashCmdList["EME"]("")
            opened = true
        end
    elseif lower:find("actionbarprofiles") then
        SafeCloseManager()
        if SlashCmdList["ACTIONBARPROFILES"] then
            SlashCmdList["ACTIONBARPROFILES"]("")
            opened = true
        elseif SlashCmdList["ABP"] then
            SlashCmdList["ABP"]("")
            opened = true
        end
    elseif lower:find("plumber") then
        SafeCloseManager()
        if SlashCmdList["PLUMBER"] then
            SlashCmdList["PLUMBER"]("")
            opened = true
        end
    elseif lower:find("leatrix_plus") or lower:find("leatrixplus") then
        SafeCloseManager()
        if SlashCmdList["LEATRIX_PLUS"] then
            SlashCmdList["LEATRIX_PLUS"]("")
            opened = true
        elseif SlashCmdList["LP"] then
            SlashCmdList["LP"]("")
            opened = true
        end
    elseif lower:find("baganator") then
        SafeCloseManager()
        if SlashCmdList["BAGANATOR"] then
            SlashCmdList["BAGANATOR"]("")
            opened = true
        end
    elseif lower:find("ndui") then
        SafeCloseManager()
        if SlashCmdList["NDUI"] then
            SlashCmdList["NDUI"]("")
            opened = true
        end
    elseif lower:find("elvui") then
        SafeCloseManager()
        if _G.ElvUI and _G.ElvUI[1] and _G.ElvUI[1].ToggleOptionsUI then
            _G.ElvUI[1]:ToggleOptionsUI()
            opened = true
        elseif SlashCmdList["ELVUI"] then
            SlashCmdList["ELVUI"]("")
            opened = true
        end
    end

    -- 2. AceConfigDialog-3.0 选项注册直接呼出 (覆盖主流 Ace3 插件)
    if not opened and _G.LibStub then
        local ACD = _G.LibStub("AceConfigDialog-3.0", true)
        local ACR = _G.LibStub("AceConfigRegistry-3.0", true)
        if ACD and ACR then
            local candidates = { addonName, lower, title, (title:gsub("%s+", "")), (addonName:gsub("%s+", "")) }
            for _, c in ipairs(candidates) do
                if ACR:GetOptionsTable(c) then
                    SafeCloseManager()
                    ACD:Open(c)
                    opened = true
                    break
                end
            end
        end
    end

    -- 3. 现代 10.0+ 暴雪 Settings API (动态遍历全部分类列表与直达)
    if not opened and Settings and Settings.OpenToCategory then
        local targetCat = nil
        local catList = nil
        if Settings.GetAllCategories then
            local ok, res = pcall(Settings.GetAllCategories)
            if ok and type(res) == "table" then catList = res end
        elseif SettingsPanel and SettingsPanel.GetAllCategories then
            local ok, res = pcall(SettingsPanel.GetAllCategories, SettingsPanel)
            if ok and type(res) == "table" then catList = res end
        end

        if catList then
            for _, cat in ipairs(catList) do
                local cName = (cat.GetName and cat:GetName()) or cat.name or ""
                local cl = cName:lower()
                if cl == lower or cl == title:lower() or cl:find(lower, 1, true) or (lower:find(cl, 1, true) and #cl >= 4) then
                    targetCat = (cat.GetID and cat:GetID()) or cat
                    break
                end
            end
        end

        if targetCat then
            SafeCloseManager()
            local ok = pcall(Settings.OpenToCategory, targetCat)
            if ok and SettingsPanel and SettingsPanel:IsShown() then
                opened = true
            end
        end

        if not opened then
            SafeCloseManager()
            local ok = pcall(Settings.OpenToCategory, title)
            if not ok then ok = pcall(Settings.OpenToCategory, addonName) end
            if ok and SettingsPanel and SettingsPanel:IsShown() then
                opened = true
            end
        end
    end

    -- 4. 旧版 InterfaceOptionsFrame_OpenToCategory
    if not opened and InterfaceOptionsFrame_OpenToCategory then
        SafeCloseManager()
        local ok = pcall(InterfaceOptionsFrame_OpenToCategory, title)
        if not ok then ok = pcall(InterfaceOptionsFrame_OpenToCategory, addonName) end
        if ok and InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
            opened = true
        end
    end

    -- 5. 常见斜杠命令与大写驼峰缩写智能试探 (如 BlizzHUDTweaks -> BHT, BetterBlizzFrames -> BBF)
    if not opened then
        local acronym = addonName:gsub("[^A-Z0-9]", "")
        local slashKeys = {
            addonName:upper(),
            lower,
            addonName,
            acronym,
            acronym:lower(),
        }
        for _, sk in ipairs(slashKeys) do
            if sk ~= "" and SlashCmdList[sk] then
                SafeCloseManager()
                local ok = pcall(SlashCmdList[sk], "")
                if ok then
                    opened = true
                    break
                end
            end
        end
    end

    local tag = L["TITLE_SUFFIX"] or "插件管理"
    if opened then
        DuoUI.Print(string.format("|cff%s[%s]|r " .. (L["CONFIG_OPENED"] or "已打开 【%s】 的设置面板。"), hex, tag, title))
        return
    end

    DuoUI.Print(string.format("|cff%s[%s]|r " .. (L["CONFIG_NOT_FOUND"] or "未检测到 【%s】 的图形设置面板，该插件可能无独立设置或需通过其特定命令配置。"), hex, tag, title))
end
ns.OpenAddonConfig = OpenAddonConfig

-- 全局浮层下拉菜单管理器
local activeDropdown = nil
local function CloseAllDropdowns()
    if activeDropdown then
        activeDropdown:Hide()
        activeDropdown = nil
    end
end
ns.CloseAllDropdowns = CloseAllDropdowns

-- 批量操作浮层菜单
local batchMenu = nil
local function GetBatchMenu()
    if not batchMenu then
        local m = CreateFrame("Frame", "DuoUI_BatchMenu", UIParent)
        m:SetFrameStrata("TOOLTIP")
        m:SetClampedToScreen(true)
        m:SetSize(116, 80)

        local border = m:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        m._border = border

        local bg = m:CreateTexture(nil, "BORDER")
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(0.06, 0.08, 0.11, 0.98)

        local items = {
            { text = L["BATCH_ENABLE_ALL"] or "全部启用", onClick = function()
                local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
                local pName = UnitName("player")
                if C_AddOns and C_AddOns.EnableAllAddOns then
                    if pName then pcall(C_AddOns.EnableAllAddOns, pName) end
                elseif EnableAllAddOns then
                    if pName then pcall(EnableAllAddOns, pName) end
                end
                for i = 1, num do
                    ns.SetAddonState(i, true)
                    local name = C_AddOns.GetAddOnInfo(i)
                    if name then ns.SetAddonState(name, true) end
                end
                if ns.EnsureCoreAddonsEnabled then ns.EnsureCoreAddonsEnabled() end
                ns.SaveAddonConfig()
                if ns.SyncActiveProfileState then ns.SyncActiveProfileState() end
                DuoUI.hasAddonChange = true
                ns.ResetSessionSortOrder()
                if ns.RebuildAddonWorkspace then ns.RebuildAddonWorkspace() end
            end },
            { text = L["BATCH_DISABLE_ALL"] or "全部停用", onClick = function()
                local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
                local pName = UnitName("player")
                if C_AddOns and C_AddOns.DisableAllAddOns then
                    if pName then pcall(C_AddOns.DisableAllAddOns, pName) end
                elseif DisableAllAddOns then
                    if pName then pcall(DisableAllAddOns, pName) end
                end
                for i = 1, num do
                    local name = C_AddOns.GetAddOnInfo(i)
                    if not ns.IsProtected(name) then
                        ns.SetAddonState(i, false)
                        if name then ns.SetAddonState(name, false) end
                    end
                end
                for k in pairs(ns.CORE_PROTECTED) do
                    ns.SetAddonState(k, true)
                end
                if ns.EnsureCoreAddonsEnabled then ns.EnsureCoreAddonsEnabled() end
                ns.SaveAddonConfig()
                if ns.SyncActiveProfileState then ns.SyncActiveProfileState() end
                DuoUI.hasAddonChange = true
                ns.ResetSessionSortOrder()
                if ns.RebuildAddonWorkspace then ns.RebuildAddonWorkspace() end
            end },
            { text = L["BATCH_REFRESH_MEM"] or "刷新内存", onClick = function()
                ns.ResetSessionSortOrder()
                if ns.RebuildAddonWorkspace then ns.RebuildAddonWorkspace(true) end
            end },
        }

        for idx, item in ipairs(items) do
            local b = CreateFrame("Button", nil, m)
            b:SetSize(112, 24)
            b:SetPoint("TOPLEFT", m, "TOPLEFT", 2, -2 - (idx - 1) * 25)

            local bBg = b:CreateTexture(nil, "BACKGROUND")
            bBg:SetAllPoints()
            bBg:SetColorTexture(1, 1, 1, 0)
            b._bg = bBg

            local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", b, "LEFT", 10, 0)
            fs:SetText(item.text)
            fs:SetTextColor(0.80, 0.85, 0.92, 1)
            b._fs = fs

            b:SetScript("OnEnter", function(self)
                local ar, ag, ab = ns.GetThemeAccent()
                self._bg:SetColorTexture(ar * 0.25, ag * 0.25, ab * 0.25, 0.85)
                self._fs:SetTextColor(1, 1, 1, 1)
            end)
            b:SetScript("OnLeave", function(self)
                self._bg:SetColorTexture(1, 1, 1, 0)
                self._fs:SetTextColor(0.80, 0.85, 0.92, 1)
            end)
            b:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                CloseAllDropdowns()
                item.onClick()
            end)
        end

        batchMenu = m
    end

    local ar, ag, ab = ns.GetThemeAccent()
    batchMenu._border:SetColorTexture(ar, ag, ab, 0.65)
    return batchMenu
end

local function ToggleBatchMenu(anchor)
    local m = GetBatchMenu()
    if activeDropdown == m and m:IsShown() then
        CloseAllDropdowns()
    else
        CloseAllDropdowns()
        m:ClearAllPoints()
        m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
        m:Show()
        activeDropdown = m
    end
end
ns.ToggleBatchMenu = ToggleBatchMenu

-- 主题配色浮层菜单
local themeMenu = nil
local function GetThemeMenu()
    if not themeMenu then
        local m = CreateFrame("Frame", "DuoUI_ThemeMenu", UIParent)
        m:SetFrameStrata("TOOLTIP")
        m:SetClampedToScreen(true)
        m:SetSize(116, 106)

        local border = m:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        m._border = border

        local bg = m:CreateTexture(nil, "BORDER")
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(0.06, 0.08, 0.11, 0.98)

        m._buttons = {}
        for idx, key in ipairs(ns.THEME_ORDER) do
            local t = ns.COLOR_THEMES[key]
            local b = CreateFrame("Button", nil, m)
            b:SetSize(112, 24)
            b:SetPoint("TOPLEFT", m, "TOPLEFT", 2, -2 - (idx - 1) * 25)

            local bBg = b:CreateTexture(nil, "BACKGROUND")
            bBg:SetAllPoints()
            bBg:SetColorTexture(1, 1, 1, 0)
            b._bg = bBg

            local dot = b:CreateTexture(nil, "ARTWORK")
            dot:SetSize(8, 8)
            dot:SetPoint("LEFT", b, "LEFT", 8, 0)
            b._dot = dot

            local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            fs:SetText(t.name)
            fs:SetTextColor(0.80, 0.85, 0.92, 1)
            b._fs = fs

            b:SetScript("OnEnter", function(self)
                local ar, ag, ab = ns.GetThemeAccent()
                self._bg:SetColorTexture(ar * 0.25, ag * 0.25, ab * 0.25, 0.85)
                self._fs:SetTextColor(1, 1, 1, 1)
            end)
            b:SetScript("OnLeave", function(self)
                local currentKey = ns.GetDB().themeKey or "gold"
                if key ~= currentKey then
                    self._bg:SetColorTexture(1, 1, 1, 0)
                    self._fs:SetTextColor(0.80, 0.85, 0.92, 1)
                else
                    local ar, ag, ab = ns.GetThemeAccent()
                    self._bg:SetColorTexture(ar * 0.15, ag * 0.15, ab * 0.15, 0.70)
                    self._fs:SetTextColor(ar, ag, ab, 1)
                end
            end)
            b:SetScript("OnClick", function()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                CloseAllDropdowns()
                local cdb = ns.GetDB()
                cdb.themeKey = key
                if ns.RebuildAddonWorkspace then ns.RebuildAddonWorkspace() end
                local curHex = ns.GetThemeAccentHex()
                DuoUI.Print(string.format("已切换主题配色为：|cff%s【%s】|r", curHex, t.name))
            end)

            m._buttons[key] = b
        end

        themeMenu = m
    end

    local ar, ag, ab = ns.GetThemeAccent()
    themeMenu._border:SetColorTexture(ar, ag, ab, 0.65)
    local currentKey = ns.GetDB().themeKey or "gold"
    for key, b in pairs(themeMenu._buttons) do
        local t = ns.COLOR_THEMES[key]
        local tr, tg, tb
        if t.isClass then tr, tg, tb = ns.GetClassColor() else tr, tg, tb = t.r, t.g, t.b end
        b._dot:SetColorTexture(tr, tg, tb, 1.0)
        if key == currentKey then
            b._bg:SetColorTexture(ar * 0.15, ag * 0.15, ab * 0.15, 0.70)
            b._fs:SetTextColor(ar, ag, ab, 1)
        else
            b._bg:SetColorTexture(1, 1, 1, 0)
            b._fs:SetTextColor(0.80, 0.85, 0.92, 1)
        end
    end
    return themeMenu
end

local function ToggleThemeMenu(anchor)
    local m = GetThemeMenu()
    if activeDropdown == m and m:IsShown() then
        CloseAllDropdowns()
    else
        CloseAllDropdowns()
        m:ClearAllPoints()
        m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -4)
        m:Show()
        activeDropdown = m
    end
end
ns.ToggleThemeMenu = ToggleThemeMenu

-- 方案右键管理菜单
local targetProfileForMenu = nil
local profileMenu = nil
local function GetProfileMenu(profileName)
    targetProfileForMenu = profileName
    if not profileMenu then
        local m = CreateFrame("Frame", "DuoUI_ProfileMenu", UIParent)
        m:SetFrameStrata("TOOLTIP")
        m:SetClampedToScreen(true)
        m:SetSize(120, 56)

        local border = m:CreateTexture(nil, "BACKGROUND")
        border:SetAllPoints()
        m._border = border

        local bg = m:CreateTexture(nil, "BORDER")
        bg:SetPoint("TOPLEFT", 1, -1)
        bg:SetPoint("BOTTOMRIGHT", -1, 1)
        bg:SetColorTexture(0.06, 0.08, 0.11, 0.98)

        -- 1. 覆盖保存当前
        local b1 = CreateFrame("Button", nil, m)
        b1:SetSize(116, 24)
        b1:SetPoint("TOPLEFT", m, "TOPLEFT", 2, -2)
        local b1Bg = b1:CreateTexture(nil, "BACKGROUND")
        b1Bg:SetAllPoints()
        b1Bg:SetColorTexture(1, 1, 1, 0)
        b1._bg = b1Bg
        local b1FS = b1:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b1FS:SetPoint("LEFT", b1, "LEFT", 8, 0)
        b1FS:SetText("覆盖保存当前")
        b1FS:SetTextColor(0.80, 0.85, 0.92, 1)
        b1._fs = b1FS
        b1:SetScript("OnEnter", function(self)
            local ar, ag, ab = ns.GetThemeAccent()
            self._bg:SetColorTexture(ar * 0.25, ag * 0.25, ab * 0.25, 0.85)
            self._fs:SetTextColor(1, 1, 1, 1)
        end)
        b1:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(1, 1, 1, 0)
            self._fs:SetTextColor(0.80, 0.85, 0.92, 1)
        end)
        b1:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            CloseAllDropdowns()
            if targetProfileForMenu then
                DuoUI.SaveAddonProfile(targetProfileForMenu)
            end
        end)

        -- 2. 删除该方案
        local b2 = CreateFrame("Button", nil, m)
        b2:SetSize(116, 24)
        b2:SetPoint("TOPLEFT", m, "TOPLEFT", 2, -27)
        local b2Bg = b2:CreateTexture(nil, "BACKGROUND")
        b2Bg:SetAllPoints()
        b2Bg:SetColorTexture(1, 1, 1, 0)
        b2._bg = b2Bg
        local b2FS = b2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        b2FS:SetPoint("LEFT", b2, "LEFT", 8, 0)
        b2FS:SetText("删除此方案")
        b2FS:SetTextColor(0.95, 0.35, 0.35, 1)
        b2._fs = b2FS
        b2:SetScript("OnEnter", function(self)
            if targetProfileForMenu ~= "默认方案" then
                self._bg:SetColorTexture(0.50, 0.15, 0.15, 0.85)
                self._fs:SetTextColor(1, 1, 1, 1)
            end
        end)
        b2:SetScript("OnLeave", function(self)
            self._bg:SetColorTexture(1, 1, 1, 0)
            if targetProfileForMenu ~= "默认方案" then
                self._fs:SetTextColor(0.95, 0.35, 0.35, 1)
            else
                self._fs:SetTextColor(0.40, 0.44, 0.50, 1)
            end
        end)
        b2:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            CloseAllDropdowns()
            if targetProfileForMenu and targetProfileForMenu ~= "默认方案" then
                DuoUI.DeleteAddonProfile(targetProfileForMenu)
            else
                DuoUI.Print("|cffff6060不能删除默认保护方案！|r")
            end
        end)
        m._delBtn = b2

        profileMenu = m
    end

    local ar, ag, ab = ns.GetThemeAccent()
    profileMenu._border:SetColorTexture(ar, ag, ab, 0.65)
    if profileName == "默认方案" then
        profileMenu._delBtn:Disable()
        profileMenu._delBtn._fs:SetText("|cff556070不可删除默认|r")
    else
        profileMenu._delBtn:Enable()
        profileMenu._delBtn._fs:SetText("|cffff6060删除此方案|r")
    end
    return profileMenu
end

local function ToggleProfileMenu(anchor, profileName)
    local m = GetProfileMenu(profileName)
    if activeDropdown == m and m:IsShown() then
        CloseAllDropdowns()
    else
        CloseAllDropdowns()
        m:ClearAllPoints()
        m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
        m:Show()
        activeDropdown = m
    end
end
ns.ToggleProfileMenu = ToggleProfileMenu
