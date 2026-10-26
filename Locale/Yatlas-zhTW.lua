-- zhTW localization for Yatlas (UTF-8)
-- Strings not defined here fall back to Yatlas-enUS.lua.

if (GetLocale() == "zhTW") then

YATLAS_HELP_TEXT = {
    "Yatlas 以小地圖地形呈現整個世界的地圖。\n\n在地圖上按住滑鼠拖曳即可移動，滾動滑鼠滾輪可縮放。可從上方選單切換地圖或跳到指定區域，也可以跳到自己的位置。\n\n將滑鼠移到標記上可顯示提示。使用「顯示標記」選單可選擇要顯示哪些標記。"
};

YATLAS_TAB_DATA = "顯示資料";
YATLAS_TAB_OPTIONS = "選項";
YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_BUTTON_TOOLTIP2 = "- 點擊開啟 Yatlas";
YATLAS_BUTTON_TOOLTIP3 = "- 按住右鍵拖曳可移動小地圖按鈕";
YATLAS_PLAYERJUMP = "玩家位置";
YATLAS_OPTIONSBUTTON = "選項";
YATLAS_OPTIONS_TITLE = "Yatlas 選項";
YATLAS_OPTIONS_BUTTONPOS = "小地圖按鈕位置";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d 度";
YATLAS_OPTIONS_ENABLEBUTTON = "顯示小地圖按鈕";
YATLAS_OPTIONS_TRACKONSHOW = "開啟時移到玩家位置";
YATLAS_OPTIONS_ALPHA = "透明度";
YATLAS_OPTIONS_ICONSIZE = "圖示大小";
YATLAS_OPTIONS_ENABLECOORD = "顯示游標座標";
YATLAS_POINTS_SHOWPOINTS_TITLE = "顯示標記";
YATLAS_POINTS_LANDMARKS = "地標";
YATLAS_POINTS_GRAVEYARDS = "墓地";
YATLAS_POINTS_TAXINODES = "飛行點";
YATLAS_POINTS_DELVES = DELVES_LABEL or "探究";
YATLAS_POINTS_RACES = DRAGONRIDING_RACES_MAP_TOGGLE or "飛龍競速";
YATLAS_POINTS_MAPNOTES = "MapNotes";
YATLAS_POINTS_GATHERER = "Gatherer";
YATLAS_POINTS_GATHERER_TREASURE = "寶藏";
YATLAS_POINTS_GATHERER_ORES = "礦石";
YATLAS_POINTS_GATHERER_HERBS = "草藥";
YATLAS_POINTS_CTMAPMOD = "CTMapMod";
YATLAS_UNKNOWN_ZONE = "未知";
YATLAS_BIGDRAGMESSAGE = "按住滑鼠拖曳地圖以移動視角。";
BINDING_NAME_YATLAS_TOGGLE = "切換 Yatlas 視窗";
BINDING_NAME_YATLAS_BIG_TOGGLE = "切換大型 Yatlas 視窗";

YATLAS_SWITCH_TO_BIG = "切換到大型檢視";
YATLAS_SWITCH_TO_NORMAL = "切換到一般檢視";
YATLAS_TOOLTIP_LOCKED_TITLE = "視窗已鎖定";
YATLAS_TOOLTIP_LOCKED = "點擊解除鎖定，即可拖曳移動視窗。";
YATLAS_TOOLTIP_UNLOCKED_TITLE = "視窗已解除鎖定";
YATLAS_TOOLTIP_UNLOCKED = "可拖曳移動視窗。點擊即可鎖定。";
YATLAS_TOOLTIP_SHOWPOINTS = "選擇要在地圖上顯示哪些標記。";
YATLAS_TOOLTIP_ZOOM_TITLE = "縮放";
YATLAS_TOOLTIP_ZOOM = "顯示縮放控制。也可以用滑鼠滾輪縮放。";
YATLAS_TOOLTIP_PLAYERJUMP = "點擊將地圖移到你的角色位置。\nShift-點擊可在移動時持續跟隨角色。";
YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING = "正在跟隨你的角色。點擊即可停止。";
YATLAS_TOOLTIP_OPTIONS = "透明度、圖示大小、要顯示的標記，以及小地圖按鈕。";
end
