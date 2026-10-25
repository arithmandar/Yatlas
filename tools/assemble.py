import re
ROOT='..'
import os
OLD=os.environ.get('YATLAS_OLD_MAPDB','/tmp/mapdb_old.lua')        # git show bf9badf:mapdb.lua
OLD2=os.environ.get('YATLAS_OLD_MAPDB2','/tmp/mapdb2_old.lua')     # git show bf9badf:mapdb2.lua
src=open(OLD,encoding='utf-8-sig').read()
src2=open(OLD2,encoding='utf-8-sig').read()
G=lambda n: open(f'/tmp/gen/{n}.lua').read()

# ---------- graveyards (from the build 19005 WorldSafeLocs extract, filtered for MoP Classic)
i=src.index('\nYatlas_graveyards'); j=src.index('\n}',i); b=src[i:j]
DROP=re.compile(r'Character Upgrade|6\.0 Invasion|\(New\)|Lower Blackrock Spire - Exit Teleport')
KEYMAP={'Deepholm':'Deephome'}
out=['-- Graveyards: {worldX, worldY} from WorldSafeLocs.dbc.',
     '-- WorldSafeLocs is server-side only in the modern client (not in 5.5.4 DB2s, no wago.tools export);',
     '-- this list is the build 19005 extract with Draenor and WoD-only entries removed, which covers',
     '-- MoP 5.4 (Timeless Isle, Isle of Giants, Vale raid). Runtime alternative: C_DeathInfo.GetGraveyardsForMap(uiMapID).',
     '-- Oct. 25, 2026: reviewed for 5.5.4.70579 (MoP Classic)',
     'Yatlas_graveyards = {']
cur=None; dropped=[]; cnt={}
for line in b.split('\n')[1:]:
    m=re.match(r'\t\["(\w+)"\]',line)
    if m:
        if cur: out.append('\t},')
        cur=m.group(1); 
        if cur=='Draenor': cur='SKIP'; continue
        out.append(f'\t["{KEYMAP.get(cur,cur)}"] = {{'); continue
    m=re.match(r'\s*\{(-?[\d.]+), (-?[\d.]+)\},\s*--\s*(.*)',line)
    if m and cur and cur!='SKIP':
        if DROP.search(m.group(3)): dropped.append(m.group(3)); continue
        out.append(f'\t\t{{{m.group(1)}, {m.group(2)}}}, \t-- {m.group(3).strip()}'); cnt[cur]=cnt.get(cur,0)+1
if cur and cur!='SKIP': out.append('\t},')
out.append('};')
gy='\n'.join(out)+'\n'
print('graveyards',cnt,'dropped',dropped)

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
open(f'{ROOT}/mapdb.lua','w',encoding='utf-8').write(mapdb)

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
rest = rest.replace('function YA_BL_gy(cont, c) \n\tfor h,v in ipairs(Yatlas_graveyards[cont]) do',
                    'function YA_BL_gy(cont, c) \n\tif(type(Yatlas_graveyards[cont]) ~= "table") then return; end\n\tfor h,v in ipairs(Yatlas_graveyards[cont]) do')
mapdb2 = head + G('zoneids') + '\n' + mid1 + G('instances') + loc_inst + rest
open(f'{ROOT}/mapdb2.lua','w',encoding='utf-8').write(mapdb2)
print('ok', len(mapdb), len(mapdb2))
