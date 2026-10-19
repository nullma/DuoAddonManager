-------------------------------------------------------------------------------
--  Core\Database.lua -- 数据持久化、预设方案管理与角色独立存储
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = ns.DuoUI
local C_AddOns = ns.C_AddOns or _G.C_AddOns or {}

-- 获取插件数据库根表
local function GetDB()
    local root = nil
    if type(_G.DuoDB) == "table" then
        root = _G.DuoDB
    elseif DuoUI.SettingsRoot then
        local ok, r = pcall(DuoUI.SettingsRoot)
        if ok and type(r) == "table" then root = r end
    end
    if not root then
        if type(_G.DuoAddonManagerDB) == "table" then
            root = _G.DuoAddonManagerDB
        elseif type(_G.DuoUI_AddonManagerDB) == "table" then
            root = _G.DuoUI_AddonManagerDB
            _G.DuoAddonManagerDB = _G.DuoUI_AddonManagerDB
        else
            _G.DuoAddonManagerDB = {}
            root = _G.DuoAddonManagerDB
        end
    end
    if type(root.addonManager) ~= "table" then root.addonManager = {} end
    local db = root.addonManager
    if type(db.profiles) ~= "table" then db.profiles = {} end
    if type(db.charProfiles) ~= "table" then db.charProfiles = {} end
    if not db.activeProfile then db.activeProfile = "默认方案" end
    if not db.selectedCategory then db.selectedCategory = "全部插件" end
    if not db.scopeMode then db.scopeMode = "char" end
    if not db.themeKey or not (ns.COLOR_THEMES and ns.COLOR_THEMES[db.themeKey]) then
        db.themeKey = "gold"
    end
    return db
end
ns.GetDB = GetDB

-- 获取当前激活方案 (优先读取本角色独立绑定的方案)
local function GetActiveProfile()
    local db = GetDB()
    local charKey = ns.GetPlayerCharacterKey()
    if db.charProfiles and db.charProfiles[charKey] and db.profiles[db.charProfiles[charKey]] then
        return db.charProfiles[charKey]
    end
    if db.activeProfile and db.profiles[db.activeProfile] then
        return db.activeProfile
    end
    local first = next(db.profiles)
    return first or "默认方案"
end
ns.GetActiveProfile = GetActiveProfile

-- 设置当前激活方案 (记录到角色独立键中，彻底杜绝换角色串方案)
local function SetActiveProfile(profileName)
    local db = GetDB()
    local charKey = ns.GetPlayerCharacterKey()
    if type(db.charProfiles) ~= "table" then db.charProfiles = {} end
    db.charProfiles[charKey] = profileName
    db.activeProfile = profileName
end
ns.SetActiveProfile = SetActiveProfile

-- 抓取当前所有插件的实时启用/停用状态快照
local function CaptureCurrentState()
    local state = {}
    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    for i = 1, num do
        local name = C_AddOns.GetAddOnInfo(i)
        if name then
            if ns.IsProtected(name) then
                state[name] = true
            else
                state[name] = ns.IsAddonEnabled(i)
            end
        end
    end
    return state
end
ns.CaptureCurrentState = CaptureCurrentState

-- 自动同步当前激活方案的实时状态 (彻底杜绝忘记保存覆盖问题)
local function SyncActiveProfileState()
    local active = GetActiveProfile()
    local db = GetDB()
    if active and db.profiles then
        db.profiles[active] = CaptureCurrentState()
    end
end
ns.SyncActiveProfileState = SyncActiveProfileState
DuoUI.SyncActiveProfileState = SyncActiveProfileState

-- 检测指定方案与当前角色实际启用的插件是否有差异 (如其他角色改动了共享方案)
local function CheckProfileDiff(profileName)
    local db = GetDB()
    local target = db.profiles and db.profiles[profileName]
    if not target then return false, 0 end

    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    local diffCount = 0

    for i = 1, num do
        local name = C_AddOns.GetAddOnInfo(i)
        if name and not ns.IsProtected(name) then
            local currentEnabled = ns.IsAddonEnabled(i)
            local shouldEnable = target[name]
            if shouldEnable == nil then
                shouldEnable = target[name:lower()]
            end
            if shouldEnable ~= nil and shouldEnable ~= currentEnabled then
                diffCount = diffCount + 1
            end
        end
    end
    return (diffCount > 0), diffCount
