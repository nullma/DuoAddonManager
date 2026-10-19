-------------------------------------------------------------------------------
--  Modules\Minimap.lua -- 极简纯净小地图悬浮坞与小地图按钮
-------------------------------------------------------------------------------
local ADDON_NAME, ns = ...
local DuoUI = ns.DuoUI
local L = ns.L or {}

local MinimapCollector = {
    collectedButtons = {},
    collectedSet = {},
    ignoredNames = {
        ["DuoAddonManagerMinimapButton"] = true,
        ["DuoAddonManager_MinimapButton"] = true,
        ["Minimap"] = true,
        ["MinimapBackdrop"] = true,
        ["MinimapCluster"] = true,
        ["MiniMapTracking"] = true,
        ["MiniMapTrackingButton"] = true,
        ["MiniMapTrackingDropDown"] = true,
        ["TimeManagerClockButton"] = true,
        ["GameTimeFrame"] = true,
        ["MinimapZoomIn"] = true,
        ["MinimapZoomOut"] = true,
        ["MiniMapWorldMapButton"] = true,
        ["QueueStatusMinimapButton"] = true,
        ["QueueStatusButton"] = true,
        ["ExpansionLandingPageMinimapButton"] = true,
        ["GarrisonLandingPageMinimapButton"] = true,
        ["AddonCompartmentFrame"] = true,
        ["MiniMapMailFrame"] = true,
        ["MiniMapVoiceChatFrame"] = true,
        ["MiniMapRecordingButton"] = true,
        ["LeaPlusGlobalMinimapCombinedButtonFrame"] = true,
        ["LeaPlusGlobalMiniBtn"] = true,
    }
}
ns.MinimapCollector = MinimapCollector

-- 1. 创建 AM 专属小地图按钮 (紧凑 28x28，精致细圆环 + 高清白金齿轮)
local minimapBtn = CreateFrame("Button", "DuoAddonManager_MinimapButton", Minimap)
minimapBtn:SetSize(28, 28)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("RightButton")
minimapBtn:SetMovable(true)

-- 外圈圆形遮罩
local outerMask = minimapBtn:CreateMaskTexture()
outerMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
outerMask:SetAllPoints()

-- 外圈精细圆环 (微弱主题色，1px 极细光环)
local outerRing = minimapBtn:CreateTexture(nil, "BACKGROUND", nil, -8)
outerRing:SetAllPoints()
local tr, tg, tb = ns.GetThemeAccent()
outerRing:SetColorTexture(tr, tg, tb, 0.9)
outerRing:AddMaskTexture(outerMask)

-- 内圈暗色底盘 (26x26，仅留 1px 细环)
local innerMask = minimapBtn:CreateMaskTexture()
innerMask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
innerMask:SetSize(26, 26)
innerMask:SetPoint("CENTER")

local innerBg = minimapBtn:CreateTexture(nil, "BACKGROUND", nil, -7)
innerBg:SetSize(26, 26)
innerBg:SetPoint("CENTER")
innerBg:SetColorTexture(0.08, 0.09, 0.12, 1)
innerBg:AddMaskTexture(innerMask)

-- 单个高精度齿轮 (22x22，饱满居中)
local btnIcon = minimapBtn:CreateTexture(nil, "ARTWORK")
btnIcon:SetSize(22, 22)
btnIcon:SetPoint("CENTER")
btnIcon:SetTexture("Interface\\WorldMap\\Gear_64")
btnIcon:SetTexCoord(0, 0.5, 0, 0.5)
btnIcon:SetVertexColor(0.95, 0.95, 0.97, 1)

-- 悬停半透明高光
local btnHighlight = minimapBtn:CreateTexture(nil, "HIGHLIGHT")
btnHighlight:SetAllPoints()
btnHighlight:SetColorTexture(1, 1, 1, 0.16)
btnHighlight:AddMaskTexture(outerMask)

-- 围绕小地图位置计算与拖动记忆
local function UpdateMinimapButtonPosition()
    local db = ns.GetDB()
    local angle = (db and db.minimapPos) or 220
    local rad = math.rad(angle)
    local w = (Minimap:GetWidth() or 180) / 2 + 4
    local h = (Minimap:GetHeight() or 180) / 2 + 4
    minimapBtn:ClearAllPoints()
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(rad) * w, math.sin(rad) * h)
end
ns.UpdateMinimapButtonPosition = UpdateMinimapButtonPosition

