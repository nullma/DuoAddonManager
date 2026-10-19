-------------------------------------------------------------------------------
--  Engine\Scanner.lua -- 插件遍历扫描、母子层级聚类、内存计算与排序引擎
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...

local DuoUI = ns.DuoUI
local C_AddOns = ns.C_AddOns or _G.C_AddOns or {}

-- 安全读取单体插件内存占用 (KB)
local function SafeGetMemory(index, name)
    if not GetAddOnMemoryUsage then return 0 end
    if index and index > 0 then
        local mem = GetAddOnMemoryUsage(index)
        if mem and type(mem) == "number" then return mem end
    end
    if name then
        local mem2 = GetAddOnMemoryUsage(name)
        if mem2 and type(mem2) == "number" then return mem2 end
    end
    return 0
end
ns.SafeGetMemory = SafeGetMemory

-- 格式化内存大小显示
local function FormatMemory(kbytes, styled)
    if not kbytes or kbytes <= 0 then
        return styled and "|cff6c7a8e0|r |cff4a5568KB|r" or "0 KB"
    end
    if kbytes >= 1024 then
        local val = string.format("%.1f", kbytes / 1024)
        return styled and (string.format("|cffe0e6ed%s|r |cff5a687aMB|r", val)) or (val .. " MB")
    else
        local val = string.format("%d", math.floor(kbytes))
        return styled and (string.format("|cffe0e6ed%s|r |cff5a687aKB|r", val)) or (val .. " KB")
    end
end
ns.FormatMemory = FormatMemory

-- 会话级排序快照 (保证在打开面板操作期间，卡片绝对静止在当前鼠标指针下，不会因启停而突然位移跳动)
local sessionSortOrder = {}
local function ResetSessionSortOrder()
    table.wipe(sessionSortOrder)
end
ns.sessionSortOrder = sessionSortOrder
ns.ResetSessionSortOrder = ResetSessionSortOrder
DuoUI.ResetSessionSortOrder = ResetSessionSortOrder

