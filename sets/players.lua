
local set = {name="players", internal = {}};
local eventframe;
local unitlocations = {};

local addpoint = function(name, unit)
    YAPoints_AddMobilePoint(nil, name, unit, nil, nil);

    YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetTexture",
            "Interface\\AddOns\\Yatlas\\images\\Icons\\Icon-PartyUnit");
    if(string.find(unit,"party")) then
        YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",1,0.4,0.4,1);
    elseif(string.find(unit,"raid")) then
        YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",1,1,0.3,1);
    else
        YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetVertexColor",0.4,0.6,1,1);
    end
    YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetWidth",16);
    YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetHeight",16);
    YAPoints_SetupMobilePointF(nil, name, unit, "Icon","SetTexCoord",0,1,0,1);
    YAPoints_SetupMobilePointF(nil, name, unit, "Icon","Show");
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