minimapBtn:SetScript("OnDragStart", function(self)
    self.isDragging = true
    self.wasDragging = true
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        if not mx or not my then return end
        local cx, cy = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale() or (UIParent and UIParent:GetEffectiveScale()) or 1
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if angle < 0 then angle = angle + 360 end
        local db = ns.GetDB()
        if db then db.minimapPos = angle end
        UpdateMinimapButtonPosition()
    end)
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self.isDragging = false
    self:SetScript("OnUpdate", nil)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.15, function()
            self.wasDragging = false
        end)
    else
        self.wasDragging = false
    end
end)

-- 2. 创建极简图标坞 (现代暗黑微光模块化卡槽风格)
local drawer = CreateFrame("Frame", "DuoAddonManager_CollectorDrawer", UIParent, "BackdropTemplate")
drawer:SetFrameStrata("DIALOG")
drawer:SetFrameLevel(100)
drawer:SetClampedToScreen(true)
drawer:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
drawer:SetBackdropColor(0.07, 0.08, 0.11, 0.96)
drawer:SetBackdropBorderColor(0.22, 0.25, 0.32, 0.85)
drawer:Hide()
ns.minimapDrawer = drawer

-- 内部容器均匀边距 (四周规整 6px，保证呼吸感与工业级质感)
local iconContainer = CreateFrame("Frame", nil, drawer)
iconContainer:SetFrameStrata("DIALOG")
iconContainer:SetFrameLevel(105)
iconContainer:SetPoint("TOPLEFT", 6, -6)
iconContainer:SetPoint("BOTTOMRIGHT", -6, 6)

-- 动态对齐抽屉位置 (智能吸附在小地图按钮侧方)
local function UpdateDrawerAnchor()
    drawer:ClearAllPoints()
    drawer:SetBackdropBorderColor(0.24, 0.27, 0.35, 0.85)
    local x, y = minimapBtn:GetCenter()
    if not x or not y then
        drawer:SetPoint("TOPRIGHT", minimapBtn, "BOTTOMLEFT", -4, -4)
        return
    end
    local screenWidth = GetScreenWidth()
    if x > (screenWidth / 2) then
        drawer:SetPoint("TOPRIGHT", minimapBtn, "BOTTOMLEFT", -6, 2)
    else
        drawer:SetPoint("TOPLEFT", minimapBtn, "BOTTOMRIGHT", 6, 2)
    end
end

-- 浅层探测按钮的主图标材质
local function GetPrimaryIconTexture(btn)
    if not btn then return nil end
    local name = btn:GetName()
    if name and _G[name .. "Icon"] and _G[name .. "Icon"]:IsObjectType("Texture") then
        return _G[name .. "Icon"]
    end
    if btn.icon and btn.icon:IsObjectType("Texture") then return btn.icon end
    if btn.Icon and btn.Icon:IsObjectType("Texture") then return btn.Icon end
    if btn.texture and btn.texture:IsObjectType("Texture") then return btn.texture end
    if btn.Texture and btn.Texture:IsObjectType("Texture") then return btn.Texture end

    local normal = btn.GetNormalTexture and btn:GetNormalTexture()
    if normal and normal:IsObjectType("Texture") then
        local nTex = normal:GetTexture()
        if nTex and nTex ~= 136430 and nTex ~= 136467 and nTex ~= 136477 then
            return normal
        end
    end

    local highlight = btn.GetHighlightTexture and btn:GetHighlightTexture()
    local pushed = btn.GetPushedTexture and btn:GetPushedTexture()

    for _, r in ipairs({btn:GetRegions()}) do
        if r:IsObjectType("Texture") and r ~= highlight and r ~= pushed then
            local tex = r:GetTexture()
            local isBorder = (tex == 136430 or tex == 136467 or tex == 136477)
            if type(tex) == "string" and (tex:find("Border") or tex:find("border")) then
                isBorder = true
            end
            if not isBorder and r:IsShown() and r:GetAlpha() > 0 then
                return r
            end
        end
    end

    return nil
end

