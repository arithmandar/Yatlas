-- The minimap button, handled by LibDBIcon-1.0 through a LibDataBroker-1.1 launcher.
-- LibDBIcon places the button on round, square and other custom minimap shapes (GetMinimapShape),
-- so Yatlas no longer positions, drags or skins its own button.

local ADDON_NAME = "Yatlas"
local ICON = "Interface\\AddOns\\Yatlas\\Images\\Icons\\Yatlas"

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local launcher = LDB:NewDataObject(ADDON_NAME, {
    type = "launcher",
    label = ADDON_NAME,
    icon = ICON,
    OnClick = function(self, button)
        if(button == "RightButton") then
            YatlasOptions_Toggle()
        elseif(YatlasOptions.MinimapLargeView) then
            BigYatlasFrame:Toggle()
        else
            YatlasFrame:Toggle()
        end
    end,
    OnTooltipShow = function(tooltip)
        if(not tooltip or not tooltip.AddLine) then return end
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP1)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP2, 1, 1, 1)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP4, 1, 1, 1)
        tooltip:AddLine(YATLAS_BUTTON_TOOLTIP3, 1, 1, 1)
    end,
})

function YatlasButton_IsShown()
    return not (YatlasOptions.Minimap and YatlasOptions.Minimap.hide)
end

function YatlasButton_SetShown(shown)
    local db = Yatlas_EnsureMinimapOptions()
    db.hide = not shown
    if(shown) then
        LDBIcon:Show(ADDON_NAME)
    else
        LDBIcon:Hide(ADDON_NAME)
    end
end

function YatlasButton_Update()
    YatlasButton_SetShown(YatlasButton_IsShown())
end

function YatlasButton_GetPosition()
    local db = YatlasOptions.Minimap
    return floor(((db and db.minimapPos) or 225) + 0.5) % 360
end

function YatlasButton_SetPosition(v)
    v = v % 360
    if(YatlasButton_GetPosition() == v) then
        return
    end
    local db = Yatlas_EnsureMinimapOptions()
    db.minimapPos = v
    LDBIcon:Refresh(ADDON_NAME, db)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if(name ~= ADDON_NAME) then return end
    self:UnregisterEvent("ADDON_LOADED")

    if(type(YatlasOptions) ~= "table") then
        YatlasOptions = {}
    end
    LDBIcon:Register(ADDON_NAME, launcher, Yatlas_EnsureMinimapOptions())
    if(YatlasOptionsButtonSlider) then
        YatlasOptionsButtonSlider:SetValue(YatlasButton_GetPosition())
    end
end)
