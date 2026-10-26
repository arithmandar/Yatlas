-- Yatlas data shared by every client flavour.
-- The per-client tables live in Data/<Flavour>/mapdb.lua and mapdb2.lua (loaded by Data/Data.xml);
-- each of those files returns right away unless YATLAS_CLIENT (Core/Constants.lua) matches.

-- Localized map names straight from the client, with an English fallback.
function Yatlas_UiMapName(uiMapID, fallback)
	local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID);
	return (info and info.name and info.name ~= "" and info.name) or fallback;
end

function Yatlas_MapName(mapID, fallback)
	local name = GetRealZoneText and GetRealZoneText(mapID);
	return (name and name ~= "" and name) or fallback;
end

Yatlas_PaperZoneNames = {};	 -- we don't fill this in by hand
Yatlas_Landmarks = {};		  -- this is filled in automatically too

-- Adjustment for dropdown menu
Yatlas_mapareas_adjust = {
	[148] = {-1,0},		 -- Darkshore
	[361] = {-0.95,0},	  -- Felwood
	[357] = {1.2, .1},	  -- Feralas
	[618] = {0.7, -0.5},	-- Winterspring

	[36] = {-0.3, 0},	   -- Alterac
	[12] = {0, 0.4},		-- Elwynn Forest
	[267] = {0.3, -0.3},	-- Hillsbrad
	[33] = {-1.4, -1},	  -- STV
	[8] = {0.4, 0},		 -- Swamp of Sorrows
	[40] = {-0.1, 0},	   -- Westfall
	[11] = {-0.7, -0.9}	 -- Wetlands
};

-- Graveyards: disabled.
-- WorldSafeLocs is server-side only in the modern clients; no client data source is available.
-- Kept as an empty table so Modules/graveyards.lua can be re-enabled later.
Yatlas_graveyards = {};

-- XXX USEME
Yatlas_Mobs = {
	-- two original outdoor raid bosses
	{"Lord Kazzak",		 "Kalimdor", -2439, -12211},
	{"Azuregos",			"Azeroth", -5884, 2764},
	-- four dragons
	{"Dragons of Nightmare", "Azeroth", -4081, 624},
	{"Dragons of Nightmare", "Kalimdor", -3741, 3174},
	{"Dragons of Nightmare", "Azeroth", -421, -10441},
	{"Dragons of Nightmare", "Kalimdor", 1874, -2796},
};

-- The maps of YA_MAPS as an ordered list of {name, directory}, in YA_MAPS_ORDER order.
function Yatlas_GetMapList()
	if(Yatlas_MapList) then
		return Yatlas_MapList;
	end
	local order = {};
	for i, dir in ipairs(YA_MAPS_ORDER or {}) do
		order[dir] = i;
	end
	local list = {};
	for name, v in pairs(YA_MAPS or {}) do
		tinsert(list, {name, v[1]});
	end
	table.sort(list, function(a, b)
		local ia, ib = order[a[2]] or 1000, order[b[2]] or 1000;
		if(ia ~= ib) then return ia < ib; end
		return a[1] < b[1];
	end);
	Yatlas_MapList = list;
	return list;
end
