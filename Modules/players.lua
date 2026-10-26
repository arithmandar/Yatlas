
local set = {name="players", internal = {}};
local eventframe;
local unitlocations = {};

-- Same look as the game's world map (GroupMembersDataProvider): the player is
-- the WorldMapArrow, turned to the facing; group members are the
-- WhiteCircle-RaidBlips atlas in class colour.
local PLAYER_ARROW = "Interface\\WorldMap\\WorldMapArrow";
local MEMBER_ATLAS = "WhiteCircle-RaidBlips";
local MEMBER_FALLBACK = "Interface\\AddOns\\Yatlas\\Images\\Icons\\Icon-PartyUnit";
local PLAYER_SCALE, MEMBER_SCALE = 1.5, 0.8;
local FAST_UPDATE = 0.05;   -- player arrow position / facing, seconds

local function atlasexists(name)
    return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) ~= nil;
end

local function iconsize(frame)
    local opt = frame and YatlasOptions and YatlasOptions.Frames and YatlasOptions.Frames[frame:GetName()];
    return (opt and opt.IconSize) or 16;
end

-- Size the icon around the centre of the point, which YP_SetOffset puts at
-- (iconsize/2, -iconsize/2) from the top left of the point frame.
local function placeicon(point, frame, scale)
    local sz = iconsize(frame);
    local icon = point.Icon;
    icon:ClearAllPoints();
    icon:SetPoint("CENTER", point, "TOPLEFT", sz / 2, -sz / 2);
    icon:SetWidth(sz * scale);
    icon:SetHeight(sz * scale);
end

local function classcolor(unit)
    local _, class = UnitClass(unit);
    local c = class and ((C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class))
            or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]));
    if(c) then
        return c.r, c.g, c.b;
    end
    return 1, 1, 1;
end

local function styleunit(point, frame, unit)
    local icon = point.Icon;
    if(unit == "player") then
        icon:SetTexture(PLAYER_ARROW);
        icon:SetTexCoord(0, 1, 0, 1);
        icon:SetVertexColor(1, 1, 1, 1);
        icon:SetRotation(GetPlayerFacing and GetPlayerFacing() or 0);
        placeicon(point, frame, PLAYER_SCALE);
        -- keep the arrow above the group members
        point:SetFrameLevel(point:GetParent():GetFrameLevel() + 6);
    else
        if(atlasexists(MEMBER_ATLAS)) then
            icon:SetAtlas(MEMBER_ATLAS);
        else
            icon:SetTexture(MEMBER_FALLBACK);
            icon:SetTexCoord(0, 1, 0, 1);
        end
        icon:SetRotation(0);
        icon:SetVertexColor(classcolor(unit));
        placeicon(point, frame, MEMBER_SCALE);
        point:SetFrameLevel(point:GetParent():GetFrameLevel() + 5);
    end
    icon:Show();
end

local addpoint = function(name, unit)
    YAPoints_AddMobilePoint(nil, name, unit, nil, nil);
end

function set.getmobilepoints(name)
    if(eventframe == nil) then
        set.internal.CreateEventFrame();
    end

    addpoint(name, "player");
    for h = 1,40 do
        addpoint(name, "raid"..h);
    end
    for h = 1,5 do
        addpoint(name, "party"..h);
    end
end

function set.OnUpdate(name, frame, elapsed)
    set.internal.OnWorldMapUpdate()
end

function set.internal.OnWorldMapUpdate()
    set.internal.OnWorldMapUpdateUnit("player");
    if(IsInRaid()) then
        for h = 1,GetNumGroupMembers() do
            set.internal.OnWorldMapUpdateUnit("raid"..h);
        end
    else
        for h = 1,GetNumSubgroupMembers() do
            set.internal.OnWorldMapUpdateUnit("party"..h);
        end
    end
end

function set.internal.HideUnit(u)
    if(unitlocations[u]) then
        unitlocations[u] = nil;
        YAPoints_HideMobile("players", u);
    end
end

function set.internal.OnWorldMapUpdateUnit(u)
    if(UnitIsUnit(u, "player") and u ~= "player") then
        -- hide other representations of the player (raidN == player)
        set.internal.HideUnit(u);
        return;
    end

    local map, bigx, bigy = Yatlas_GetUnitLocation(u);

    if(map == nil or Yatlas_mapdb1[map] == nil) then
        -- unknown position (instance, other continent, out of range)
        set.internal.HideUnit(u);
        return;
    end

    local ux, uy = Yatlas_Big2Mini_Coord(bigx, bigy);
    unitlocations[u] = { map, ux, uy};
    YAPoints_Mobile_SetLocation("players", u, map, ux, uy);
    -- class and size can change (unit token reused, icon size option), so restyle
    YAPoints_ForEachMobilePoint("players", u, function(point, frame)
        styleunit(point, frame, u);
    end);
end

-- Between the 0.5 s map updates, keep the player arrow moving and turning.
function set.internal.FastUpdate()
    local map, bigx, bigy = Yatlas_GetUnitLocation("player");
    if(map == nil or Yatlas_mapdb1[map] == nil) then
        return;
    end
    local ux, uy = Yatlas_Big2Mini_Coord(bigx, bigy);
    YAPoints_Mobile_SetLocation("players", "player", map, ux, uy);
    local facing = GetPlayerFacing and GetPlayerFacing() or 0;
    YAPoints_ForEachMobilePoint("players", "player", function(point)
        point.Icon:SetRotation(facing);
    end);
end

function set.internal.CreateEventFrame()
    if(eventframe ~= nil) then
        return;
    end

    eventframe = CreateFrame("Frame");

    eventframe:SetScript("OnEvent", function(self, event)
        if(event == "GROUP_ROSTER_UPDATE") then
            -- drop units that left the group, or moved between party and raid tokens
            local q = {};
            for h,v in pairs(unitlocations) do
                if(not UnitExists(h) or (IsInRaid() and string.sub(h, 1, 5) == "party")
                        or (not IsInRaid() and string.sub(h, 1, 4) == "raid")) then
                    tinsert(q,h);
                end
            end

            for h,v in ipairs(q) do
                set.internal.HideUnit(v);
            end
        end
        set.internal.OnWorldMapUpdate();
    end)

    local elapsedsum = 0;
    eventframe:SetScript("OnUpdate", function(self, elapsed)
        elapsedsum = elapsedsum + elapsed;
        if(elapsedsum < FAST_UPDATE) then
            return;
        end
        elapsedsum = 0;
        if((YatlasFrame and YatlasFrame:IsVisible()) or (BigYatlasFrame and BigYatlasFrame:IsVisible())) then
            set.internal.FastUpdate();
        end
    end)

    eventframe:RegisterEvent("GROUP_ROSTER_UPDATE");
    eventframe:RegisterEvent("ZONE_CHANGED_NEW_AREA");
    eventframe:RegisterEvent("PLAYER_ENTERING_WORLD");
end

function set.setuplegend(point, env, dat)
    point:Show();
    point.Text:SetText(UnitName(dat.name));
    point.Icon:SetTexture(nil);
    point.Text:Show();
    point.Icon:SetHeight(env.iconsize);
    point.Icon:SetWidth(env.iconsize);
end

YAPoints_RegisterSet(set);
