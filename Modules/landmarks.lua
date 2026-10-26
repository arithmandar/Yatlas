
-- userdat for our own points: {nil,nil,nil,nil, fallback icon code, atlas}
-- the atlases are the ones the game's own maps use; the fallback codes select
-- the old Yatlas icons when an atlas is not available (see setuppoint)
local landmarkaltdungeon = {nil,nil,nil,nil,-1,"Dungeon"};     -- blue circle
local landmarkaltraid = {nil,nil,nil,nil,-1,"Raid"};           -- green circle
local landmarkalttown = {nil,nil,nil,nil,-4,"poi-town"};

local function atlasexists(atlas)
    return atlas and C_Texture and C_Texture.GetAtlasInfo
            and C_Texture.GetAtlasInfo(atlas) ~= nil;
end

local set = {name="landmarks"};

function set.getpoints(name, map) 
    -- we got these from map api.  don't use if we see Megellan
    if(type(Yatlas_Landmarks[map]) == "table" and Magellan_Init == nil) then
        for h,v in ipairs(Yatlas_Landmarks[map]) do
            local x,y = Yatlas_Big2Mini_Coord(v[1],v[2]);

            YAPoints_AddPoint(nil, "landmarks", v[3], x, y, nil, Yatlas_Landmarks[map][h]);
        end
    end

    -- we got these...from OURSELVES!
    if(type(Yatlas_instances[map]) == "table") then
        for h,v in ipairs(Yatlas_instances[map]) do
            local x,y = Yatlas_Big2Mini_Coord(v[2],v[3]);

            -- v[5] = Map.db2 InstanceType (1 = dungeon, 2 = raid)
            local alt = (v[5] == 2) and landmarkaltraid or landmarkaltdungeon;
            YAPoints_AddPoint(nil, "landmarks", v[1], x, y, nil, alt);
        end
    end

     -- 'other towns' ...we got these...from OURSELVES!
    if(type(Yatlas_towns2[map]) == "table") then
        for h,v in ipairs(Yatlas_towns2[map]) do
            local x,y = Yatlas_Big2Mini_Coord(v[2],v[3]);

            YAPoints_AddPoint(nil, "landmarks", v[1], x, y, nil, landmarkalttown);
        end
    end
end

function set.setuppoint(point, env, dat) 
    local text, bg = point.Foreground, point.Icon;
    local x1, x2, y1, y2;
    local r, g, b;
    local bgtextname;
    local iconsize = env.iconsize;

    local tindex = dat.userdat[5];
    local atlas = dat.userdat[6];

    -- prefer the game's atlas (C_AreaPoiInfo atlasName, or our dungeon / raid / town icons)
    if(not atlasexists(atlas)) then
        atlas = nil;
    end

    if(atlas) then
        tindex = nil;
    elseif(tindex == nil) then
        tindex = 4;
    elseif(tindex >= 0 and tindex ~= 4 and tindex ~= 5 and Yatlas_GetPOITextureCoords == nil) then
        tindex = 4;
    end

    if(atlas) then
        r,g,b = 1,1,1;
    elseif(tindex == 4 or tindex == 5 or tindex < 0) then
        x1 = 0; y1 = 0;
        x2 = 1; y2 = 1;

        r = 0.2;
        g = 0.6;
        b = 1;
        bgtextname = "Interface\\AddOns\\Yatlas\\images\\Icons\\Icon-Circle";
        if(tindex == 5) then
            bgtextname = "Interface\\AddOns\\Yatlas\\images\\Icons\\Icon-Star";
            iconsize = iconsize+2;
        elseif(tindex == -1) then
            r = 0.9;
            g = 0.1;
            b = 0.9;
            bgtextname = "Interface\\AddOns\\Yatlas\\images\\Icons\\Icon-Cave";
        elseif(tindex == -4) then
            r = 0.3;
            g = 0.8;
            b = 1;
            bgtextname = "Interface\\AddOns\\Yatlas\\images\\Icons\\Icon-Exclaim";
        end
    else
       x1, x2, y1, y2 = Yatlas_GetPOITextureCoords(tindex);
       r,g,b = 1,1,1;
       bgtextname  = "Interface\\Minimap\\POIIcons"
    end

    point:Show();
    point:SetOffset(dat.x, dat.y);
    text:SetText("");

    bg:Show();
    bg:SetHeight(iconsize);
    bg:SetWidth(iconsize);
    if(atlas) then
        bg:SetAtlas(atlas);
    else
        bg:SetTexture(bgtextname);
        bg:SetTexCoord(x1, x2, y1, y2);
    end
    bg:SetVertexColor(r, g, b, 1);
end

function set.setuplegend(point, env, dat)
    env.iconsize = 16;
    set.setuppoint(point, env, dat);

    point.Text:SetText(dat.name);
end

function set.configmenu(name, lm)
    if(UIDROPDOWNMENU_MENU_LEVEL == 1) then
        local info = {};
        info.text = YATLAS_POINTS_LANDMARKS;
        info.func = YFOODropDown_do_toggle_normal;
        info.checked = YatlasOptions.Frames[lm].PointCfg and not YatlasOptions.Frames[lm].PointCfg[name];
        info.value = name;
        info.keepShownOnClick = 1;
        UIDropDownMenu_AddButton(info);
    end
end

YAPoints_RegisterSet(set);

