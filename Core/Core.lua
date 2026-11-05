-- Addon wide setup: saved options, slash commands, support for other addons and switching
-- between the two frames. The map frame logic (YatlasFrameTemplate) is in Core\MapFrame.lua,
-- the frames themselves are built in UI\Yatlas.lua.

YatlasOptions = {}

function YatlasFrame_OnLoadExtra()
    YatlasFrame.YA_PD_allocText = "YA_PD_allocText"
    YatlasFrame.YA_PD_ResetList = "YA_PD_ResetList"

    SLASH_YATLAS1 = "/yatlas"
    SlashCmdList["YATLAS"] = function() YatlasFrame:Toggle() end

    YatlasFrame.hoverTooltip = "YatlasTooltip"

    -- The MapNotes / GatherMate hooks were removed with their point sets (Modules\index.xml does
    -- not load mapnotes, ctmapmod, gatherer or gathermate). The GatherMate one replaced the
    -- GatherMate addon object with a function, which would have broken that addon.

    YatlasMAHelp = YATLAS_HELP_TEXT
end

function BigYatlasFrame_OnLoadExtra()
    -- not a UIPanelWindows entry: the panel manager re-anchors "full" panels, which loses the
    -- SetAllPoints of the frame it is a plain full screen frame that Escape closes
    tinsert(UISpecialFrames, "BigYatlasFrame")

    SLASH_BIGYATLAS1 = "/bigyatlas"
    SlashCmdList["BIGYATLAS"] = function() BigYatlasFrame:Toggle() end

    BigYatlasFrame.RawBigShow = BigYatlasFrame.Show
    BigYatlasFrame.Show = function(self)
        if(SetupFullscreenScale) then
            SetupFullscreenScale(self)
        end
        return self:RawBigShow()
    end

    BigYatlasFrame.hoverTooltip = "BigYatlasTooltip"
end

-- Switch between the normal and the large frame, keeping the map and
-- the point at the centre of the view (each frame keeps its own zoom).
function Yatlas_SwitchFrame(from)
    local to = (from == BigYatlasFrame) and YatlasFrame or BigYatlasFrame
    if(not from or not to or not from.opt or not to.opt) then
        return
    end

    local fvf = _G[from:GetName().."ViewFrame"]
    local fz = from:GetZoom()
    local cx = from.opt.Location[1] + fvf:GetWidth() / fz / 2
    local cy = from.opt.Location[2] + fvf:GetHeight() / fz / 2
    local map = from.opt.Map

    if(from:IsShown()) then
        from:Toggle()
    end
    if(not to:IsShown()) then
        to:Toggle()
    end

    if(to.opt.Map ~= map) then
        to:SetMap(map)
    end
    local tvf = _G[to:GetName().."ViewFrame"]
    local tz = to:GetZoom()
    to:SetLocation(cx - tvf:GetWidth() / tz / 2, cy - tvf:GetHeight() / tz / 2, true)
end
