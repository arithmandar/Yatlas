-- esES localization for Yatlas (UTF-8)
-- Strings not defined here fall back to Yatlas-enUS.lua.

if (GetLocale() == "esES" or GetLocale() == "esMX") then

YATLAS_HELP_TEXT = {
    "Yatlas muestra un mapa de todo el mundo basado en el terreno del minimapa.\n\nHaz clic en el mapa y arrástralo para moverte; usa la rueda de desplazamiento para acercar o alejar. Con los menús de arriba puedes elegir un mapa o una zona, o ir a tu posición.\n\nPasa el cursor sobre un punto para ver información. En «Mostrar puntos» eliges qué puntos se muestran."
};

YATLAS_TAB_DATA = "Mostrar datos";
YATLAS_TAB_OPTIONS = "Opciones";
YATLAS_BUTTON_TOOLTIP1 = "Yatlas";
YATLAS_BUTTON_TOOLTIP2 = "- Haz clic para abrir Yatlas";
YATLAS_BUTTON_TOOLTIP3 = "- Haz clic derecho y arrastra para mover el botón del minimapa";
YATLAS_PLAYERJUMP = "Ir al jugador";
YATLAS_OPTIONSBUTTON = "Opciones";
YATLAS_OPTIONS_TITLE = "Opciones de Yatlas";
YATLAS_OPTIONS_BUTTONPOS = "Posición del botón del minimapa";
YATLAS_OPTIONS_BUTTONPOS_TIP = "%d grados";
YATLAS_OPTIONS_ENABLEBUTTON = "Mostrar botón del minimapa";
YATLAS_OPTIONS_TRACKONSHOW = "Centrar en el jugador al abrir";
YATLAS_OPTIONS_ALPHA = "Transparencia";
YATLAS_OPTIONS_ICONSIZE = "Tamaño de los iconos";
YATLAS_OPTIONS_ENABLECOORD = "Mostrar coordenadas del cursor";
YATLAS_POINTS_SHOWPOINTS_TITLE = "Mostrar puntos";
YATLAS_POINTS_LANDMARKS = "Lugares de interés";
YATLAS_POINTS_GRAVEYARDS = "Cementerios";
YATLAS_POINTS_TAXINODES = "Puntos de vuelo";
YATLAS_POINTS_DELVES = DELVES_LABEL or "Abismos";
YATLAS_POINTS_RACES = DRAGONRIDING_RACES_MAP_TOGGLE or "Carreras de surcacielos";
YATLAS_POINTS_MAPNOTES = "MapNotes";
YATLAS_POINTS_GATHERER = "Gatherer";
YATLAS_POINTS_GATHERER_TREASURE = "Tesoros";
YATLAS_POINTS_GATHERER_ORES = "Minerales";
YATLAS_POINTS_GATHERER_HERBS = "Hierbas";
YATLAS_POINTS_CTMAPMOD = "CTMapMod";
YATLAS_UNKNOWN_ZONE = "Desconocido";
YATLAS_BIGDRAGMESSAGE = "Haz clic en el mapa y arrástralo para mover la vista.";
BINDING_NAME_YATLAS_TOGGLE = "Mostrar/ocultar Yatlas";
BINDING_NAME_YATLAS_BIG_TOGGLE = "Mostrar/ocultar la ventana grande de Yatlas";

YATLAS_SWITCH_TO_BIG = "Cambiar a vista grande";
YATLAS_SWITCH_TO_NORMAL = "Cambiar a vista normal";
YATLAS_TOOLTIP_LOCKED_TITLE = "Ventana bloqueada";
YATLAS_TOOLTIP_LOCKED = "Haz clic para desbloquearla y poder moverla.";
YATLAS_TOOLTIP_UNLOCKED_TITLE = "Ventana desbloqueada";
YATLAS_TOOLTIP_UNLOCKED = "Puedes arrastrar la ventana. Haz clic para bloquearla.";
YATLAS_TOOLTIP_SHOWPOINTS = "Elige qué puntos se muestran en el mapa.";
YATLAS_TOOLTIP_ZOOM_TITLE = "Zoom";
YATLAS_TOOLTIP_ZOOM = "Muestra los controles de zoom. También puedes usar la rueda del ratón.";
YATLAS_TOOLTIP_PLAYERJUMP = "Haz clic para centrar el mapa en tu personaje.\nMayús-clic para seguirte mientras te mueves.";
YATLAS_TOOLTIP_PLAYERJUMP_FOLLOWING = "Siguiendo a tu personaje. Haz clic para detener.";
YATLAS_TOOLTIP_OPTIONS = "Transparencia, tamaño de iconos, puntos mostrados y botón del minimapa.";
end
