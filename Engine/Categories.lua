-------------------------------------------------------------------------------
--  Engine\Categories.lua -- CurseForge 官方标准 10 大分类字典与智能推断引擎
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

-- ==============================================================================
-- 按照 CurseForge 官方标准体系分类 (CurseForge WoW Standard Categories)
-- ==============================================================================
-- 1. 战斗与PvP (Combat & PvP)
-- 2. 用户界面 (User Interface)
-- 3. 社交与组队 (Guild & Social)
-- 4. 背包与物品 (Bags & Inventory)
-- 5. 拍卖与商业 (Auctions & Economy)
-- 6. 地图与探索 (Map & Navigation)
-- 7. 任务与成就 (Quests & Leveling)
-- 8. 装备与属性 (Gear & Stats)
-- 9. 藏品与趣味 (Collections & Minigames)
-- 10. 开发与系统 (Development & System)
-- 11. 综合杂项 (Miscellaneous)

local BUILTIN_CATEGORIES = {
    -- 1. 战斗与PvP (CurseForge: Combat & PvP - 首领报警、伤害统计、PvP、冷却监控、姓名板与战斗辅助)
    ["bigwigs"]                 = "战斗与PvP",
    ["littlewigs"]              = "战斗与PvP",
    ["dbm"]                     = "战斗与PvP",
    ["dbm-core"]                = "战斗与PvP",
    ["details"]                 = "战斗与PvP",
    ["weakauras"]               = "战斗与PvP",
    ["weakaurasoptions"]        = "战斗与PvP",
    ["weakaurasmodelpaths"]     = "战斗与PvP",
    ["weakaurastemplates"]      = "战斗与PvP",
    ["cell"]                    = "战斗与PvP",
    ["clique"]                  = "战斗与PvP",
    ["mrt"]                     = "战斗与PvP",
    ["methodraids"]             = "战斗与PvP",
    ["angrykeystones"]          = "战斗与PvP",
    ["mythicdungeontools"]      = "战斗与PvP",
    ["mythicdungeontools_ui"]   = "战斗与PvP",
    ["diguatimelineaudiohelper"]= "战斗与PvP",
    ["diguatimeline"]           = "战斗与PvP",
    ["abilitytimeline"]         = "战斗与PvP",
    ["cooldowndone"]            = "战斗与PvP",
    ["coolinator"]              = "战斗与PvP",
    ["minimalistcooldownedge"]  = "战斗与PvP",
    ["spellalerttimer"]         = "战斗与PvP",
    ["targetnameplateindicator"]= "战斗与PvP",
    ["rangedisplay"]            = "战斗与PvP",
    ["rangedisplay_options"]    = "战斗与PvP",
    ["battlegroundenemiesfixed"]= "战斗与PvP",
    ["battlegroundenemies"]     = "战斗与PvP",
    ["sarena"]                  = "战斗与PvP",
    ["sarena_reloaded"]         = "战斗与PvP",
    ["pvp sound"]               = "战斗与PvP",
    ["pvpsound"]                = "战斗与PvP",
    ["mmr tracker"]             = "战斗与PvP",
    ["mmrtracker"]              = "战斗与PvP",
    ["betterqueuetimers"]       = "战斗与PvP",
    ["sweepyboop"]              = "战斗与PvP",
    ["miniauras"]               = "战斗与PvP",
    ["minicc"]                  = "战斗与PvP",
    ["mini"]                    = "战斗与PvP",
    ["minitattarget"]           = "战斗与PvP",
    ["minitabtarget"]           = "战斗与PvP",
    ["omnicc"]                  = "战斗与PvP",
    ["omnicd"]                  = "战斗与PvP",
    ["plater"]                  = "战斗与PvP",
    ["hekili"]                  = "战斗与PvP",
    ["threatclassic2"]          = "战斗与PvP",
    ["gladiatorlossa"]          = "战斗与PvP",
    ["163ui_combattimer"]       = "战斗与PvP",

    -- 2. 用户界面 (CurseForge: User Interface - 综合界面百宝箱、框体移动、动作条、提示与美化)
    ["leatrix_plus"]            = "用户界面",
    ["blizzmove"]               = "用户界面",
    ["blizzmove_debug"]         = "用户界面",
    ["betterblizzframes"]       = "用户界面",
    ["plumber"]                 = "用户界面",
    ["tullarange"]              = "用户界面",
    ["tullarange_config"]       = "用户界面",
    ["advancedinterfaceoptions"]= "用户界面",
    ["ellesmereui"]             = "用户界面",
    ["duoui"]                   = "用户界面",
    ["duoaddonmanager"]         = "用户界面",
    ["duoui_addonmanager"]      = "用户界面",
    ["duoui_data"]              = "用户界面",
    ["duoui_eui"]               = "用户界面",
    ["duoui_media"]             = "用户界面",
    ["elvui"]                   = "用户界面",
    ["ndui"]                    = "用户界面",
    ["tukui"]                   = "用户界面",
    ["bartender4"]              = "用户界面",
    ["dominos"]                 = "用户界面",
    ["shadowedunitframes"]      = "用户界面",
    ["masque"]                  = "用户界面",
    ["tinypad"]                 = "用户界面",
    ["tiptac"]                  = "用户界面",

    -- 3. 社交与组队 (CurseForge: Guild & Social - 集合石、聊天增强、邮件与数据同步)
    ["meetingstone"]            = "社交与组队",
    ["meetingstoneex"]          = "社交与组队",
    ["meetinghorn"]             = "社交与组队",
    ["meetinghorn_ellesmereui"] = "社交与组队",
    ["postal"]                  = "社交与组队",
    ["whisperpop"]              = "社交与组队",
    ["lnuichat"]                = "社交与组队",
    ["teleportannouncer"]       = "社交与组队",
    ["abyteamstats"]            = "社交与组队",
    ["dd"]                      = "社交与组队",
    ["dd_datasync"]             = "社交与组队",
    ["ddsync"]                  = "社交与组队",
    ["wcl_player_score"]        = "社交与组队",
    ["wim"]                     = "社交与组队",
    ["cell_chat"]               = "社交与组队",

    -- 4. 背包与物品 (CurseForge: Bags & Inventory - 整合背包、物品整理与银行)
    ["baganator"]               = "背包与物品",
    ["syndicator"]              = "背包与物品",
    ["bagnon"]                  = "背包与物品",
    ["betterbags"]              = "背包与物品",
    ["adibags"]                 = "背包与物品",
    ["arkinventory"]            = "背包与物品",
    ["alreadyknown"]            = "背包与物品",

    -- 5. 拍卖与商业 (CurseForge: Auctions & Economy - 拍卖行、专业助手与商人购买)
    ["krowi_extendedvendorui"]  = "拍卖与商业",
    ["buyemall"]                = "拍卖与商业",
    ["yui_auctionhelper"]       = "拍卖与商业",
    ["auctionator"]             = "拍卖与商业",
    ["tradeskillmaster"]        = "拍卖与商业",
    ["auctioneer"]              = "拍卖与商业",
    ["gathering"]               = "拍卖与商业",

    -- 6. 地图与探索 (CurseForge: Map & Navigation - 地图标记、航线、稀有侦测与传送)
    ["handynotes"]              = "地图与探索",
    ["mapster"]                 = "地图与探索",
    ["roymapguide"]             = "地图与探索",
    ["worldflightmap"]          = "地图与探索",
    ["rarescanner"]             = "地图与探索",
    ["silverdragon"]            = "地图与探索",
    ["gathermate2"]             = "地图与探索",
    ["teleportmenu"]            = "地图与探索",
    ["waypointui"]              = "地图与探索",
    ["city guide"]              = "地图与探索",
    ["cityguide"]               = "地图与探索",
    ["tomtom"]                  = "地图与探索",
    ["rareshare"]               = "地图与探索",

    -- 7. 任务与成就 (CurseForge: Quests & Leveling - 任务自动交接、升级指引与成就追踪)
    ["autoturnin"]              = "任务与成就",
    ["btwquests"]               = "任务与成就",
    ["world quest tab"]         = "任务与成就",
    ["worldquesttab"]           = "任务与成就",
    ["worldquesttracker"]       = "任务与成就",
    ["questie"]                 = "任务与成就",
    ["btwevents"]               = "任务与成就",
    ["allthethings"]            = "任务与成就",

    -- 8. 装备与属性 (CurseForge: Gear & Stats - 装等评分、配装属性与钥石掉落)
    ["gearinsight"]             = "装备与属性",
    ["keystoneloot"]            = "装备与属性",
    ["iteminfooverlay"]         = "装备与属性",
    ["pawn"]                    = "装备与属性",
    ["itemrack"]                = "装备与属性",
    ["simcraft"]                = "装备与属性",
    ["merinspect"]              = "装备与属性",

    -- 9. 藏品与趣味 (CurseForge: Collections & Minigames - 坐骑宠物与神器趣味追踪)
    ["remix artifact tracker"]  = "藏品与趣味",
    ["remixartifacttracker"]    = "藏品与趣味",
    ["rarity"]                  = "藏品与趣味",
    ["pettracker"]              = "藏品与趣味",

    -- 10. 开发与系统 (CurseForge: Development & System - 报错抓取、ID显示与前置库)
    ["!buggrabber"]             = "开发与系统",
    ["buggrabber"]              = "开发与系统",
    ["bugsack"]                 = "开发与系统",
    ["idtip"]                   = "开发与系统",
    ["devtool"]                 = "开发与系统",
    ["ace3"]                    = "开发与系统",
    ["163ui_info"]              = "开发与系统",
}
ns.BUILTIN_CATEGORIES = BUILTIN_CATEGORIES

