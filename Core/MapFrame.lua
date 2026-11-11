-- The map frame logic: YatlasFrameTemplate is mixed into YatlasFrame and BigYatlasFrame by
-- YatlasFrame_Bootstrap (UI\Templates.lua). Constants are in Core\Constants.lua.
local pre = YATLAS_MINIMAP_PATH
local MINI2BIGX = YATLAS_MINI2BIG_X
local MINI2BIGY = YATLAS_MINI2BIG_Y
local _G = _G

YatlasFrameTemplate = {}

function YatlasFrameTemplate:OnLoad()
    local lm = self:GetName()
    local viewframe = _G[lm.."ViewFrame"]

    self.texturelayout = {}
    self.wzoom = 3
    self.hzoom = 3
    self.wzoom_real = 3
    self.hzoom_real = 3
    self.points = {}
    self.pointframes = {}

    self:RegisterForDrag("LeftButton")
    -- YATLAS_EVENTS: Core\Constants.lua. WORLD_MAP_UPDATE no longer exists, positions are polled in OnUpdate
    for _, event in ipairs(YATLAS_EVENTS) do
        self:RegisterEvent(event)
    end
    viewframe:RegisterForDrag("RightButton","LeftButton")
    viewframe:EnableMouseWheel(true)

    YAPoints_RegisterFrame(self:GetName())

    self.update_time = 0
end

function YatlasFrameTemplate:OnEvent(event, ...)
    local framename = self:GetName()

    if(event == "VARIABLES_LOADED") then
        if(YatlasOptions == nil) then
            YatlasOptions = {}
        end

        self:EnsureExistingOptions()

        self.opt = YatlasOptions.Frames[framename]
        self:SetZoom(self.opt.Zoom)
        self:SetMap(self.opt.Map)

        self:UpdateLock()
        self:SetAlpha(self.opt.Alpha)

        if(self.opt.track) then
            YatlasFramePlayerJumpButton_Seek(self, self.opt.track)
        end
    elseif(event == "AREA_POIS_UPDATED" or event == "PLAYER_ENTERING_WORLD") then
        -- area POIs changed, or a loading screen (login, phase): reload the landmarks. Both frames
        -- get the event: the reset is a cheap wipe, and the rebuilds are coalesced into one for the
        -- visible frames (the landmarks set loads them again on demand, Modules\landmarks.lua).
        Yatlas_ResetLandmarks()
        YAPoints_RequestUpdate()
        if(event == "PLAYER_ENTERING_WORLD" and self.opt) then
            self:OnWorldMapUpdate()
        end
    elseif(event == "ZONE_CHANGED_NEW_AREA") then
        if(self.opt) then
            self:OnWorldMapUpdate()
        end
    end
end

function YatlasFrameTemplate:EnsureExistingOptions()
    if(YatlasOptions.Frames == nil) then
        YatlasOptions.Frames = {}
    end

    local name = self:GetName()

    if(YatlasOptions.Frames[name] == nil) then
        YatlasOptions.Frames[name] = {}
    end

    for h,v in pairs(YA_FRAME_OPTION_DEFAULTS) do
        if(YatlasOptions.Frames[name][h] ~= nil) then
            -- don't do anything!
        elseif(YatlasOptions[h] ~= nil) then
            YatlasOptions.Frames[name][h] = YatlasOptions[h]
            YatlasOptions[h] = nil
        elseif(type(v) == "table") then
            -- don't copy reference.  copy value...unfortunately, we only
            -- copy one level deep, which seems good enough...
            YatlasOptions.Frames[name][h] = {}
            for x,k in pairs(v) do
                YatlasOptions.Frames[name][h][x] = k
            end
        else
            YatlasOptions.Frames[name][h] = v
        end
    end
end

