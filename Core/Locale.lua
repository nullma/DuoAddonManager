-------------------------------------------------------------------------------
--  Core\Locale.lua -- 全自动中英多语言本地化系统 (i18n Localization Engine)
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local locale = GetLocale and GetLocale() or "zhCN"
local isCN = (locale == "zhCN" or locale == "zhTW")
ns.isCN = isCN

local L = setmetatable({}, {
    __index = function(t, k)
        return k
    end
})
ns.L = L

-- 基础英文词典 (Default / enUS / enGB / others)
local enUS = {
    -- 窗口标题与全局
    ["TITLE_SUFFIX"]            = "Addon Manager",
    ["SEARCH_PLACEHOLDER"]      = "Search addons...",
    ["BLIZZARD_OPTIONS_TITLE"]  = "Duo Addon Manager",
    ["OPEN_MANAGER"]            = "Open Addon Manager",

    -- 顶部栏与方案
    ["PROFILES_LABEL"]          = "Profile:",
    ["DEFAULT_PROFILE"]         = "Default",
    ["BATCH_BTN"]               = "Batch",
    ["BATCH_ENABLE_ALL"]        = "Enable All",
    ["BATCH_DISABLE_ALL"]       = "Disable All",
    ["BATCH_REFRESH_MEM"]       = "Refresh Memory",
    ["NEW_PROFILE_PROMPT"]      = "Enter new profile name:",
    ["PROFILE_EXISTS"]          = "Profile already exists.",
    ["SAVE_NEW_PROFILE"]        = "Save As New Profile",
    ["SAVE_NEW_PROFILE_DESC"]   = "Create preset with current addon states",

    -- 主题配色
    ["THEME_GOLD"]              = "Imperial Gold",
    ["THEME_CLASS"]             = "Class Color",
    ["THEME_EMERALD"]           = "Emerald Forest",
    ["THEME_ROYAL"]             = "Royal Blue",
    ["THEME_MENU_TITLE"]        = "Theme Accent",

    -- 底部状态栏
    ["STATUS_ENABLED"]          = "Enabled",
    ["STATUS_TOTAL_MEM"]        = "Total Mem",
    ["STATUS_AUTO_SAVED"]       = "Auto Saved",
    ["STATUS_ESC_CLOSE"]        = "[ESC] Close",
    ["STATUS_ESC_CLOSE_TEXT"]   = "Close",
    ["SAVE_AND_RELOAD"]         = "Save & Reload",
    ["TIP_RELOAD_NEEDED"]       = "Addon changes pending. Reload recommended.",
    ["SYNCED_CHANGES"]          = "Synced latest changes for [%s]",
    ["AUTO_SAVED_TO"]           = "Auto-saved to [%s]",
    ["RELOAD_NEEDED"]           = "Reload needed",
    ["PROFILE_PREFIX"]          = "Profile [%s]",

    -- 运行状态悬浮窗
    ["TOOLTIP_STATUS_TITLE"]    = "Addon Runtime Status",
    ["TOOLTIP_MAIN_ADDONS"]     = "Main Addons: %d / %d Enabled",
    ["TOOLTIP_SUB_MODULES"]     = "Submodules: %d Total (%d Enabled)",
    ["TOOLTIP_MEM_USAGE"]       = "Total Memory: %s",

    -- Curse 官方 10 大分类
    ["全部插件"]                 = "All Addons",
    ["战斗与PvP"]               = "Combat & PvP",
    ["用户界面"]                 = "User Interface",
    ["社交与组队"]               = "Guild & Social",
    ["背包与物品"]               = "Bags & Inventory",
    ["拍卖与商业"]               = "Auctions & Economy",
    ["地图与探索"]               = "Map & Navigation",
    ["任务与成就"]               = "Quests & Leveling",
    ["装备与属性"]               = "Gear & Stats",
    ["藏品与趣味"]               = "Collections & Fun",
    ["开发与系统"]               = "Development & System",
    ["综合杂项"]                 = "Miscellaneous",

    -- 卡片徽章与微交互
    ["BADGE_CORE"]              = "Core",
    ["BADGE_ITEMS"]             = "items",
    ["BADGE_COLLAPSE"]          = "Hide",
    ["BADGE_LOD"]               = "LOD",
    ["OPEN_SETTINGS"]           = "Open Addon Settings",
    ["FOLDER_NAME"]             = "Folder: ",
    ["VERSION_LABEL"]           = "Version: ",
    ["AUTHOR_LABEL"]            = "Author: ",
    ["TOOLTIP_PROTECTED"]       = "Core protected addon, cannot be disabled",
    ["TOOLTIP_DEPS"]            = "Dependencies: %s",
    ["TOOLTIP_EXPAND_FINE_TUNE"]= "Click to fine-tune (%d): %s",
    ["TOOLTIP_MEM"]             = "Memory: %s",
    ["CONFIG_OPENED"]           = "Opened settings for [%s].",
    ["CONFIG_NOT_FOUND"]        = "No graphical settings panel found for [%s].",

    -- 方案提示与操作
    ["PROFILE_PRESET"]          = "Profile: %s",
    ["PROFILE_ACTIVE_TIP"]      = "● Currently Active (Real-time auto-saved)",
    ["PROFILE_SWITCH_TIP"]      = "Left-Click: Apply profile",
    ["PROFILE_MANAGE_TIP"]      = "Right-Click: Overwrite / Delete",
    ["PROFILE_CURRENT"]         = "Current Profile",
    ["CARD_TOGGLE_TIP"]         = "Click addon card to toggle enable/disable",
    ["BATCH_TOOLTIP_TITLE"]     = "Batch Operations",
    ["BATCH_TOOLTIP_DESC"]      = "Click to open batch control menu:",
    ["BATCH_TOOLTIP_ENABLE"]    = "• Enable all addons",
    ["BATCH_TOOLTIP_DISABLE"]   = "• Disable all addons",
    ["BATCH_TOOLTIP_MEM"]       = "• Refresh memory usage",
    ["THEME_CURRENT"]           = "Current Theme: ",
    ["THEME_DESC"]              = "Click to switch between 4 dark themes",
    ["COMBAT_WARNING"]          = "Cannot open Addon Manager in combat!",
    ["BLIZZARD_OPTIONS_DESC"]   = "Click button below to open Addon Manager.\nYou can also type |cff00cfff/am|r or |cff00cfff/addons|r in chat.",

    -- 小地图图标与悬浮坞
    ["MINIMAP_TITLE"]           = "Duo Addon Manager & Dock",
    ["MINIMAP_LEFT_CLICK"]      = "Toggle Minimap Icon Dock",
    ["MINIMAP_RIGHT_CLICK"]     = "Open Addon Manager (/am)",
    ["MINIMAP_RIGHT_DRAG"]      = "Drag to reposition around minimap",
    ["MINIMAP_FAST_RL"]         = "/rl to quickly reload UI",
    ["MOUSE_LEFT_CLICK"]        = "Left Click: ",
    ["MOUSE_RIGHT_CLICK"]       = "Right Click: ",
    ["MOUSE_RIGHT_DRAG"]        = "Right Drag: ",
    ["FAST_COMMAND"]            = "Command: ",
    ["RELOAD_UI_SHORT"]         = "Quick reload UI",
}

