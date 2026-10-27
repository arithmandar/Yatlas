-- The Yatlas frames: the normal YatlasFrame and the full screen BigYatlasFrame.
-- Replaces UI\Yatlas.xml; the building blocks are in UI\Templates.lua.

local IMG = YATLAS_IMAGE_PATH;

local function texture(parent, layer, file, w, h, anchor, name)
    return Yatlas_CreateTexture(parent, {name = name, layer = layer, file = file, size = {w, h}, anchor = anchor});
end

local function createYatlasFrame()
    local f = Yatlas_CreateMapFrame{
        name = "YatlasFrame", size = {539, 628}, anchor = {"TOPLEFT", UIParent, nil, 64, -64},
        strata = "HIGH", toplevel = true, movable = true,
    };

    texture(f, "BACKGROUND", "Interface\\WorldMap\\WorldMap-Icon", 64, 64, {"TOPLEFT", nil, nil, 6, -4}, "YatlasFramePortrait");
    texture(f, "BORDER", IMG.."frame-topleft", 512, 512, {"TOPLEFT", nil, nil, 0, 0});
    texture(f, "BORDER", IMG.."frame-botleft", 512, 128, {"TOPLEFT", nil, nil, 0, -510});
    texture(f, "BORDER", IMG.."frame-topright", 128, 512, {"TOPLEFT", nil, nil, 512, 0});
    texture(f, "BORDER", IMG.."frame-botright", 128, 128, {"TOPLEFT", nil, nil, 512, -510});

    Yatlas_CreateText(f, {
        name = "YatlasFrameName", layer = "OVERLAY", font = "GameFontHighlight", text = "YATLAS_TITLE",
        size = {256, 12}, anchor = {"TOP", nil, nil, 1, -17},
    });
    Yatlas_CreateText(f, {
        name = "YatlasFrameVersion", layer = "OVERLAY", font = "GameFontHighlight", text = "YATLAS_VERSION",
        size = {112, 12}, justify = "RIGHT", color = {0.4, 0.4, 0.4}, anchor = {"TOPRIGHT", nil, nil, -68, -18},
    });

    local close = Yatlas_CreateCloseButton("YatlasFrameCloseButton", f,
        {"CENTER", f, "TOPRIGHT", -8, -25}, true);
    local lock = Yatlas_CreateLockButton("YatlasFrameLockButton", f, {"RIGHT", close, "LEFT", 0, 0});
    Yatlas_CreateSwitchButton("YatlasFrameSwitchButton", f, {"RIGHT", lock, "LEFT", 0, 0}, "Bigger");
    Yatlas_CreateViewFrame(f, {512, 512}, {"TOPLEFT", nil, nil, 22, -74});
    Yatlas_CreateDropDown("YatlasFrameDropDown", f, {"TOPLEFT", nil, nil, 58, -40},
        YatlasFrameDropDown_OnLoad, YatlasFrameDropDown_OnEvent);
    Yatlas_CreateDropDown("YatlasFrameDropDown2", f, {"TOPLEFT", nil, nil, 235, -40},
        YatlasFrameDropDown2_OnLoad, YatlasFrameDropDown2_OnEvent);
    Yatlas_CreatePlayerJumpButton("YatlasFramePlayerJumpButton", f, {"TOPLEFT", nil, nil, 425, -42});
    Yatlas_CreateButton{
        name = "YatlasFrameOptionsButton", parent = f, template = "UIPanelButtonTemplate", size = {108, 24},
        text = "YATLAS_OPTIONSBUTTON", anchor = {"BOTTOMRIGHT", nil, "BOTTOMRIGHT", -5, 8}, raise = true,
        onClick = function() YatlasOptions_Toggle(); end,
        tooltip = {"YATLAS_OPTIONSBUTTON", "YATLAS_TOOLTIP_OPTIONS", "ANCHOR_TOPRIGHT"},
    };

    tinsert(UISpecialFrames, "YatlasFrame");
    YatlasFrame_Bootstrap(f);
    YatlasFrame_OnLoadExtra();

    local view = YatlasFrameViewFrame;
    Yatlas_CreateTooltip("YatlasTooltip", f, {"BOTTOMRIGHT", view, "BOTTOMRIGHT", 0, 0});
    Yatlas_CreateYFOO("YFOO", view, {"BOTTOMRIGHT", nil, "BOTTOMRIGHT", -8, 8});
    Yatlas_CreateZoomButton("YatlasFrameZoomButton", view, {"BOTTOMLEFT", nil, "BOTTOMLEFT", 8, 8},
        "YatlasFrameZoomFrame", {"TOP", nil, nil, 0, -20}, f);
