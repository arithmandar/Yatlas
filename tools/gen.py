#!/usr/bin/env python3
"""Generate Yatlas data tables for WoW MoP Classic 5.5.4.70579.

Inputs (all in /tmp):
  *.csv                 DB2 exports from https://wago.tools/db2/<Table>/csv?build=5.5.4.70579
  wdt/tiles.pkl         MAID chunks parsed from the 5.5.4 WDT files (see wdt.py)
  at_mc.sql, at_sf.sql  areatrigger_teleport rows (MistCore 5.0.5 / SkyFire 5.4.8)
Outputs: /tmp/gen/*.lua snippets that get spliced into mapdb.lua / mapdb2.lua
"""
import csv, re, pickle, os, sys
sys.path.insert(0, '/tmp')
from oldparse import mapdb1 as old_mapdb1

BUILD = '5.5.4.70579'
OUT = '/tmp/gen'; os.makedirs(OUT, exist_ok=True)

def rd(t): return list(csv.DictReader(open(f'/tmp/{t}.csv', encoding='utf-8')))
def luastr(s): return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'
def num(v):
    s = f'{float(v):.6f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s

Map = {int(r['ID']): r for r in rd('Map')}
Dir = {k: v['Directory'] for k, v in Map.items()}
Area = {int(r['ID']): r for r in rd('AreaTable')}
UiMap = {int(r['ID']): r for r in rd('UiMap')}
UiA = rd('UiMapAssignment')

# Maps Yatlas can display (have minimap tiles + a UiMap). Order = dropdown order.
WORLD = [  # (MapID, continent/zone UiMapID, English display name)
    (0, 13, 'Eastern Kingdoms'),
    (1, 12, 'Kalimdor'),
    (530, 101, 'Outland'),
    (571, 113, 'Northrend'),
    (870, 424, 'Pandaria'),
    (646, 207, 'Deepholm'),
    (732, 244, 'Tol Barad'),
    (1064, 504, 'Isle of Thunder'),
    (974, 407, 'Darkmoon Island'),
]
WORLD_IDS = [m for m, _, _ in WORLD]

# ---------------------------------------------------------------- Map.db2
with open(f'{OUT}/worldmapids2.lua', 'w') as f:
    f.write(f'-- Map data extracted from Map.db2\n-- Oct. 25, 2026: updated to {BUILD} (MoP Classic)\n')
    f.write('-- [Directory] = MapID (instanceID, as returned by UnitPosition / GetInstanceInfo)\n')
    f.write('Yatlas_WorldMapIds2 = {\n')
    for k in sorted(Map):
        f.write(f'\t[{luastr(Dir[k])}] = {k},\n')
    f.write('};\n')

# ---------------------------------------------------------------- minimap tiles (WDT MAID)
tiles = pickle.load(open('/tmp/wdt/tiles.pkl', 'rb'))
old1 = old_mapdb1()
with open(f'{OUT}/mapdb1.lua', 'w') as f:
    f.write('-- Minimap tile textures (FileDataIDs) from the MAID chunk of world\\maps\\<Directory>\\<Directory>.wdt\n')
    f.write(f'-- Oct. 25, 2026: updated to {BUILD} (MoP Classic). Key "XXxYY" = minimap tile mapXX_YY.\n')
    f.write('-- Value is a FileDataID usable directly with Texture:SetTexture(fileID).\n')
    f.write('Yatlas_mapdb1 = {\n')
    stats = {}
    for mid in WORLD_IDS:
        d = Dir[mid]
        t = tiles[d][2]
        f.write(f'\t[{luastr(d)}] = {{ -- MapID {mid}, WDT FileDataID {tiles[d][1]}\n')
        real = {k: e[7] for k, e in t.items() if e[7]}
        # keep the old hand made "mocking up" ocean fillers, remapped to the new FileDataID
        mock = {}
        for k, (tex, cmt) in old1.get(d, {}).items():
            if 'mock' in cmt and k not in real:
                m = re.match(r'map(\d+)_(\d+)', tex)
                src = (int(m.group(1)), int(m.group(2)))
                if src in real: mock[k] = real[src]
        for k in sorted(set(real) | set(mock), key=lambda p: (p[0], p[1])):
            if k in real: f.write(f'\t\t["{k[0]:02d}x{k[1]:02d}"] = {real[k]},\n')
            else: f.write(f'\t\t["{k[0]:02d}x{k[1]:02d}"] = {mock[k]}, -- mocking up\n')
        f.write('\t},\n')
        stats[d] = (len(real), len(mock))
    f.write('};\n')