-- 简体与繁体中文词典 (zhCN / zhTW)
local zhCN = {
    -- 窗口标题与全局
    ["TITLE_SUFFIX"]            = "插件管理",
    ["SEARCH_PLACEHOLDER"]      = "搜索插件...",
    ["BLIZZARD_OPTIONS_TITLE"]  = "Duo 插件管理",
    ["OPEN_MANAGER"]            = "打开插件管理器",

    -- 顶部栏与方案
    ["PROFILES_LABEL"]          = "方案:",
    ["DEFAULT_PROFILE"]         = "默认方案",
    ["BATCH_BTN"]               = "批量管理",
    ["BATCH_ENABLE_ALL"]        = "全部启用",
    ["BATCH_DISABLE_ALL"]       = "全部禁用",
    ["BATCH_REFRESH_MEM"]       = "刷新内存",
    ["NEW_PROFILE_PROMPT"]      = "请输入新方案名称:",
    ["PROFILE_EXISTS"]          = "该方案名称已存在！",
    ["SAVE_NEW_PROFILE"]        = "另存为新方案",
    ["SAVE_NEW_PROFILE_DESC"]   = "以当前插件启用状态创建新预设",

    -- 主题配色
    ["THEME_GOLD"]              = "暗金尊享",
    ["THEME_CLASS"]             = "职业专属",
    ["THEME_EMERALD"]           = "翡翠森林",
    ["THEME_ROYAL"]             = "深海幽蓝",
    ["THEME_MENU_TITLE"]        = "界面配色",

    -- 底部状态栏
    ["STATUS_ENABLED"]          = "已启用",
    ["STATUS_TOTAL_MEM"]        = "总内存",
    ["STATUS_AUTO_SAVED"]       = "实时自动保存",
    ["STATUS_ESC_CLOSE"]        = "[ESC] 关闭",
    ["STATUS_ESC_CLOSE_TEXT"]   = "关闭",
    ["SAVE_AND_RELOAD"]         = "保存并重载",
    ["TIP_RELOAD_NEEDED"]       = "插件配置已变更，建议重载界面生效",
    ["SYNCED_CHANGES"]          = "已自动同步【%s】最新改动",
    ["AUTO_SAVED_TO"]           = "已自动保存至【%s】",
    ["RELOAD_NEEDED"]           = "需重载生效",
    ["PROFILE_PREFIX"]          = "方案【%s】",

    -- 运行状态悬浮窗
    ["TOOLTIP_STATUS_TITLE"]    = "插件运行状态",
    ["TOOLTIP_MAIN_ADDONS"]     = "主插件: %d / %d 已启用",
    ["TOOLTIP_SUB_MODULES"]     = "底层模块总数: %d 款 (已启用 %d 款)",
    ["TOOLTIP_MEM_USAGE"]       = "占用总内存: %s",

    -- Curse 官方 10 大分类
    ["全部插件"]                 = "全部插件",
    ["战斗与PvP"]               = "战斗与PvP",
    ["用户界面"]                 = "用户界面",
    ["社交与组队"]               = "社交与组队",
    ["背包与物品"]               = "背包与物品",
    ["拍卖与商业"]               = "拍卖与商业",
    ["地图与探索"]               = "地图与探索",
    ["任务与成就"]               = "任务与成就",
    ["装备与属性"]               = "装备与属性",
    ["藏品与趣味"]               = "藏品与趣味",
    ["开发与系统"]               = "开发与系统",
    ["综合杂项"]                 = "综合杂项",

    -- 卡片徽章与微交互
    ["BADGE_CORE"]              = "核心",
    ["BADGE_ITEMS"]             = "项",
    ["BADGE_COLLAPSE"]          = "收起",
    ["BADGE_LOD"]               = "按需",
    ["OPEN_SETTINGS"]           = "打开该插件设置",
    ["FOLDER_NAME"]             = "目录名: ",
    ["VERSION_LABEL"]           = "版本: ",
    ["AUTHOR_LABEL"]            = "作者: ",
    ["TOOLTIP_PROTECTED"]       = "核心保护插件，不可随意禁用",
    ["TOOLTIP_DEPS"]            = "依赖: %s",
    ["TOOLTIP_EXPAND_FINE_TUNE"]= "点击展开微调 (%d): %s",
    ["TOOLTIP_MEM"]             = "内存占用: %s",
    ["CONFIG_OPENED"]           = "已打开 【%s】 的设置面板。",
    ["CONFIG_NOT_FOUND"]        = "未检测到 【%s】 的图形设置面板，该插件可能无独立设置或需通过其特定命令配置。",

    -- 方案提示与操作
    ["PROFILE_PRESET"]          = "预设方案: %s",
    ["PROFILE_ACTIVE_TIP"]      = "● 当前激活方案（改动实时自动保存）",
    ["PROFILE_SWITCH_TIP"]      = "左键：切换应用此方案",
    ["PROFILE_MANAGE_TIP"]      = "右键：另存覆盖 / 删除此方案",
    ["PROFILE_CURRENT"]         = "当前方案",
    ["CARD_TOGGLE_TIP"]         = "点击插件卡片切换启用/停用",
    ["BATCH_TOOLTIP_TITLE"]     = "批量操作",
    ["BATCH_TOOLTIP_DESC"]      = "点击展开批量控制菜单：",
    ["BATCH_TOOLTIP_ENABLE"]    = "• 全部启用插件",
    ["BATCH_TOOLTIP_DISABLE"]   = "• 全部停用插件",
    ["BATCH_TOOLTIP_MEM"]       = "• 刷新内存占用",
    ["THEME_CURRENT"]           = "当前配色: ",
    ["THEME_DESC"]              = "点击展开 4 款专业暗黑定制配色",
    ["COMBAT_WARNING"]          = "战斗中无法打开插件管理面板！",
    ["BLIZZARD_OPTIONS_DESC"]   = "点击下方按钮即可打开独立现代化插件管理面板。\n您也可以在任意聊天框输入 |cff00cfff/am|r 或 |cff00cfff/addons|r 直接呼出。",

    -- 小地图图标与悬浮坞
    ["MINIMAP_TITLE"]           = "Duo 插件管理与收纳",
    ["MINIMAP_LEFT_CLICK"]      = "展开/收起小地图图标坞",
    ["MINIMAP_RIGHT_CLICK"]     = "打开插件管理器主界面 (/am)",
    ["MINIMAP_RIGHT_DRAG"]      = "围绕小地图调整图标位置",
    ["MINIMAP_FAST_RL"]         = "/rl 快速重载界面",
    ["MOUSE_LEFT_CLICK"]        = "左键点击：",
    ["MOUSE_RIGHT_CLICK"]       = "右键点击：",
    ["MOUSE_RIGHT_DRAG"]        = "右键拖动：",
    ["FAST_COMMAND"]            = "快速命令：",
    ["RELOAD_UI_SHORT"]         = "快速重载界面",
}

-- 语言注入
local dict = isCN and zhCN or enUS
for k, v in pairs(dict) do
    L[k] = v
end

-- 获取分类多语言展示名辅助函数
local function GetCategoryDisplayName(rawCatName)
    if not rawCatName then return L["综合杂项"] end
    return L[rawCatName] or rawCatName
end
ns.GetCategoryDisplayName = GetCategoryDisplayName