function YatlasFrameTemplate:Toggle()
    local lm = self:GetName()

    if(YATLAS_NO_DATA) then
        DEFAULT_CHAT_FRAME:AddMessage("Yatlas: this game client (WOW_PROJECT_ID "
            ..tostring(YATLAS_CLIENT and YATLAS_CLIENT.projectID).. ") is not supported.")
        return
    end

    if(UIPanelWindows[lm] == nil) then
        if(self:IsShown()) then
            self:Hide()
        else
            self:Show()
        end
    else
        if(self:IsVisible()) then
            HideUIPanel(self)
        else
            ShowUIPanel(self)
        end
    end
end

function YatlasFrameDropDown_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED")
end

function YatlasFrameDropDown_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_Initialize(self, YatlasFrameDropDown_Initialize)
        UIDropDownMenu_SetSelectedID(self, 1)
        UIDropDownMenu_SetWidth(self, 150)
    end
end

-- Find the Yatlas frame (YatlasFrame or BigYatlasFrame) that owns a
-- drop-down. The menus used to be hard-wired to YatlasFrame, so the map and
-- zone menus of the large frame changed the (hidden) normal frame.
local function Yatlas_DropDownOwner(dropdown)
    if(type(dropdown) == "string") then
        dropdown = _G[dropdown]
    end
    while(dropdown and not dropdown.SetMap) do
        dropdown = dropdown:GetParent()
    end
    return dropdown or YatlasFrame
end

function YatlasFrameDropDown_Initialize(dropdown)
    local owner = Yatlas_DropDownOwner(dropdown or UIDROPDOWNMENU_INIT_MENU)
    local info
    for _,v in ipairs(Yatlas_GetMapList()) do
            info = {
                    text = v[1],
                    arg1 = owner,
                    arg2 = v[2],
                    checked = (owner.opt and owner.opt.Map == v[2]) or nil,
                    func = YatlasFrameDropDownButton_OnClick
            }
            UIDropDownMenu_AddButton(info)
    end
end

function YatlasFrameDropDownButton_OnClick(self, owner, map)
    if(owner and map) then
        return owner:SetMap(map)
    end
end

function YatlasFrameTemplate:ToggleLock()
    if(self.opt.Locked) then
        self.opt.Locked = false
    else
        self.opt.Locked = true
    end
    self:UpdateLock()
end

function YatlasFrameTemplate:UpdateLock()
    local btn = _G[self:GetName().."LockButton"]

    if(btn) then
        if(self.opt.Locked) then
            btn:SetNormalTexture(YATLAS_IMAGE_PATH.."LockButton-Locked-Up")
            btn:SetPushedTexture(YATLAS_IMAGE_PATH.."LockButton-Locked-Down")
        else
            btn:SetNormalTexture(YATLAS_IMAGE_PATH.."LockButton-Unlocked-Up")
            btn:SetPushedTexture(YATLAS_IMAGE_PATH.."LockButton-Unlocked-Down")
        end
    end
end

function YatlasFrameTemplate:SetMap(mapname)
    local lm = self:GetName()

    self.opt.Map = mapname

    local mapdropdown = _G[lm.."DropDown"]
    if(mapdropdown) then
        for i,v in ipairs(Yatlas_GetMapList()) do
            if(v[2] == mapname) then
                UIDropDownMenu_SetSelectedID(mapdropdown, i)
                UIDropDownMenu_SetText(mapdropdown, v[1])
            end
        end
    end

    -- initialize zone pulldown
    local mapdropdown2 = _G[lm.."DropDown2"]
    if(mapdropdown2) then
        UIDropDownMenu_ClearAll(mapdropdown2)
        UIDropDownMenu_Initialize(mapdropdown2, YatlasFrameDropDown2_Initialize)
    end

    self:AdjustLocation(0,0,true)
    YAPoints_OnMapChange(self)
    self.lastmap = self.opt.Map
end

function YatlasFrameDropDown2_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED")
end

function YatlasFrameDropDown2_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_SetWidth(self, 150)
    end
end