end

local function createBigYatlasFrame()
    local f = Yatlas_CreateMapFrame{name = "BigYatlasFrame", allPoints = UIParent, strata = "FULLSCREEN"};

    -- 1024x768 area the controls are positioned in
    local guide = Yatlas_CreateFrame{
        name = "BigYatlasPositioningGuide", parent = f, size = {1024, 768},
        anchor = {"CENTER", nil, "CENTER", 0, 0},
    };
    Yatlas_CreateText(guide, {
        name = "BigYatlasPositioningGuideVersion", font = "GameFontHighlight", text = "YATLAS_VERSION",
        size = {112, 12}, justify = "RIGHT", color = {0.4, 0.4, 0.4}, anchor = {"TOPRIGHT", nil, nil, -54, -6},
    });

    -- the frame is made of 4 x 3 textures of 256x256, centred on the screen
    local rows = {
        {"top", 384, {1, 2, 3, 4}}, {"mid", 128, {1, 4}}, {"bot", -128, {1, 2, 3, 4}},
    };
    for _,row in ipairs(rows) do
        for _,col in ipairs(row[3]) do
            texture(f, "ARTWORK", IMG.."bframe-"..row[1]..col, 256, 256,
                {"TOPLEFT", nil, "CENTER", -768 + col * 256, row[2]});
        end
    end
    Yatlas_CreateText(f, {
        layer = "ARTWORK", font = "GameFontNormal", text = "YATLAS_TITLE", anchor = {"CENTER", nil, nil, 0, 372},
    });

    local close = Yatlas_CreateCloseButton("BigYatlasFrameCloseButton", f,
        {"TOPRIGHT", guide, "TOP", 510, 0});
    Yatlas_CreateSwitchButton("BigYatlasFrameSwitchButton", f, {"RIGHT", close, "LEFT", 8, 0}, "Smaller");
    local dd = Yatlas_CreateDropDown("BigYatlasFrameDropDown", f, {"TOP", guide, "TOP", -120, -35},
        YatlasFrameDropDown_OnLoad, YatlasFrameDropDown_OnEvent, "CONTINENT");
    local dd2 = Yatlas_CreateDropDown("BigYatlasFrameDropDown2", f, {"LEFT", dd, "RIGHT", 13, 0},
        YatlasFrameDropDown2_OnLoad, YatlasFrameDropDown2_OnEvent, "ZONE");
    Yatlas_CreatePlayerJumpButton("BigYatlasFramePlayerJumpButton", f, {"LEFT", dd2, "RIGHT", 11, 2});
    Yatlas_CreateViewFrame(f, {1004, 670}, {"TOPLEFT", guide, "TOP", -502, -69});

    YatlasFrame_Bootstrap(f);
    BigYatlasFrame_OnLoadExtra();

    Yatlas_CreateTooltip("BigYatlasTooltip", f, {"BOTTOMRIGHT", BigYatlasFrameViewFrame, "BOTTOMRIGHT", 0, 0});
    Yatlas_CreateYFOO("BigYFOO", guide, {"BOTTOMRIGHT", nil, "BOTTOMRIGHT", -11, 4});
    Yatlas_CreateZoomButton("BigYatlasFrameZoomButton", BigYatlasFrameViewFrame,
        {"BOTTOMLEFT", nil, "BOTTOMLEFT", 11, 4}, "BigYatlasFrameZoomFrame", {"BOTTOM", nil, nil, 0, 20}, f);
end

createYatlasFrame();
createBigYatlasFrame();
