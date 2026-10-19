-------------------------------------------------------------------------------
--  Core\Init.lua -- 命名空间初始化、基础工具与通用常量
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = _G.DuoAddonManager or _G.DuoUI_AddonManager or {}
_G.DuoAddonManager = DuoUI
_G.DuoUI_AddonManager = DuoUI
ns.DuoUI = DuoUI

-- 标记全局已载入
_G.DuoAddonManagerModuleLoaded = true
_G.DuoUI_AddonManagerModuleLoaded = true

-- 字符串裁剪工具
local function str_trim(s)
    if not s then return "" end
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end
if not string.trim then
    string.trim = str_trim
end
ns.str_trim = str_trim

-- 统一前缀输出工具
if not DuoUI.Print then
    DuoUI.Print = function(msg)
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff0091edDuo|r " .. tostring(msg))
        else
            print("|cff0091edDuo|r " .. tostring(msg))
        end
    end
end
ns.Print = DuoUI.Print
