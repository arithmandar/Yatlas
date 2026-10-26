

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