local CATEGORY_MAP = {
    -- 严格映射 CurseForge 官方英文分类及国内常用别名至标准 10 大分类
    ["combat"]                  = "战斗与PvP",
    ["boss encounters"]         = "战斗与PvP",
    ["boss"]                    = "战斗与PvP",
    ["pvp"]                     = "战斗与PvP",
    ["arena"]                   = "战斗与PvP",
    ["battleground"]            = "战斗与PvP",
    ["battlegrounds"]           = "战斗与PvP",
    ["class"]                   = "战斗与PvP",
    ["buffs & debuffs"]         = "战斗与PvP",
    ["buffs"]                   = "战斗与PvP",
    ["debuffs"]                 = "战斗与PvP",
    ["damage meters"]           = "战斗与PvP",
    ["combat alerts"]           = "战斗与PvP",
    ["cooldowns"]               = "战斗与PvP",

    ["user interface"]          = "用户界面",
    ["interface"]               = "用户界面",
    ["action bars"]             = "用户界面",
    ["unit frames"]             = "用户界面",
    ["unitframes"]              = "用户界面",
    ["nameplates"]              = "战斗与PvP",
    ["tooltips"]                = "用户界面",
    ["artwork"]                 = "用户界面",
    ["bars"]                    = "用户界面",
    ["frames"]                  = "用户界面",

    ["guild"]                   = "社交与组队",
    ["social"]                  = "社交与组队",
    ["chat & communication"]    = "社交与组队",
    ["chat"]                    = "社交与组队",
    ["mail"]                    = "社交与组队",
    ["communication"]           = "社交与组队",

    ["bags & inventory"]        = "背包与物品",
    ["bags"]                    = "背包与物品",
    ["inventory"]               = "背包与物品",
    ["item"]                    = "背包与物品",
    ["items"]                   = "背包与物品",

    ["professions"]             = "拍卖与商业",
    ["auction & economy"]       = "拍卖与商业",
    ["auction"]                 = "拍卖与商业",
    ["economy"]                 = "拍卖与商业",
    ["trades"]                  = "拍卖与商业",
    ["vendor"]                  = "拍卖与商业",

    ["map & minimap"]           = "地图与探索",
    ["map"]                     = "地图与探索",
    ["maps"]                    = "地图与探索",
    ["minimap"]                 = "地图与探索",
    ["navigation"]              = "地图与探索",
    ["coordinates"]             = "地图与探索",

    ["quests & leveling"]       = "任务与成就",
    ["quest"]                   = "任务与成就",
    ["quests"]                  = "任务与成就",
    ["leveling"]                = "任务与成就",
    ["achievements"]            = "任务与成就",
    ["achievement"]             = "任务与成就",

    ["gear"]                    = "装备与属性",
    ["stats"]                   = "装备与属性",
    ["equipment"]               = "装备与属性",

    ["collections"]             = "藏品与趣味",
    ["minigames"]               = "藏品与趣味",
    ["mounts"]                  = "藏品与趣味",
    ["pets"]                    = "藏品与趣味",

    ["development tools"]       = "开发与系统",
    ["developer"]               = "开发与系统",
    ["system"]                  = "开发与系统",
    ["libraries"]               = "开发与系统",
    ["miscellaneous"]           = "综合杂项",
}
ns.CATEGORY_MAP = CATEGORY_MAP

