-- constants (metadata, paths, option defaults, ...) are in Core\Constants.lua
local pre = YATLAS_MINIMAP_PATH;
local MINI2BIGX = YATLAS_MINI2BIG_X;
local MINI2BIGY = YATLAS_MINI2BIG_Y;
local _G=_G;

YatlasOptions = {}

local dummyv = nil;
local nilfunc = function() end

YatlasFrameTemplate = {};

function YatlasFrame_Bootstrap(self, frame)
    --frame = YatlasFrame;
    if(frame == nil) then
        frame = self;
    end

    for h,v in pairs(YatlasFrameTemplate) do
        if(frame[h]) then
            frame["old_"..h] = frame[h];
        end

        frame[h] = v;
    end
    frame:OnLoad();
end

function YatlasFrameTemplate:OnLoad()
    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];

    self.texturelayout = {};
    self.wzoom = 3;
    self.hzoom = 3;
    self.wzoom_real = 3;
    self.hzoom_real = 3;
    self.points = {};
    self.pointframes = {};

    self:RegisterForDrag("LeftButton");
    self:RegisterEvent("VARIABLES_LOADED");
    self:RegisterEvent("ADDON_LOADED");
    -- WORLD_MAP_UPDATE no longer exists; positions are polled in OnUpdate
    self:RegisterEvent("PLAYER_ENTERING_WORLD");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    self:RegisterEvent("AREA_POIS_UPDATED");
    viewframe:RegisterForDrag("RightButton","LeftButton");
    viewframe:EnableMouseWheel(true);

    YAPoints_RegisterFrame(self:GetName());

    self.update_time = 0;
end

function YatlasFrame_OnLoadExtra()
    YatlasFrame.OnEventExtra = YatlasFrame_OnEventExtra;
    YatlasFrame.YA_PD_allocText = "YA_PD_allocText";
    YatlasFrame.YA_PD_ResetList = "YA_PD_ResetList";
    
    SLASH_YATLAS1 = "/yatlas";
    SlashCmdList["YATLAS"] = function() YatlasFrame:Toggle() end

    YatlasFrame.hoverTooltip = "YatlasTooltip";

    -- initalize zones
    for h,v in pairs(Yatlas_WorldMapIds) do
	Yatlas_PaperZoneNames[h] = {Yatlas_GetMapZones(h)};
    end

    -- wrap mapnotes for updates
    if(MapNotes_DeleteNote) then
        YA_old_MapNotes_DeleteNote = MapNotes_DeleteNote;
        MapNotes_DeleteNote = function(...)
            local v = YA_old_MapNotes_DeleteNote(...)
            YAPoints_ForceUpdate();
            return v;
        end
        YA_old_MapNotes_WriteNote = MapNotes_WriteNote;
        MapNotes_WriteNote = function(...)
            local v = YA_old_MapNotes_WriteNote(...);
            YAPoints_ForceUpdate();
            return v;
        end
    end

    -- wrap gatherer
    --print("Test for GatherMate")
    if(GatherMate) then
        --print("Found")
         YA_old_GatherMate = GatherMate;
         GatherMate = function(...)
            local v = YA_old_GatherMate(...)
            YAPoints_ForceUpdate();
            return v;
        end
    end

    -- myaddons support
    YatlasDetails = {
        name = YATLAS_TITLE,
	version = YATLAS_VERSION,
	releaseDate = YATLAS_RELEASE_DATE,
	author = YATLAS_AUTHOR,
        website = YATLAS_WEBSITE,
	category = MYADDONS_CATEGORY_MAP,
    };
    YatlasMAHelp = YATLAS_HELP_TEXT;
end

function BigYatlasFrame_OnLoadExtra()
    UIPanelWindows["BigYatlasFrame"] = { area = "full",	pushable = 0,	whileDead = 1 };

    SLASH_BIGYATLAS1 = "/bigyatlas";
    SlashCmdList["BIGYATLAS"] = function() BigYatlasFrame:Toggle() end

    BigYatlasFrame.RawBigShow = BigYatlasFrame.Show;
    BigYatlasFrame.Show = function(self)
        if(SetupFullscreenScale) then
            SetupFullscreenScale(self);
        end
        return self:RawBigShow();
    end

    BigYatlasFrame.hoverTooltip = "BigYatlasTooltip";
end