print('tiles', stats)

# ---------------------------------------------------------------- AreaTable.db2
with open(f'{OUT}/areadb.lua', 'w') as f:
    f.write(f'-- Data from AreaTable.db2\n-- Oct. 25, 2026: updated to {BUILD} (MoP Classic)\n')
    f.write('-- enUS names; localized at load time through C_Map.GetAreaInfo() (see end of file)\n')
    f.write('Yatlas_areadb = \n{\n')
    for k in sorted(Area):
        n = Area[k]['AreaName_lang']
        if n: f.write(f'\t[{k}] = {luastr(n)},\n')
    f.write('};\n')

# ---------------------------------------------------------------- UiMap / UiMapAssignment  (replaces WorldMapArea)
def bounds(a):
    """Return WorldMapArea style {LocLeft, LocRight, LocTop, LocBottom} for the full 0..1 UiMap."""
    u0, u1, U0, U1 = (float(a[k]) for k in ('UiMin_0', 'UiMin_1', 'UiMax_0', 'UiMax_1'))
    x0, y0, x1, y1 = (float(a[k]) for k in ('Region_0', 'Region_1', 'Region_3', 'Region_4'))
    # UI x grows towards -worldY, UI y grows towards -worldX
    sy = (y1 - y0) / (U0 - u0); sx = (x1 - x0) / (U1 - u1)
    left = y1 + u0 * sy; right = left - sy
    top = x1 + u1 * sx; bottom = top - sx
    return left, right, top, bottom

by_ui = {}
for a in UiA: by_ui.setdefault(int(a['UiMapID']), []).append(a)
for v in by_ui.values(): v.sort(key=lambda a: int(a['OrderIndex']))

mapareas = {}   # MapID -> {areaID: (bounds, uiMapID, name)}
uimapids = {}   # MapID -> {areaID: uiMapID}
for uid in sorted(UiMap):
    u = UiMap[uid]; typ = int(u['Type'])
    if typ not in (2, 3, 6) or uid not in by_ui: continue
    a = by_ui[uid][0]
    if typ == 6 and int(a['MapID']) not in WORLD_IDS: continue                    # OrderIndex 0 = the UiMap's own map
    if int(a['WMOGroupID']) or int(a['WMODoodadPlacementID']): continue
    mid = int(a['MapID'])
    if typ == 2: aid = 0
    else:
        aid = int(a['AreaID'])
        if not aid: continue
    d = mapareas.setdefault(mid, {})
    if aid in d: continue                 # first (lowest) UiMap wins (phased copies come later)
    d[aid] = (bounds(a), uid, u['Name_lang'])
    uimapids.setdefault(mid, {})[aid] = uid

with open(f'{OUT}/mapareas.lua', 'w') as f:
    f.write('-- Map ID from Map.db2; Area ID mapped to AreaTable.db2\n')
    f.write('-- Coordination from UiMapAssignment.db2 (WorldMapArea.dbc was removed in 8.0; values are\n')
    f.write('-- {LocLeft, LocRight, LocTop, LocBottom} = {maxWorldY, minWorldY, maxWorldX, minWorldX}\n')
    f.write('-- extrapolated to the full 0..1 UiMap rectangle, i.e. identical to the old WorldMapArea layout)\n')
    f.write('Yatlas_mapareas = {\n')
    f.write(f'-- Oct. 25, 2026: updated to {BUILD} (MoP Classic)\n')
    for mid in sorted(mapareas):
        f.write(f'\t-- Map ID: {mid}\n\t[{luastr(Dir.get(mid, str(mid)))}] = {{\n')
        for aid in sorted(mapareas[mid]):
            (l, r, t, b), uid, name = mapareas[mid][aid]
            f.write(f'\t\t[{aid}] = {{{num(l)}, {num(r)}, {num(t)}, {num(b)}}}, -- {name} (uiMapID {uid})\n')
        f.write('\t},\n')
    f.write('};\n')

    f.write('\n-- [Directory] = { [areaID] = uiMapID }   ([0] = continent UiMap). For C_Map.* calls.\n')
    f.write('Yatlas_UiMapIds = {\n')
    for mid in sorted(uimapids):
        f.write(f'\t[{luastr(Dir.get(mid, str(mid)))}] = {{')
        f.write(', '.join(f'[{a}]={u}' for a, u in sorted(uimapids[mid].items())))
        f.write('},\n')
    f.write('};\n')