-- 深度规范化：仅在收集时执行一次 (幂等保护，杜绝重复扫描与重绘)
local function CleanAndRestoreButton(btn)
    if not btn or btn._duoCleaned then return end
    btn._duoCleaned = true

    btn:SetScale(1)

    if btn.SetFixedFrameStrata then
        btn:SetFixedFrameStrata(false)
    end
    btn:SetFrameStrata("DIALOG")

    if btn.SetFixedFrameLevel then
        btn:SetFixedFrameLevel(false)
    end
    btn:SetFrameLevel(iconContainer:GetFrameLevel() + 5)

    btn.showOnMouseover = false
    if btn.fadeOut then
        pcall(function() btn.fadeOut:Stop() end)
    end
    btn:SetAlpha(1)

    if btn.background then
        btn.background:Hide()
        btn.background:SetAlpha(0)
    end
    if btn.border then
        btn.border:Hide()
        btn.border:SetAlpha(0)
    end

    for _, region in ipairs({btn:GetRegions()}) do
        if region:IsObjectType("Texture") then
            local tex = region:GetTexture()
            local isBorder = false

            if tex == 136430 or tex == 136467 or tex == 136477 then
                isBorder = true
            elseif type(tex) == "string" and (tex:find("TrackingBorder") or tex:find("MiniMap%-Border") or tex:find("UI%-Minimap%-Border")) then
                isBorder = true
            elseif region == btn.border or region == btn.Border then
                isBorder = true
            elseif region == btn.background or region == btn.Background then
                isBorder = true
            end

            if isBorder then
                region:SetAlpha(0)
                region:Hide()
            else
                region:SetAlpha(1)
                if region.SetDesaturated then
                    region:SetDesaturated(false)
                end
                local r, g, b = region:GetVertexColor()
                if r and (r < 0.7 or g < 0.7 or b < 0.7) then
                    region:SetVertexColor(1, 1, 1, 1)
                end
            end
        end
    end

    if not btn._duoSlot then
        local slot = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        slot:SetAllPoints(btn)
        slot:SetFrameStrata("DIALOG")
        slot:SetFrameLevel(btn:GetFrameLevel() - 1)
        slot:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        slot:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
        slot:SetBackdropBorderColor(0.24, 0.27, 0.35, 0.75)
        btn._duoSlot = slot

        btn:HookScript("OnEnter", function()
            if btn._duoSlot then
                local ar, ag, ab = ns.GetThemeAccent()
                btn._duoSlot:SetBackdropBorderColor(ar, ag, ab, 0.9)
                btn._duoSlot:SetBackdropColor(0.18, 0.20, 0.26, 0.98)
            end
        end)
        btn:HookScript("OnLeave", function()
            if btn._duoSlot then
                btn._duoSlot:SetBackdropBorderColor(0.24, 0.27, 0.35, 0.75)
                btn._duoSlot:SetBackdropColor(0.12, 0.14, 0.18, 0.95)
            end
        end)
    end

    local primaryIcon = GetPrimaryIconTexture(btn)
    if primaryIcon then
        primaryIcon:ClearAllPoints()
        primaryIcon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        primaryIcon:SetSize(20, 20)
        pcall(function()
            primaryIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end)

        local bName = btn:GetName() or ""
        if bName:find("RaiderIO") then
            primaryIcon:SetVertexColor(0.85, 0.86, 0.88, 1)
        end
    end
end

-- 排列所有收纳的图标
local isLayouting = false
local function LayoutCollectedIcons()
    if isLayouting then return end
    isLayouting = true

    local buttons = {}
    for _, btn in ipairs(MinimapCollector.collectedButtons) do
        if btn and btn:IsShown() then
            table.insert(buttons, btn)
        end
    end

    local total = #buttons
    if total == 0 then
        drawer:SetSize(38, 38)
        isLayouting = false
        return
    end

    local cols = math.min(5, total)
    local rows = math.ceil(total / cols)

    local btnSize = 26
    local spacing = 4
    local padding = 6

    local width = cols * btnSize + (cols - 1) * spacing + padding * 2
    local height = rows * btnSize + (rows - 1) * spacing + padding * 2
    drawer:SetSize(width, height)

    for i, btn in ipairs(buttons) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        btn:ClearAllPoints()
        btn:SetParent(iconContainer)
        btn:SetScale(1)
        btn:SetSize(btnSize, btnSize)
        btn:SetPoint("TOPLEFT", iconContainer, "TOPLEFT", col * (btnSize + spacing), -row * (btnSize + spacing))
        btn:SetAlpha(1)
    end

    isLayouting = false
end

-- 收集单体图标
local function CollectButton(btn, name)
    if not btn or MinimapCollector.collectedSet[btn] then return end
    if name and MinimapCollector.ignoredNames[name] then return end
    if name and (name:match("^Minimap") or name:match("^MiniMap") or name:match("^QueueStatus") or name:match("^TimeManager") or name:match("^AddonCompartment")) then
        return
    end

    MinimapCollector.collectedSet[btn] = true
    table.insert(MinimapCollector.collectedButtons, btn)
    CleanAndRestoreButton(btn)