function YatlasFrameTemplate:OnEvent(event, ...)
    local framename = self:GetName();

    if(event == "VARIABLES_LOADED") then
        if(YatlasOptions == nil) then
            YatlasOptions = {};
        end

        if(YatlasOptions.ShowButton == nil) then
            YatlasOptions.ShowButton = true;
        end
        if(YatlasOptions.ButtonLocation == nil) then
            YatlasOptions.ButtonLocation = 0;
        end

        self:EnsureExistingOptions();

        self.opt = YatlasOptions.Frames[framename];
        self:SetZoom(self.opt.Zoom);
        self:SetMap(self.opt.Map);

        self:UpdateLock();
        self:SetAlpha(self.opt.Alpha);

        if(self.opt.track) then
            YatlasFramePlayerJumpButton_Seek(self, self.opt.track);
        end
    elseif(event == "AREA_POIS_UPDATED") then
        Yatlas_ResetLandmarks();
        if(self.opt) then
            self:OnWorldMapUpdate();
        end
    elseif(event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") then
        if(self.opt) then
            self:OnWorldMapUpdate();
        end
    end

    if(self.OnEventExtra) then
        self:OnEventExtra(event, ...);
    end
end

function YatlasFrame_OnEventExtra(self, event, ...)
    local framename = self:GetName();
    local addon = ...;

    if(event == "ADDON_LOADED" and addon == "Yatlas") then
        if(myAddOnsFrame_Register) then
            myAddOnsFrame_Register(YatlasDetails, YatlasMAHelp);
        end
    end
end

function YatlasFrameTemplate:EnsureExistingOptions()
    if(YatlasOptions.Frames == nil) then
        YatlasOptions.Frames = {};
    end

    local name = self:GetName();

    if(YatlasOptions.Frames[name] == nil) then
        YatlasOptions.Frames[name] = {};
    end

    for h,v in pairs(YA_FRAME_OPTION_DEFAULTS) do
        if(YatlasOptions.Frames[name][h] ~= nil) then
            -- don't do anything!
        elseif(YatlasOptions[h] ~= nil) then
            YatlasOptions.Frames[name][h] = YatlasOptions[h];
            YatlasOptions[h] = nil;
        elseif(type(v) == "table") then
            -- don't copy reference.  copy value...unfortunately, we only 
            -- copy one level deep, which seems good enough...
            YatlasOptions.Frames[name][h] = {};
            for x,k in pairs(v) do
                YatlasOptions.Frames[name][h][x] = k;
            end
        else
            YatlasOptions.Frames[name][h] = v;
        end
    end
end

function YatlasFrameTemplate:Toggle()
    local lm = self:GetName();

    if(UIPanelWindows[lm] == nil) then
        if(self:IsShown()) then
            self:Hide();
        else
            self:Show();
        end
    else
	if (self:IsVisible() ) then
	    HideUIPanel(self);
	else
            -- SetupWorldMapScale();
            ShowUIPanel(self);
	end
    end
end

-- Switch between the normal and the large frame, keeping the map and
-- the point at the centre of the view (each frame keeps its own zoom).
function Yatlas_SwitchFrame(from)
    local to = (from == BigYatlasFrame) and YatlasFrame or BigYatlasFrame;
    if(not from or not to or not from.opt or not to.opt) then
        return;
    end

    local fvf = _G[from:GetName().."ViewFrame"];
    local fz = from:GetZoom();
    local cx = from.opt.Location[1] + fvf:GetWidth() / fz / 2;
    local cy = from.opt.Location[2] + fvf:GetHeight() / fz / 2;
    local map = from.opt.Map;

    if(from:IsShown()) then
        from:Toggle();
    end
    if(not to:IsShown()) then
        to:Toggle();
    end

    if(to.opt.Map ~= map) then
        to:SetMap(map);
    end
    local tvf = _G[to:GetName().."ViewFrame"];
    local tz = to:GetZoom();
    to:SetLocation(cx - tvf:GetWidth() / tz / 2, cy - tvf:GetHeight() / tz / 2, true);
end

-- Shared button tooltip: a title line and an optional wrapped description.
function Yatlas_ShowButtonTooltip(self, title, text, anchor)
    if(not title) then
        return;
    end
    GameTooltip:SetOwner(self, anchor or "ANCHOR_BOTTOMLEFT");
    GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    if(text) then
        GameTooltip:AddLine(text, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end

function YatlasFrameSwitchButton_OnEnter(self)
    if(self:GetParent() == BigYatlasFrame) then
        Yatlas_ShowButtonTooltip(self, YATLAS_SWITCH_TO_NORMAL);
    else
        Yatlas_ShowButtonTooltip(self, YATLAS_SWITCH_TO_BIG);
    end
end

-- Also called from OnClick so the tooltip follows the new lock state.
function YatlasFrameLockButton_OnEnter(self)
    if(not self:IsMouseOver()) then
        return;
    end
    if(YatlasFrame.opt and YatlasFrame.opt.Locked) then
        Yatlas_ShowButtonTooltip(self, YATLAS_TOOLTIP_LOCKED_TITLE, YATLAS_TOOLTIP_LOCKED);
    else
        Yatlas_ShowButtonTooltip(self, YATLAS_TOOLTIP_UNLOCKED_TITLE, YATLAS_TOOLTIP_UNLOCKED);
    end
end

function YatlasFrameDropDown_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function YatlasFrameDropDown_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_Initialize(self, YatlasFrameDropDown_Initialize);
        UIDropDownMenu_SetSelectedID(self, 1);
        UIDropDownMenu_SetWidth(self, 150);
    end
end

-- Find the Yatlas frame (YatlasFrame or BigYatlasFrame) that owns a
-- drop-down. The menus used to be hard-wired to YatlasFrame, so the map and
-- zone menus of the large frame changed the (hidden) normal frame.
local function Yatlas_DropDownOwner(dropdown)
    if(type(dropdown) == "string") then
        dropdown = _G[dropdown];
    end
    while(dropdown and not dropdown.SetMap) do
        dropdown = dropdown:GetParent();
    end
    return dropdown or YatlasFrame;
end

function YatlasFrameDropDown_Initialize(dropdown)
    local owner = Yatlas_DropDownOwner(dropdown or UIDROPDOWNMENU_INIT_MENU);
    local info;
    for h,v in pairs(YA_MAPS) do
            info = {
                    text = h;
                    arg1 = owner;
                    arg2 = v[1];
                    checked = (owner.opt and owner.opt.Map == v[1]) or nil;
                    func = YatlasFrameDropDownButton_OnClick;
            };
            UIDropDownMenu_AddButton(info);
    end
end

function YatlasFrameDropDownButton_OnClick(self, owner, map)
    if(owner and map) then
        return owner:SetMap(map);
    end
end

function YatlasFrameTemplate:ToggleLock()
    if(self.opt.Locked) then
        self.opt.Locked = false;
    else
        self.opt.Locked = true;
    end   
    self:UpdateLock();
end

function YatlasFrameTemplate:UpdateLock()
    local fm = self:GetName();
    local norm = _G[fm.."LockButtonNorm"];
    local push = _G[fm.."LockButtonPush"];

    if(norm and push) then
        if(self.opt.Locked) then
            norm:SetTexture(YATLAS_IMAGE_PATH.."LockButton-Locked-Up");
            push:SetTexture(YATLAS_IMAGE_PATH.."LockButton-Locked-Down");
        else
            norm:SetTexture(YATLAS_IMAGE_PATH.."LockButton-Unlocked-Up");
            push:SetTexture(YATLAS_IMAGE_PATH.."LockButton-Unlocked-Down");
        end
    end
end

function YatlasFrameTemplate:SetMap(mapname)
    local lm = self:GetName();

    self.opt.Map = mapname;
    
    local mapdropdown = _G[lm.."DropDown"];
    if(mapdropdown) then
        local i = 1;
        for h,v in pairs(YA_MAPS) do
            if(v[1] == mapname) then
                UIDropDownMenu_SetSelectedID(mapdropdown, i);
                UIDropDownMenu_SetText(mapdropdown,h);
            end
            i = i + 1;
        end
    end

    -- initialize zone pulldown
    local mapdropdown2 = _G[lm.."DropDown2"];
    if(mapdropdown2) then
        UIDropDownMenu_ClearAll(mapdropdown2);
        UIDropDownMenu_Initialize(mapdropdown2, YatlasFrameDropDown2_Initialize);
    end

    self:AdjustLocation(0,0,true);
    YAPoints_OnMapChange(self);
    self.lastmap = self.opt.Map;
end

function YatlasFrameDropDown2_OnLoad(self)
    self:RegisterEvent("VARIABLES_LOADED");
end

function YatlasFrameDropDown2_OnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_SetWidth(self, 150);
    end
end

function YatlasFrameDropDown2_Initialize(dropdown)
    local frame = Yatlas_DropDownOwner(dropdown or UIDROPDOWNMENU_INIT_MENU);
    if(not frame.opt) then
        return;
    end
    frame.zonepulldowns = {};
    local info;

    if(Yatlas_mapareas[frame.opt.Map] ~= nil) then
        for h,v in pairs(Yatlas_mapareas[frame.opt.Map]) do
            if(Yatlas_areadb[h]) then
                tinsert(frame.zonepulldowns, h);
            end
        end
    end

    table.sort(frame.zonepulldowns,
        function (a,b) return Yatlas_areadb[a] < Yatlas_areadb[b]; end);
    for j,v in ipairs(frame.zonepulldowns) do
        info = {
            text = Yatlas_areadb[v];
            value = frame;
            arg1 = frame;
            arg2 = v;
            func = YatlasFrameDropDownButton2_OnClick;
        };
        UIDropDownMenu_AddButton(info);
    end 

end

function YatlasFrameDropDownButton2_OnClick(self, frame, z)
    frame = frame or self.value;
    z = z or frame.zonepulldowns[self:GetID()];
    local vf = _G[frame:GetName().."ViewFrame"];
    local map = frame.opt.Map;
    local zoom = frame:GetZoom();

    if(not z or not Yatlas_mapareas[map]) then return; end
    
    if(type(Yatlas_mapareas[map][z]) == "table") then
        local x, y, mx, my;

        x = (Yatlas_mapareas[map][z][1]+
           Yatlas_mapareas[map][z][2])/2;
        y = (Yatlas_mapareas[map][z][3]+
           Yatlas_mapareas[map][z][4])/2;

        mx, my = Yatlas_Big2Mini_Coord(x,y);

        if(Yatlas_mapareas_adjust[z]) then
            mx = Yatlas_mapareas_adjust[z][1] + mx;
            my = Yatlas_mapareas_adjust[z][2] + my;
        end

        frame:SetLocation(mx-(vf:GetWidth()/2)/zoom, my-(vf:GetHeight()/2)/zoom);
    end
end

function YatlasFrameTemplate:UpdateDropDown2()
    local framename = self:GetName();
    local vfname = framename.."ViewFrame";
    local vf = _G[vfname];
    local zoom = self.opt.Zoom;
    local dd2 = _G[framename.."DropDown2"];
--print(tostring(framename).." "..tostring(vfname).." "..tostring(zoom).." "..tostring(dd2))
    if(dd2 and self.zonepulldowns) then
        -- FIXME this isn't quite right somehow!! (besides height/width being flipped)
        local zid = self:GetZoneIDs((vf:GetHeight()/zoom/2),(vf:GetWidth()/zoom/2));
        for i,v in ipairs(self.zonepulldowns) do
	--print(tostring(v).." "..tostring(vid))
            if(v == zid) then
                UIDropDownMenu_SetSelectedID(dd2, i);
                UIDropDownMenu_SetText(dd2,Yatlas_areadb[zid]);
                break;
            end
        end
    end
end

--

function YatlasFramePlayerJumpButton_Toggle(btn)
    local f = btn:GetParent();
    local o = f.opt;
    if(o.track) then
        o.track = nil;
    else
        o.track = "player";
        YatlasFramePlayerJumpButton_Seek(f, "player");
    end

    YatlasFramePlayerJumpButton_Update(btn)
end

function YatlasFramePlayerJumpButton_Jump(btn)
    local f = btn:GetParent();
    local o = f.opt;
    
    o.track = nil;
    YatlasFramePlayerJumpButton_Seek(f, "player");
    
    YatlasFramePlayerJumpButton_Update(btn)
end

-- Goto Player tooltip; also shows whether the map is following the player.
function YatlasFramePlayerJumpButton_OnEnter(btn)
    if(not btn:IsMouseOver()) then
        return;
    end
    Yatlas_ShowButtonTooltip(btn, YATLAS_PLAYERJUMP, YATLAS_TOOLTIP_PLAYERJUMP);
    local f = btn:GetParent();
    if(f and f.opt and f.opt.track) then
        GameTooltip:AddLine(YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING, GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b, true);
        GameTooltip:Show();
    end
end

function YatlasFramePlayerJumpButton_Seek(frame, unit) 
    -- the unit position is now available directly, no need to cycle
    -- through the continents of the world map any more
    frame.trackseek = unit;

    if(frame.opt) then
        frame:OnWorldMapUpdateU(unit);
    end
end

function YatlasFramePlayerJumpButton_Update(btn)
    if(btn:GetParent() and btn:GetParent().opt) then
        local t = btn:GetParent().opt.track;

        if(t) then
            tex = "Interface\\Buttons\\UI-Panel-Button-Down";
        else
            tex = "Interface\\Buttons\\UI-Panel-Button-Up";
        end
--        _G[btn:GetName().."Left"]:SetTexture(tex);
--        _G[btn:GetName().."Middle"]:SetTexture(tex);
--        _G[btn:GetName().."Right"]:SetTexture(tex);
        if(GameTooltip:IsOwned(btn)) then
            YatlasFramePlayerJumpButton_OnEnter(btn);
        end
    end
end

function YatlasFrameTemplate:GetMap()
    return self.opt.Map;
end

function YatlasFrameTemplate:SetZoom(z, nocenter)
    local textureno = 1;
    local lm = self:GetName();
    local vf = _G[lm.."ViewFrame"];

    self.wzoom = math.floor(vf:GetWidth()/z)+1;
    self.hzoom = math.floor(vf:GetHeight()/z)+1;
    self.wzoom_real = math.ceil(vf:GetWidth()/z)+1;
    self.hzoom_real = math.ceil(vf:GetHeight()/z)+1;

    if(_G[lm.."MapTexture"..(self.wzoom_real*self.hzoom_real)] == nil) then
        return self:SetZoom(z+4);
    elseif(z > vf:GetHeight() or z > vf:GetWidth()) then
        return self:SetZoom(z-4);
    end
    local lastzoom = self.opt.Zoom;
    self.opt.Zoom = z;

    -- allocate textures
    self.texturelayout = {};
    for hw = 1,self.wzoom_real do
        self.texturelayout[hw] = {};
        for hh = 1,self.hzoom_real do
            self.texturelayout[hw][hh] = _G[lm.."MapTexture"..textureno];
            self.texturelayout[hw][hh].hx = hw;
            self.texturelayout[hw][hh].hy = hh;
            textureno = textureno + 1;
        end
    end
    while(_G[lm.."MapTexture"..textureno]) do
        _G[lm.."MapTexture"..textureno]:Hide();
        textureno = textureno + 1;
    end

    -- unclip all textures now, ESPECIALLY the middle textures
    for hw = 1,self.wzoom_real do
        for hh = 1,self.hzoom_real do
            self.texturelayout[hw][hh]:Show();
            self.texturelayout[hw][hh]:SetTexCoord(0, 1, 0, 1);
            self.texturelayout[hw][hh]:SetHeight(z);
            self.texturelayout[hw][hh]:SetWidth(z);
        end
    end

    if(nocenter or lastzoom == z) then
        self:AdjustLocation(0,0,true)
    else
        local oldcx, oldcy;
        local newcx, newcy;

        oldcy = (vf:GetHeight()/2)/lastzoom;
        oldcx = (vf:GetWidth()/2)/lastzoom;
        newcy = (vf:GetHeight()/2)/z;
        newcx = (vf:GetWidth()/2)/z;

        self:AdjustLocation(oldcx-newcx,-oldcy+newcy,true)
    end
end

function YatlasFrameTemplate:GetZoom()
    return self.opt and self.opt.Zoom or 256;
end

function YatlasFrameTemplate:SetLocation(x,y,forceupdate)
    local zx, zy, mymap;
    local framename = self:GetName();
    local vfname = framename.."ViewFrame";
    local vf = _G[vfname];
    local texturelayout = self.texturelayout;
    local zoom = self.opt.Zoom;
    local wzoom, hzoom = self.wzoom,self.hzoom;
    local wzoom_real,hzoom_real = self.wzoom_real, self.hzoom_real;

    zx = math.floor(x);
    zy = math.floor(y);
    mymap = self.opt.Map;

    -- offset calc
    local px, py;
    px = math.floor((x-zx)*zoom);
    py = math.floor((y-zy)*zoom);

    if(zx ~= math.floor(self.opt.Location[1]) or forceupdate or
        zy ~= math.floor(self.opt.Location[2]) or mymap ~= self.lastmap) then
        local v = {};
        local jx, jy, nsv;

        for hx = 1,wzoom_real do
            v[hx] = {};
            for hy = 1,hzoom_real do
                local tex = texturelayout[hx][hy];

                -- get info
                v[hx][hy] = Yatlas_mapdb1[mymap][format("%.2dx%.2d",zx+hx-1,zy+hy-1)];
                if(v[hx][hy] == nil) then
                    v[hx][hy] = dummyv;
                end

                -- set textures
                if(v[hx][hy]) then
		    if(type(v[hx][hy]) == "number") then
		        -- 5.5.4+: Yatlas_mapdb1 stores minimap tile FileDataIDs
		        -- clamp the tile edges and turn off pixel snapping so that
		        -- neighbouring tiles line up without visible gaps
		        if(tex.SetSnapToPixelGrid and not tex.yatlasNoSnap) then
		            tex:SetSnapToPixelGrid(false);
		            tex:SetTexelSnappingBias(0);
		            tex.yatlasNoSnap = true;
		        end
		        tex:SetTexture(v[hx][hy], "CLAMP", "CLAMP");
		    else
		        tex:SetTexture(pre..mymap.."\\"..v[hx][hy][1]);
		    end
                    tex:SetVertexColor(1,1,1,1);
                else
                    tex:SetTexture("Interface\\Buttons\\WHITE8X8");
                    tex:SetVertexColor(0,0,0,1);
                end
            end
        end
    end

    -- Do offset and clipping (:SetTexCoord and :SetHeight/Width)
    -- We do the most thinking about border textures 

    local bottomh = vf:GetHeight()-zoom*(hzoom-2)-(zoom-py);
    local rightw = vf:GetWidth()-zoom*(wzoom-2)-(zoom-px);
    local needbottom_extra = false;
    local needright_extra = false;
    local old_bottomh, old_rightw;
    if(bottomh > zoom) then
        needbottom_extra = true;
        old_bottomh = bottomh;
        bottomh = zoom;
    end
    if(rightw > zoom) then
        needright_extra = true;
        old_rightw = rightw;
        rightw = zoom;
    end

    -- center textures (easy)
    for w = 2,wzoom-1 do
        for h = 2,hzoom-1 do
            ya_raw_setoff(texturelayout[w][h],vfname,px,py);
        end
    end

    -- Upper left corner
    texturelayout[1][1]:SetTexCoord( (x-zx), 1, (y-zy), 1);
    texturelayout[1][1]:SetHeight( zoom-py);
    texturelayout[1][1]:SetWidth( zoom-px);
    ya_raw_setoff(texturelayout[1][1],vfname,0,0);

    -- Upper right corner
    if(px ~= 0 or wzoom ~= wzoom_real) then
        texturelayout[wzoom][1]:Show();
        texturelayout[wzoom][1]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
        texturelayout[wzoom][1]:SetHeight( zoom-py);
        texturelayout[wzoom][1]:SetWidth(rightw);
        ya_raw_setoff(texturelayout[wzoom][1],vfname,px,0);
    else
        texturelayout[wzoom][1]:Hide();
    end

    -- Lower left corner
    if(py ~= 0  or wzoom ~= wzoom_real) then
        texturelayout[1][hzoom]:Show();
        texturelayout[1][hzoom]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
        texturelayout[1][hzoom]:SetWidth( zoom-px);
        texturelayout[1][hzoom]:SetHeight(bottomh);
        ya_raw_setoff(texturelayout[1][hzoom],vfname,0,py);
    else
        texturelayout[1][hzoom]:Hide();
    end

    -- lower right corner
    if((py ~= 0 and px ~= 0) or wzoom ~= wzoom_real) then
        texturelayout[wzoom][hzoom]:Show();
        texturelayout[wzoom][hzoom]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
        texturelayout[wzoom][hzoom]:SetHeight(bottomh);
        texturelayout[wzoom][hzoom]:SetWidth(rightw);
        ya_raw_setoff(texturelayout[wzoom][hzoom],vfname,px,py);
    else
        texturelayout[wzoom][hzoom]:Hide();
    end

    -- top line
    for h = 2,wzoom-1 do
        texturelayout[h][1]:SetTexCoord( 0, 1, (y-zy), 1);
        texturelayout[h][1]:SetHeight( zoom-py);
        ya_raw_setoff(texturelayout[h][1],vfname,px,0);
    end

    -- bottom line
    if(py ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,wzoom-1 do
            texturelayout[h][hzoom]:Show();
            texturelayout[h][hzoom]:SetTexCoord( 0, 1, 0, bottomh/zoom);
            texturelayout[h][hzoom]:SetHeight(bottomh);
            ya_raw_setoff(texturelayout[h][hzoom],vfname, px,py);
        end
    else
        for h = 2,wzoom-1 do
            texturelayout[h][hzoom]:Hide();
        end
    end

    -- left line
    for h = 2,hzoom-1 do
        texturelayout[1][h]:SetTexCoord( (x-zx), 1, 0, 1);
        texturelayout[1][h]:SetWidth( zoom-px);
        ya_raw_setoff(texturelayout[1][h],vfname,0,py);
    end

    -- right line
    if(px ~= 0 or wzoom ~= wzoom_real) then
        for h = 2,hzoom-1 do
            texturelayout[wzoom][h]:Show();
            texturelayout[wzoom][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
            texturelayout[wzoom][h]:SetWidth(rightw);
            ya_raw_setoff(texturelayout[wzoom][h],vfname,px,py);
        end
    else
        for h = 2,hzoom-1 do
            texturelayout[wzoom][h]:Hide();
        end
    end

    -- if our zoom is not a multiple of our size, we have a little extra we
    -- need to worry about :X
    if(wzoom_real ~= wzoom) then
        if(needright_extra) then
            rightw = (old_rightw-zoom);
        end

        if(needbottom_extra) then
            bottomh = (old_bottomh-zoom);

            for h = 1,wzoom_real-1 do
                texturelayout[h][hzoom_real]:SetHeight(bottomh);
                if(h == 1) then
                    texturelayout[h][hzoom_real]:SetTexCoord( (x-zx), 1, 0, bottomh/zoom);
                    texturelayout[h][hzoom_real]:SetWidth(zoom-px);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,0,py);
                elseif(not needright_extra and h == wzoom_real-1) then
                    texturelayout[h][hzoom_real]:SetWidth(rightw);
                    texturelayout[h][hzoom_real]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);                    
                else
                    texturelayout[h][hzoom_real]:SetWidth(zoom);
                    texturelayout[h][hzoom_real]:SetTexCoord( 0, 1, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[h][hzoom_real],vfname,px,py);
                end
                texturelayout[h][hzoom_real]:Show();
            end
            
        else
            for h = 1,wzoom_real-1 do
                texturelayout[h][hzoom_real]:Hide();
            end
        end

        if(needright_extra) then
            for h = 1,hzoom_real do
                texturelayout[wzoom_real][h]:SetWidth(rightw);
                texturelayout[wzoom_real][h]:Show();
                if(h == 1) then
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, (y-zy), 1);
                    texturelayout[wzoom_real][h]:SetHeight(zoom-py);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,0);
                elseif(not needbottom_extra and h == hzoom_real-1) then
                    texturelayout[wzoom_real][h]:SetHeight(bottomh);
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);    
                elseif(h == hzoom_real) then
                    if(needbottom_extra) then
                        texturelayout[wzoom_real][h]:SetHeight(bottomh);
                        texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, bottomh/zoom);
                        ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                    else
                        texturelayout[wzoom_real][h]:Hide();
                    end
                else
                    texturelayout[wzoom_real][h]:SetHeight(zoom);
                    texturelayout[wzoom_real][h]:SetTexCoord( 0, rightw/zoom, 0, 1);
                    ya_raw_setoff(texturelayout[wzoom_real][h],vfname,px,py);
                end
                
            end
        else
            for h = 1,hzoom_real do
                texturelayout[wzoom_real][h]:Hide();
            end
        end

    end

    -- set zone text
    if(not vf.dragme) then
        self:UpdateDropDown2();
    end

    self.opt.Location[1] = x;
    self.opt.Location[2] = y;

    YAPoints_OnMove(self, x,y);
