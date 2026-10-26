-- ruRU localization for Yatlas (UTF-8)
-- Strings not defined here fall back to Yatlas-enUS.lua.

if (GetLocale() == "ruRU") then

YATLAS_HELP_TEXT = {
    "Yatlas показывает карту всего мира на основе рельефа миникарты.\n\nЧтобы перемещаться, нажмите на карту и перетащите её; колесо мыши меняет масштаб. В меню сверху можно выбрать карту или зону либо перейти к своему местоположению.\n\nНаведите курсор на точку, чтобы увидеть подсказку. В меню «Показать точки» можно выбрать, какие точки отображать."
};

YATLAS_TAB_DATA = "Показать данные";
YATLAS_TAB_OPTIONS = "Настройки";
YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_BUTTON_TOOLTIP2 = "- Щелкните, чтобы открыть Yatlas";
YATLAS_BUTTON_TOOLTIP3 = "- Перетащите правой кнопкой мыши, чтобы переместить кнопку у миникарты";
YATLAS_PLAYERJUMP = "К игроку";
YATLAS_OPTIONSBUTTON = "Настройки";
YATLAS_OPTIONS_TITLE = "Настройки Yatlas";
YATLAS_OPTIONS_BUTTONPOS = "Положение кнопки у миникарты";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d°";
YATLAS_OPTIONS_ENABLEBUTTON = "Показывать кнопку у миникарты";
YATLAS_OPTIONS_TRACKONSHOW = "Переходить к игроку при открытии";
YATLAS_OPTIONS_ALPHA = "Прозрачность";
YATLAS_OPTIONS_ICONSIZE = "Размер значков";
YATLAS_OPTIONS_ENABLECOORD = "Показывать координаты курсора";
YATLAS_POINTS_SHOWPOINTS_TITLE = "Показать точки";
YATLAS_POINTS_LANDMARKS = "Ориентиры";
YATLAS_POINTS_GRAVEYARDS = "Кладбища";
YATLAS_POINTS_TAXINODES = "Точки полёта";
YATLAS_POINTS_DELVES = DELVES_LABEL or "Вылазки";
YATLAS_POINTS_RACES = DRAGONRIDING_RACES_MAP_TOGGLE or "Гонки на драконах";
YATLAS_POINTS_MAPNOTES = "MapNotes";
YATLAS_POINTS_GATHERER = "Gatherer";
YATLAS_POINTS_GATHERER_TREASURE = "Сокровища";
YATLAS_POINTS_GATHERER_ORES = "Руда";
YATLAS_POINTS_GATHERER_HERBS = "Травы";
YATLAS_POINTS_CTMAPMOD = "CTMapMod";
YATLAS_UNKNOWN_ZONE = "Неизвестно";
YATLAS_BIGDRAGMESSAGE = "Нажмите на карту и перетащите её, чтобы сдвинуть обзор.";
BINDING_NAME_YATLAS_TOGGLE = "Показать/скрыть Yatlas";
BINDING_NAME_YATLAS_BIG_TOGGLE = "Показать/скрыть большое окно Yatlas";

YATLAS_SWITCH_TO_BIG = "Перейти в большой режим";
YATLAS_SWITCH_TO_NORMAL = "Перейти в обычный режим";
YATLAS_TOOLTIP_LOCKED_TITLE = "Окно закреплено";
YATLAS_TOOLTIP_LOCKED = "Щелкните, чтобы открепить окно и перемещать его.";
YATLAS_TOOLTIP_UNLOCKED_TITLE = "Окно откреплено";
YATLAS_TOOLTIP_UNLOCKED = "Окно можно перетаскивать. Щелкните, чтобы закрепить.";
YATLAS_TOOLTIP_SHOWPOINTS = "Выберите, какие точки показывать на карте.";
YATLAS_TOOLTIP_ZOOM_TITLE = "Масштаб";
YATLAS_TOOLTIP_ZOOM = "Показать управление масштабом. Масштаб также меняется колесом мыши.";
YATLAS_TOOLTIP_PLAYERJUMP = "Щелкните, чтобы показать на карте вашего персонажа.\nShift-щелчок — следовать за вами при движении.";
YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING = "Карта следует за персонажем. Щелкните, чтобы остановить.";
YATLAS_TOOLTIP_OPTIONS = "Прозрачность, размер значков, показываемые точки и кнопка у миникарты.";
end
