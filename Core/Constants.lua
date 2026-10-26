-- Yatlas constants.
-- Loaded right after Core\Compat.lua (it needs Yatlas_GetAddOnMetadata) and
-- before Locale\ (BINDING_HEADER_YATLAS uses YATLAS_TITLE).

local ADDON = "Yatlas";

local function meta(field)
    local v = Yatlas_GetAddOnMetadata(ADDON, field);
    -- unpackaged checkout: the packager has not replaced @tokens@ yet
    if(v == nil or v == "" or string.find(v, "@", 1, true)) then
        return nil;
    end
    return v;
end

-- ---------------------------------------------------------------------------
-- Addon metadata (from Yatlas.toc)
-- ---------------------------------------------------------------------------
YATLAS_TITLE        = meta("Title") or ADDON;
YATLAS_VERSION      = meta("Version") or "dev";
YATLAS_RELEASE_DATE = meta("X-Date");          -- @project-date-iso@, filled in by the packager
YATLAS_AUTHOR       = meta("Author") or "";
YATLAS_CREDITS      = meta("X-Credits") or "";
YATLAS_WEBSITE      = meta("X-Website") or "";

-- ---------------------------------------------------------------------------
-- Texture paths
-- ---------------------------------------------------------------------------
YATLAS_IMAGE_PATH   = "Interface\\AddOns\\Yatlas\\Images\\";
YATLAS_ICON_PATH    = YATLAS_IMAGE_PATH.."Icons\\";
YATLAS_MINIMAP_PATH = "World\\Minimaps\\";    -- only for pre-5.5.4 tile names; tiles are FileDataIDs now

-- ---------------------------------------------------------------------------
-- Coordinates: one minimap tile is 533 1/3 yards
-- ---------------------------------------------------------------------------
YATLAS_MINI2BIG_X = 533.3333;
YATLAS_MINI2BIG_Y = 533.3333;

-- ---------------------------------------------------------------------------
-- Per-frame option defaults (YatlasOptions.Frames[frame])
-- ---------------------------------------------------------------------------
YA_FRAME_OPTION_DEFAULTS = {
    ["Locked"] = true,
    ["Map"] = "Kalimdor",
    ["Location"] = {31.0625, 33.250},
    ["Alpha"] = 1,
    ["IconSize"] = 14,
    ["PointCfg"] = {},
    ["Zoom"] = 256,
};

-- ---------------------------------------------------------------------------
-- Backdrops (the <Backdrop> XML tag was removed; frames inherit
-- BackdropTemplate and call Yatlas_ApplyBackdrop with one of these)
-- ---------------------------------------------------------------------------
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
