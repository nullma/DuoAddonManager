-------------------------------------------------------------------------------
--  Engine\Theming.lua -- 全局主题调色板与 EllesmereUI 动态联动换肤系统
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = ns.DuoUI

local L = ns.L or {}

-- 内置 4 款经由专业暗色 UI 调校的高端配色方案
local COLOR_THEMES = {
    ["gold"]    = { name = L["THEME_GOLD"] or "暗金尊享", tag = "暗金", r = 0.96, g = 0.65, b = 0.14, hex = "f5a624" },
    ["class"]   = { name = L["THEME_CLASS"] or "职业专属", tag = "职业", isClass = true },
    ["emerald"] = { name = L["THEME_EMERALD"] or "翡翠森林", tag = "翡翠", r = 0.10, g = 0.78, b = 0.54, hex = "1ac78a" },
    ["royal"]   = { name = L["THEME_ROYAL"] or "深海幽蓝", tag = "幽蓝", r = 0.22, g = 0.55, b = 0.98, hex = "388cfa" },
}
local THEME_ORDER = { "gold", "class", "emerald", "royal" }
ns.COLOR_THEMES = COLOR_THEMES
ns.THEME_ORDER = THEME_ORDER

-- 获取当前玩家职业专属高亮色
local function GetClassColor()
    local _, classFilename = UnitClass("player")
    local c = nil
    if classFilename then
        if _G.C_ClassColor and _G.C_ClassColor.GetClassColor then
            c = _G.C_ClassColor.GetClassColor(classFilename)
        end
        if not c and _G.RAID_CLASS_COLORS then
            c = _G.RAID_CLASS_COLORS[classFilename]
        end
    end
    if c and c.r and c.g and c.b then
        local hex
        if c.GenerateHexColorNoAlpha then
            hex = c:GenerateHexColorNoAlpha()
        elseif c.colorStr then
            hex = tostring(c.colorStr)
            if #hex > 6 then hex = hex:sub(-6) end
        else
            hex = string.format("%02x%02x%02x",
                math.floor(math.min(1, math.max(0, c.r)) * 255 + 0.5),
                math.floor(math.min(1, math.max(0, c.g)) * 255 + 0.5),
                math.floor(math.min(1, math.max(0, c.b)) * 255 + 0.5)
            )
        end
        return c.r, c.g, c.b, hex
    end
    return 0.96, 0.65, 0.14, "f5a624"
end
ns.GetClassColor = GetClassColor

-- 动态获取当前配置的主题三原色数值
local function GetThemeAccent()
    local db = ns.GetDB and ns.GetDB()
    local key = db and db.themeKey or "gold"
    if key == "class" then
        local r, g, b = GetClassColor()
        return r, g, b
    end
    local t = COLOR_THEMES[key]
    if t and t.r then
        return t.r, t.g, t.b
    end
    return 0.96, 0.65, 0.14
end
ns.GetThemeAccent = GetThemeAccent

-- 动态获取当前配置的主题十六进制颜色字串 (用于富文本染色)
local function GetThemeAccentHex()
    local db = ns.GetDB and ns.GetDB()
    local key = db and db.themeKey or "gold"
    if key == "class" then
        local _, _, _, hex = GetClassColor()
        return hex
    end
    local t = COLOR_THEMES[key]
    if t and t.hex then return t.hex end
    local r, g, b = GetThemeAccent()
    return string.format("%02x%02x%02x",
        math.floor(math.min(1, math.max(0, r)) * 255 + 0.5),
        math.floor(math.min(1, math.max(0, g)) * 255 + 0.5),
        math.floor(math.min(1, math.max(0, b)) * 255 + 0.5)
    )
end
ns.GetThemeAccentHex = GetThemeAccentHex

-- 注册 EllesmereUI 主题切换回调 (零延迟热重绘)
local function HookThemeChanges()
    local EUI = _G.EllesmereUI
    if not EUI then return end
    local entry = {
        type = "callback",
        fn = function(r, g, b)
            if DuoUI.RefreshAddonManagerUI then
                DuoUI.RefreshAddonManagerUI()
            end
            local managerWindow = ns.managerWindow
            if managerWindow and managerWindow:IsShown() then
                local ar, ag, ab = GetThemeAccent()
                local hex = GetThemeAccentHex()
                if managerWindow._winBorder then
                    managerWindow._winBorder:SetColorTexture(ar, ag, ab, 0.4)
                end
                if managerWindow._titleFS then
                    managerWindow._titleFS:SetText(string.format("|cff%sDuo|r |cffffffff%s|r", hex, (L and L["TITLE_SUFFIX"]) or "插件管理"))
                end
                if managerWindow._thumbTex then
                    managerWindow._thumbTex:SetColorTexture(ar, ag, ab, 0.45)
                end
            end
        end,
    }
    if EUI.RegAccent then
        EUI.RegAccent(entry)
    elseif EUI._accentElements then
        table.insert(EUI._accentElements, entry)
    end
end
ns.HookThemeChanges = HookThemeChanges

HookThemeChanges()
local themeBoot = CreateFrame("Frame")
themeBoot:RegisterEvent("PLAYER_LOGIN")
themeBoot:SetScript("OnEvent", function(self)
    HookThemeChanges()
    self:UnregisterAllEvents()
end)
