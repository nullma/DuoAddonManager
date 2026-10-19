-------------------------------------------------------------------------------
--  Core\Compatibility.lua -- 暴雪 API 跨版本兼容层与插件启停核心安全控制
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local C_AddOns = _G.C_AddOns or {}
ns.C_AddOns = C_AddOns

-- 获取当前角色全局唯一 GUID (保留备用)
local function GetPlayerCharacterGUID()
    if UnitGUID then
        local guid = UnitGUID("player")
        if guid and guid ~= "" then return guid end
    end
    return nil
end
ns.GetPlayerCharacterGUID = GetPlayerCharacterGUID

-- 获取角色独立键名 (name-realm)，用于多角色方案隔离
local function GetPlayerCharacterKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or ""
    return (name .. "-" .. realm):lower()
end
ns.GetPlayerCharacterKey = GetPlayerCharacterKey

-- 触发暴雪底层持久化写入
local function SaveAddonConfig()
    if C_AddOns and C_AddOns.SaveAddOns then
        pcall(C_AddOns.SaveAddOns)
    elseif SaveAddOns then
        pcall(SaveAddOns)
    end
end
ns.SaveAddonConfig = SaveAddonConfig

-- 安全设置插件启停状态 (支持当前角色专属模式与全账号全局模式)
local function SetAddonState(addonIndexOrName, enabled, forceGlobal)
    if not addonIndexOrName then return end
    local pName = UnitName("player")
    local db = ns.GetDB and ns.GetDB()
    local isGlobal = forceGlobal
    if isGlobal == nil then
        isGlobal = (db and db.scopeMode == "global")
    end

    if enabled then
        if C_AddOns and C_AddOns.EnableAddOn then
            if not isGlobal and pName then
                pcall(C_AddOns.EnableAddOn, addonIndexOrName, pName)
            else
                pcall(C_AddOns.EnableAddOn, addonIndexOrName)
            end
        elseif EnableAddOn then
            if not isGlobal and pName then
                pcall(EnableAddOn, addonIndexOrName, pName)
            else
                pcall(EnableAddOn, addonIndexOrName)
            end
        end
    else
        if C_AddOns and C_AddOns.DisableAddOn then
            if not isGlobal and pName then
                pcall(C_AddOns.DisableAddOn, addonIndexOrName, pName)
            else
                pcall(C_AddOns.DisableAddOn, addonIndexOrName)
            end
        elseif DisableAddOn then
            if not isGlobal and pName then
                pcall(DisableAddOn, addonIndexOrName, pName)
            else
                pcall(DisableAddOn, addonIndexOrName)
            end
        end
    end
end
ns.SetAddonState = SetAddonState

-- 核心受保护插件白名单 (防止误停用导致无法打开管理面板)
local CORE_PROTECTED = {
    ["duoaddonmanager"]    = true,
    ["duoui_addonmanager"] = true,
}
ns.CORE_PROTECTED = CORE_PROTECTED

local function IsProtected(addonName)
    if not addonName then return false end
    return CORE_PROTECTED[addonName:lower()] == true
end
ns.IsProtected = IsProtected

-- 安全检测插件是否启用 (完美兼容 11.0+ 字符串/索引与按需加载)
local function IsAddonEnabled(indexOrName)
    local name = indexOrName
    if type(indexOrName) == "number" and C_AddOns.GetAddOnInfo then
        name = C_AddOns.GetAddOnInfo(indexOrName) or indexOrName
    end
    if not name then return false end

    -- 1. 暴雪 API 查询：C_AddOns.GetAddOnEnableState(name, [character])
    -- 0 = 禁用, 1 = 当前角色启用, 2 = 全部角色启用
    local pName = UnitName("player")
    if C_AddOns and C_AddOns.GetAddOnEnableState then
        if pName then
            local ok, state = pcall(C_AddOns.GetAddOnEnableState, name, pName)
            if ok and type(state) == "number" then
                return state > 0
            end
            if type(indexOrName) == "number" then
                local okIdx, stateIdx = pcall(C_AddOns.GetAddOnEnableState, indexOrName, pName)
                if okIdx and type(stateIdx) == "number" then
                    return stateIdx > 0
                end
            end
        end

        local okAll, stateAll = pcall(C_AddOns.GetAddOnEnableState, name)
        if okAll and type(stateAll) == "number" then
            return stateAll > 0
        end
        if type(indexOrName) == "number" then
            local okAllIdx, stateAllIdx = pcall(C_AddOns.GetAddOnEnableState, indexOrName)
            if okAllIdx and type(stateAllIdx) == "number" then
                return stateAllIdx > 0
            end
        end
    elseif GetAddOnEnableState then
        if pName then
            local ok, state = pcall(GetAddOnEnableState, pName, name)
            if not ok then ok, state = pcall(GetAddOnEnableState, name, pName) end
            if ok and type(state) == "number" then
                return state > 0
            end
        end
        local okAll, stateAll = pcall(GetAddOnEnableState, name)
        if okAll and type(stateAll) == "number" then
            return stateAll > 0
        end
    end

    -- 2. 兜底回退：若上述状态均无法读取，则检查是否已载入当前游戏会话
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        if ok and loaded then return true end
        if type(indexOrName) == "number" then
            local ok2, loaded2 = pcall(C_AddOns.IsAddOnLoaded, indexOrName)
            if ok2 and loaded2 then return true end
        end
    elseif IsAddOnLoaded then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        if ok and loaded then return true end
    end

    return false
end
ns.IsAddonEnabled = IsAddonEnabled

-- 核心插件账号级常驻与自愈保护 (确保任何小号上线均默认启用管理器)
local function EnsureCoreAddonsEnabled()
    local pName = UnitName("player")
    for addonName in pairs(CORE_PROTECTED) do
        if C_AddOns and C_AddOns.EnableAddOn then
            pcall(C_AddOns.EnableAddOn, addonName)
            if pName then pcall(C_AddOns.EnableAddOn, addonName, pName) end
        elseif EnableAddOn then
            pcall(EnableAddOn, addonName)
            if pName then pcall(EnableAddOn, addonName, pName) end
        end
    end
end
ns.EnsureCoreAddonsEnabled = EnsureCoreAddonsEnabled
EnsureCoreAddonsEnabled()

local coreBoot = CreateFrame("Frame")
coreBoot:RegisterEvent("PLAYER_LOGIN")
coreBoot:RegisterEvent("PLAYER_ENTERING_WORLD")
coreBoot:SetScript("OnEvent", function()
    EnsureCoreAddonsEnabled()
end)
