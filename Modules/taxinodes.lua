
-- Flight paths (taxi nodes)
-- positions come from Yatlas_taxinodes (TaxiNodes.db2); the localized name and the
-- discovered state come from the client (Yatlas_GetTaxiInfo / C_TaxiMap) when available.

local set = {name="taxinodes"};
local eventframe;

-- Enum.FlightPathFaction: 0 = Neutral, 1 = Horde, 2 = Alliance
local FACTION_ATLAS = {
    [0] = "TaxiNode_Neutral",
    [1] = "TaxiNode_Horde",
    [2] = "TaxiNode_Alliance",
};
local FACTION_COLOR = {
    [0] = {1, 0.82, 0},
    [1] = {1, 0.3, 0.2},
    [2] = {0.3, 0.6, 1},
};

local function atlasexists(atlas)
    return atlas and C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo(atlas) ~= nil;
end

local function playerfaction()
    local f = UnitFactionGroup("player");
    if(f == "Horde") then
        return 1;
    elseif(f == "Alliance") then
        return 2;
    end
    return 0;
end

local function createeventframe()
    if(eventframe) then
        return;
    end

    -- new flight paths are learned at the flight master
    eventframe = CreateFrame("Frame");
    eventframe:SetScript("OnEvent", function(self, event)
        Yatlas_ResetTaxiInfo();
        YAPoints_ForceUpdate();
    end);
    eventframe:RegisterEvent("TAXIMAP_OPENED");
    eventframe:RegisterEvent("TAXI_NODE_STATUS_CHANGED");
end

function set.getpoints(name, map)
    createeventframe();

    if(type(Yatlas_taxinodes[map]) ~= "table") then
        return;
    end

    local info = Yatlas_GetTaxiInfo(map);
    local myfaction = playerfaction();

    for h,v in ipairs(Yatlas_taxinodes[map]) do
        -- v = {name, worldY, worldX, taxiNodeID, faction, conditional}
        local live = info[v[4]];
        local faction = v[5];
        if(live and live.faction) then
            faction = live.faction;
        end

        local show = (faction == 0 or faction == myfaction);
        if(v[6] == 1 and not live) then
            -- quest / phase dependent node the client doesn't list
            show = false;
        end

        if(show) then
            local x,y = Yatlas_Big2Mini_Coord(v[2],v[3]);
            local label = (live and live.name and live.name ~= "") and live.name or v[1];

            YAPoints_AddPoint(nil, "taxinodes", label, x, y, nil,
                    {faction = faction, atlas = live and live.atlasName,
                     undiscovered = live and live.isUndiscovered});
        end
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local faction = dat.userdat.faction;
    local liveatlas = dat.userdat.atlas;
    local undiscovered = dat.userdat.undiscovered;
    local iconsize = env.iconsize;

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);

    local atlas = (atlasexists(liveatlas) and liveatlas) or FACTION_ATLAS[faction];
    if(atlasexists(atlas)) then
        bg:SetAtlas(atlas);
        bg:SetHeight(iconsize * Yatlas_AtlasScale(atlas));
        bg:SetWidth(iconsize * Yatlas_AtlasScale(atlas));
        if(undiscovered and string.lower(atlas) ~= "taxinode_undiscovered") then
            -- Classic has no undiscovered atlas: dim the faction icon instead. Mainline sends
            -- TaxiNode_Undiscovered, which is grey already; dimming it again made it hard to see.
            bg:SetVertexColor(0.6, 0.6, 0.6, 0.7);
        else
            bg:SetVertexColor(1, 1, 1, 1);
        end
    else
        local c = FACTION_COLOR[faction] or FACTION_COLOR[0];
        bg:SetTexture(YATLAS_ICON_PATH.."Icon-Diamond");
        bg:SetTexCoord(0, 1, 0, 1);
        bg:SetVertexColor(c[1], c[2], c[3], undiscovered and 0.6 or 1);
    end
end

-- the description the world map shows for undiscovered flight paths (FlightPointDataProvider)
local function undiscoveredtext(faction)
    if(faction == 1 and UNDISCOVERED_FACTION_FLIGHTPOINT and FACTION_HORDE) then
        return UNDISCOVERED_FACTION_FLIGHTPOINT:format(FACTION_HORDE);
    elseif(faction == 2 and UNDISCOVERED_FACTION_FLIGHTPOINT and FACTION_ALLIANCE) then
        return UNDISCOVERED_FACTION_FLIGHTPOINT:format(FACTION_ALLIANCE);
    end
    return UNDISCOVERED_NEUTRAL_FLIGHTPOINT;     -- nil on clients without the string
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
    if(dat.userdat.undiscovered) then
        point.Desc:SetText(undiscoveredtext(dat.userdat.faction));
    end
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = YATLAS_POINTS_TAXINODES;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = YatlasOptions.Frames[lm].PointCfg and not YatlasOptions.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

YAPoints_RegisterSet(set);
