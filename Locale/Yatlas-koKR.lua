-- koKR localization for Yatlas (UTF-8)
-- Strings not defined here fall back to Yatlas-enUS.lua.

if (GetLocale() == "koKR") then

YATLAS_HELP_TEXT = {
    "Yatlas는 미니맵 지형을 바탕으로 전 세계 지도를 보여 줍니다.\n\n지도를 클릭한 채 끌어서 이동하고, 마우스 휠로 확대/축소합니다. 위쪽 메뉴에서 지도나 지역을 고르거나 내 위치로 이동할 수 있습니다.\n\n지점 위에 마우스를 올리면 툴팁이 표시됩니다. [지점 표시] 메뉴에서 표시할 지점을 고를 수 있습니다."
};

YATLAS_TAB_DATA = "정보 보기";
YATLAS_TAB_OPTIONS = "설정";
YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_BUTTON_TOOLTIP2 = "- 클릭하여 Yatlas 열기";
YATLAS_BUTTON_TOOLTIP3 = "- 오른쪽 클릭 후 끌어서 미니맵 버튼 이동";
YATLAS_PLAYERJUMP = "내 위치로";
YATLAS_OPTIONSBUTTON = "설정";
YATLAS_OPTIONS_TITLE = "Yatlas 설정";
YATLAS_OPTIONS_BUTTONPOS = "미니맵 버튼 위치";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d도";
YATLAS_OPTIONS_ENABLEBUTTON = "미니맵 버튼 표시";
YATLAS_OPTIONS_TRACKONSHOW = "열 때 내 위치로 이동";
YATLAS_OPTIONS_ALPHA = "투명도";
YATLAS_OPTIONS_ICONSIZE = "아이콘 크기";
YATLAS_OPTIONS_ENABLECOORD = "커서 좌표 표시";
YATLAS_POINTS_SHOWPOINTS_TITLE = "지점 표시";
YATLAS_POINTS_LANDMARKS = "주요 지역";
YATLAS_POINTS_GRAVEYARDS = "무덤";
YATLAS_POINTS_TAXINODES = "비행 지점";
YATLAS_POINTS_DELVES = DELVES_LABEL or "구렁";
YATLAS_POINTS_MAPNOTES = "MapNotes";
YATLAS_POINTS_GATHERER = "Gatherer";
YATLAS_POINTS_GATHERER_TREASURE = "보물";
YATLAS_POINTS_GATHERER_ORES = "광석";
YATLAS_POINTS_GATHERER_HERBS = "약초";
YATLAS_POINTS_CTMAPMOD = "CTMapMod";
YATLAS_UNKNOWN_ZONE = "알 수 없음";
YATLAS_BIGDRAGMESSAGE = "지도를 클릭한 채 끌어서 화면을 이동하세요.";
BINDING_NAME_YATLAS_TOGGLE = "Yatlas 창 열기/닫기";
BINDING_NAME_YATLAS_BIG_TOGGLE = "큰 Yatlas 창 열기/닫기";

YATLAS_SWITCH_TO_BIG = "큰 보기로 전환";
YATLAS_SWITCH_TO_NORMAL = "일반 보기로 전환";
YATLAS_TOOLTIP_LOCKED_TITLE = "창 잠김";
YATLAS_TOOLTIP_LOCKED = "클릭하면 잠금이 풀려 창을 옮길 수 있습니다.";
YATLAS_TOOLTIP_UNLOCKED_TITLE = "창 잠금 해제됨";
YATLAS_TOOLTIP_UNLOCKED = "창을 끌어서 옮길 수 있습니다. 클릭하면 잠급니다.";
YATLAS_TOOLTIP_SHOWPOINTS = "지도에 표시할 지점을 고릅니다.";
YATLAS_TOOLTIP_ZOOM_TITLE = "확대/축소";
YATLAS_TOOLTIP_ZOOM = "확대/축소 조절을 표시합니다. 마우스 휠로도 확대/축소할 수 있습니다.";
YATLAS_TOOLTIP_PLAYERJUMP = "클릭하면 지도를 캐릭터 위치로 옮깁니다.\nShift-클릭하면 이동하는 동안 계속 따라갑니다.";
YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING = "캐릭터를 따라가는 중입니다. 클릭하면 멈춥니다.";
YATLAS_TOOLTIP_OPTIONS = "투명도, 아이콘 크기, 표시할 지점, 미니맵 버튼을 설정합니다.";
end
