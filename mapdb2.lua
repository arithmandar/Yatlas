-- Yatlas map mapping
-- Display_Name - Actual Map Folder Name (Map.db2 Directory)
-- Oct. 25, 2026: updated for MoP Classic 5.5.4.70579. Display names come from the client
-- (C_Map.GetMapInfo) so they are localized without LibBabble-SubZone-3.0.
local function YA_UiMapName(uiMapID, fallback)
	local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID);
	return (info and info.name and info.name ~= "" and info.name) or fallback;
end

YA_MAPS = {
	[YA_UiMapName(13, "Eastern Kingdoms")] = {"Azeroth"},
	[YA_UiMapName(12, "Kalimdor")] = {"Kalimdor"},
	[YA_UiMapName(101, "Outland")] = {"Expansion01"},
	[YA_UiMapName(113, "Northrend")] = {"Northrend"},
	[YA_UiMapName(424, "Pandaria")] = {"HawaiiMainLand"},
	[YA_UiMapName(207, "Deepholm")] = {"Deephome"},
	[YA_UiMapName(244, "Tol Barad")] = {"TolBarad"},
	[YA_UiMapName(504, "Isle of Thunder")] = {"MoguIslandDailyArea"},
	[YA_UiMapName(407, "Darkmoon Island")] = {"DarkmoonFaire"},
};

-- [Directory] = uiMapID of the map shown for it (continent, or the zone for single-zone maps).
-- Previously these were the SetMapZoom() continent indexes (1..6); SetMapZoom() no longer exists,
-- the C_Map API works with uiMapIDs.
Yatlas_WorldMapIds = {
	["Azeroth"] = 13,
	["Kalimdor"] = 12,
	["Expansion01"] = 101,
	["Northrend"] = 113,
	["HawaiiMainLand"] = 424,
	["Deephome"] = 207,
	["TolBarad"] = 244,
	["MoguIslandDailyArea"] = 504,
	["DarkmoonFaire"] = 407,
};


