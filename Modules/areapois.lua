-- Point sets from the mainline area POI APIs (mainline only)
--   delves : C_AreaPoiInfo.GetDelvesForMap              (world map: DelveEntranceDataProvider)
--   races  : C_AreaPoiInfo.GetDragonridingRacesForMap   (world map: DragonridingRaceDataProvider)
-- The name, the atlas and the position come from C_AreaPoiInfo.GetAreaPOIInfo at run time, so
-- there is no generated data. Classic clients do not have these APIs and get no points.

if(not C_AreaPoiInfo) then
    return;
end

local sets = {};        -- every set below; their caches are wiped on AREA_POIS_UPDATED
local eventframe;

local function atlasexists(atlas)
    return atlas and C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo(atlas) ~= nil;
end

local function createeventframe()
    if(eventframe) then
        return;
    end

    -- e.g. bountiful delves change during the day
    eventframe = CreateFrame("Frame");
    eventframe:SetScript("OnEvent", function(self, event)
        for _, set in ipairs(sets) do
            wipe(set.cache);
        end
        YAPoints_ForceUpdate();
    end);
    eventframe:RegisterEvent("AREA_POIS_UPDATED");
end

-- def = {name, getter, label (function), atlas (fallback), icon (legacy texture)}
local function registerset(def)
    if(def.getter == nil) then
        return;
    end

    local set = {name = def.name, cache = {}};   -- cache[map] = list from Yatlas_CollectAreaPOIs

    function set.getpoints(name, map)
        createeventframe();

        if(map == nil) then
            return;
        end

        if(set.cache[map] == nil) then
            set.cache[map] = Yatlas_CollectAreaPOIs(map, def.getter);
        end

        for _, v in ipairs(set.cache[map]) do
            local x,y = Yatlas_Big2Mini_Coord(v[1],v[2]);

            YAPoints_AddPoint(nil, def.name, v[3], x, y, nil, {atlas = v[6], description = v[4]});
        end
    end

    function set.setuppoint(point, env, dat)
        local text, bg = point.Foreground, point.Icon;
        local iconsize = env.iconsize;
        local atlas = dat.userdat.atlas;

        if(not atlasexists(atlas)) then
            atlas = def.atlas;
        end

        point:Show();
        point:SetOffset(dat.x, dat.y);
        text:SetText("");

        bg:Show();
        if(atlasexists(atlas)) then
            iconsize = iconsize * Yatlas_AtlasScale(atlas);
            bg:SetAtlas(atlas);
        else
            bg:SetTexture(YATLAS_ICON_PATH..def.icon);
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
        point.Desc:SetText(dat.userdat.description);
    end

    function set.configmenu(name, lm)
        if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
            local info = {};
            info.text = def.label();
            info.func = YFOODropDown_do_toggle_normal;
            info.checked = YatlasOptions.Frames[lm].PointCfg and not YatlasOptions.Frames[lm].PointCfg[name];
            info.value = name;
            info.keepShownOnClick = 1;
            UIDropDownMenu_AddButton(info);
        end
    end

    tinsert(sets, set);
    YAPoints_RegisterSet(set);
end

registerset({name = "delves", getter = C_AreaPoiInfo.GetDelvesForMap,
             label = function() return YATLAS_POINTS_DELVES; end,
             atlas = "delves-regular", icon = "Icon-Cave"});

registerset({name = "races", getter = C_AreaPoiInfo.GetDragonridingRacesForMap,
             label = function() return YATLAS_POINTS_RACES; end,
             atlas = "racing", icon = "Icon-Diamond"});