function YatlasFrameDropDown2_Initialize(dropdown)
    local frame = Yatlas_DropDownOwner(dropdown or UIDROPDOWNMENU_INIT_MENU)
    if(not frame.opt) then
        return
    end
    frame.zonepulldowns = {}
    local info

    if(Yatlas_mapareas[frame.opt.Map] ~= nil) then
        for h,v in pairs(Yatlas_mapareas[frame.opt.Map]) do
            if(Yatlas_areadb[h]) then
                tinsert(frame.zonepulldowns, h)
            end
        end
    end

    table.sort(frame.zonepulldowns,
        function (a,b) return Yatlas_areadb[a] < Yatlas_areadb[b] end)
    for j,v in ipairs(frame.zonepulldowns) do
        info = {
            text = Yatlas_areadb[v],
            value = frame,
            arg1 = frame,
            arg2 = v,
            func = YatlasFrameDropDownButton2_OnClick,
        }
        UIDropDownMenu_AddButton(info)
    end

end

function YatlasFrameDropDownButton2_OnClick(self, frame, z)
    frame = frame or self.value
    z = z or frame.zonepulldowns[self:GetID()]
    local vf = _G[frame:GetName().."ViewFrame"]
    local map = frame.opt.Map
    local zoom = frame:GetZoom()

    if(not z or not Yatlas_mapareas[map]) then return end

    if(type(Yatlas_mapareas[map][z]) == "table") then
        local x, y, mx, my

        x = (Yatlas_mapareas[map][z][1]+
           Yatlas_mapareas[map][z][2])/2
        y = (Yatlas_mapareas[map][z][3]+
           Yatlas_mapareas[map][z][4])/2

        mx, my = Yatlas_Big2Mini_Coord(x,y)

        if(Yatlas_mapareas_adjust[z]) then
            mx = Yatlas_mapareas_adjust[z][1] + mx
            my = Yatlas_mapareas_adjust[z][2] + my
        end

        frame:SetLocation(mx-(vf:GetWidth()/2)/zoom, my-(vf:GetHeight()/2)/zoom)
    end
end

function YatlasFrameTemplate:UpdateDropDown2()
    local framename = self:GetName()
    local vfname = framename.."ViewFrame"
    local vf = _G[vfname]
    local zoom = self.opt.Zoom
    local dd2 = _G[framename.."DropDown2"]
    if(dd2 and self.zonepulldowns) then
        local zid = self:GetZoneIDs()
        for i,v in ipairs(self.zonepulldowns) do
            if(v == zid) then
                UIDropDownMenu_SetSelectedID(dd2, i)
                UIDropDownMenu_SetText(dd2,Yatlas_areadb[zid])
                break
            end
        end
    end
end

--

function YatlasFramePlayerJumpButton_Toggle(btn)
    local f = btn:GetParent()
    local o = f.opt
    if(o.track) then
        o.track = nil
    else
        o.track = "player"
        YatlasFramePlayerJumpButton_Seek(f, "player")
    end

    YatlasFramePlayerJumpButton_Update(btn)
end

function YatlasFramePlayerJumpButton_Jump(btn)
    local f = btn:GetParent()
    local o = f.opt

    o.track = nil
    YatlasFramePlayerJumpButton_Seek(f, "player")

    YatlasFramePlayerJumpButton_Update(btn)
end

-- Goto Player tooltip also shows whether the map is following the player.
function YatlasFramePlayerJumpButton_OnEnter(btn)
    if(not btn:IsMouseOver()) then
        return
    end
    Yatlas_ShowButtonTooltip(btn, YATLAS_PLAYERJUMP, YATLAS_TOOLTIP_PLAYERJUMP)
    local f = btn:GetParent()
    if(f and f.opt and f.opt.track) then
        GameTooltip:AddLine(YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true)
        GameTooltip:Show()
    end
end

function YatlasFramePlayerJumpButton_Seek(frame, unit)
    -- the unit position is now available directly, no need to cycle
    -- through the continents of the world map any more
    frame.trackseek = unit

    if(frame.opt) then
        frame:OnWorldMapUpdateU(unit)
    end