end
ns.CheckProfileDiff = CheckProfileDiff
DuoUI.CheckProfileDiff = CheckProfileDiff

-- 静默将指定方案对齐至当前角色底层 (用于跨角色自动同步最新改动)
local function AlignProfileToCharacter(profileName)
    local db = GetDB()
    local target = db.profiles and db.profiles[profileName]
    if not target then return 0 end

    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    local changedCount = 0

    for i = 1, num do
        local name = C_AddOns.GetAddOnInfo(i)
        if name and not ns.IsProtected(name) then
            local currentEnabled = ns.IsAddonEnabled(i)
            local shouldEnable = target[name]
            if shouldEnable == nil then
                shouldEnable = target[name:lower()]
            end
            if shouldEnable ~= nil and shouldEnable ~= currentEnabled then
                ns.SetAddonState(i, shouldEnable)
                ns.SetAddonState(name, shouldEnable)
                changedCount = changedCount + 1
            end
        end
    end

    if changedCount > 0 then
        ns.SaveAddonConfig()
    end
    return changedCount
end
ns.AlignProfileToCharacter = AlignProfileToCharacter
DuoUI.AlignProfileToCharacter = AlignProfileToCharacter

-- 对话框输入框辅助
local function GetDialogEditBox(dialog)
    if not dialog then return nil end
    return dialog.EditBox or dialog.editBox or (dialog.GetName and _G[dialog:GetName() .. "EditBox"])
end

local function GetDialogText(dialog)
    local eb = GetDialogEditBox(dialog)
    if eb and eb.GetText then
        return eb:GetText() or ""
    end
    return ""
end