end

function YatlasFrameTemplate:GetLocation()
    local fm = self:GetName();

    return self.opt.Location[1],
        self.opt.Location[2];
end

function YatlasFrameTemplate:AdjustLocation(dx,dy,forceupdate)
    local fm = self:GetName();

    if(self.opt == nil) then
        -- we aren't ready yet!
        return;
    end

    self:SetLocation(
        self.opt.Location[1] + dx,
        self.opt.Location[2] - dy,
                        forceupdate);
end

function YatlasFrameTemplate:GetZoneText(offx, offy)
    -- untested?
    local f = {self:GetZoneIDs(offx, offy)};

    if(getn(f) < 1) then
        return YATLAS_UNKNOWN_ZONE;
    end

    local r = {};
    for h,v in pairs(f) do
        r[h] = Yatlas_areadb[v];
    end

    return unpack(r);
end

function YatlasFrameTemplate:GetZoneIDs(offx, offy)
    local fm = self:GetName();
    local x, y = unpack(self.opt.Location);
    local zoom = self:GetZoom();
    local viewframe = _G[fm.."ViewFrame"];

    local cx = x+(viewframe:GetWidth()/2)/zoom
    local cy = y+(viewframe:GetHeight()/2)/zoom

    local cbx, cby = Yatlas_Mini2Big_Coord(cx, cy)

    -- TODO: this isn't very accurate
    local maparea = Yatlas_mapareas[self.opt.Map];
    for h,k in pairs(maparea) do
        if(h ~= 0 and cbx < k[1] and cbx > k[2] and cby < k[3] and cby > k[4])then
            return h
        end
    end
