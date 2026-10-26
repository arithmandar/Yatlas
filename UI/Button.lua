

function YatlasButton_OnEvent(event) 
    if(event == "VARIABLES_LOADED") then
        YatlasOptionsButtonSlider:SetValue(YatlasOptions.ButtonLocation);
        YatlasButton_Update();
        -- Retail Edit Mode / other addons can resize the minimap
        if(not YatlasButtonFrame.sizehooked) then
            YatlasButtonFrame.sizehooked = true;
            Minimap:HookScript("OnSizeChanged", function()
                if(YatlasOptions) then YatlasButton_Update(); end
            end);
        end
    end
end

-- Look of the button: the game's round minimap button textures (UI-Minimap-Background,
-- MiniMap-TrackingBorder) around Interface\WorldMap\WorldMap-Icon, the icon of the TOC.
-- The border texture has its ring in the top left corner; mainline draws it a bit smaller.
local BUTTON_LOOK = {
    mainline = {border = 50, background = 24, icon = 18},
    classic  = {border = 53, background = 20, bgx = 7, bgy = -5, icon = 17, iconx = 7, icony = -6},
};
local ICON_INSET = 0.05;    -- the icon's own rim is trimmed; pressing shows it in full

function YatlasButton_SetupLook(button)
    local look = (YATLAS_CLIENT and YATLAS_CLIENT.isRetail) and BUTTON_LOOK.mainline or BUTTON_LOOK.classic;

    -- XML textures without <Anchors> are attached to all points of the button, which
    -- would override SetSize: clear the points first
    button.Border:ClearAllPoints();
    button.Background:ClearAllPoints();
    button.Icon:ClearAllPoints();

    button.Border:SetSize(look.border, look.border);
    button.Border:SetPoint("TOPLEFT");

    button.Background:SetSize(look.background, look.background);
    button.Icon:SetSize(look.icon, look.icon);
    if(look.bgx) then
        button.Background:SetPoint("TOPLEFT", look.bgx, look.bgy);
        button.Icon:SetPoint("TOPLEFT", look.iconx, look.icony);
    else
        button.Background:SetPoint("CENTER");
        button.Icon:SetPoint("CENTER");
    end

    YatlasButton_SetPressed(button, false);
end

function YatlasButton_SetPressed(button, pressed)
    local d = pressed and 0 or ICON_INSET;
    button.Icon:SetTexCoord(d, 1 - d, d, 1 - d);
end

-- The button circles the minimap at (minimap radius + 8), measured from the minimap center.
-- The minimap is 140x140 in Classic but 198x198 in Retail, so the size is read at run time
-- instead of the old fixed 70 / 78 offsets.
local function minimapradius()
    return (Minimap:GetWidth() or 140) / 2 + 8;
end

function YatlasButton_Update()
    if(YatlasOptions.ShowButton) then
        local r = minimapradius();
        YatlasButtonFrame:ClearAllPoints();
        YatlasButtonFrame:SetPoint("CENTER", Minimap, "CENTER",
            -(r * cos(YatlasOptions.ButtonLocation)),
            r * sin(YatlasOptions.ButtonLocation));
        YatlasButtonFrame:Show();
    else
        YatlasButtonFrame:Hide();
    end
end

function YatlasButton_BeingDragged()
    -- angle of the cursor around the minimap center (0 = left, 90 = top)
    local scale = Minimap:GetEffectiveScale();
    local xpos, ypos = GetCursorPosition();
    local cx, cy = Minimap:GetCenter();

    xpos = cx - xpos / scale;
    ypos = ypos / scale - cy;

    YatlasButton_SetPosition(math.deg(math.atan2(ypos, xpos)));
end

function YatlasButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText(YATLAS_BUTTON_TOOLTIP1);
    GameTooltip:AddLine(YATLAS_BUTTON_TOOLTIP2);
    GameTooltip:AddLine(YATLAS_BUTTON_TOOLTIP3);
    GameTooltip:Show();
end

function YatlasButton_SetPosition(v)
    if(v < 0) then
        v = v + 360;
    end
    if(v == YatlasOptions.ButtonLocation) then
        return;
    end

    YatlasOptionsButtonSlider:SetValue(YatlasOptions.ButtonLocation);

    YatlasOptions.ButtonLocation = v;
    YatlasButton_Update()
end

function YatlasButton_GetPosition()
    return YatlasOptions.ButtonLocation;
end


function YatlasButton_OnClick()
    YatlasFrame:Toggle();
end