local function ResolveCategory(addonName, rawCategory, title)
    local lower = addonName:lower()
    local tLower = (title or ""):lower()

    -- 1. 精准内置字典直通 (最精准的官方 CurseForge 映射)
    if BUILTIN_CATEGORIES[lower] then return BUILTIN_CATEGORIES[lower] end

    -- 2. 特征子模块前缀智能透传 (如 HandyNotes_xxx 自动归入 地图与探索)
    if lower:find("^handynotes") or lower:find("^gathermate2") or lower:find("^silverdragon") then return "地图与探索" end
    if lower:find("^bigwigs") or lower:find("^littlewigs") or lower:find("^dbm") or lower:find("^details") then return "战斗与PvP" end
    if lower:find("^btwquests") then return "任务与成就" end
    if lower:find("^gearinsight") then return "装备与属性" end
    if lower:find("^duoui") or lower:find("^ellesmere") then return "用户界面" end

    -- 3. 英文名与中文字符串特征语义匹配 (严格遵循 CurseForge 分类标准体系)
    if lower:find("handynotes") or lower:find("city guide") or lower:find("cityguide") or lower:find("map") or lower:find("radar") or lower:find("waypoint") or lower:find("teleport") or lower:find("flight") or lower:find("scanner") or tLower:find("地图") or tLower:find("导航") or tLower:find("路径") or tLower:find("传送") then return "地图与探索" end
    if lower:find("details") or lower:find("dbm") or lower:find("bigwigs") or lower:find("littlewigs") or lower:find("weakauras") or lower:find("wa") or lower:find("cell") or lower:find("clique") or lower:find("mrt") or lower:find("keystone") or lower:find("plater") or lower:find("nameplate") or lower:find("threat") or lower:find("combat") or lower:find("alert") or lower:find("cooldown") or lower:find("timer") or lower:find("range") or tLower:find("战斗") or tLower:find("首领") or tLower:find("团队") or tLower:find("减益") or tLower:find("增益") or tLower:find("冷却") or tLower:find("报警") or tLower:find("打断") or tLower:find("副本") or tLower:find("语音") or tLower:find("大秘境") or tLower:find("钥石") then return "战斗与PvP" end
    if lower:find("pvp") or lower:find("arena") or lower:find("battleground") or lower:find("mmr") or lower:find("queue") or lower:find("target") or lower:find("aura") or lower:find("timeline") or tLower:find("竞技场") or tLower:find("战场") then return "战斗与PvP" end
    if lower:find("meeting") or lower:find("集合石") or tLower:find("集合石") or lower:find("datasync") or tLower:find("数据同步") or lower:find("chat") or lower:find("whisper") or lower:find("postal") or lower:find("mail") or lower:find("wim") or tLower:find("聊天") or tLower:find("组队") or tLower:find("公会") or tLower:find("邮件") or tLower:find("好友") then return "社交与组队" end
    if lower:find("syndicator") or lower:find("bagnon") or lower:find("bag") or lower:find("item") or lower:find("inventory") or lower:find("bank") or tLower:find("背包") or tLower:find("物品") or tLower:find("银行") then return "背包与物品" end
    if lower:find("auction") or lower:find("tsm") or lower:find("gold") or lower:find("vendor") or lower:find("profession") or lower:find("craft") or lower:find("buy") or tLower:find("拍卖") or tLower:find("商业") or tLower:find("专业") or tLower:find("商人") or tLower:find("购物") then return "拍卖与商业" end
    if lower:find("worldquest") or lower:find("quest") or lower:find("achievement") or lower:find("turnin") or tLower:find("任务") or tLower:find("成就") or tLower:find("升级") then return "任务与成就" end
    if lower:find("gear") or lower:find("pawn") or lower:find("inspect") or lower:find("stat") or lower:find("loot") or tLower:find("装备") or tLower:find("属性") or tLower:find("装等") or tLower:find("掉落") then return "装备与属性" end
    if lower:find("remix") or lower:find("tracker") or lower:find("pet") or lower:find("mount") or lower:find("toy") or lower:find("transmog") or tLower:find("神器") or tLower:find("藏品") or tLower:find("坐骑") or tLower:find("宠物") or tLower:find("玩具") or tLower:find("幻化") then return "藏品与趣味" end
    if lower:find("plumber") or lower:find("duoui") or lower:find("ellesmere") or lower:find("elvui") or lower:find("ndui") or lower:find("unitframe") or lower:find("skin") or lower:find("actionbar") or lower:find("button") or lower:find("move") or lower:find("tooltip") or lower:find("tiptac") or lower:find("pad") or tLower:find("皮肤") or tLower:find("界面") or tLower:find("动作条") or tLower:find("框体") or tLower:find("移动") or tLower:find("提示") or tLower:find("百宝箱") then return "用户界面" end
    if lower:find("bug") or lower:find("debug") or lower:find("dev") or lower:find("idtip") or lower:find("lib") or lower:find("ace3") or tLower:find("开发") or tLower:find("调试") or tLower:find("错误") or tLower:find("报错") or tLower:find("系统") then return "开发与系统" end

    -- 4. 从 TOC 元数据严格归一化映射 (彻底杜绝生僻小分类泄露)
    if rawCategory and rawCategory ~= "" then
        local catLower = rawCategory:lower():trim()
        if CATEGORY_MAP[catLower] then return CATEGORY_MAP[catLower] end
        if rawCategory:find("界面") or rawCategory:find("UI") or rawCategory:find("动作条") or rawCategory:find("框体") then return "用户界面" end
        if rawCategory:find("战斗") or rawCategory:find("团队") or rawCategory:find("首领") or rawCategory:find("PvP") or rawCategory:find("增益") or rawCategory:find("减益") or rawCategory:find("仇恨") then return "战斗与PvP" end
        if rawCategory:find("背包") or rawCategory:find("物品") or rawCategory:find("银行") then return "背包与物品" end
        if rawCategory:find("商业") or rawCategory:find("拍卖") or rawCategory:find("专业") or rawCategory:find("经济") then return "拍卖与商业" end
        if rawCategory:find("地图") or rawCategory:find("小地图") or rawCategory:find("探索") or rawCategory:find("导航") then return "地图与探索" end
        if rawCategory:find("任务") or rawCategory:find("成就") or rawCategory:find("升级") then return "任务与成就" end
        if rawCategory:find("装备") or rawCategory:find("属性") or rawCategory:find("装等") then return "装备与属性" end
        if rawCategory:find("社交") or rawCategory:find("公会") or rawCategory:find("组队") or rawCategory:find("聊天") or rawCategory:find("邮件") then return "社交与组队" end
        if rawCategory:find("藏品") or rawCategory:find("坐骑") or rawCategory:find("宠物") or rawCategory:find("玩具") then return "藏品与趣味" end
        if rawCategory:find("开发") or rawCategory:find("系统") or rawCategory:find("调试") or rawCategory:find("支持库") then return "开发与系统" end
    end
    return "综合杂项"
end
ns.ResolveCategory = ResolveCategory