end

function YatlasFrameTemplate:OnWorldMapUpdate()
    -- update landmarks of the map we are showing
    if(self.opt and Yatlas_LoadLandmarks(self.opt.Map)) then
        YAPoints_ForceUpdate();
    end

    if(self.trackseek or (self.opt and self.opt.track)) then
        self:OnWorldMapUpdateU(self.trackseek or self.opt.track)
    end
end

function YatlasFrameTemplate:OnWorldMapUpdateU(u)
    local map, unitx, unity = Yatlas_GetUnitLocation(u);
    local lm = self:GetName();
    local viewframe = _G[lm.."ViewFrame"];
    local zoom = self.opt.Zoom

    if(map == nil or Yatlas_mapdb1[map] == nil) then  
        if(u == self.trackseek) then
            self.trackseek = nil;
        end
        return;
    end

    if(u == self.trackseek) then
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity);

        self:SetMap(map);
        self:SetLocation(zx-(viewframe:GetWidth()/2)/zoom,
                    zy-(viewframe:GetHeight()/2)/zoom);

        self.trackseek = nil;
    elseif(u == self.opt.track) then
        local rx,ry = self:GetLocation();
        local zx,zy = Yatlas_Big2Mini_Coord(unitx, unity);
        local whaffzoom = (viewframe:GetWidth()/2)/zoom;
        local hhaffzoom = (viewframe:GetHeight()/2)/zoom;

        rx = rx+whaffzoom;
        ry = ry+hhaffzoom;

        zx = zx-whaffzoom;
        zy = zy-hhaffzoom;

        if(map ~= self.opt.Map or zx > rx or zx + whaffzoom*2 < rx  or
                zy > ry or zy + hhaffzoom*2 < ry) then
            self:SetMap(map);
            self:SetLocation(zx, zy);
        end
    end