-- 注册另存新方案对话框
StaticPopupDialogs["DUOUI_SAVE_ADDON_PROFILE"] = {
    text = "|cff00cfff[Duo]|r\n" .. ((ns.L and ns.L["NEW_PROFILE_PROMPT"]) or "请输入新方案名称："),
    button1 = OKAY or "确定",
    button2 = CANCEL or "取消",
    hasEditBox = true,
    maxLetters = 24,
    OnShow = function(self)
        local eb = GetDialogEditBox(self)
        if eb then
            eb:SetText("")
            eb:SetFocus()
        end
    end,
    OnAccept = function(self)
        local text = GetDialogText(self)
        if text and text:trim() ~= "" then
            DuoUI.SaveAddonProfile(text:trim())
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local text = self.GetText and self:GetText() or GetDialogText(self)
        if text and text:trim() ~= "" then
            DuoUI.SaveAddonProfile(text:trim())
        end
        local parent = self:GetParent()
        if parent and parent.Hide then parent:Hide() end
    end,
    EditBoxOnEscapePressed = function(self)
        local parent = self:GetParent()
        if parent and parent.Hide then parent:Hide() end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- 保存插件方案
function DuoUI.SaveAddonProfile(profileName)
    if not profileName or profileName:trim() == "" then return end
    profileName = profileName:trim()
    local db = GetDB()
    db.profiles[profileName] = CaptureCurrentState()
    SetActiveProfile(profileName)
    local hex = ns.GetThemeAccentHex()
    DuoUI.Print("|cff" .. hex .. "[插件管理]|r 方案 【" .. profileName .. "】 保存成功！")
    if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
end

-- 应用插件方案
function DuoUI.ApplyAddonProfile(profileName)
    if InCombatLockdown and InCombatLockdown() then
        DuoUI.Print("|cffff3030战斗中无法切换插件方案！|r")
        return
    end
    local db = GetDB()
    local target = db.profiles[profileName]
    if not target then return end

    SetActiveProfile(profileName)
    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    local changedCount = 0

    for i = 1, num do
        local name = C_AddOns.GetAddOnInfo(i)
        if name then
            local currentEnabled = ns.IsAddonEnabled(i)
            local shouldEnable = target[name]
            if shouldEnable == nil then
                shouldEnable = target[name:lower()]
            end
            if ns.IsProtected(name) then shouldEnable = true end

            if shouldEnable ~= nil and shouldEnable ~= currentEnabled then
                ns.SetAddonState(i, shouldEnable)
                ns.SetAddonState(name, shouldEnable)
                changedCount = changedCount + 1
            end
        end
    end

    ns.SaveAddonConfig()

    DuoUI.hasAddonChange = (changedCount > 0)
    local hex = ns.GetThemeAccentHex()
    DuoUI.Print(string.format("|cff" .. hex .. "[插件管理]|r 已切换至 【%s】 方案（%d 项变更%s）。",
        profileName, changedCount, changedCount > 0 and "，需重载生效" or ""))

    if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
end

-- 删除插件方案
function DuoUI.DeleteAddonProfile(profileName)
    local db = GetDB()
    if not db.profiles[profileName] then return end
    db.profiles[profileName] = nil
    if GetActiveProfile() == profileName then
        local firstKey = next(db.profiles) or "默认方案"
        SetActiveProfile(firstKey)
        if not db.profiles[firstKey] then
            db.profiles[firstKey] = CaptureCurrentState()
        end
    end
    local hex = ns.GetThemeAccentHex()
    DuoUI.Print("|cff" .. hex .. "[插件管理]|r 方案 【" .. profileName .. "】 已删除。")
    if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
end

-- 一键将方案应用至全账号所有角色 (全局同步)
function DuoUI.ApplyProfileToAllCharacters(profileName)
    if InCombatLockdown and InCombatLockdown() then
        DuoUI.Print("|cffff3030战斗中无法切换插件方案！|r")
        return
    end
    local db = GetDB()
    local target = db.profiles[profileName]
    if not target then return end

    if type(db.charProfiles) == "table" then
        for k in pairs(db.charProfiles) do
            db.charProfiles[k] = profileName
        end
    end
    local myKey = ns.GetPlayerCharacterKey()
    db.charProfiles[myKey] = profileName
    db.activeProfile = profileName

    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    local changedCount = 0

    for i = 1, num do
        local name = C_AddOns.GetAddOnInfo(i)
        if name then
            local currentEnabled = ns.IsAddonEnabled(i)
            local shouldEnable = target[name]
            if shouldEnable == nil then
                shouldEnable = target[name:lower()]
            end
            if ns.IsProtected(name) then shouldEnable = true end

            if shouldEnable ~= nil and shouldEnable ~= currentEnabled then
                ns.SetAddonState(i, shouldEnable, true)
                ns.SetAddonState(name, shouldEnable, true)
                changedCount = changedCount + 1
            else
                ns.SetAddonState(i, shouldEnable or false, true)
                ns.SetAddonState(name, shouldEnable or false, true)
            end
        end
    end

    if ns.EnsureCoreAddonsEnabled then ns.EnsureCoreAddonsEnabled() end
    ns.SaveAddonConfig()

    DuoUI.hasAddonChange = true
    local hex = ns.GetThemeAccentHex()
    DuoUI.Print(string.format("|cff%s[插件管理]|r 已将 【%s】 方案一键应用至全账号所有角色！需重载生效。", hex, profileName))

    if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
end

-- 为当前角色生成独立专属方案 (解绑单飞)
function DuoUI.CloneAsCharacterProfile(sourceProfileName)
    local db = GetDB()
    local target = db.profiles[sourceProfileName]
    local pName = UnitName("player") or "角色"
    local baseName = string.format("%s专属", pName)
    local newName = baseName
    local idx = 1
    while db.profiles[newName] do
        idx = idx + 1
        newName = string.format("%s%d", baseName, idx)
    end

    local cloned = {}
    if target then
        for k, v in pairs(target) do cloned[k] = v end
    else
        cloned = ns.CaptureCurrentState()
    end
    db.profiles[newName] = cloned
    SetActiveProfile(newName)

    local hex = ns.GetThemeAccentHex()
    DuoUI.Print(string.format("|cff%s[插件管理]|r 已为当前角色生成独立专属方案：【%s】！", hex, newName))

    if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
end
