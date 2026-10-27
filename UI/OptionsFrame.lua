-- The options dialog (YatlasOptionsFrame). Replaces UI\OptionsFrame.xml.

function YatlasOptionsFrameSelect_Initialize()
    local i = 1;
    local info;
    for h,v in pairs(YatlasOptions.Frames) do
            info = {
                    text = h;
                    func = YatlasOptionsFrameSelect_OnClick;
                    value = _G[h];
            };
            UIDropDownMenu_AddButton(info);
            if(i == 1 and YatlasOptionsFrameSelect.currFrame == nil) then
                YatlasOptionsFrameSelect.currFrame = _G[h];
            end
            i = i + 1;
    end
end

function YatlasOptionsFrameSelect_OnClick(self)
    UIDropDownMenu_SetSelectedID(YatlasOptionsFrameSelect, self:GetID());
    YatlasOptionsFrameSelect.currFrame = self.value;
    YatlasOptionsFrame_Update();
end

function YatlasOptionsFrame_Update()
    local frame = YatlasOptionsFrameSelect.currFrame;
    if(frame) then
        local lm = frame:GetName();
        local opt = YatlasOptions.Frames[lm];

        YatlasOptionsAlphaSlider:SetValue(opt.Alpha);
        YatlasOptionsIconSizeSlider:SetValue(opt.IconSize);
    end
end

function YatlasOptions_Toggle()
    if(YatlasOptionsFrame:IsShown()) then
        YatlasOptionsFrame:Hide()
    else
        YatlasOptionsFrame:Show();
    end
end

local function showButtonPositionTip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(format(YATLAS_OPTIONS_BUTTONPOS_TIP, self:GetValue()));
end

local function createOptionsFrame()
    local f = Yatlas_CreateFrame{
        name = "YatlasOptionsFrame", parent = UIParent, size = {420, 410}, anchor = {"CENTER"},
        strata = "DIALOG", toplevel = true, movable = true, mouse = true,
        backdrop = YATLAS_BACKDROP_DIALOG, hidden = true,
    };
    UIPanelWindows["YatlasOptionsFrame"] = { area = "center", pushable = 0, whileDead = 1 };

    local header = Yatlas_CreateTexture(f, {
        name = "YatlasOptionsFrameHeader", file = "Interface\\DialogFrame\\UI-DialogBox-Header",
        size = {256, 58}, anchor = {"TOP", nil, nil, 0, 12},
    });
    Yatlas_CreateText(f, {
        font = "GameFontNormal", text = "YATLAS_OPTIONS_TITLE", anchor = {"TOP", header, nil, 0, -14},
    });

    Yatlas_CreateCheckBox{
        name = "YatlasOptionsButtonEnable", parent = f, anchor = {"TOPLEFT", nil, nil, 24, -29},
        label = "YATLAS_OPTIONS_ENABLEBUTTON",
        onEvent = function(self)
            self:SetChecked(YatlasOptions.ShowButton);
        end,
        onClick = function(self)
            YatlasOptions.ShowButton = self:GetChecked() and true or false;
            YatlasButton_Update();
        end,
    };

    Yatlas_CreateOptionSlider{
        name = "YatlasOptionsButtonSlider", parent = f, anchor = {"TOPLEFT", nil, nil, 56, -64},
        label = "YATLAS_OPTIONS_BUTTONPOS", min = 0, max = 360, step = 1,
        onChange = function(self)
            if(YatlasButton_GetPosition() ~= self:GetValue()) then
                YatlasButton_SetPosition(self:GetValue());
                if(self:IsVisible()) then
                    showButtonPositionTip(self);
                end
            end
        end,
        onEnter = showButtonPositionTip,
    };

    Yatlas_CreateCheckBox{
        name = "YatlasOptionsTrackOnShow", parent = f, anchor = {"TOPLEFT", nil, nil, 24, -90},
        label = "YATLAS_OPTIONS_TRACKONSHOW",
        onEvent = function(self)
            local aframe = next(YatlasOptions.Frames);
            self:SetChecked(YatlasOptions.Frames[aframe].trackonshow ~= nil);
        end,
        -- controls all frames at once
        onClick = function(self)
            for _,v in pairs(YatlasOptions.Frames) do
                v.trackonshow = self:GetChecked() and "player" or nil;
            end
        end,
    };

    local box = Yatlas_CreateOptionBox("YatlasOptionsFrameFrame", f, {
        {"TOPLEFT", nil, nil, 24, -140}, {"TOPRIGHT", nil, nil, -24, -140},
    }, 226);

    Yatlas_CreateFrame{
        type = "Button", name = "YatlasOptionsFrameSelect", parent = box, template = "UIDropDownMenuTemplate",
        anchor = {"TOPLEFT", nil, nil, 10, -12}, events = {"VARIABLES_LOADED"},
        scripts = {
            OnEvent = function(self, event)
                if(event == "VARIABLES_LOADED") then
                    UIDropDownMenu_Initialize(self, YatlasOptionsFrameSelect_Initialize);
                    UIDropDownMenu_SetSelectedID(self, 1);
                    UIDropDownMenu_SetWidth(self, 150);
                    YatlasOptionsFrame_Update();
                end
            end,
        },
    };

    Yatlas_CreateOptionSlider{
        name = "YatlasOptionsAlphaSlider", parent = box, anchor = {"TOPLEFT", nil, nil, 32, -78},
        label = "YATLAS_OPTIONS_ALPHA", min = 0.1, max = 1, step = 0.05,
        onChange = function(self)
            local frame = YatlasOptionsFrameSelect.currFrame;
            if(frame) then
                frame:SetAlpha(self:GetValue());
                YatlasOptions.Frames[frame:GetName()].Alpha = self:GetValue();
            end
        end,
    };

    Yatlas_CreateOptionSlider{
        name = "YatlasOptionsIconSizeSlider", parent = box, anchor = {"TOPLEFT", nil, nil, 32, -122},
        label = "YATLAS_OPTIONS_ICONSIZE", min = 8, max = 36, step = 1,
        onChange = function(self)
            local frame = YatlasOptionsFrameSelect.currFrame;
            local v = self:GetValue();
            if(frame and YatlasOptions.Frames[frame:GetName()].IconSize ~= v) then
                YatlasOptions.Frames[frame:GetName()].IconSize = v;
                YAPoints_Update(frame);
            end
        end,
    };

    Yatlas_CreateButton{
        name = "YatlasOptionsFrameOkay", parent = f, template = "GameMenuButtonTemplate", text = "OKAY",
        anchor = {"BOTTOMRIGHT", nil, nil, -13, 16},
        onClick = function()
            Yatlas_PlaySound("GS_TITLE_OPTION_OK");
            YatlasOptionsFrame:Hide();
        end,
    };
end

createOptionsFrame();