-- Zones per tile map, from UiMap.db2 + UiMapAssignment.db2 (5.5.4.70579); [1] = 0 is the continent itself
-- (GetMapZones() no longer exists; order is alphabetical by enUS name)
Yatlas_ZoneIds = {
	-- Map ID = 0
	["Azeroth"] = {
		0, 5145, 45, 3, 4, 46, 6176, 41, 6454, 1, 10, 139, 12, 267, 1537, 4815, 38, 6457, 33, 6170, 44, 4706, 5351, 51, 5144, 130, 1519, 5339, 8, 5287, 47, 85, 4922, 1497, 5146, 28, 40, 11,
	},
	-- Map ID = 1
	["Kalimdor"] = {
		0, 5695, 331, 16, 6452, 148, 1657, 405, 14, 15, 6453, 361, 357, 493, 616, 215, 17, 1637, 6450, 1377, 4709, 406, 440, 141, 400, 1638, 5034, 490, 6451, 618,
	},
	-- Map ID = 530
	["Expansion01"] = {
		0, 6456, 3524, 3522, 3525, 3430, 3433, 3483, 4080, 3518, 3523, 3520, 3703, 3487, 6455, 3519, 3557, 3521,
	},
	-- Map ID = 571
	["Northrend"] = {
		0, 3537, 2817, 65, 394, 495, 4742, 210, 3711, 67, 4197, 66,
	},
	-- Map ID = 870
	["HawaiiMainLand"] = {
		0, 6138, 6661, 6134, 5841, 5785, 6006, 6757, 5842, 5840, 5805,
	},
	-- Map ID = 646
	["Deephome"] = {
		5042,
	},
	-- Map ID = 732
	["TolBarad"] = {
		5095, 5389,
	},
	-- Map ID = 1064
	["MoguIslandDailyArea"] = {
		6507,
	},
	-- Map ID = 974
	["DarkmoonFaire"] = {
		5861,
	},
};

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
-- Oct. 25, 2026: updated to 5.5.4.70579 (MoP Classic)
-- Primary source: the client AreaTrigger.db2 row that teleports into the instance
--   (trigger -> instance mapping from MoP server data: MistCore 5.0.5 / SkyFire 5.4.8 areatrigger_teleport)
-- Fallback: Map.db2 Corpse_0/Corpse_1 (entrance) of build 7.3.5, the last client that shipped them
-- {name, worldY, worldX, instanceMapID}; name is localized at load time via GetRealZoneText(mapID)
Yatlas_instances = {
	["Azeroth"] = {
		{"Shadowfang Keep", 1576.699951, -227.998001, 33}, -- AreaTrigger 145
		{"Stormwind Stockade", 848.557007, -8761.849609, 34}, -- AreaTrigger 101
		{"Deadmines", 1684.23999, -11207.299805, 36}, -- AreaTrigger 78
		{"Uldaman", -2955, -6055.5, 70}, -- AreaTrigger 286
		{"Uldaman", -3762.189941, -6606.47998, 70}, -- AreaTrigger 902
		{"Gnomeregan", 916.549011, -5154.97998, 90}, -- AreaTrigger 324
		{"Gnomeregan", 827.914978, -4914.930176, 90}, -- AreaTrigger 523
		{"Sunken Temple", -3990.02002, -10292.299805, 109}, -- AreaTrigger 446
		{"Blackrock Spire", -1239.060059, -7519.680176, 229}, -- AreaTrigger 1468
		{"Blackrock Depths", -937.666992, -7176.629883, 230}, -- AreaTrigger 1466
		{"Stratholme", -4060.600098, 3237.459961, 329}, -- AreaTrigger 2214
		{"Stratholme", -3389.199951, 3392.459961, 329}, -- AreaTrigger 2216
		{"Molten Core", -1035.869995, -7510.870117, 409}, -- AreaTrigger 3528
		{"Blackwing Lair", -1218.666504, -7663.412598, 469}, -- Map.db2 7.3.5 Corpse
		{"Karazhan", -1998.119995, -11101.900391, 532}, -- AreaTrigger 4131
		{"Throne of the Tides", 5401.649414, -5585.871582, 643}, -- Map.db2 7.3.5 Corpse
		{"Blackrock Caverns", -1330.684082, -7570.244629, 645}, -- Map.db2 7.3.5 Corpse
		{"Blackwing Descent", -1188.831665, -7541.767578, 669}, -- Map.db2 7.3.5 Corpse
		{"Grim Batol", -3446.350098, -4047.73999, 670}, -- Map.db2 7.3.5 Corpse
		{"The Bastion of Twilight", -4221.209961, -4903.010254, 671}, -- Map.db2 7.3.5 Corpse
		{"Zul'Gurub", -1219.838501, -11916.228516, 859}, -- Map.db2 7.3.5 Corpse
		{"Scarlet Halls", -820, 2869, 1001}, -- Map.db2 7.3.5 Corpse
		{"Scarlet Monastery", 2924.379883, -798.429016, 1004}, -- approx.: old Scarlet Monastery courtyard (AreaTrigger 45)
		{"Scholomance", -2552.560059, 1274.780029, 1007}, -- Map.db2 7.3.5 Corpse
	},
	["Kalimdor"] = {
		{"Wailing Caverns", -2212.780029, -753.596008, 43}, -- AreaTrigger 228
		{"Razorfen Kraul", -1655.01001, -4455.109863, 47}, -- AreaTrigger 244
		{"Blackfathom Deeps", 756.96698, 4253.109863, 48}, -- AreaTrigger 257
		{"Razorfen Downs", -2536.929932, -4664.600098, 129}, -- AreaTrigger 442
		{"Zul'Farrak", -2891.949951, -6790.879883, 209}, -- AreaTrigger 924
		{"Onyxia's Lair", -3752.110107, -4768.609863, 249}, -- AreaTrigger 2848
		{"Opening of the Dark Portal", -4156.919922, -8777.389648, 269}, -- AreaTrigger 4320
		{"Maraudon", 2617.570068, -1484.069946, 349}, -- AreaTrigger 3133
		{"Maraudon", 2861.949951, -1181.97998, 349}, -- AreaTrigger 3134
		{"Ragefire Chasm", -4427.259766, 1818.400024, 389}, -- AreaTrigger 2230
		{"Dire Maul", 934.929016, -3759.689941, 429}, -- AreaTrigger 3183
		{"Dire Maul", 793.726013, -3981.199951, 429}, -- AreaTrigger 3184
		{"Dire Maul", 123.966003, -4028.209961, 429}, -- AreaTrigger 3185
		{"Dire Maul", 1249.920044, -3822.629883, 429}, -- AreaTrigger 3186
		{"Dire Maul", 1089.930054, -3519.949951, 429}, -- AreaTrigger 3189
		{"Ruins of Ahn'Qiraj", 1508.650024, -8424.94043, 509}, -- AreaTrigger 4008
		{"Ahn'Qiraj Temple", 2005.329956, -8230.400391, 531}, -- AreaTrigger 4010
		{"The Battle for Mount Hyjal", -4155.649902, -8158.899902, 534}, -- AreaTrigger 4319
		{"The Escape From Durnholde", -4047.439941, -8326.269531, 560}, -- AreaTrigger 4321
		{"The Culling of Stratholme", -4469.580078, -8758.780273, 595}, -- AreaTrigger 5150
		{"Halls of Origination", -1837.479126, -10225.995117, 644}, -- Map.db2 7.3.5 Corpse
		{"The Vortex Pinnacle", -2317.934082, -11522.493164, 657}, -- Map.db2 7.3.5 Corpse
		{"Firelands", -2943.31958, 3987.199707, 720}, -- Map.db2 7.3.5 Corpse
		{"Throne of the Four Winds", 72.083336, -11360.602539, 754}, -- Map.db2 7.3.5 Corpse
		{"Lost City of the Tol'vir", -1308.623291, -10686.149414, 755}, -- Map.db2 7.3.5 Corpse
		{"End Time", -4454.092285, -8288.604492, 938}, -- Map.db2 7.3.5 Corpse
		{"Well of Eternity", -3994.935791, -8595.836914, 939}, -- Map.db2 7.3.5 Corpse
		{"Hour of Twilight", -4590.4375, -8291.131836, 940}, -- Map.db2 7.3.5 Corpse
		{"Dragon Soul", -4512.6875, -8263.276367, 967}, -- Map.db2 7.3.5 Corpse
	},
	["Expansion01"] = {
		{"Hellfire Citadel: The Shattered Halls", 3091.590088, -310.210999, 540}, -- AreaTrigger 4151
		{"Hellfire Citadel: The Blood Furnace", 3170.51001, -307.251007, 542}, -- AreaTrigger 4152
		{"Hellfire Citadel: Ramparts", 3087.620117, -365.610992, 543}, -- AreaTrigger 4150
		{"Magtheridon's Lair", 3079.120117, -309.678009, 544}, -- AreaTrigger 4153
		{"Coilfang: The Steamvault", 6951.299805, 818.487, 545}, -- AreaTrigger 4364
		{"Coilfang: The Underbog", 6741.939941, 782.879028, 546}, -- AreaTrigger 4363
		{"Coilfang: The Slave Pens", 7015.27002, 745.838989, 547}, -- AreaTrigger 4365
		{"Coilfang: Serpentshrine Cavern", 6865.240234, 843.88501, 548}, -- AreaTrigger 4416
		{"Tempest Keep", 1364.530029, 3087.179932, 550}, -- AreaTrigger 4470
		{"Tempest Keep: The Arcatraz", 1325.920044, 3314.780029, 552}, -- AreaTrigger 4468
		{"Tempest Keep: The Botanica", 1479.01001, 3418.919922, 553}, -- AreaTrigger 4467
		{"Tempest Keep: The Mechanar", 1545.390015, 2861.370117, 554}, -- AreaTrigger 4469
		{"Auchindoun: Shadow Labyrinth", 4943.109863, -3656.050049, 555}, -- AreaTrigger 4407
		{"Auchindoun: Sethekk Halls", 4650.310059, -3362.350098, 556}, -- AreaTrigger 4406
		{"Auchindoun: Mana-Tombs", 4942.799805, -3068.129883, 557}, -- AreaTrigger 4405
		{"Auchindoun: Auchenai Crypts", 5236.870117, -3361.550049, 558}, -- AreaTrigger 4404
		{"Black Temple", 318.533997, -3671.959961, 564}, -- AreaTrigger 4598
		{"Gruul's Lair", 5083.410156, 3556.790039, 565}, -- AreaTrigger 4535
		{"Zul'Aman", -8008.72998, 6851.879883, 568}, -- AreaTrigger 4738
		{"The Sunwell", -6775.149902, 12551, 580}, -- AreaTrigger 4889
		{"Magister's Terrace", -7348.740234, 12878.799805, 585}, -- AreaTrigger 4887
	},
	["Northrend"] = {
		{"Naxxramas", -1280.189941, 3681.290039, 533}, -- AreaTrigger 5191
		{"Utgarde Keep", -4854.47998, 1257.109985, 574}, -- AreaTrigger 4745
		{"Utgarde Pinnacle", -4861.700195, 1226.22998, 575}, -- AreaTrigger 4747
		{"The Nexus", 6985.689941, 3902.790039, 576}, -- AreaTrigger 4983
		{"The Oculus", 6984.160156, 3869.840088, 578}, -- AreaTrigger 5246
		{"Halls of Stone", -963.434021, 8922.030273, 599}, -- AreaTrigger 5010
		{"Drak'Tharon Keep", -2017.160034, 4775.319824, 600}, -- AreaTrigger 4998
		{"Azjol-Nerub", 2174.629883, 3668.290039, 601}, -- AreaTrigger 5117
		{"Halls of Lightning", -1390.01001, 9188.820312, 602}, -- AreaTrigger 5093
		{"Ulduar", -1113.439941, 9364.360352, 603}, -- AreaTrigger 5379
		{"Gundrak", -4666.02002, 6700.47998, 604}, -- AreaTrigger 5205
		{"Gundrak", -4396.330078, 6976.540039, 604}, -- AreaTrigger 5206
		{"Violet Hold", 480.919006, 5675.430176, 608}, -- AreaTrigger 5209
		{"The Obsidian Sanctum", 260.950989, 3442.629883, 615}, -- AreaTrigger 5243
		{"The Eye of Eternity", 6984.200195, 3870.290039, 616}, -- AreaTrigger 5290
		{"Ahn'kahet: The Old Kingdom", 2027.199951, 3639.399902, 619}, -- AreaTrigger 5215
		{"Vault of Archavon", 2839.810059, 5494.879883, 624}, -- AreaTrigger 5258
		{"Icecrown Citadel", 2063.27002, 5772.109863, 631}, -- AreaTrigger 5670
		{"The Forge of Souls", 1995.280029, 5678.560059, 632}, -- AreaTrigger 5635
		{"Trial of the Crusader", 744.413025, 8515.209961, 649}, -- AreaTrigger 5503
		{"Trial of the Champion", 791.784973, 8562.599609, 650}, -- AreaTrigger 5505
		{"Pit of Saron", 2003.160034, 5584.109863, 658}, -- AreaTrigger 5637
		{"Halls of Reflection", 1957.319946, 5627.410156, 668}, -- AreaTrigger 5636
		{"The Ruby Sanctum", 186.169998, 3608.189941, 724}, -- AreaTrigger 5869
	},
	["HawaiiMainLand"] = {
		{"Shado-Pan Monastery", 2545.899902, 3646, 959}, -- AreaTrigger 7694
		{"Temple of the Jade Serpent", -2475.709961, 957.348999, 960}, -- AreaTrigger 7854
		{"Stormstout Brewery", 1261.498291, -720.003479, 961}, -- AreaTrigger 7705
		{"Gate of the Setting Sun", 2080.378418, 699.680542, 962}, -- AreaTrigger 7726
		{"Mogu'shan Palace", 426.84375, 1401.840332, 994}, -- AreaTrigger 8134
		{"Terrace of Endless Spring", -49.5, 959.958313, 996}, -- AreaTrigger 8027
		{"Mogu'shan Vaults", 1115.736084, 3977.240479, 1008}, -- AreaTrigger 7838
		{"Heart of Fear", 4068.059814, 165.236115, 1009}, -- AreaTrigger 8314
		{"Siege of Niuzao Temple", 5088.919922, 1443.130005, 1011}, -- AreaTrigger 8315
		{"Siege of Orgrimmar", 613.852417, 1230.899292, 1136}, -- WorldSafeLocs "Garrosh Raid - Exit Target"
	},
	["Deephome"] = {
		{"The Stonecore", 610.296875, 1031.907959, 725}, -- Map.db2 7.3.5 Corpse
	},
	["TolBarad"] = {
		{"Baradin Hold", 1050.089966, -1274, 757}, -- AreaTrigger 6664
	},
	["MoguIslandDailyArea"] = {
		{"Throne of Thunder", 5014.869141, 7264.408203, 1098}, -- AreaTrigger 8882
	},
};