# Yatlas_ZoneIds: zones whose terrain lives on each tile map (grouped by MapID, not by UI parent)
zone_ids = {}
for mid, cuid, _ in WORLD:
    lst = {}
    for uid in sorted(UiMap):
        u = UiMap[uid]
        if int(u['Type']) not in (3, 6) or uid not in by_ui: continue
        a = by_ui[uid][0]
        aid = int(a['AreaID'])
        if int(a['MapID']) == mid and aid and aid not in lst and aid in mapareas.get(mid, {}) and mapareas[mid][aid][1] == uid:
            lst[aid] = Area[aid]['AreaName_lang'] if aid in Area else u['Name_lang']
    zone_ids[mid] = ([0] if 0 in mapareas.get(mid, {}) else []) + sorted(lst, key=lambda k: lst[k])

with open(f'{OUT}/zoneids.lua', 'w') as f:
    f.write(f'-- Zones per tile map, from UiMap.db2 + UiMapAssignment.db2 ({BUILD}); [1] = 0 is the continent itself\n')
    f.write('-- (GetMapZones() no longer exists; order is alphabetical by enUS name)\n')
    f.write('Yatlas_ZoneIds = {\n')
    for mid, l in zone_ids.items():
        if not l: continue
        f.write(f'\t-- Map ID = {mid}\n\t[{luastr(Dir[mid])}] = {{\n\t\t')
        f.write(', '.join(str(x) for x in l))
        f.write(',\n\t},\n')
    f.write('};\n')

# ---------------------------------------------------------------- instance entrances
tele = []
for fn in ('/tmp/at_mc.sql', '/tmp/at_sf.sql'):
    for m in re.finditer(r"\((\d+),\s*'((?:[^'\\]|\\.)*)',\s*(\d+),", open(fn).read()):
        tele.append((int(m.group(1)), m.group(2), int(m.group(3))))
AT = {int(r['ID']): r for r in rd('AreaTrigger')}
inst = {}  # target map -> list of (continent, Y, X, triggerID)
for tid, name, tmap in tele:
    if tid not in AT or tmap not in Map: continue
    if int(Map[tmap]['InstanceType']) not in (1, 2): continue
    r = AT[tid]; cont = int(r['ContinentID'])
    if cont not in WORLD_IDS: continue
    e = (cont, float(r['Pos_1']), float(r['Pos_0']), tid)
    if e not in inst.setdefault(tmap, []): inst[tmap].append(e)

RETIRED = {44, 169, 189, 289, 309, 598, 627, 637, 721, 734, 930, 951, 977, 995, 1032}
OLDMAP = {int(r['ID']): r for r in csv.DictReader(open('/tmp/Map_7.3.5.26972.csv'))}
entries = {mid: [] for mid in WORLD_IDS}
for tmap, es in inst.items():
    if tmap in RETIRED: continue
    for cont, y, x, tid in es: entries[cont].append((tmap, y, x, f'AreaTrigger {tid}'))
found = set(inst) - RETIRED
for k, r in Map.items():
    if int(r['InstanceType']) not in (1, 2) or k in RETIRED or k in found: continue
    o = OLDMAP.get(k)
    if o and int(o['CorpseMapID']) in WORLD_IDS and (float(o['Corpse_0']) or float(o['Corpse_1'])):
        entries[int(o['CorpseMapID'])].append((k, float(o['Corpse_1']), float(o['Corpse_0']), 'Map.db2 7.3.5 Corpse'))
        found.add(k)
# hand fixes (no trigger / corpse data for these MoP instances)
entries[0].append((1004, 2924.379883, -798.429016, 'approx.: old Scarlet Monastery courtyard (AreaTrigger 45)'))
entries[870].append((1136, 613.852417, 1230.899292, 'WorldSafeLocs "Garrosh Raid - Exit Target"'))
found |= {1004, 1136}
missing = [(k, Map[k]['MapName_lang']) for k, r in Map.items() if int(r['InstanceType']) in (1, 2) and k not in RETIRED and k not in found]
print('instances without entrance:', missing)