end

function YatlasFramePlayerJumpButton_Update(btn)
    if(btn:GetParent() and btn:GetParent().opt) then
        local t = btn:GetParent().opt.track

        --[[
        if(t) then
            tex = "Interface\\Buttons\\UI-Panel-Button-Down"
        else
            tex = "Interface\\Buttons\\UI-Panel-Button-Up"
        end
--        _G[btn:GetName().."Left"]:SetTexture(tex)
--        _G[btn:GetName().."Middle"]:SetTexture(tex)
--        _G[btn:GetName().."Right"]:SetTexture(tex)
        ]]
        if(GameTooltip:IsOwned(btn)) then
            YatlasFramePlayerJumpButton_OnEnter(btn)
        end
    end
end

function YatlasFrameTemplate:GetMap()
    return self.opt.Map
end

-- Zoom = screen pixels per map tile. Tile textures are created on demand (Yatlas_CreateMapTexture),
-- up to YATLAS_MAX_TILES (Core\Constants.lua), down to YATLAS_MIN_ZOOM.

local function ya_tilecount(vf, z)
    return (math.ceil(vf:GetWidth()/z)+1) * (math.ceil(vf:GetHeight()/z)+1)
end

-- zoom in (dir > 0) or out (dir < 0) by YATLAS_ZOOM_STEP, at least one pixel per step
function YatlasFrameTemplate:StepZoom(dir)
    local z = self:GetZoom()
    local nz = (dir > 0) and math.floor(z*YATLAS_ZOOM_STEP + 0.5) or math.floor(z/YATLAS_ZOOM_STEP + 0.5)

    if(nz == z) then
        nz = z + ((dir > 0) and 1 or -1)
    end
    self:SetZoom(nz)
end

function YatlasFrameTemplate:SetZoom(z, nocenter)
    local lm = self:GetName()
    local vf = _G[lm.."ViewFrame"]

    z = math.floor(math.max(z, YATLAS_MIN_ZOOM))
    z = math.min(z, math.floor(math.min(vf:GetWidth(), vf:GetHeight())))
    while(ya_tilecount(vf, z) > YATLAS_MAX_TILES) do
        z = z + 1
    end

    -- a grid of full size tiles covering the view plus one tile for the fractional offset;
    -- the view frame clips whatever hangs over its right and bottom edges
    local cols = math.ceil(vf:GetWidth()/z)+1
    local rows = math.ceil(vf:GetHeight()/z)+1
    self.tilecols, self.tilerows = cols, rows

    local lastzoom = self.opt.Zoom
    self.opt.Zoom = z

    local canvas = vf.Canvas
    canvas:SetSize(cols*z, rows*z)

    local textureno = 1
    self.texturelayout = {}
    for hx = 1,cols do
        local column = {}
        self.texturelayout[hx] = column
        for hy = 1,rows do
            local tex = _G[lm.."MapTexture"..textureno] or Yatlas_CreateMapTexture(self, textureno)
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", canvas, "TOPLEFT", z*(hx-1), -z*(hy-1))
            tex:SetSize(z, z)
            tex:SetTexCoord(0, 1, 0, 1)
            column[hy] = tex
            textureno = textureno + 1
        end
    end
    while(_G[lm.."MapTexture"..textureno]) do
        _G[lm.."MapTexture"..textureno]:Hide()
        textureno = textureno + 1
    end
    self.tilex = nil        -- the grid changed: SetLocation assigns every tile again

    if(nocenter or lastzoom == z) then
        self:AdjustLocation(0,0,true)
    else
        local oldcx, oldcy
        local newcx, newcy

        oldcy = (vf:GetHeight()/2)/lastzoom
        oldcx = (vf:GetWidth()/2)/lastzoom
        newcy = (vf:GetHeight()/2)/z
        newcx = (vf:GetWidth()/2)/z

        self:AdjustLocation(oldcx-newcx,-oldcy+newcy,true)
    end
