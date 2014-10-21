local BZ = Yatlas_GetLocaleLibBabble("LibBabble-SubZone-3.0");

-- Yatlas map mapping
-- Display_Name - Actual Map Folder Name
YA_MAPS = {
	[BZ["Eastern Kingdoms"]] = {"Azeroth"},
	[BZ["Kalimdor"]] = {"Kalimdor"},
	[BZ["Outland"]] = {"Expansion01"},
	[BZ["Northrend"]] = {"Northrend"},
	[BZ["Pandaria"]] = {"HawaiiMainLand"},
	[BZ["Draenor"]] = {"Draenor"},
};

Yatlas_WorldMapIds = {
	["Kalimdor"] = 1,
	["Azeroth"] = 2,
	["Expansion01"] = 3,
	["Northrend"] = 4,
	["HawaiiMainLand"] = 5,
	["Draenor"] = 6,
};


-- These MUST MATCH the values returned by GetMapZones()
-- (These are the id versions)
Yatlas_ZoneIds = {
	["Azeroth"] =   {
		0, 1, 3, 4, 8, 10, 11, 12, 21, 25, 28, 30, 38, 40, 
		41, 44, 45, 46, 47, 51, 85, 130, 139, 170, 214, 267, 
		269, 276, 293, 296, 308, 330, 408, 409, 1497, 1519, 
		1537, 1579, 2037, 2280, 3459, 4706, 4922, 5146, 5152, 
		5339, 5351, 6606, 6936
	},
	["Kalimdor"] =  {
		0, 14, 15, 16, 17, 141, 148, 215, 331, 332, 357, 361, 
		377, 400, 405, 406, 440, 457, 490, 493, 616, 618, 
		876, 1377, 1637, 1638, 1657, 1941, 2159, 2917, 3478, 
		4707, 4709, 4795, 4826, 4887, 5034, 5060, 5695, 6463
	},	
	["Expansion01"] = {
		0, 3430, 3433, 3455, 3479, 3483, 3487, 3518, 3519, 
		3520, 3521, 3522, 3523, 3524, 3525, 3540, 3557, 3703, 
		3917, 4080, 7498, 7499, 
	},
	["Northrend"] = {
		0, 65, 66, 67, 210, 394, 495, 2817, 3477, 3537, 
		3711, 3979, 4197, 4201, 4258, 4395, 4602, 4630, 4742, 
	},
	["HawaiiMainLand"] = {
		0, 5785, 5805, 5840, 5841, 5842, 6006, 6134, 6138, 6661, 6757, 
	},
	["Draenor"] = {
		0, 6662, 6719, 6720, 6721, 6722, 6723, 6755, 6756, 6908, 6941, 6975, 7229, 7230, 7490, 
	},
}

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