-- 全量插件扫描与归拢聚类核心 (防抖节流内存计算，杜绝卡片点击与打字微卡顿)
local lastMemoryUpdate = 0
local function ScanAddonsData(forceMemory)
    local now = (GetTime and GetTime()) or 0
    if forceMemory or (now - lastMemoryUpdate >= 2.0) then
        collectgarbage("collect")
        if UpdateAddOnMemoryUsage then pcall(UpdateAddOnMemoryUsage) end
        lastMemoryUpdate = now
    end

    local num = C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or 0
    local rawList = {}
    local byName = {}

    local metadataCache = ns.metadataCache
    if not metadataCache then
        metadataCache = {}
        ns.metadataCache = metadataCache
    end

    for i = 1, num do
        local name, title, notes, loadable, reason, security = C_AddOns.GetAddOnInfo(i)
        if name then
            local meta = metadataCache[name]
            if not meta then
                local rawCategory = C_AddOns.GetAddOnMetadata and (
                    C_AddOns.GetAddOnMetadata(i, "Category") or
                    C_AddOns.GetAddOnMetadata(i, "X-Category") or
                    C_AddOns.GetAddOnMetadata(i, "Group")
                )
                local cleanTitle = title and title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):trim() or name
                local category = ns.ResolveCategory(name, rawCategory, cleanTitle)
                local icon = C_AddOns.GetAddOnMetadata and (
                    C_AddOns.GetAddOnMetadata(i, "IconTexture") or
                    C_AddOns.GetAddOnMetadata(i, "IconAtlas")
                )
                local version = C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(i, "Version")
                local author = C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(i, "Author")
                local deps = { C_AddOns.GetAddOnDependencies(i) }

                meta = {
                    title = title or name,
                    cleanTitle = cleanTitle,
                    notes = notes or "",
                    category = category,
                    icon = icon,
                    version = version,
                    author = author,
                    deps = deps,
                    isProtected = ns.IsProtected(name),
                }
                metadataCache[name] = meta
            end

            local enabled = ns.IsAddonEnabled(i)
            local isLoaded = C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(i)
            local isLOD = C_AddOns.IsAddOnLoadOnDemand and C_AddOns.IsAddOnLoadOnDemand(i)
            local mem = SafeGetMemory(i, name)

            local entry = {
                index       = i,
                name        = name,
                title       = meta.title,
                cleanTitle  = meta.cleanTitle,
                notes       = meta.notes,
                version     = meta.version,
                author      = meta.author,
                enabled     = enabled,
                isLoaded    = isLoaded,
                isLOD       = isLOD,
                loadable    = loadable,
                reason      = reason,
                mem         = mem,
                deps        = meta.deps,
                category    = meta.category,
                icon        = meta.icon,
                isProtected = meta.isProtected,
                children    = {},
            }
            rawList[#rawList + 1] = entry
            byName[name] = entry
            byName[name:lower()] = entry
        end
    end

    local isChild = {}

    -- 1. 优先按名称前缀/母子命名结构聚类 (让主套件优先成为母项，如 DuoUI 是 DuoUI_Media/Data/EUI 的母项)
    local sortedForPrefix = {}
    for _, e in ipairs(rawList) do sortedForPrefix[#sortedForPrefix + 1] = e end
    table.sort(sortedForPrefix, function(a, b) return #a.name < #b.name end)

    for _, entry in ipairs(sortedForPrefix) do
        if not isChild[entry.name] then
            local sepIdx = entry.name:find("[-_]")
            if sepIdx then
                local prefix = entry.name:sub(1, sepIdx - 1)
                local parentEntry = byName[prefix] or byName[prefix:lower()]
                if not parentEntry and prefix:upper() == "DBM" then
                    parentEntry = byName["DBM-Core"] or byName["dbm-core"] or byName["DBM"]
                end
                if parentEntry and parentEntry ~= entry and not isChild[parentEntry.name] then
                    parentEntry.children[#parentEntry.children + 1] = entry
                    isChild[entry.name] = true
                end
            end
        end
    end

    -- 2. 特殊插件附属关系纠偏 (MiniCC -> MiniAuras, EllesmereUI Skins -> EllesmereUI)
    if (byName["MiniCC"] or byName["minicc"]) and (byName["MiniAuras"] or byName["miniauras"]) then
        local p = byName["MiniAuras"] or byName["miniauras"]
        local c = byName["MiniCC"] or byName["minicc"]
        if not isChild[c.name] and p ~= c then
            p.children[#p.children + 1] = c
            isChild[c.name] = true
        end
    end
    -- 将含有 EllesmereUI 皮肤/MeetingHorn 皮肤的插件吸纳进 EllesmereUI
    if byName["EllesmereUI"] or byName["ellesmereui"] then
        local euiParent = byName["EllesmereUI"] or byName["ellesmereui"]
        for _, entry in ipairs(rawList) do
            if not isChild[entry.name] and entry ~= euiParent then
                local el = entry.name:lower()
                local tl = entry.cleanTitle:lower()
                if (el:find("ellesmereui") and el ~= "ellesmereui") or tl:find("ellesmereui 皮肤") or tl:find("ellesmereui皮肤") then
                    euiParent.children[#euiParent.children + 1] = entry
                    isChild[entry.name] = true
                end
            end
        end
    end

    -- 3. 依赖关系聚类 (注意：主干插件/受保护插件绝不能被媒体库/数据包逆向吞并为子项)
    for _, entry in ipairs(rawList) do
        local lowerName = entry.name:lower()
        if not isChild[entry.name] and lowerName ~= "duoui" and lowerName ~= "ellesmereui" and #entry.deps > 0 then
            for _, depName in ipairs(entry.deps) do
                local depLower = depName:lower()
                local isSubmoduleOfEntry = depLower:match("^" .. lowerName .. "[-_]")
                local isLibOrMedia = depLower:find("media") or depLower:find("data")
                local targetParent = byName[depName] or byName[depLower]
                if not isSubmoduleOfEntry and not isLibOrMedia and targetParent and targetParent.name ~= entry.name and not isChild[targetParent.name] then
                    targetParent.children[#targetParent.children + 1] = entry
                    isChild[entry.name] = true
                    break
                end
            end
        end
    end

    -- 确保 DuoUI 与 EllesmereUI 永远是顶级母项，不受依赖反向吸纳
    isChild["DuoUI"] = nil
    isChild["EllesmereUI"] = nil

    local categories = {}
    local catMap = {}
    local allEntries = {}
    local totalMemory = 0
    local totalEnabled = 0

    local function GetCategoryBucket(catName)
        if not catMap[catName] then
            local bucket = {
                name     = catName,
                entries  = {},
                totalMem = 0,
            }
            catMap[catName] = bucket
            categories[#categories + 1] = bucket
        end
        return catMap[catName]
    end

    for _, entry in ipairs(rawList) do
        totalMemory = totalMemory + entry.mem
        if entry.enabled then totalEnabled = totalEnabled + 1 end

        if not isChild[entry.name] then
            local groupMem = entry.mem
            local groupEnabled = entry.enabled and 1 or 0
            for _, child in ipairs(entry.children) do
                groupMem = groupMem + child.mem
                if child.enabled then groupEnabled = groupEnabled + 1 end
            end
            entry.groupMem = groupMem
            entry.groupEnabledCount = groupEnabled

            allEntries[#allEntries + 1] = entry
            local bucket = GetCategoryBucket(entry.category)
            bucket.entries[#bucket.entries + 1] = entry
            bucket.totalMem = bucket.totalMem + groupMem
        end
    end

    -- 严格按照 CurseForge 核心热度与用户心智模型排序
    local ORDER_WEIGHTS = {
        ["战斗与PvP"]   = 1,
        ["用户界面"]     = 2,
        ["社交与组队"]   = 3,
        ["背包与物品"]   = 4,
        ["拍卖与商业"]   = 5,
        ["地图与探索"]   = 6,
        ["任务与成就"]   = 7,
        ["装备与属性"]   = 8,
        ["藏品与趣味"]   = 9,
        ["开发与系统"]   = 10,
        ["综合杂项"]     = 99,
    }

    table.sort(categories, function(a, b)
        local wa = ORDER_WEIGHTS[a.name] or 50
        local wb = ORDER_WEIGHTS[b.name] or 50
        if wa ~= wb then return wa < wb end
        return a.name < b.name
    end)

    local parentEnabledCount = 0
    for _, entry in ipairs(allEntries) do
        if entry.enabled or entry.isProtected then
            parentEnabledCount = parentEnabledCount + 1
        end
        if #entry.children > 0 then
            table.sort(entry.children, function(ca, cb)
                local aActive = ca.enabled and 1 or 0
                local bActive = cb.enabled and 1 or 0
                if aActive ~= bActive then return aActive > bActive end
                if math.abs((ca.mem or 0) - (cb.mem or 0)) > 0.001 then
                    return (ca.mem or 0) > (cb.mem or 0)
                end
                return (ca.cleanTitle or ca.name):lower() < (cb.cleanTitle or cb.name):lower()
            end)
        end
    end

    -- 会话级排序位置锁定：在打开窗口期间锁定顺序，点击卡片启停不发生跳变；关闭窗口或主动刷新时重置顺序
    local function SortEntries(a, b)
        if sessionSortOrder[a.name] and sessionSortOrder[b.name] then
            return sessionSortOrder[a.name] < sessionSortOrder[b.name]
        elseif sessionSortOrder[a.name] then
            return true
        elseif sessionSortOrder[b.name] then
            return false
        end

        -- 1. 已启用优先 (已启用插件排在前面，停用插件排在后面)
        local aActive = (a.enabled or a.isProtected) and 1 or 0
        local bActive = (b.enabled or b.isProtected) and 1 or 0
        if aActive ~= bActive then
            return aActive > bActive
        end
        -- 2. 默认按内存从大到小降序排列
        local aMem = a.groupMem or 0
        local bMem = b.groupMem or 0
        if math.abs(aMem - bMem) > 0.001 then
            return aMem > bMem
        end
        return (a.cleanTitle or a.name):lower() < (b.cleanTitle or b.name):lower()
    end

    for _, bucket in ipairs(categories) do
        table.sort(bucket.entries, SortEntries)
    end
    table.sort(allEntries, SortEntries)

    -- 如果当前会话尚未建立顺序索引，记录当前完整排序
    local hasSessionOrder = false
    for _ in pairs(sessionSortOrder) do hasSessionOrder = true; break end
    if not hasSessionOrder then
        for idx, entry in ipairs(allEntries) do
            sessionSortOrder[entry.name] = idx
        end
    end

    return categories, allEntries, totalMemory, parentEnabledCount, #allEntries, totalEnabled, num
end
ns.ScanAddonsData = ScanAddonsData
