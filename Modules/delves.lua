-- Delve entrances (mainline only)
-- C_AreaPoiInfo.GetDelvesForMap(uiMapID) lists the delves of a zone, the same source the
-- world map's DelveEntranceDataProvider uses. The name, the atlas (delves-regular /
-- delves-bountiful) and the position come from C_AreaPoiInfo.GetAreaPOIInfo at run time,
-- so there is no generated data. Classic clients do not have the API and get no points.

if(not (C_AreaPoiInfo and C_AreaPoiInfo.GetDelvesForMap)) then
    return;
end

local set = {name="delves"};
local delves = {};      -- [map] = list from Yatlas_CollectAreaPOIs
local eventframe;

local function atlasexists(atlas)
    return atlas and C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo(atlas) ~= nil;
end

local function createeventframe()
    if(eventframe) then
        return;
    end

    -- bountiful delves change during the day
    eventframe = CreateFrame("Frame");
    eventframe:SetScript("OnEvent", function(self, event)
        wipe(delves);
        YAPoints_ForceUpdate();
    end);
    eventframe:RegisterEvent("AREA_POIS_UPDATED");
end

function set.getpoints(name, map)
    createeventframe();

    if(map == nil) then
        return;
    end

    if(delves[map] == nil) then
        delves[map] = Yatlas_CollectAreaPOIs(map, C_AreaPoiInfo.GetDelvesForMap);
    end

    for _, v in ipairs(delves[map]) do
        local x,y = Yatlas_Big2Mini_Coord(v[1],v[2]);

        YAPoints_AddPoint(nil, "delves", v[3], x, y, nil, {atlas = v[6]});
    end
end

function set.setuppoint(point, env, dat)
    local text, bg = point.Foreground, point.Icon;
    local iconsize = env.iconsize;
    local atlas = dat.userdat.atlas;

    if(not atlasexists(atlas)) then
        atlas = "delves-regular";
    end

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    if(atlasexists(atlas)) then
        iconsize = iconsize * Yatlas_AtlasScale(atlas);
        bg:SetAtlas(atlas);
    else
        bg:SetTexture(YATLAS_ICON_PATH.."Icon-Cave");
        bg:SetTexCoord(0, 1, 0, 1);
    end
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    bg:SetVertexColor(1, 1, 1, 1);
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = YATLAS_POINTS_DELVES;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = YatlasOptions.Frames[lm].PointCfg and not YatlasOptions.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

YAPoints_RegisterSet(set);
