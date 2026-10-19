-------------------------------------------------------------------------------
--  Main.lua -- 插件入口、斜杠命令系统与系统集成
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local DuoUI = ns.DuoUI

-- 1. 最优先注册斜杠命令与小地图点击响应，确保无论任何时刻输入都绝对有反应！
SLASH_DUOUI_ADDONS1 = "/am"
SLASH_DUOUI_ADDONS2 = "/addons"
SLASH_DUOUI_ADDONS3 = "/duoam"
SLASH_DUOUI_ADDONS4 = "/dam"
SlashCmdList["DUOUI_ADDONS"] = function(msg)
    local chat = ChatFrame1 or DEFAULT_CHAT_FRAME
    local cmd = msg and (ns.str_trim(msg)):lower() or ""
    if cmd ~= "" and ns.COLOR_THEMES and ns.COLOR_THEMES[cmd] then
        local db = ns.GetDB()
        if db then
            db.themeKey = cmd
            if DuoUI.RefreshAddonManagerUI then DuoUI.RefreshAddonManagerUI() end
            local t = ns.COLOR_THEMES[cmd]
            local hex = ns.GetThemeAccentHex()
            if chat then
                chat:AddMessage(string.format("|cff%s[DuoAddonManager]|r 已切换配色方案为：【%s】", hex, t.name))
            end
            return
        end
    end

    local ok, err = pcall(function()
        local toggle = DuoUI.ToggleAddonManager
            or _G.DuoAddonManager_ToggleAddonManager
            or _G.DuoUI_ToggleAddonManager
        if toggle then
            toggle()
        elseif chat then
            chat:AddMessage("|cffff3030[DuoAddonManager]:|r 模块尚未完全加载，请稍候。")
        end
    end)
    if not ok and chat then
        chat:AddMessage("|cffff3030[DuoAddonManager 错误]:|r " .. tostring(err))
    end
end

-- 快速重载命令 (/rl 与 /reloadui)
SLASH_DUOUI_RELOAD1 = "/rl"
SLASH_DUOUI_RELOAD2 = "/reloadui"
SlashCmdList["DUOUI_RELOAD"] = function()
    ReloadUI()
end

-- 暴雪 10.0+ 插件收纳菜单 (Addon Compartment) 回调入口
function _G.DuoAddonManagerCompartmentFunc(...)
    SlashCmdList["DUOUI_ADDONS"]("")
end
_G.DuoUI_AddonManagerCompartmentFunc = _G.DuoAddonManagerCompartmentFunc
_G.DuoUI_AddonCompartmentFunc = _G.DuoAddonManagerCompartmentFunc

-- 登入就绪提示
local function PrintReadyMessage()
    local chat = ChatFrame1 or DEFAULT_CHAT_FRAME
    if chat and not DuoUI._hasAnnouncedReady then
        DuoUI._hasAnnouncedReady = true
        chat:AddMessage("|cff0091edDuo|r 插件管理已就绪，输入 |cff00cfff/am|r 打开。")
    end
end

-- 登入后检测方案是否在其他角色上被更新，若有则自动对齐并提示
local function CheckLoginProfileSync()
    if C_Timer and C_Timer.After then
        C_Timer.After(2.0, function()
            local active = ns.GetActiveProfile and ns.GetActiveProfile()
            if active and ns.CheckProfileDiff then
                local hasDiff, diffCount = ns.CheckProfileDiff(active)
                if hasDiff then
                    ns.AlignProfileToCharacter(active)
                    DuoUI.hasAddonChange = true
                    local chat = ChatFrame1 or DEFAULT_CHAT_FRAME
                    if chat then
                        chat:AddMessage(string.format("|cff0091ed[Duo]|r 方案【|cffffffff%s|r】在其他角色上有更新（|cffffcc00%d 项变更|r），已自动对齐设置，输入 |cff00cfff/reload|r 即可生效！", active, diffCount))
                    end
                end
            end
        end)
    end
end

local bootFrame = CreateFrame("Frame")
bootFrame:RegisterEvent("PLAYER_LOGIN")
bootFrame:SetScript("OnEvent", function(self)
    PrintReadyMessage()
    CheckLoginProfileSync()
    self:UnregisterAllEvents()
end)

if IsLoggedIn and IsLoggedIn() then
    PrintReadyMessage()
    CheckLoginProfileSync()
end
