-- Saved options, migrations and options dialog handlers.

YatlasOptions = {}

YA_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = true,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 14,
    ["PointCfg"] = {},
    ["Zoom"] = 256,
}

function Yatlas_EnsureFrameOptions(frame)
    if(YatlasOptions.Frames == nil) then
        YatlasOptions.Frames = {}
    end

    local name = frame:GetName()
    if(YatlasOptions.Frames[name] == nil) then
        YatlasOptions.Frames[name] = {}
    end

    for h,v in pairs(YA_FRAME_OPTION_DEFAULTS) do
        if(YatlasOptions.Frames[name][h] ~= nil) then
            -- Keep existing per-frame settings.
        elseif(YatlasOptions[h] ~= nil) then
            YatlasOptions.Frames[name][h] = YatlasOptions[h]
            YatlasOptions[h] = nil
        elseif(type(v) == "table") then
            YatlasOptions.Frames[name][h] = {}
            for x,k in pairs(v) do
                YatlasOptions.Frames[name][h][x] = k
            end
        else
            YatlasOptions.Frames[name][h] = v
        end
    end
end

-- LibDBIcon uses degrees with 0 = right; the old ButtonLocation used 0 = left.
-- Migrate the old button visibility and position into the LibDBIcon database.
function Yatlas_EnsureMinimapOptions()
    local db = YatlasOptions.Minimap
    if(type(db) ~= "table") then
        db = {}
        if(YatlasOptions.ShowButton == false) then
            db.hide = true
        end
        if(type(YatlasOptions.ButtonLocation) == "number") then
            db.minimapPos = (180 - YatlasOptions.ButtonLocation) % 360
        end
        YatlasOptions.Minimap = db
    end
    YatlasOptions.ShowButton = nil
    YatlasOptions.ButtonLocation = nil
    return db
end

function YatlasOptionsFrameSelect_Initialize()
    local i = 1
    local info
    for h,v in pairs(YatlasOptions.Frames) do
            info = {
                    text = h,
                    func = YatlasOptionsFrameSelect_OnClick,
                    value = _G[h]
            }
            UIDropDownMenu_AddButton(info)
            if(i == 1 and YatlasOptionsFrameSelect.currFrame == nil) then
                YatlasOptionsFrameSelect.currFrame = _G[h]
            end
            i = i + 1
    end
end

function YatlasOptionsFrameSelect_OnClick(self)
    UIDropDownMenu_SetSelectedID(YatlasOptionsFrameSelect, self:GetID())
    YatlasOptionsFrameSelect.currFrame = self.value
    YatlasOptionsFrame_Update()
end

function YatlasOptionsFrame_Update()
    local frame = YatlasOptionsFrameSelect.currFrame
    if(frame) then
        local lm = frame:GetName()
        local opt = YatlasOptions.Frames[lm]

        YatlasOptionsAlphaSlider:SetValue(opt.Alpha)
        YatlasOptionsIconSizeSlider:SetValue(opt.IconSize)
        YatlasOptionsAlphaSlider.ValueText:SetText(format("%.2f", YatlasOptionsAlphaSlider:GetValue()))
        YatlasOptionsIconSizeSlider.ValueText:SetText(format("%.0f", YatlasOptionsIconSizeSlider:GetValue()))
    end
end

function YatlasOptions_Toggle()
    if(YatlasOptionsFrame:IsShown()) then
        YatlasOptionsFrame:Hide()
    else
        YatlasOptionsFrame:Show()
    end
end

YatlasOptionsHandlers = {}

function YatlasOptionsHandlers.OnShow()
    YatlasOptionsButtonEnable:SetChecked(YatlasButton_IsShown())
    YatlasOptionsButtonSlider:SetValue(YatlasButton_GetPosition())
    YatlasOptionsButtonLargeView:SetChecked(YatlasOptions.MinimapLargeView)
end

function YatlasOptionsHandlers.ButtonEnableOnEvent(self)
    self:SetChecked(YatlasButton_IsShown())
end

function YatlasOptionsHandlers.ButtonEnableOnClick(self)
    YatlasButton_SetShown(self:GetChecked() and true or false)
end

function YatlasOptionsHandlers.ButtonLargeViewOnEvent(self)
    self:SetChecked(YatlasOptions.MinimapLargeView)
end

function YatlasOptionsHandlers.ButtonLargeViewOnClick(self)
    YatlasOptions.MinimapLargeView = self:GetChecked() and true or false
end

function YatlasOptionsHandlers.ButtonPositionTip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(format(YATLAS_OPTIONS_BUTTONPOS_TIP, self:GetValue()))
end

function YatlasOptionsHandlers.ButtonPositionOnChange(self)
    if(YatlasButton_GetPosition() ~= self:GetValue()) then
        YatlasButton_SetPosition(self:GetValue())
        if(self:IsVisible()) then
            YatlasOptionsHandlers.ButtonPositionTip(self)
        end
    end
end

function YatlasOptionsHandlers.TrackOnShowOnEvent(self)
    local aframe = next(YatlasOptions.Frames)
    self:SetChecked(YatlasOptions.Frames[aframe].trackonshow ~= nil)
end

function YatlasOptionsHandlers.TrackOnShowOnClick(self)
    for _,v in pairs(YatlasOptions.Frames) do
        v.trackonshow = self:GetChecked() and "player" or nil
    end
end

function YatlasOptionsHandlers.FrameSelectOnEvent(self, event)
    if(event == "VARIABLES_LOADED") then
        UIDropDownMenu_Initialize(self, YatlasOptionsFrameSelect_Initialize)
        UIDropDownMenu_SetSelectedID(self, 1)
        UIDropDownMenu_SetWidth(self, 150)
        YatlasOptionsFrame_Update()
    end
end

function YatlasOptionsHandlers.AlphaOnChange(self)
    self.ValueText:SetText(format("%.2f", self:GetValue()))
    local frame = YatlasOptionsFrameSelect.currFrame
    if(frame) then
        frame:SetAlpha(self:GetValue())
        YatlasOptions.Frames[frame:GetName()].Alpha = self:GetValue()
    end
end

function YatlasOptionsHandlers.IconSizeOnChange(self)
    local frame = YatlasOptionsFrameSelect.currFrame
    local v = self:GetValue()
    self.ValueText:SetText(format("%.0f", v))
    if(frame and YatlasOptions.Frames[frame:GetName()].IconSize ~= v) then
        YatlasOptions.Frames[frame:GetName()].IconSize = v
        YAPoints_Update(frame)
    end
end

function YatlasOptionsHandlers.OkayOnClick()
    Yatlas_PlaySound("GS_TITLE_OPTION_OK")
    YatlasOptionsFrame:Hide()
end