end

function ya_raw_setoff(texture, parent, px, py) 
    local zoom = _G[parent]:GetParent().opt.Zoom
    texture:ClearAllPoints();
    texture:SetPoint("TOPLEFT", parent,
            "TOPLEFT", (zoom)*(texture.hx-1) - px,
            -(zoom)*(texture.hy-1) + py);
end

ya_lastdragx, ya_lastdragy = nil, nil;
function YatlasFrameViewFrame_OnDrag(self)
    local x,y = GetCursorPosition();
    local fx, fy;
    local zoom = self:GetParent().opt.Zoom;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    fx = math.floor(x - self:GetLeft())/(zoom);
    fy = math.floor(y - self:GetBottom())/(zoom);
    if(ya_lastdragx ~= nil) then
        self:GetParent():AdjustLocation(ya_lastdragx - fx, ya_lastdragy - fy);
    end

    ya_lastdragx = fx;
    ya_lastdragy = fy;
end

function YatlasFrameViewFrame_UpdateCursorCoord(self)
    local x, y = GetCursorPosition();
    local owner = self:GetParent();
    if(not owner or not owner.opt) then return; end
    local rx, ry = unpack(owner.opt.Location);
    local top = self:GetTop();
    local zoom = owner.opt.Zoom;
    
    if(self.lastoux == x and self.lastouy == y) then
        return;
    end
    self.lastoux = x;
    self.lastouy = y;

    x = x / self:GetEffectiveScale();
    y = y / self:GetEffectiveScale();

    rx = rx + math.floor(x - self:GetLeft())/zoom;
    ry = ry + self:GetHeight()/zoom-math.floor(y - self:GetBottom())/zoom;
    local bigx, bigy = Yatlas_Mini2Big_Coord(rx,ry);