-- Instances (entrances)
-- data from Map.dbc, filter the map type to find instance
Yatlas_instances = {
	["Azeroth"] = {
		{BZ["Shadowfang Keep"], 1571.569946, -230.9889984},
		{BZ["Stormwind Stockade"], 848.0103149, -8762.378906},
		{BZ["Deadmines"], 1681.150024, -11207.7998},
		{BZ["Uldaman"], -2954.997314, -6060.181641},
		{BZ["Gnomeregan"], 931.5987549, -5162.661621},
		{BZ["Sunken Temple"], -3987.629883, -10291.7002},
		{BZ["Scarlet Monastery of Old"], -811.2636719, 2892.235352},
		{BZ["Lower Blackrock Spire"], -1233.041504, -7522.526855},
		{BZ["Blackrock Depths"], -928.6394653, -7178.094727},
		{BZ["Scholomance OLD"], -2552.563965, 1274.78125},
		{BZ["Ancient Zul'Gurub"], -1224.577148, -11916.05957},
		{BZ["Stratholme"], -3378.483154, 3392.316895},
		{BZ["Deeprun Tram"], 517.3479614, -8349.223633},
		{BZ["Molten Core"], -1036.69812, -7510.564941},
		{BZ["Blackwing Lair"], -1218.666504, -7663.412598},
		{BZ["Karazhan"], -2004.065308, -11110.40723},
		{BZ["Throne of the Tides"], 5401.649414, -5585.871582},
		{BZ["Blackrock Caverns"], -1330.684082, -7570.244629},
		{BZ["Blackwing Descent"], -1188.831665, -7541.767578},
		{BZ["Grim Batol"], -3446.350098, -4047.73999},
		{BZ["The Bastion of Twilight"], -4221.209961, -4903.010254},
		{BZ["Zul'Gurub"], -1219.838501, -11916.22852},
		{BZ["Scarlet Halls"], -820, 2869},
		{BZ["Scholomance"], -2552.560059, 1274.780029},
		{BZ["Upper Blackrock Spire"], -1233.041504, -7522.526855},
	},
	["Kalimdor"] = {
		{BZ["Wailing Caverns"], -2209.240479, -751.1312256},
		{BZ["Razorfen Kraul"], -1660.211792, -4459.449219},
		{BZ["Blackfathom Deeps"], 748.387085, 4249.120605},
		{BZ["Razorfen Downs"], -2535.871582, -4662.882813},
		{BZ["Zul'Farrak"], -2891.278076, -6790.57666},
		{BZ["Onyxia's Lair"], -3752.421143, -4753.3125},
		{BZ["Opening of the Dark Portal"], -4193.513184, -8750.827148},
		{BZ["Maraudon"], 2924.977539, -1432.697144},
		{BZ["Ragefire Chasm"], -4423.371582, 1816.755859},
		{BZ["Dire Maul"], 1130, -3908.030029},
		{BZ["Ruins of Ahn'Qiraj"], 1526.365723, -8114.464355},
		{BZ["Ahn'Qiraj Temple"], 1526.785767, -8111.724121},
		{BZ["The Battle for Mount Hyjal"], -4182.050293, -8178.507813},
		{BZ["The Escape from Durnholde"], -4061.508789, -8309.80957},
		{BZ["The Culling of Stratholme"], -4457.417969, -8756.086914},
		{BZ["Halls of Origination"], -1837.479126, -10225.99512},
		{BZ["The Vortex Pinnacle"], -2317.934082, -11522.49316},
		{BZ["Firelands"], -2943.31958, 3987.199707},
		{BZ["Throne of the Four Winds"], 72.08333588, -11360.60254},
		{BZ["Lost City of the Tol'vir"], -1308.623291, -10686.14941},
		{BZ["End Time"], -4454.092285, -8288.604492},
		{BZ["Well of Eternity"], -3994.935791, -8595.836914},
		{BZ["Hour of Twilight"], -4590.4375, -8291.131836},
		{BZ["Dragon Soul"], -4512.6875, -8263.276367},
	},
	["Expansion01"] = {
		{BZ["Hellfire Citadel: The Shattered Halls"], 3064.435547, -306.7581787},
		{BZ["Hellfire Citadel: The Blood Furnace"], 3151.992676, -295.419342},
		{BZ["Hellfire Citadel: Ramparts"], 3067.895508, -360.0498657},
		{BZ["Magtheridon's Lair"], 3106.635986, -330.2338562},
		{BZ["Coilfang: The Steamvault"], 6915.07959, 764.2190552},
		{BZ["Coilfang: The Underbog"], 6768.072754, 764.6282349},
		{BZ["Coilfang: The Slave Pens"], 7011.32666, 742.1582031},
		{BZ["Coilfang: Serpentshrine Cavern"], 6865.242676, 775.786377},
		{BZ["Auchindoun: Shadow Labyrinth"], 4943.162598, -3640.687744},
		{BZ["Auchindoun: Sethekk Halls"], 4665.592285, -3361.862549},
		{BZ["Auchindoun: Mana-Tombs"], 4942.756348, -3089.516357},
		{BZ["Auchindoun: Auchenai Crypts"], 5156.455078, -3363.439941},
		{BZ["Black Temple"], 317.2936707, -3644.527344},
		{BZ["Gruul's Lair"], 5144.150879, 3525.452881},
		{BZ["Zul'Aman"], -7989.713379, 6851.020996},
		{BZ["The Sunwell"], -6774.56543, 12551.7627},
		{BZ["Magister's Terrace"], -7343.094727, 12881.90234},
	},
	["Northrend"] = {
		{BZ["Utgarde Keep"], -4868.421875, 1211.759399},
		{BZ["Utgarde Pinnacle"], -4860.953613, 1232.40979},
		{BZ["The Nexus"], 6985.435547, 3899.925781},
		{BZ["The Oculus"], 6983.939941, 3865.923096},
		{BZ["Halls of Stone"], -966.8064575, 8921.792969},
		{BZ["Drak'Tharon Keep"], -2023.049072, 4774.583008},
		{BZ["Azjol-Nerub"], 2171.275146, 3672.215332},
		{BZ["Halls of Lightning"], -1386.790649, 9185.087891},
		{BZ["Ulduar"], -1115.175415, 9359.371094},
		{BZ["Gundrak"], -4654.903809, 6708.730957},
		{BZ["Violet Hold"], 498.046936, 5689.489746},
		{BZ["The Obsidian Sanctum"], 260.4013062, 3438.15332},
		{BZ["The Eye of Eternity"], 6984.330078, 3869.981445},
		{BZ["Ahn'kahet: The Old Kingdom"], 2032.063843, 3641.458008},
		{BZ["Vault of Archavon"], 2840.33374, 5488.124512},
		{BZ["Icecrown Citadel"], 2065.932373, 5776.921875},
		{BZ["The Forge of Souls"], 2003.62854, 5670.791504},
		{BZ["Trial of the Crusader"], 736.137146, 8515.286133},
		{BZ["Trial of the Champion"], 792.22052, 8571.43457},
		{BZ["Pit of Saron"], 2010.270874, 5592.057129},
		{BZ["Halls of Reflection"], 1973.286499, 5628.875},
		{BZ["The Ruby Sanctum"], 186.8020782, 3608.129395},
		{BZ["Nexus Legendary"], 6985.439941, 3899.929932},
	},
	["HawaiiMainLand"] = {
		{BZ["Temple of the Jade Serpent"], -2473.409912, 957.7059937},
		{BZ["Stormstout Brewery"], 1267.453735, -688.7050781},
		{BZ["Gate of the Setting Sun"], 2253.664063, 970.8108521},
		{BZ["Mogu'shan Vaults"], 1121.290649, 3982.997314},
	},
};

