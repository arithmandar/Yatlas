-- Yatlas compatibility layer for the modern Classic client (MoP Classic 5.5.4+).
--
-- The legacy world map API (GetMapInfo, SetMapZoom, GetPlayerMapPosition,
-- GetNumMapLandmarks, GetMapLandmarkInfo, WORLD_MAP_UPDATE, ...) no longer exists.
-- Everything Yatlas needs from it is wrapped here so the rest of the addon only
-- deals with Yatlas' own coordinate system:
--
--   map  = Map.db2 Directory (the key of Yatlas_mapdb1 / Yatlas_mapareas)
--   bigx = world Y   (the first value of Yatlas_Big2Mini_Coord)
--   bigy = world X   (the second value of Yatlas_Big2Mini_Coord)

-- ---------------------------------------------------------------------------
-- Renamed / moved globals
-- ---------------------------------------------------------------------------

Yatlas_GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata;
Yatlas_GetPOITextureCoords = (C_Minimap and C_Minimap.GetPOITextureCoords) or GetPOITextureCoords;

-- backdrops (the <Backdrop> XML tag was removed; frames inherit BackdropTemplate
-- and call SetBackdrop with one of these in their OnLoad)
YATLAS_BACKDROP_TOOLTIP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
};

YATLAS_BACKDROP_DIALOG = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
};

YATLAS_BACKDROP_SLIDER = {
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 6, right = 6, top = 3, bottom = 3 },
};

function Yatlas_ApplyBackdrop(frame, backdrop)
    if(frame and frame.SetBackdrop) then
        frame:SetBackdrop(backdrop);
    end
end

function Yatlas_PlaySound(kitname)
    if(SOUNDKIT and SOUNDKIT[kitname]) then
        PlaySound(SOUNDKIT[kitname]);
    end
end

-- ---------------------------------------------------------------------------
-- Map.db2 ID <-> Directory
-- ---------------------------------------------------------------------------

local ya_dir_by_mapid;

function Yatlas_MapIDToDirectory(mapid)
    if(mapid == nil) then
        return nil;
    end

    if(ya_dir_by_mapid == nil) then
        ya_dir_by_mapid = {};
        for dir, id in pairs(Yatlas_WorldMapIds2) do
            -- only maps we actually have minimap tiles for
            if(Yatlas_mapdb1[dir]) then
                ya_dir_by_mapid[id] = dir;
            end
        end
    end

    return ya_dir_by_mapid[mapid];
end

-- ---------------------------------------------------------------------------
-- Unit positions
-- ---------------------------------------------------------------------------

-- returns map, bigx, bigy  (nil if the unit isn't on a map Yatlas knows)
function Yatlas_GetUnitLocation(unit)
    if(not UnitExists(unit)) then
        return nil;
    end

    local worldx, worldy, mapid;

    -- world coordinates straight from the client (open world only)
    if(UnitPosition) then
        local _;
        worldx, worldy, _, mapid = UnitPosition(unit);
    end

    -- otherwise go through the ui map of the unit
    if(worldx == nil and C_Map and C_Map.GetBestMapForUnit) then
        local uimap = C_Map.GetBestMapForUnit(unit);
        local pos = uimap and C_Map.GetPlayerMapPosition(uimap, unit);
        if(pos) then
            local cont, world = C_Map.GetWorldPosFromMapPos(uimap, pos);
            if(world) then
                mapid = cont;
                worldx, worldy = world:GetXY();
            end
        end
    end

    if(worldx == nil) then
        return nil;
    end

    local map = Yatlas_MapIDToDirectory(mapid);
    if(map == nil) then
        return nil;
    end

    return map, worldy, worldx;
end

-- ---------------------------------------------------------------------------
-- Landmarks (towns, points of interest) from C_AreaPoiInfo
-- ---------------------------------------------------------------------------

-- fills Yatlas_Landmarks[map] with {bigx, bigy, name, description, textureIndex, atlasName}
function Yatlas_LoadLandmarks(map)
    if(map == nil or Yatlas_Landmarks[map] ~= nil) then
        return false;
    end

    local list = {};
    Yatlas_Landmarks[map] = list;

    if(not (C_AreaPoiInfo and C_Map and C_Map.GetWorldPosFromMapPos)
            or type(Yatlas_UiMapIds[map]) ~= "table") then
        return false;
    end

    local mapid = Yatlas_WorldMapIds2[map];
    local seen = {};

    for _, uimap in pairs(Yatlas_UiMapIds[map]) do
        local pois = C_AreaPoiInfo.GetAreaPOIForMap(uimap) or {};

        for _, poi in ipairs(pois) do
            if(not seen[poi]) then
                local info = C_AreaPoiInfo.GetAreaPOIInfo(uimap, poi);

                if(info and info.position) then
                    local cont, world = C_Map.GetWorldPosFromMapPos(uimap, info.position);

                    if(world and (mapid == nil or cont == mapid)) then
                        local worldx, worldy = world:GetXY();
                        seen[poi] = true;
                        tinsert(list, {worldy, worldx, info.name, info.description,
                                       info.textureIndex, info.atlasName});
                    end
                end
            end
        end
    end

    return true;
end

-- area POIs (e.g. capture points, world events) changed: rebuild on demand
function Yatlas_ResetLandmarks()
    for h in pairs(Yatlas_Landmarks) do
        Yatlas_Landmarks[h] = nil;
    end
end