end

function YatlasFrameTemplate:GetZoom()
    return self.opt and self.opt.Zoom or 256
end

-- Show the map with its top left corner at map position x, y (in tiles). The canvas top left
-- corner is the tile origin (self.tilex, self.tiley) = floor(x), floor(y): the tile textures are
-- assigned again only when that origin, the map or the zoom changes; otherwise panning only
-- moves the canvas (and the static points anchored on it, YP_SetOffset in Core\Points.lua).
function YatlasFrameTemplate:SetLocation(x,y,forceupdate)
    local vf = _G[self:GetName().."ViewFrame"]
    local zoom = self.opt.Zoom
    local zx, zy = math.floor(x), math.floor(y)
    local mymap = self.opt.Map

    if(forceupdate or zx ~= self.tilex or zy ~= self.tiley or mymap ~= self.lastmap) then
        local tiles = Yatlas_mapdb1[mymap] or {}
        local texturelayout = self.texturelayout

        for hx = 1,self.tilecols do
            for hy = 1,self.tilerows do
                local tex = texturelayout[hx][hy]
                local tile = tiles[format("%.2dx%.2d",zx+hx-1,zy+hy-1)]

                if(type(tile) == "number") then
                    -- 5.5.4+: Yatlas_mapdb1 stores minimap tile FileDataIDs
                    tex:SetTexture(tile, "CLAMP", "CLAMP")
                    tex:Show()
                elseif(tile) then
                    tex:SetTexture(pre..mymap.."\\"..tile[1])
                    tex:Show()
                else
                    -- no tile: the black background of the view frame shows through
                    tex:Hide()
                end
            end
        end
        self.tilex, self.tiley = zx, zy
    end

    vf.Canvas:ClearAllPoints()
    vf.Canvas:SetPoint("TOPLEFT", vf, "TOPLEFT", -(x-zx)*zoom, (y-zy)*zoom)

    -- set zone text
    if(not vf.dragme) then
        self:UpdateDropDown2()
    end

    self.opt.Location[1] = x
    self.opt.Location[2] = y

    YAPoints_OnMove(self, x,y)
end

function YatlasFrameTemplate:GetLocation()
    local fm = self:GetName()

    return self.opt.Location[1],
        self.opt.Location[2]
end

function YatlasFrameTemplate:AdjustLocation(dx,dy,forceupdate)
    local fm = self:GetName()

    if(self.opt == nil) then
        -- we aren't ready yet!
        return
    end

    self:SetLocation(
        self.opt.Location[1] + dx,
        self.opt.Location[2] - dy,
                        forceupdate)
end