with open(f'{OUT}/instances.lua', 'w') as f:
    f.write('-- Instances (entrances)\n')
    f.write(f'-- Oct. 25, 2026: updated to {BUILD} (MoP Classic)\n')
    f.write('-- Primary source: the client AreaTrigger.db2 row that teleports into the instance\n')
    f.write('--   (trigger -> instance mapping from MoP server data: MistCore 5.0.5 / SkyFire 5.4.8 areatrigger_teleport)\n')
    f.write('-- Fallback: Map.db2 Corpse_0/Corpse_1 (entrance) of build 7.3.5, the last client that shipped them\n')
    f.write('-- {name, worldY, worldX, instanceMapID, instanceType}; name is localized at load time via GetRealZoneText(mapID)\n')
    f.write('-- instanceType from Map.db2 InstanceType: 1 = dungeon (party), 2 = raid\n')
    f.write('Yatlas_instances = {\n')
    for mid in WORLD_IDS:
        rows = sorted(entries[mid], key=lambda r: (r[0], r[3]))
        kept = []
        for r in rows:
            if any(k[0] == r[0] and abs(k[1]-r[1]) < 150 and abs(k[2]-r[2]) < 150 for k in kept): continue
            kept.append(r)
        if not kept: continue
        f.write(f'\t[{luastr(Dir[mid])}] = {{\n')
        for tmap, y, x, src in kept:
            f.write(f'\t\t{{{luastr(Map[tmap]["MapName_lang"])}, {num(y)}, {num(x)}, {tmap}, {int(Map[tmap]["InstanceType"])}}}, -- {src}\n')
        f.write('\t},\n')
    f.write('};\n')

# ---------------------------------------------------------------- taxi nodes (flight paths)
# TaxiNodes.db2 Flags: 0x1 = shown on the Alliance map, 0x2 = shown on the Horde map,
# 0x80 = hidden from the world map UI. Pos_0 = world X, Pos_1 = world Y.
# faction uses the Enum.FlightPathFaction values: 0 = Neutral, 1 = Horde, 2 = Alliance.
# conditional = 1 when the node has a PlayerCondition (quest / phase); those are shown
# only when C_TaxiMap confirms them at runtime.
taxi = {mid: [] for mid in WORLD_IDS}
for r in rd('TaxiNodes'):
    cont, fl = int(r['ContinentID']), int(r['Flags'])
    if cont not in taxi or not (fl & 3) or (fl & 0x80): continue
    faction = 0 if (fl & 3) == 3 else (2 if fl & 1 else 1)
    cond = 1 if int(r['ConditionID']) else 0
    taxi[cont].append((int(r['ID']), r['Name_lang'], float(r['Pos_1']), float(r['Pos_0']), faction, cond))
with open(f'{OUT}/taxinodes.lua', 'w') as f:
    f.write(f'-- Flight paths, from TaxiNodes.db2 ({BUILD})\n')
    f.write('-- {name, worldY, worldX, taxiNodeID, faction (0 neutral, 1 horde, 2 alliance), conditional}\n')
    f.write('-- name is localized at runtime from C_TaxiMap.GetTaxiNodesForMap (see Modules/taxinodes.lua)\n')
    f.write('Yatlas_taxinodes = {\n')
    for mid in WORLD_IDS:
        if not taxi[mid]: continue
        f.write(f'\t[{luastr(Dir[mid])}] = {{\n')
        for nid, name, y, x, fac, cond in sorted(taxi[mid]):
            f.write(f'\t\t{{{luastr(name)}, {num(y)}, {num(x)}, {nid}, {fac}, {cond}}},\n')
        f.write('\t},\n')
    f.write('};\n\n')
print('taxi nodes', {Dir[m]: len(v) for m, v in taxi.items() if v})

pickle.dump({'zone_ids': zone_ids, 'inst': inst, 'mapareas': mapareas}, open(f'{OUT}/meta.pkl', 'wb'))
print('mapareas maps', len(mapareas), 'instances', sum(len(v) for v in inst.values()))
for mid, l in zone_ids.items(): print(Dir[mid], len(l), [Area[a]['AreaName_lang'] if a else 'continent' for a in l])