-- Localize instance names with the client's Map table.
if GetRealZoneText then
	for _, list in pairs(Yatlas_instances) do
		for _, v in ipairs(list) do
			local name = GetRealZoneText(v[4]);
			if name and name ~= "" then v[1] = name; end
		end
	end
end

Yatlas_towns2 = {
	["Kalimdor"] = {
		-- Ashenvale --
		{"Maestra's Post",		  154, 3240, 413},
		{"The Talondeep Path",		  -718, 1913, 1277},
		{"Raynewood Retreat",	   -1881, 2707, 426},
		{"Satyrnaar",			   -2981.2, 2694, 430},
		{"Warsong Lumber Camp",	 -3545.8, 2438, 437},
		{"Zoram'Gar Outpost",	   1012.5, 3353, 2897},
		-- Azshara --
		{"Valormok",				-4400, 3600, 1237},
		{"Talrendis Point",		 -3975, 2693, 3137},
		{"Ruins of Eldarath",	   -5150, 3542, 1221},
		-- Darkshore --
		{"Ruins of Mathystra",	  -845, 7368, 443},
		{"Bashal'Aran",			 -22.9, 6695, 446},
		{"Ameth'Aran",			  200, 5702, 447},
		{"Grove of the Ancients",   102, 4993, 448},
		-- Desolace --
		{"Sargeron",				762, -230, 603},
		{"Thunder Axe Fortress",	1762, -346, 599},
		{"Kodo Graveyard",		  1929, -1303, 596},
		{"Ghostwalker Post",		1752,  -1238, 597},
		{"Mannoroc Coven",		  1902, -1905, 602}, 
		{"Valley of Spears",		2793, -1273, 607},
		{"Gelkis Village",		  2558, -2184, 606},
		{"Magram Village",		  1045, -1807, 4797},
		{"Kolkar Village",		  954, -948, 609},
		-- Durotar --
		{"Razor Hill",			  -4741.6, 309, 362},
		{"The Den",				 -4218, -609, 364},
		{"Sen'jin Village",		 -4912, -823, 367},
		-- Duskwallow --
		{"Brackenwall Village",	 -2877, -3122, 496},
		{"Stonemaul Ruins",		 -3295, -4329, 508},
		-- Felwood --
		{"Felpaw Village",		  -1935, 6785, 1762},
		{"Jaedenar",				-551, 4329, 1763},
		{"Emerald Sanctuary",	   -1310, 4008, 2479},
		{"Talonbranch Glade",	   -1935, 6173, 1998},
		-- Feralas --
		{"Ruins of Isildien",	   1376, -5686, 2522},
		{"Gordunni Outpost",		155, -3730, 1103},
		{"Grimtotem Compound",	  824, -4507, 1100},
		-- Moonglade --
		{"Nighthaven",			  -2497, 7890, 2361},
		{"Stormrage Barrow Dens",   -2947, 7565, 2363},
		{"Shrine of Remulos",	   -2214, 7846, 2362},
		-- Mulgore --
		{"Red Rocks",			   -1137.5, -935, 225},
		{"Bloodhoof Village",	   -381.2, -2318, 222},
		{"Brambleblade Ravine",	 -1181, -3000, 358},
		{"Camp Narache",			-254, -2904, 221},
		-- Silithus --
		{"Staghelm Point",		  100, -6548, 3426},
		{"Valor's Rest",			-304, -6430, 3077},
		{"Southwind Village",	   364, -7196, 2738},
		{"Bronzebeard Encampment",  1122, -8036, 3427},
		-- Stonetalon Mountains --   
		{"Malaka'jin",			  -327, -196, 2539},
		{"The Talon Den",		   1814, 2409, 468},
		{"The Talondeep Path",	  -579, 1544, 1277},
		-- Tanaris --
		{"Steamwheedle Port",	   -4864, -6937, 977},
		{"Uldum",				   -2785, -9656, 5034},
		{"Dunemaul Compound",	   -3050, -8435, 983},
		{"Sandsorrow Warch",		-2952, -7162, 979},
		-- Teldrassil --
		{"Aldrassil",			   818, 10480, 256},
		{"The Oracle Glade",		1918, 10684, 264},
		{"Dolanaar",				968, 9846, 186},
		{"Starbreeze Village",	  420, 9871, 260},
		{"Rut'Theran Village",	  991, 8709, 702},
		-- The Barrens --
		{"The Sludge Fen",		  -3079, 1044, 382},
		{"Northwatch Hold",		 -3641, -2098, 4847},
		-- Thousand Needles --
		{"The Great Lift",		  -1849, -4662, 485},
		{"Mirage Raceway",		  -3914, -6220, 2240},
		{"Roguefeather Den",		-1614, -5487, 487},
		{"The Weathered Nook",	  -2797, -5208, 488},
		{"Ironstone Camp",		  -3422, -5825, 3037},
		{"Whitereach Post",		 -1366, -4918, 2237},
		{"Darkcloud Pinnacle",	  -1931, -5087, 2097},
		-- Un'goro Crater --
		{"Marshal's Refuge",		-1087, -6165, 541},		
		{"Fungal Rock",			 -1856, -6382, 542},
		-- Winterspring --
		{"Owl Wing Thicket",		-4958, 5652, 2250},
		{"The Hidden Grove",		-4842, 7733, 2242},
		{"Starfall Village",		-3931, 7147, 2253},
		{"Winterfall Village",	  -5129, 6764, 2244},
	},
	["Azeroth"] = {
		-- Alterac --
		{"Strahnbrad",			  -956, 679, 280},
		{"Ruins of Alterac",		-310, 539, 281},
		{"Dalaran",				 364, 266, 279},
		-- Arathi Highlands --
		{"The Tower of Arathor",	-1500, -1777, 325},
		{"Stromgarde",			  -1800, -1631, 324},
		{"Witherbark Village",	  -3398, -1741, 317},
		{"Faldir's Cove",		   -2112, -2079, 327},
		{"Refuge Pointe",		   -2416, -1373, 320},
		-- Badlands --
		{"Angor Fortress",		  -3137, -6375, 338},
		{"Dustbelch Grotto",		-2289, -7275, 347},
		-- Blasted Lands --
		{"Nethergarde Keep",		-3431, -10991, 1438},
		{"The Dark Portal",		 -3193, -11829, 72},
		{"Dreadmaul Hold",		  -2664, -108524, 1437},
		-- Burning Steppes --   
		{"Flame Crest",			 -2193, -7480, 251},
		{"Blackrock Stronghold",	-1439, -7701, 252},
		-- Deadwind Pass --
		-- Dun Morogh --
		{"Anvilmar",				387, -6102, 77},
		{"Kharanos",				-500, -5583, 131},
		{"Brewnall Village",		302, -5360, 137},
		-- Duskwood --
		{"Ravenhill",			   327, -10735, 94},
		-- Eastern Plaguelands --
		{"Terrorweb Tunnel",		-2772, 3034, 2626},
		{"Terrorweb Tunnel",		-2470, 2751, 2626},
		{"Light's Hope Chapel",	 -5339, 2298, 2268},
		{"Tyr's Hand",			  -5558, 1596, 2266},
		{"Darrowshire",			 -3695, 1438, 2262},
		{"Corin's Crossing",		-4505, 2032, 2264},	
		-- Elwynn Forest --
		{"Northshire Abbey",		-172, -8878, 24}, 
		{"Eastvale Logging Camp",   -1352, -9460, 88},
		{"Goldshire",			   68, -9458, 87},
		{"Westbrook Garrison",	  677, -9624, 120},
		-- Hillsbrad Foothills
		{"Azurlode Mine",		   196, -827, 288},
		{"Durnholde Keep",		  -1457, -456, 275},
		{"Dun Garok",			   -1218, -1292, 290},
		{"Purgation Isle",		  590, -1333, 896},
		-- Loch Modan --
		{"The Farstrider Lodge",	-4270, -5655, 147},
		-- Red Ridge Mountains --
		{"Tower of Ilgalar",		-3297, -9280, 96},
		{"Stonewatch Keep",		 -3052, -9380, 2099}, 
		-- Searing Gorge --
		{"Thorium Point",		   -1153, -6504, 1446},
		-- Silverpine Forest --
		{"Ambermill",			   791, -122, 233},
		{"Pyrewood Village",		1556, -385, 204},
		-- Strangethorn Vale --
		{"Mosh'Ogg Ogre Mound",	 -1006, -12368, 105},
		{"Venture Co. Base Camp",   -523, -11972, 1740},
		{"Gurubashi Arena",		 278, -13204, 1741},
		-- Swamp of Sorrows --
		{"Fallow Sanctuary",		-3641, -9954, 76},
		{"Misty Valley",			-2526, -10164, 116},
		{"Stagalbog Cave",		  -3745, -10795, 1817},
		-- The Hinterlands --
		{"Skulk Rock",			  -3795, 393, 351},
		{"Quel'Danil Lodge",		-2764, 239, 350},
		{"The Altar of Zul",		-3454, -293, 355},
		{"Jintha'Alor",			 -3955, -468, 354},
		-- Tirisfal Glades --
		{"Agamand Mills",		   871, 2839, 157},
		{"Deathknell",			  1580, 1929, 154},
		{"Brill",				   286, 2304, 159},
		-- Western Plaguelands --
		{"Hearthglen",			  1516, 2877, 190},
		{"Ruins of Andorhal",	   -1518,1383, 193},
		{"Caer Darrow",			 -2558, 1156, 2298},
		{"The Bulwark",			 -762, 1745, 813},
		{"Chillwind Camp",		  -1441, 925, 3197},
		-- Westfall --
		{"Jangolode Mine",		  1453, -9968, 111},
		{"Gold Coast Quarry",	   1915, -10416, 113},
		{"Moonbrook",			   1501, -11010, 20},
		-- Wetlands --
		{"Dun Modr",				-2327, -2610, 205},
		{"Dun Algaz",			   -2369, -4198, 836},
		{"Grim Batol",			  -3429, -4006, 1037},		
	},
}

-- Localize town names with the client's own AreaTable (4th field = AreaTable ID).
if C_Map and C_Map.GetAreaInfo then
	for _, towns in pairs(Yatlas_towns2) do
		for _, v in ipairs(towns) do
			local name = v[4] and C_Map.GetAreaInfo(v[4]);
			if name and name ~= "" then v[1] = name; end
		end
	end
end

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