end

function YatlasFrameTemplate:OnUpdate(elapsed)
    self.update_time = self.update_time + elapsed;

    if(self.update_time > 0.5) then
       YAPoints_OnUpdate(self, self.update_time);

        if(self.opt) then
            self:OnWorldMapUpdate();
        end
        self.update_time = 0;
   end
end

function Yatlas_Mini2Big_Coord(x,y)
    return (x - 32)*-MINI2BIGX,(y-32)*-MINI2BIGY;
end

function Yatlas_Big2Mini_Coord(x,y)
    return (x/-MINI2BIGX + 32),(y/-MINI2BIGY + 32);
end

function Yatlas_GetMapZones(map)
    -- map zone ids to name
    local ret = {};    
    if(Yatlas_ZoneIds[map]) then
	for h,v in ipairs(Yatlas_ZoneIds[map]) do
    	    tinsert(ret, Yatlas_areadb[v]);
	end
    end
    table.sort(ret);
    
    return unpack(ret);
end

-- YatlasOptionsFrame

function YatlasOptionsFrameSelect_Initialize() 
    local i = 1;
    local info;
    for h,v in pairs(YatlasOptions.Frames) do
            info = {
                    text = h;
                    func = YatlasOptionsFrameSelect_OnClick;
                    value = _G[h];
            };
            UIDropDownMenu_AddButton(info);
            if(i == 1 and YatlasOptionsFrameSelect.currFrame == nil) then
                YatlasOptionsFrameSelect.currFrame = _G[h];
            end
            i = i + 1;
    end
