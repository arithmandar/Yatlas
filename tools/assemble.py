import re
ROOT='..'
import os
OLD=os.environ.get('YATLAS_OLD_MAPDB','/tmp/mapdb_old.lua')        # git show bf9badf:mapdb.lua
OLD2=os.environ.get('YATLAS_OLD_MAPDB2','/tmp/mapdb2_old.lua')     # git show bf9badf:mapdb2.lua
src=open(OLD,encoding='utf-8-sig').read()
src2=open(OLD2,encoding='utf-8-sig').read()
G=lambda n: open(f'/tmp/gen/{n}.lua').read()

# ---------- graveyards: DISABLED for 5.5.4
# WorldSafeLocs is server-side only in the modern client (not in any 5.5.4 DB2, no wago.tools
# export), so there is no client data source for graveyard positions. The feature is switched off
# (Modules/graveyards.lua is no longer loaded) until a reliable source is found.
gy = ('-- Graveyards: disabled for 5.5.4.70579 (MoP Classic).\n'
      '-- WorldSafeLocs is server-side only in the modern client; no client data source is available.\n'
      '-- Kept as an empty table so Modules/graveyards.lua can be re-enabled later.\n'
      'Yatlas_graveyards = {};\n')

loc_area='''
-- Localize area names with the client's own AreaTable (replaces LibBabble-SubZone-3.0).
if C_Map and C_Map.GetAreaInfo then
\tfor id in pairs(Yatlas_areadb) do
\t\tlocal name = C_Map.GetAreaInfo(id);
\t\tif name and name ~= "" then Yatlas_areadb[id] = name; end
\tend
end
'''
mapdb = ('-- Yatlas map database\n'
 '-- Oct. 25, 2026: regenerated for WoW MoP Classic 5.5.4.70579 from wago.tools DB2 exports and WDT files.\n'
 '-- See Docs/DataSources-5.5.4.md for the source of every table.\n\n'
 + G('worldmapids2') + '\n' + G('mapdb1') + '\n' + G('areadb') + loc_area + '\n' + G('mapareas') + '\n' + gy)
open(f'{ROOT}/Data/mapdb.lua','w',encoding='utf-8').write(mapdb)

# ---------- mapdb2.lua
def cut(s, start, end_marker):
    a=s.index(start); b=s.index(end_marker,a)+len(end_marker); return s[:a], s[b:]
head = '''-- Yatlas map mapping
-- Display_Name - Actual Map Folder Name (Map.db2 Directory)
-- Oct. 25, 2026: updated for MoP Classic 5.5.4.70579. Display names come from the client
-- (C_Map.GetMapInfo) so they are localized without LibBabble-SubZone-3.0.
local function YA_UiMapName(uiMapID, fallback)
\tlocal info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(uiMapID);
\treturn (info and info.name and info.name ~= "" and info.name) or fallback;
end

YA_MAPS = {
\t[YA_UiMapName(13, "Eastern Kingdoms")] = {"Azeroth"},
\t[YA_UiMapName(12, "Kalimdor")] = {"Kalimdor"},
\t[YA_UiMapName(101, "Outland")] = {"Expansion01"},
\t[YA_UiMapName(113, "Northrend")] = {"Northrend"},
\t[YA_UiMapName(424, "Pandaria")] = {"HawaiiMainLand"},
\t[YA_UiMapName(207, "Deepholm")] = {"Deephome"},
\t[YA_UiMapName(244, "Tol Barad")] = {"TolBarad"},
\t[YA_UiMapName(504, "Isle of Thunder")] = {"MoguIslandDailyArea"},
\t[YA_UiMapName(407, "Darkmoon Island")] = {"DarkmoonFaire"},
};

-- [Directory] = uiMapID of the map shown for it (continent, or the zone for single-zone maps).
-- Previously these were the SetMapZoom() continent indexes (1..6); SetMapZoom() no longer exists,
-- the C_Map API works with uiMapIDs.
Yatlas_WorldMapIds = {
\t["Azeroth"] = 13,
\t["Kalimdor"] = 12,
\t["Expansion01"] = 101,
\t["Northrend"] = 113,
\t["HawaiiMainLand"] = 424,
\t["Deephome"] = 207,
\t["TolBarad"] = 244,
\t["MoguIslandDailyArea"] = 504,
\t["DarkmoonFaire"] = 407,
};


'''
a=src2.index('-- These MUST MATCH'); b=src2.index('Yatlas_PaperZoneNames')
mid1 = src2[b:src2.index('-- Instances (entrances)')]
a2=src2.index('Yatlas_towns2')
rest = src2[a2:]
loc_inst='''
-- Localize instance names with the client's Map table.
if GetRealZoneText then
\tfor _, list in pairs(Yatlas_instances) do
\t\tfor _, v in ipairs(list) do
\t\t\tlocal name = GetRealZoneText(v[4]);
\t\t\tif name and name ~= "" then v[1] = name; end
\t\tend
\tend
end

'''
# drop the old graveyard blacklist (graveyards are disabled, see above)
rest = rest[:rest.index("-- 'blacklist' some of our 'graveyards'")].rstrip() + '\n'
# town names: add AreaTable IDs so they can be localized in game (see towns.py)
import towns
rest = towns.process(rest)
mapdb2 = head + G('zoneids') + '\n' + mid1 + G('instances') + loc_inst + G('taxinodes') + rest
open(f'{ROOT}/Data/mapdb2.lua','w',encoding='utf-8').write(mapdb2)
print('ok', len(mapdb), len(mapdb2))