function YatlasFrameTemplate:GetZoneText(offx, offy)
    -- untested?
    local f = {self:GetZoneIDs(offx, offy)}

    if(#f < 1) then
        return YATLAS_UNKNOWN_ZONE
    end

    local r = {}
    for h,v in pairs(f) do
        r[h] = Yatlas_areadb[v]
    end

    return unpack(r)
end

-- The zone under the centre of the view (offx, offy: optional offset from the centre, in map
-- tiles). Zones are bounding boxes that overlap, so the smallest box containing the point wins
-- (with pairs() order, the old "first match" could change from one session to the next).
function YatlasFrameTemplate:GetZoneIDs(offx, offy)
    local fm = self:GetName()
    local x, y = unpack(self.opt.Location)
    local zoom = self:GetZoom()
    local viewframe = _G[fm.."ViewFrame"]

    local cx = x+(viewframe:GetWidth()/2)/zoom + (offx or 0)
    local cy = y+(viewframe:GetHeight()/2)/zoom + (offy or 0)

    local cbx, cby = Yatlas_Mini2Big_Coord(cx, cy)

    local maparea = Yatlas_mapareas[self.opt.Map]
    if(type(maparea) ~= "table") then
        return nil
    end

    local best, bestsize
    for h,k in pairs(maparea) do
        if(h ~= 0 and type(k) == "table" and cbx < k[1] and cbx > k[2] and cby < k[3] and cby > k[4]) then
            local size = (k[1] - k[2]) * (k[3] - k[4])
            if(best == nil or size < bestsize or (size == bestsize and h < best)) then
                best, bestsize = h, size
            end
        end
    end
    return best
end

-- follow the tracked unit (the landmarks set loads Yatlas_Landmarks on demand, Modules\landmarks.lua)
function YatlasFrameTemplate:OnWorldMapUpdate()
    if(self.trackseek or (self.opt and self.opt.track)) then
        self:OnWorldMapUpdateU(self.trackseek or self.opt.track)
    end
end

function YatlasFrameTemplate:OnWorldMapUpdateU(u)
    local map, unitx, unity = Yatlas_GetUnitLocation(u)
    local lm = self:GetName()
    local viewframe = _G[lm.."ViewFrame"]
    local zoom = self.opt.Zoom

    if(map == nil or Yatlas_mapdb1[map] == nil) then
        if(u == self.trackseek) then
            self.trackseek = nil
        end
        return
    end

    if(u == self.trackseek) then
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity)

        self:SetMap(map)
        self:SetLocation(zx-(viewframe:GetWidth()/2)/zoom,
                    zy-(viewframe:GetHeight()/2)/zoom)

        self.trackseek = nil
    elseif(u == self.opt.track) then
        local rx,ry = self:GetLocation()
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity)
        local whaffzoom = (viewframe:GetWidth()/2)/zoom
        local hhaffzoom = (viewframe:GetHeight()/2)/zoom

        rx = rx+whaffzoom
        ry = ry+hhaffzoom

        zx = zx-whaffzoom
        zy = zy-hhaffzoom

        if(map ~= self.opt.Map or zx > rx or zx + whaffzoom*2 < rx  or
                zy > ry or zy + hhaffzoom*2 < ry) then
            self:SetMap(map)
            self:SetLocation(zx, zy)
        end
    end
end

function YatlasFrameViewFrame_OnDrag(self)
    local x,y = GetCursorPosition()
    local fx, fy
    local zoom = self:GetParent().opt.Zoom

    x = x / self:GetEffectiveScale()
    y = y / self:GetEffectiveScale()

    fx = math.floor(x - self:GetLeft())/(zoom)
    fy = math.floor(y - self:GetBottom())/(zoom)
    -- the last drag position is kept on the ViewFrame (reset in its OnDragStart)
    if(self.lastdragx ~= nil) then
        self:GetParent():AdjustLocation(self.lastdragx - fx, self.lastdragy - fy)
    end

    self.lastdragx = fx
    self.lastdragy = fy
end


function YatlasFrameTemplate:OnUpdate(elapsed)
    self.update_time = self.update_time + elapsed

    if(self.update_time > 0.5) then
       YAPoints_OnUpdate(self, self.update_time)

        if(self.opt) then
            self:OnWorldMapUpdate()
        end
        self.update_time = 0
   end
end

function Yatlas_Mini2Big_Coord(x,y)
    return (x - 32)*-MINI2BIGX,(y-32)*-MINI2BIGY
end

function Yatlas_Big2Mini_Coord(x,y)
    return (x/-MINI2BIGX + 32),(y/-MINI2BIGY + 32)
end

function Yatlas_GetMapZones(map)
    -- map zone ids to name
    local ret = {}
    if(Yatlas_ZoneIds[map]) then
        for h,v in ipairs(Yatlas_ZoneIds[map]) do
            tinsert(ret, Yatlas_areadb[v])
        end
    end
    table.sort(ret)

    return unpack(ret)
end

-- the options dialog (YatlasOptionsFrame) is in UI\OptionsFrame.lua, the hover tooltip
-- (YatlasTooltipTemplate) in UI\Templates.lua
