-- Addon wide setup: saved options, slash commands, support for other addons and switching
-- between the two frames. The map frame logic (YatlasFrameTemplate) is in Core\MapFrame.lua,
-- the frames themselves are built in UI\Yatlas.lua.

YatlasOptions = {}

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
    if(GatherMate) then
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
    -- not a UIPanelWindows entry: the panel manager re-anchors "full" panels, which loses the
    -- SetAllPoints of the frame; it is a plain full screen frame that Escape closes
    tinsert(UISpecialFrames, "BigYatlasFrame");

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

function YatlasFrame_OnEventExtra(self, event, ...)
    local addon = ...;

    if(event == "ADDON_LOADED" and addon == "Yatlas") then
        if(myAddOnsFrame_Register) then
            myAddOnsFrame_Register(YatlasDetails, YatlasMAHelp);
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