end

function YatlasOptionsFrameSelect_OnClick(self) 
    UIDropDownMenu_SetSelectedID(YatlasOptionsFrameSelect, self:GetID());
    YatlasOptionsFrameSelect.currFrame = self.value;
    YatlasOptionsFrame_Update();
end

function YatlasOptionsFrame_Update()
    local frame = YatlasOptionsFrameSelect.currFrame;
    if(frame) then
        local lm = frame:GetName();
        local opt = YatlasOptions.Frames[lm];

        YatlasOptionsAlphaSlider:SetValue(opt.Alpha);
        YatlasOptionsIconSizeSlider:SetValue(opt.IconSize);
    end
end

-- YatlasTooltip
YatlasTooltipTemplate = {};

function YatlasTooltipTemplate:OnLoad()
    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r,
                                TOOLTIP_DEFAULT_COLOR.g,
                                TOOLTIP_DEFAULT_COLOR.b);
    self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
    self.lines = {};
    self.nextnew = 1;
    self.nextfree = 1;
end

function YatlasTooltipTemplate:Show()
    local r = getmetatable(self).__index.Show(self);
    self:FixSize();
    return r;
end

function YatlasTooltipTemplate:GetNext()
    if(self.nextfree < self.nextnew) then
        self.nextfree = self.nextfree + 1;
        return self.lines[self.nextfree-1];
    end

    if(self.nextnew > 32) then
        return;
    end

    local f = CreateFrame("Button");

    f:SetHeight(16);
    f:SetWidth(16);
    f:SetParent(self);
    f:EnableMouse(true);

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);
    
    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    f.Clear = YP_Clear;
    f.SetOffset = nilfunc;

    f.Text = f:CreateFontString(nil, "ARTWORK");
    f.Text:SetFontObject(GameFontHighlight);
    f.Text:SetPoint("TOPLEFT", f.Icon, 24, 0);
  
    if(self.nextnew == 1) then
        f:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -8);
    else
        f:SetPoint("TOPLEFT", self.lines[self.nextnew-1], "BOTTOMLEFT", 0, -2);
    end

    tinsert(self.lines, f);
    self.nextnew = self.nextnew + 1;
    self.nextfree = self.nextfree + 1;
    return f;
end

function YatlasTooltipTemplate:FixSize() 
    local hei = 16;
    local wid = 4;

    for h = 1,(self.nextfree-1) do
        hei = hei + self.lines[h]:GetHeight() + 2;
        if(self.lines[h].Text:GetWidth() > wid) then
            wid = self.lines[h].Text:GetWidth();
        end
    end
    self:SetHeight(hei);
    self:SetWidth(wid+64);
end


function YatlasTooltipTemplate:Clear() 
    for h = 1,(self.nextfree-1) do
        self.lines[h]:Hide();
    end
    self.nextfree = 1;
    self:FixSize();
    self:Hide();
end


function YatlasOptions_Toggle()
	if(YatlasOptionsFrame:IsShown()) then
		YatlasOptionsFrame:Hide()
	else
		YatlasOptionsFrame:Show();
	end
end