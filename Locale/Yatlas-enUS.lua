-- Addon metadata (YATLAS_TITLE, YATLAS_VERSION, ...) lives in Core\Constants.lua.

-- localize from this point on as needed
YATLAS_HELP_TEXT = {
    "Yatlas shows a map of the whole world, drawn from the minimap terrain.\n\n"..
    "Click and drag the map to move around, and use the mouse wheel to zoom. "..
    "Use the menus at the top to pick a map or zone, or jump to your own position.\n\n"..
    "Hover over a point to see a tooltip. Use the Show Points menu to choose which points are shown."
    };

YATLAS_TAB_DATA = "Show Data";
YATLAS_TAB_OPTIONS = "Options";

YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_BUTTON_TOOLTIP2 = "- Click to open the Yatlas";
YATLAS_BUTTON_TOOLTIP3 = "- Right-click and drag to move the minimap button.";
YATLAS_PLAYERJUMP = "Goto Player";
YATLAS_OPTIONSBUTTON = "Options";

YATLAS_OPTIONS_TITLE = "Yatlas Options";
YATLAS_OPTIONS_BUTTONPOS = "Minimap Button Position";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d degrees";
YATLAS_OPTIONS_ENABLEBUTTON = "Enable Minimap Button";
YATLAS_OPTIONS_TRACKONSHOW = "Zoom to Player on Show";
YATLAS_OPTIONS_ALPHA = "Transparency";
YATLAS_OPTIONS_ICONSIZE = "Icon Size";
YATLAS_OPTIONS_ENABLECOORD = "Enable Cursor Coordinates";

YATLAS_POINTS_SHOWPOINTS_TITLE = "Show Points";
YATLAS_POINTS_LANDMARKS = "Landmarks";
YATLAS_POINTS_LM_INSTANCES = "Instances";
YATLAS_POINTS_LM_CAPITALS = "Capitals";
YATLAS_POINTS_LM_TOWNS = "Towns";
YATLAS_POINTS_LM_TRAVEL = "Travel";	-- boats, zeppelins, portals (mainline map API)
YATLAS_POINTS_LM_OTHER = "Other";
YATLAS_POINTS_GRAVEYARDS = "Graveyards";
YATLAS_POINTS_TAXINODES = "Flight Paths";
YATLAS_POINTS_DELVES = DELVES_LABEL or "Delves";	-- mainline only (the game's own string when it exists)
YATLAS_POINTS_RACES = DRAGONRIDING_RACES_MAP_TOGGLE or "Skyriding Races";	-- mainline only (the game's own string when it exists)
YATLAS_POINTS_MAPNOTES = "MapNotes";
YATLAS_POINTS_GATHERER = "Gatherer";
YATLAS_POINTS_GATHERER_TREASURE = "Treasure";
YATLAS_POINTS_GATHERER_ORES = "Ores";
YATLAS_POINTS_GATHERER_HERBS = "Herbs";
YATLAS_POINTS_CTMAPMOD = "CTMapMod";

YATLAS_UNKNOWN_ZONE = "Unknown";

YATLAS_BIGDRAGMESSAGE = "Click on map and drag to move view."
YATLAS_SWITCH_TO_BIG = "Switch to large view";
YATLAS_SWITCH_TO_NORMAL = "Switch to normal view";
YATLAS_TOOLTIP_LOCKED_TITLE = "Frame locked";
YATLAS_TOOLTIP_LOCKED = "Click to unlock the frame so you can drag it.";
YATLAS_TOOLTIP_UNLOCKED_TITLE = "Frame unlocked";
YATLAS_TOOLTIP_UNLOCKED = "Drag the frame to move it. Click to lock it.";
YATLAS_TOOLTIP_SHOWPOINTS = "Choose which points are shown on the map.";
YATLAS_TOOLTIP_ZOOM_TITLE = "Zoom";
YATLAS_TOOLTIP_ZOOM = "Show the zoom controls. You can also zoom with the mouse wheel.";
YATLAS_TOOLTIP_PLAYERJUMP = "Click to centre the map on your character.\nShift-click to keep following you as you move.";
YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING = "Following your character. Click to stop.";
YATLAS_TOOLTIP_OPTIONS = "Transparency, icon size, points to show and the minimap button.";

YATLAS_ZOOMIN =     "+";
YATLAS_ZOOMOUT =     "-";

BINDING_NAME_YATLAS_TOGGLE = "Toggle Yatlas Frame";
BINDING_NAME_YATLAS_BIG_TOGGLE = "Toggle Large Yatlas Frame";
BINDING_HEADER_YATLAS = YATLAS_TITLE;