Yatlas_towns2 = {
	["Kalimdor"] = {
		-- Ashenvale --
		{"Maestra's Post",		  154, 3240},
		{"The Talondeep Path",		  -718, 1913},
		{"Raynewood Retreat",	   -1881, 2707},
		{"Satyrnaar",			   -2981.2, 2694},
		{"Warsong Lumber Camp",	 -3545.8, 2438},
		{"Zoram'Gar Outpost",	   1012.5, 3353},
		-- Azshara --
		{"Valormok",				-4400, 3600},
		{"Talrendis Point",		 -3975, 2693},
		{"Ruins of Eldarath",	   -5150, 3542},
		-- Darkshore --
		{"Ruins of Mathystra",	  -845, 7368},
		{"Bashal'Aran",			 -22.9, 6695},
		{"Ameth'Aran",			  200, 5702},
		{"Grove of the Ancients",   102, 4993},
		-- Desolace --
		{"Sargeron",				762, -230},
		{"Thunder Axe Fortress",	1762, -346},
		{"Kodo Graveyard",		  1929, -1303},
		{"Ghostwalker Post",		1752,  -1238},
		{"Mannoroc Coven",		  1902, -1905}, 
		{"Valley of Spears",		2793, -1273},
		{"Gelkis Village",		  2558, -2184},
		{"Magram Village",		  1045, -1807},
		{"Kolkar Village",		  954, -948},
		-- Durotar --
		{"Razor Hill",			  -4741.6, 309},
		{"The Den",				 -4218, -609},
		{"Sen'jin Village",		 -4912, -823},
		-- Duskwallow --
		{"Brackenwall Village",	 -2877, -3122},
		{"Stonemaul Ruins",		 -3295, -4329},
		-- Felwood --
		{"Felpaw Village",		  -1935, 6785},
		{"Jaedenar",				-551, 4329},
		{"Emerald Sanctuary",	   -1310, 4008},
		{"Talonbranch Glade",	   -1935, 6173},
		-- Feralas --
		{"Ruins of Isildien",	   1376, -5686},
		{"Gordunni Outpost",		155, -3730},
		{"Grimtotem Compound",	  824, -4507},
		-- Moonglade --
		{"Nighthaven",			  -2497, 7890},
		{"Stormrage Barrow Dens",   -2947, 7565},
		{"Shrine of Remulos",	   -2214, 7846},
		-- Mulgore --
		{"Red Rocks",			   -1137.5, -935},
		{"Bloodhoof Village",	   -381.2, -2318},
		{"Brambleblade Ravine",	 -1181, -3000},
		{"Camp Narache",			-254, -2904},
		-- Silithus --
		{"Staghelm Point",		  100, -6548},
		{"Valor's Rest",			-304, -6430},
		{"Southwind Village",	   364, -7196},
		{"Bronzebeard Encampment",  1122, -8036},
		-- Stonetalon Mountains --   
		{"Malaka'jin",			  -327, -196},
		{"The Talon Den",		   1814, 2409},
		{"The Talondeep Path",	  -579, 1544},
		-- Tanaris --
		{"Steamwheedle Port",	   -4864, -6937},
		{"Uldum",				   -2785, -9656},
		{"Dunemaul Compound",	   -3050, -8435},
		{"Sandsorrow Warch",		-2952, -7162},
		-- Teldrassil --
		{"Aldrassil",			   818, 10480},
		{"The Oracle Glade",		1918, 10684},
		{"Dolanaar",				968, 9846},
		{"Starbreeze Village",	  420, 9871},
		{"Rut'Theran Village",	  991, 8709},
		-- The Barrens --
		{"The Sludge Fen",		  -3079, 1044},
		{"Northwatch Hold",		 -3641, -2098},
		-- Thousand Needles --
		{"The Great Lift",		  -1849, -4662},
		{"Mirage Raceway",		  -3914, -6220},
		{"Roguefeather Den",		-1614, -5487},
		{"The Weathered Nook",	  -2797, -5208},
		{"Ironstone Camp",		  -3422, -5825},
		{"Whitereach Post",		 -1366, -4918},
		{"Darkcloud Pinnacle",	  -1931, -5087},
		-- Un'goro Crater --
		{"Marshal's Refuge",		-1087, -6165},		
		{"Fungal Rock",			 -1856, -6382},
		-- Winterspring --
		{"Owl Wing Thicket",		-4958, 5652},
		{"The Hidden Grove",		-4842, 7733},
		{"Starfall Village",		-3931, 7147},
		{"Winterfall Village",	  -5129, 6764},
	},
	["Azeroth"] = {
		-- Alterac --
		{"Strahnbrad",			  -956, 679},
		{"Ruins of Alterac",		-310, 539},
		{"Dalaran",				 364, 266},
		{"Lordamere Internment Camp", 226, -95},
		-- Arathi Highlands --
		{"The Tower of Arathor",	-1500, -1777},
		{"Stromgarde",			  -1800, -1631},
		{"Witherbark Village",	  -3398, -1741},
		{"Faldir's Cove",		   -2112, -2079},
		{"Refuge Pointe",		   -2416, -1373},
		-- Badlands --
		{"Angor Fortress",		  -3137, -6375},
		{"Dustbelch Grotto",		-2289, -7275},
		-- Blasted Lands --
		{"Nethergarde Keep",		-3431, -10991},
		{"The Dark Portal",		 -3193, -11829},
		{"Dreadmaul Hold",		  -2664, -108524},
		-- Burning Steppes --   
		{"Flame Crest",			 -2193, -7480},
		{"Blackrock Stronghold",	-1439, -7701},
		-- Deadwind Pass --
		-- Dun Morogh --
		{"Anvilmar",				387, -6102},
		{"Kharanos",				-500, -5583},
		{"Brewnall Village",		302, -5360},
		-- Duskwood --
		{"Ravenhill",			   327, -10735},
		-- Eastern Plaguelands --
		{"Terrorweb Tunnel",		-2772, 3034},
		{"Terrorweb Tunnel",		-2470, 2751},
		{"Light's Hope Chapel",	 -5339, 2298},
		{"Tyr's Hand",			  -5558, 1596},
		{"Darrowshire",			 -3695, 1438},
		{"Corin's Crossing",		-4505, 2032},	
		-- Elwynn Forest --
		{"Northshire Abbey",		-172, -8878}, 
		{"Eastvale Logging Camp",   -1352, -9460},
		{"Goldshire",			   68, -9458},
		{"Westbrook Garrison",	  677, -9624},
		-- Hillsbrad Foothills
		{"Azurlode Mine",		   196, -827},
		{"Durnholde Keep",		  -1457, -456},
		{"Dun Garok",			   -1218, -1292},
		{"Purgation Isle",		  590, -1333},
		-- Loch Modan --
		{"The Farstrider Lodge",	-4270, -5655},
		-- Red Ridge Mountains --
		{"Tower of Ilgalar",		-3297, -9280},
		{"Stonewatch Keep",		 -3052, -9380}, 
		-- Searing Gorge --
		{"Thorium Point",		   -1153, -6504},
		-- Silverpine Forest --
		{"Ambermill",			   791, -122},
		{"Pyrewood Village",		1556, -385},
		-- Strangethorn Vale --
		{"Mosh'Ogg Ogre Mound",	 -1006, -12368},
		{"Venture Co. Base Camp",   -523, -11972},
		{"Gurubashi Arena",		 278, -13204},
		-- Swamp of Sorrows --
		{"Fallow Sanctuary",		-3641, -9954},
		{"Misty Valley",			-2526, -10164},
		{"Stagalbog Cave",		  -3745, -10795},
		-- The Hinterlands --
		{"Skulk Rock",			  -3795, 393},
		{"Quel'Danil Lodge",		-2764, 239},
		{"The Altar of Zul",		-3454, -293},
		{"Jintha'Alor",			 -3955, -468},
		-- Tirisfal Glades --
		{"Agamand Mills",		   871, 2839},
		{"Deathknell",			  1580, 1929},
		{"Brill",				   286, 2304},
		-- Western Plaguelands --
		{"Hearthglen",			  1516, 2877},
		{"Ruins of Andorhal",	   -1518,1383},
		{"Caer Darrow",			 -2558, 1156},
		{"The Bulwark",			 -762, 1745},
		{"Chillwind Camp",		  -1441, 925},
		-- Westfall --
		{"Jangolode Mine",		  1453, -9968},
		{"Gold Coast Quarry",	   1915, -10416},
		{"Moonbrook",			   1501, -11010},
		-- Wetlands --
		{"Dun Modr",				-2327, -2610},
		{"Dun Algaz",			   -2369, -4198},
		{"Grim Batol",			  -3429, -4006},		
	},
}

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

