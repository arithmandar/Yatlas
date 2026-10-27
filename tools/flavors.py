"""Client flavours Yatlas ships data for.

Each flavour gets its own Data/<folder>/mapdb.lua + mapdb2.lua. The files start with a
client check (YATLAS_CLIENT, see Core/Constants.lua) and return right away on other clients.

world: the tile maps Yatlas can show, in drop-down order.
       (MapID, uiMapID used for the name / C_Map calls, English fallback name[, name source])
       name source 'map' = use GetRealZoneText(MapID) instead of the UiMap name.
teleports: tools/data/areatrigger_teleport_<name>.csv (which AreaTrigger enters which instance)
corpse: tools/data/map_corpse_<build>.csv fallback for instances without a trigger
        ('self' = the flavour's own Map.db2 Corpse_0/Corpse_1 columns)
journal: use JournalInstanceEntrance.db2 (mainline) as the primary instance source
"""

FLAVORS = {
    'ClassicEra': dict(
        build='1.15.9.70003', check='isClassicEra', label='Classic Era',
        world=[
            (0, 1415, 'Eastern Kingdoms'),
            (1, 1414, 'Kalimdor'),
        ],
        teleports='azerothcore', corpse='1.13.0.28211',
        retired={13, 29, 44, 169, 598},   # test maps and the unused old Scarlet Monastery
        instance_fixes=[
            # Naxxramas floats above the Plaguelands; AreaTrigger 4055 is the attunement check
            # at the entrance (no areatrigger_teleport row because the WotLK version moved)
            (0, 533, -3730.290039, 3133.149902, 'AreaTrigger 4055 (Naxxramas entrance)'),
        ],
    ),
    'TBC': dict(
        build='2.5.6.70006', check='isTBC', label='Burning Crusade Classic (Anniversary)',
        world=[
            (0, 1415, 'Eastern Kingdoms'),
            (1, 1414, 'Kalimdor'),
            (530, 1945, 'Outland'),     # 987 is an orphan copy outside the world map tree
        ],
        teleports='azerothcore', corpse='7.3.5.26972',
        retired={13, 29, 44, 169, 598},   # test maps and the unused old Scarlet Monastery
        instance_fixes=[
            # Naxxramas floats above the Plaguelands; AreaTrigger 4055 is the attunement check
            # at the entrance (no areatrigger_teleport row because the WotLK version moved)
            (0, 533, -3730.290039, 3133.149902, 'AreaTrigger 4055 (Naxxramas entrance)'),
        ],
    ),
    'Mists': dict(
        build='5.5.4.70579', check='isMists', label='Mists of Pandaria Classic',
        world=[
            (0, 13, 'Eastern Kingdoms'),
            (1, 12, 'Kalimdor'),
            (530, 1467, 'Outland'),     # 5.5.4: 101 does not exist; 987 is an orphan copy
            (571, 113, 'Northrend'),
            (646, 207, 'Deepholm'),
            (732, 244, 'Tol Barad'),
            (870, 424, 'Pandaria'),
            (1064, 504, 'Isle of Thunder'),
            (974, 407, 'Darkmoon Island'),
        ],
        teleports='mists', corpse='7.3.5.26972',
        # MoP instances that are no longer reachable (old versions replaced in Cataclysm / MoP)
        retired={44, 169, 189, 289, 309, 598, 627, 637, 721, 734, 930, 951, 977, 995, 1032},
        instance_fixes=[
            (0, 1004, 2924.379883, -798.429016, 'approx.: old Scarlet Monastery courtyard (AreaTrigger 45)'),
            (870, 1136, 613.852417, 1230.899292, 'WorldSafeLocs "Garrosh Raid - Exit Target"'),
        ],
    ),
    'Forever': dict(
        # World of Warcraft: Forever (WOW_PROJECT_CAMELOT = 18): the 1-60 world on the mainline engine
        build='1.60.1.70630', check='isForever', label='World of Warcraft: Forever',
        world=[
            (0, 1415, 'Eastern Kingdoms'),
            (1, 1414, 'Kalimdor'),
            (2991, 2665, 'Zephras Isle'),   # 2665 = the continent entry, 2521 the zone
        ],
        # Forever's own Map.db2 has the entrances (Corpse) of the original instances; the new
        # 1.60 dungeons have no entrance in the client data yet
        teleports='azerothcore', corpse='self',
        retired={13, 29, 44, 169, 598},   # test maps and the unused old Scarlet Monastery
        instance_fixes=[
            # Naxxramas floats above the Plaguelands; AreaTrigger 4055 is the attunement check
            (0, 533, -3730.290039, 3133.149902, 'AreaTrigger 4055 (Naxxramas entrance)'),
        ],
    ),
    'Mainline': dict(
        build='12.1.5.70575', check='isRetail', label='Retail (Midnight)',
        world=[
            (0, 13, 'Eastern Kingdoms'),
            (1, 12, 'Kalimdor'),
            (530, 101, 'Outland'),
            (571, 113, 'Northrend'),
            (646, 207, 'Deepholm'),
            (732, 244, 'Tol Barad'),
            (870, 424, 'Pandaria'),
            (1064, 504, 'Isle of Thunder'),
            (1116, 572, 'Draenor'),
            (1220, 619, 'Broken Isles'),
            (1669, 994, 'Argus'),
            (1642, 875, 'Zandalar'),
            (1643, 876, 'Kul Tiras'),
            (1718, 1355, 'Nazjatar'),
            (2222, 1550, 'The Shadowlands'),
            (2374, 1970, 'Zereth Mortis'),
            (2444, 1978, 'Dragon Isles'),
            (2570, 2118, 'The Forbidden Reach'),
            (2454, 2133, 'Zaralek Cavern'),
            (2548, 2200, 'Emerald Dream'),
            (2552, 2274, 'Khaz Algar (Surface)', 'map'),
            (2601, 2274, 'Khaz Algar'),
            (2706, 2346, 'Undermine'),
            (2127, 2369, 'Siren Isle'),
            (2738, 2371, "K'aresh"),
            (2694, 2413, 'Harandar'),
            (2771, 2405, 'Voidstorm'),
            (974, 407, 'Darkmoon Island'),
        ],
        journal=True, corpse='self',
    ),
}