end

-- 扫描圆形小地图图标并加入收纳
local function ScanAndCollectMinimapIcons()
    local lib = _G.LibStub and _G.LibStub("LibDBIcon-1.0", true)
    if lib and lib.objects then
        for name, button in pairs(lib.objects) do
            if button and not MinimapCollector.ignoredNames[name] then
                CollectButton(button, name)
            end
        end
    end

    for _, child in ipairs({Minimap:GetChildren()}) do
        local name = child:GetName()
        if child:IsObjectType("Button") and not (name and MinimapCollector.ignoredNames[name]) then
            local w, h = child:GetSize()
            if w and w >= 15 and w <= 50 and h and h >= 15 and h <= 50 then
                CollectButton(child, name or "MinimapChild")
            end
        end
    end

    LayoutCollectedIcons()
end
ns.ScanAndCollectMinimapIcons = ScanAndCollectMinimapIcons

local function ToggleMinimapCollector()
    if drawer:IsShown() then
        drawer:Hide()
    else
        if InCombatLockdown and InCombatLockdown() then
            return
        end
        local r, g, b = ns.GetThemeAccent()
        outerRing:SetColorTexture(r, g, b, 0.9)
        drawer:SetBackdropBorderColor(r, g, b, 0.4)
        UpdateDrawerAnchor()
        ScanAndCollectMinimapIcons()
        drawer:Show()
    end
end
ns.ToggleMinimapCollector = ToggleMinimapCollector

-- 鼠标离开自然平滑隐藏 (移开 1.6 秒收起)
local hideTimer = 0
drawer:SetScript("OnUpdate", function(self, elapsed)
    if not self:IsShown() then return end

    local isOver = false
    if self.IsMouseOver and self:IsMouseOver() then
        isOver = true
    elseif minimapBtn.IsMouseOver and minimapBtn:IsMouseOver() then
        isOver = true
    end

    if isOver then
        hideTimer = 0
    else
        hideTimer = hideTimer + elapsed
        if hideTimer > 1.6 then
            self:Hide()
            hideTimer = 0
        end
    end
end)

-- 小地图按钮点击事件 (左键切换悬浮坞，右键打开管理器)
minimapBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        if not self.isDragging and not self.wasDragging then
            DuoUI.ToggleAddonManager()
        end
    else
        ToggleMinimapCollector()
    end
end)

minimapBtn:SetScript("OnEnter", function(self)
    local x = self:GetCenter()
    if x and x < (GetScreenWidth() / 2) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    else
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    end
    GameTooltip:ClearLines()
    local hex = ns.GetThemeAccentHex()
    GameTooltip:AddLine(string.format("|cff%s%s|r", hex, L["MINIMAP_TITLE"] or "Duo 插件管理与收纳"), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(string.format("|cff00ff00%s|r", L["MOUSE_LEFT_CLICK"] or "左键点击："), L["MINIMAP_LEFT_CLICK"] or "展开/收起小地图图标坞", 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine(string.format("|cff00ff00%s|r", L["MOUSE_RIGHT_CLICK"] or "右键点击："), L["MINIMAP_RIGHT_CLICK"] or "打开插件管理器主界面 (/am)", 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine(string.format("|cff00ff00%s|r", L["MOUSE_RIGHT_DRAG"] or "右键拖动："), L["MINIMAP_RIGHT_DRAG"] or "围绕小地图调整图标位置", 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:AddDoubleLine(string.format("|cff00ff00%s|r", L["FAST_COMMAND"] or "快速命令："), string.format("|cffffd100/rl|r %s", L["RELOAD_UI_SHORT"] or "快速重载界面"), 1, 1, 1, 0.8, 0.8, 0.8)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 延迟多次扫描，确保进游戏后延迟加载的单体插件也能被完美收纳
local scannerFrame = CreateFrame("Frame")
scannerFrame:RegisterEvent("PLAYER_LOGIN")
scannerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
scannerFrame:SetScript("OnEvent", function(self, event)
    if C_Timer and C_Timer.After then
        C_Timer.After(1, function()
            UpdateMinimapButtonPosition()
            ScanAndCollectMinimapIcons()
        end)
        C_Timer.After(3, function()
            ScanAndCollectMinimapIcons()
        end)
    else
        UpdateMinimapButtonPosition()
        ScanAndCollectMinimapIcons()
    end
end)

if IsLoggedIn and IsLoggedIn() then
    UpdateMinimapButtonPosition()
    ScanAndCollectMinimapIcons()
end