-- 'blacklist' some of our 'graveyards'
function YA_BL_gy(cont, c) 
	for h,v in ipairs(Yatlas_graveyards[cont]) do
		if(v[1] == c[1] and v[2] == c[2]) then
			tremove(Yatlas_graveyards[cont], h);
			return;
		end
	end
end
YA_BL_gy("Azeroth", {-831.880981, -3518.520020});   -- AB
YA_BL_gy("Azeroth", {-1215.589966, -2531.750000});  -- AB
YA_BL_gy("Azeroth", {536.494995, -1085.719971});	-- AV
YA_BL_gy("Azeroth", {101.143997, -184.934006});	 -- AV
YA_BL_gy("Azeroth", {-5687.000000, -515.000000});   -- Dun Morogh Extra
YA_BL_gy("Azeroth", {-9115.000000, 423.000000});	-- Stormwind Bogus
YA_BL_gy("Azeroth", {-9151.980469, 410.944000});	-- Stormwind Bogus
YA_BL_gy("Azeroth", {1822.609985, 214.673996});	 -- Undercity Bogus
YA_BL_gy("Azeroth", {-5049.450195, -809.697021});   -- Ironforge extra
YA_BL_gy("Azeroth", {-13290.000000, 108.000000});   -- Gurubashi Arena Bogus
YA_BL_gy("Kalimdor", {1357.099976, -4412.009766});  -- Orgrimmar Bogus
YA_BL_gy("Kalimdor", {1459.170044, -1858.670044});  -- WSG
YA_BL_gy("Kalimdor", {1035.270020, -2104.280029});  -- WSG

