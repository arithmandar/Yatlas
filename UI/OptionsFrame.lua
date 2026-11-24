-- The options dialog (YatlasOptionsFrame). Replaces UI\OptionsFrame.xml.

local function createOptionsFrame()
    local f = Yatlas_CreateFrame{
        name = "YatlasOptionsFrame", parent = UIParent, size = {420, 436}, anchor = {"CENTER"},
        strata = "DIALOG", toplevel = true, movable = true, mouse = true,
        backdrop = YATLAS_BACKDROP_DIALOG, hidden = true,
    }
    UIPanelWindows["YatlasOptionsFrame"] = { area = "center", pushable = 0, whileDead = 1 }
    -- Sync controls when the dialog is shown.
    f:HookScript("OnShow", YatlasOptionsHandlers.OnShow)

    local header = Yatlas_CreateTexture(f, {
        name = "YatlasOptionsFrameHeader", file = "Interface\\DialogFrame\\UI-DialogBox-Header",
        size = {256, 58}, anchor = {"TOP", nil, nil, 0, 12},
    })
    Yatlas_CreateText(f, {
        font = "GameFontNormal", text = "YATLAS_OPTIONS_TITLE", anchor = {"TOP", header, nil, 0, -14},
    })

    Yatlas_CreateCheckBox{
        name = "YatlasOptionsButtonEnable", parent = f, anchor = {"TOPLEFT", nil, nil, 24, -29},
        label = "YATLAS_OPTIONS_ENABLEBUTTON",
        onEvent = YatlasOptionsHandlers.ButtonEnableOnEvent,
        onClick = YatlasOptionsHandlers.ButtonEnableOnClick,
    }

    Yatlas_CreateOptionSlider{
        name = "YatlasOptionsButtonSlider", parent = f, anchor = {"TOPLEFT", nil, nil, 56, -64},
        label = "YATLAS_OPTIONS_BUTTONPOS", min = 0, max = 360, step = 1,
        onChange = YatlasOptionsHandlers.ButtonPositionOnChange,
        onEnter = YatlasOptionsHandlers.ButtonPositionTip,
    }

    Yatlas_CreateCheckBox{
        name = "YatlasOptionsButtonLargeView", parent = f, anchor = {"TOPLEFT", nil, nil, 24, -90},
        label = "YATLAS_OPTIONS_BUTTONLARGEVIEW",
        onEvent = YatlasOptionsHandlers.ButtonLargeViewOnEvent,
        onClick = YatlasOptionsHandlers.ButtonLargeViewOnClick,
    }

    Yatlas_CreateCheckBox{
        name = "YatlasOptionsTrackOnShow", parent = f, anchor = {"TOPLEFT", nil, nil, 24, -116},
        label = "YATLAS_OPTIONS_TRACKONSHOW",
        onEvent = YatlasOptionsHandlers.TrackOnShowOnEvent,
        onClick = YatlasOptionsHandlers.TrackOnShowOnClick,
    }

    local box = Yatlas_CreateOptionBox("YatlasOptionsFrameFrame", f, {
        {"TOPLEFT", nil, nil, 24, -166}, {"TOPRIGHT", nil, nil, -24, -166},
    }, 226)

    Yatlas_CreateFrame{
        type = "Button", name = "YatlasOptionsFrameSelect", parent = box, template = "UIDropDownMenuTemplate",
        anchor = {"TOPLEFT", nil, nil, 10, -12}, events = {"VARIABLES_LOADED"},
        scripts = {
            OnEvent = YatlasOptionsHandlers.FrameSelectOnEvent,
        },
    }

    local alpha = Yatlas_CreateOptionSlider{
        name = "YatlasOptionsAlphaSlider", parent = box, anchor = {"TOPLEFT", nil, nil, 32, -78},
        label = "YATLAS_OPTIONS_ALPHA", min = 0.1, max = 1, step = 0.05,
        onChange = YatlasOptionsHandlers.AlphaOnChange,
    }
    alpha.ValueText = Yatlas_CreateText(alpha, {
        font = "GameFontHighlight", anchor = {"LEFT", alpha, "RIGHT", 12, 0},
    })

    local iconSize = Yatlas_CreateOptionSlider{
        name = "YatlasOptionsIconSizeSlider", parent = box, anchor = {"TOPLEFT", nil, nil, 32, -122},
        label = "YATLAS_OPTIONS_ICONSIZE", min = 8, max = 36, step = 1,
        onChange = YatlasOptionsHandlers.IconSizeOnChange,
    }
    iconSize.ValueText = Yatlas_CreateText(iconSize, {
        font = "GameFontHighlight", anchor = {"LEFT", iconSize, "RIGHT", 12, 0},
    })

    Yatlas_CreateButton{
        name = "YatlasOptionsFrameOkay", parent = f, template = "GameMenuButtonTemplate", text = "OKAY",
        anchor = {"BOTTOMRIGHT", nil, nil, -13, 16},
        onClick = YatlasOptionsHandlers.OkayOnClick,
    }
end

createOptionsFrame()
