#!/usr/bin/env python3
"""Generate the Yatlas data files for one or more WoW client flavours.

    python3 yatlas_data.py                 # every flavour in flavors.py
    python3 yatlas_data.py Mists TBC       # only these

Writes ../Data/<Flavour>/mapdb.lua and ../Data/<Flavour>/mapdb2.lua.

Inputs
  * DB2 exports from wago.tools for the flavour's build (downloaded into tools/.cache/<build>/)
  * WDT files of the shown maps (MAID chunk = minimap tile FileDataIDs), also from wago.tools
  * the original Yatlas data (git show bf9badf:mapdb.lua / mapdb2.lua) for the hand made
    "mocking up" ocean tiles and the hand picked town list
  * tools/data/areatrigger_teleport_*.csv  which AreaTrigger enters which instance (server data)
  * tools/data/map_corpse_*.csv            Map.db2 Corpse_0/1 (instance entrance) of old clients
"""
import math, csv, json, os, re, struct, subprocess, sys
from flavors import FLAVORS

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CACHE = os.path.join(HERE, '.cache')
DATE = 'Oct. 26, 2026'
OLD_COMMIT = 'bf9badf'   # last commit with the original (pre-5.5.4) Yatlas data


# ---------------------------------------------------------------- helpers
def get(url, fn=None):
    a = ['curl', '-sfL', '-A', 'Mozilla/5.0', url] + (['-o', fn] if fn else [])
    r = subprocess.run(a, capture_output=True)
    if r.returncode:
        raise RuntimeError(f'download failed: {url}')
    return r.stdout


def luastr(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"') + '"'


def num(v):
    s = f'{float(v):.6f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def old_source(name):
    return subprocess.run(['git', '-C', ROOT, 'show', f'{OLD_COMMIT}:{name}'],
                          capture_output=True, check=True).stdout.decode('utf-8-sig')


def old_mapdb1():
    src = old_source('mapdb.lua')
    i = src.index('\nYatlas_mapdb1'); j = src.index('\n}', i)
    res, cur = {}, None
    for line in src[i:j].split('\n'):
        m = re.match(r'\t\["(\w+)"\] = \{', line)
        if m:
            cur = m.group(1); res[cur] = {}; continue
        m = re.match(r'\t\t\["(\d+)x(\d+)"\] = \{"(\w+)", \{(\d+),(\d+)\}\}(.*)', line)
        if m and cur:
            res[cur][(int(m.group(1)), int(m.group(2)))] = (m.group(3), m.group(6).strip())
    return res


def old_towns():
    src = old_source('mapdb2.lua')
    a = src.index('Yatlas_towns2')
    return src[a:src.index('\n}\n', a) + 3]


class Build:
    def __init__(self, build):
        self.build = build
        self.dir = os.path.join(CACHE, build)
        os.makedirs(os.path.join(self.dir, 'wdt'), exist_ok=True)

    def table(self, name):
        fn = os.path.join(self.dir, f'{name}.csv')
        if not os.path.exists(fn) or os.path.getsize(fn) < 64:
            get(f'https://wago.tools/db2/{name}/csv?build={self.build}', fn)
        with open(fn, encoding='utf-8') as f:
            head = f.read(64)
        if head.startswith('{'):
            raise RuntimeError(f'{name} not available for {self.build}')
        return list(csv.DictReader(open(fn, encoding='utf-8')))

    def wdt_tiles(self, mapid, directory, fdid=None):
        fn = os.path.join(self.dir, 'wdt', f'{directory}.wdt')
        if not os.path.exists(fn):
            if not fdid:
                path = f'world/maps/{directory.lower()}/{directory.lower()}.wdt'
                j = json.loads(get(f'https://wago.tools/api/files?search={path}') or b'{}')
                fd = [k for k, v in j.items() if v == path]
                if not fd:
                    raise RuntimeError(f'no WDT for {mapid} {directory}')
                fdid = int(fd[0])
            get(f'https://wago.tools/api/casc/{fdid}?version={self.build}&download', fn)
            open(fn + '.fdid', 'w').write(str(fdid))
        fdid = int(open(fn + '.fdid').read()) if os.path.exists(fn + '.fdid') else fdid
        b = open(fn, 'rb').read(); p = 0; tiles = {}
        while p + 8 <= len(b):
            tag = b[p:p + 4][::-1].decode('latin1'); sz = struct.unpack('<I', b[p + 4:p + 8])[0]
            data = b[p + 8:p + 8 + sz]
            if tag == 'MAID':
                for i in range(min(4096, sz // 32)):
                    e = struct.unpack('<8I', data[i * 32:i * 32 + 32])
                    if e[7]:
                        tiles[(i % 64, i // 64)] = e[7]   # minimap texture FileDataID
            p += 8 + sz
        return fdid, tiles


def bounds(a):
    """WorldMapArea style {LocLeft, LocRight, LocTop, LocBottom} for the full 0..1 UiMap."""
    u0, u1, U0, U1 = (float(a[k]) for k in ('UiMin_0', 'UiMin_1', 'UiMax_0', 'UiMax_1'))
    x0, y0, x1, y1 = (float(a[k]) for k in ('Region_0', 'Region_1', 'Region_3', 'Region_4'))
    # UI x grows towards -worldY, UI y grows towards -worldX
    sy = (y1 - y0) / (U0 - u0); sx = (x1 - x0) / (U1 - u1)
    left = y1 + u0 * sy; right = left - sy
    top = x1 + u1 * sx; bottom = top - sx
    return left, right, top, bottom


# ---------------------------------------------------------------- towns (hand picked list of the original Yatlas)
TOWN_CONTINENT = {'Azeroth': 0, 'Kalimdor': 1, 'Expansion01': 530, 'Northrend': 571, 'HawaiiMainLand': 870}
# old name -> AreaTable ID, used only when the old name has no exact match in the flavour
TOWN_RENAMED = {
    'Magram Village': 4797,             # now "Magram Territory" (Desolace)
    'Sandsorrow Warch': 979,            # typo, "Sandsorrow Watch" (Tanaris)
    'Dalaran': 279,                     # "Dalaran Crater" (city left for Northrend)
    'Stromgarde': 324,                  # "Stromgarde Keep"
    'Azurlode Mine': 288,               # typo, "Azurelode Mine"
    'Ruins of Andorhal': 193,           # "Andorhal"
}


def towns_block(Area, mapids, log, cities=()):
    def norm(x): return re.sub(r'[^a-z0-9]', '', x.lower())
    idx = {}
    for r in Area.values():
        idx.setdefault((int(r['ContinentID']), norm(r['AreaName_lang'])), []).append(r)

    def parents(r):
        out = set()
        while r is not None:
            out.add(norm(r['AreaName_lang'])); r = Area.get(int(r['ParentAreaID']))
        return out

    out, cur, zone, missing, keep, dup = [], None, None, [], True, []
    for line in old_towns().split('\n'):
        m = re.match(r'\t\["(\w+)"\] = \{', line)
        if m:
            cur = m.group(1); keep = TOWN_CONTINENT.get(cur) in mapids
        if not keep:
            if re.match(r'\t\},?\s*$', line): keep = True
            continue
        m = re.match(r'\s*--\s*(.+?)\s*--\s*$', line)
        if m: zone = norm(m.group(1))
        m = re.match(r'(\s*)\{"([^"]+)",(\s*-?[\d.]+),(\s*-?[\d.]+)\}(.*)$', line)
        if m and cur in TOWN_CONTINENT:
            ind, name, y, x, tail = m.groups()
            cands = idx.get((TOWN_CONTINENT[cur], norm(name)), [])
            if zone:
                cands = [c for c in cands if zone in parents(c)] or cands
            aid = int(cands[0]['ID']) if cands else None
            if aid is None and name in TOWN_RENAMED and TOWN_RENAMED[name] in Area:
                aid = TOWN_RENAMED[name]
            if aid is None:
                missing.append(name); continue       # no longer in this client
            if any(c == TOWN_CONTINENT[cur] and math.hypot(cy - float(y), cx - float(x)) < 80
                   for c, cy, cx in cities):
                dup.append(name); continue           # also a world map town (Yatlas_cities)
            line = f'{ind}{{"{name}",{y},{x}, {aid}}}{tail}'
        out.append(line)
    if missing:
        print('  towns without AreaTable match (dropped):', missing, file=log)
    if dup:
        print('  towns also in Yatlas_cities (dropped):', dup, file=log)
    return '\n'.join(out).rstrip() + '\n'


# ---------------------------------------------------------------- towns and capitals (AreaPOI.db2)
# The world map town / capital markers of the old continents. Classic Era and Anniversary still
# return them from C_AreaPoiInfo; MoP Classic and Retail keep the rows but flag them hidden (512),
# so they are written to the data for every client and drawn with the game's town / city atlas.
#   Flags without 512 (hidden) and 128:  13 = town, 29 = capital
#   Icon (Interface\Minimap\POIIcons index): town 4 (Era/TBC) or 5 (MoP/Retail); capital 5 (Era/TBC),
#   6, or the faction capital icons 46-49 (Retail). Other icons with these flags are events
#   (e.g. the Darkmoon Faire, icon 181) and are skipped.
POI_TOWN_ICON = {'1': 4, '2': 4}            # by major build version; default 5

def cities_block(POI, Area, Dir, mapids, build, log):
    def norm(x): return re.sub(r'[^a-z0-9]', '', x.lower())
    town_icon = POI_TOWN_ICON.get(build.split('.')[0], 5)
    idx = {}
    for r in Area.values():
        idx.setdefault((int(r['ContinentID']), norm(r['AreaName_lang'])), []).append(int(r['ID']))
    lists, n = {}, [0, 0]
    for r in sorted(POI, key=lambda r: int(r['ID'])):
        cont, flags, icon = int(r['ContinentID']), int(r['Flags']), int(r['Icon'])
        if cont not in mapids or r['UiTextureAtlasMemberID'] != '0' or r['PlayerConditionID'] != '0':
            continue
        base = flags & ~(512 | 128)
        if base == 13 or (base == 29 and icon == town_icon):
            kind = 1
        elif base == 29 and icon in (5, 6, 46, 47, 48, 49):
            kind = 2
        else:
            continue
        name = r['Name_lang']
        # AreaPOI.AreaID is the zone the marker is in (not the town), so match the name and only
        # use the zone to pick between areas of the same name
        zone = int(r['AreaID'] or 0)
        if zone > 0 and (zone not in Area or int(Area[zone]['ContinentID']) != cont):
            continue        # the zone moved to another map (e.g. Eversong Woods in Midnight)
        if zone > 0 and re.search(r'\(.+\)$', Area[zone]['AreaName_lang']):
            continue        # legacy copy, e.g. "Silvermoon City (Burning Crusade)" in Midnight
        base_name = re.sub(r'^The ', '', name)
        c = []
        for nm in (name, base_name, re.sub(r' City$', '', name), name + ' City', base_name + ' City'):
            c = idx.get((cont, norm(nm)))
            if c: break
        if c and len(c) > 1 and zone > 0:
            c = [a for a in c if zone in (a, int(Area[a]['ParentAreaID']))] or c
        aid = c[0] if c else 0
        lists.setdefault(cont, []).append((name, float(r['Pos_1']), float(r['Pos_0']), int(r['ID']), kind, aid))
        n[kind - 1] += 1
    out = ['-- Towns (kind 1) and capitals (kind 2) of the world map, from AreaPOI.db2\n',
           '-- {name, worldY, worldX, AreaPOI ID, kind, AreaTableID (0 = keep the name)}\n',
           'Yatlas_cities = {\n']
    for cont in sorted(lists):
        out.append(f'\t[{luastr(Dir[cont])}] = {{\n')
        for name, y, x, pid, kind, aid in lists[cont]:
            out.append(f'\t\t{{{luastr(name)}, {num(y)}, {num(x)}, {pid}, {kind}, {aid}}},\n')
        out.append('\t},\n')
    out.append('};\n\n')
    print(f'  towns {n[0]}, capitals {n[1]} (AreaPOI)', file=log)
    pos = [(c, v[1], v[2]) for c, l in lists.items() for v in l]
    return ''.join(out), pos


# ---------------------------------------------------------------- one flavour
def generate(name, cfg, log=sys.stdout):
    B = Build(cfg['build'])
    BUILD = cfg['build']
    print(f'== {name} ({BUILD})', file=log)
    Map = {int(r['ID']): r for r in B.table('Map')}
    Dir = {k: v['Directory'] for k, v in Map.items()}
    Area = {int(r['ID']): r for r in B.table('AreaTable')}
    UiMap = {int(r['ID']): r for r in B.table('UiMap')}
    UiA = B.table('UiMapAssignment')
    WORLD = cfg['world']
    WORLD_IDS = [w[0] for w in WORLD]
    WANT = {}
    for w in WORLD: WANT.setdefault(w[0], w[1])
    out1, out2 = [], []
    w1, w2 = out1.append, out2.append

    # ------------------------------------------------ Map.db2
    w1('-- Map data extracted from Map.db2\n')
    w1('-- [Directory] = MapID (instanceID, as returned by UnitPosition / GetInstanceInfo)\n')
    w1('Yatlas_WorldMapIds2 = {\n')
    for k in sorted(Map):
        w1(f'\t[{luastr(Dir[k])}] = {k},\n')
    w1('};\n\n')

    # ------------------------------------------------ minimap tiles (WDT MAID)
    old1 = old_mapdb1()
    w1('-- Minimap tile textures (FileDataIDs) from the MAID chunk of world\\maps\\<Directory>\\<Directory>.wdt\n')
    w1('-- Key "XXxYY" = minimap tile mapXX_YY. Value is a FileDataID usable with Texture:SetTexture(fileID).\n')
    w1('Yatlas_mapdb1 = {\n')
    stats = {}
    for mid in WORLD_IDS:
        d = Dir[mid]
        fdid, real = B.wdt_tiles(mid, d, int(Map[mid].get('WdtFileDataID') or 0) or None)
        w1(f'\t[{luastr(d)}] = {{ -- MapID {mid}, WDT FileDataID {fdid}\n')
        # keep the hand made "mocking up" ocean fillers of the original Yatlas, remapped
        mock = {}
        for k, (tex, cmt) in old1.get(d, {}).items():
            if 'mock' in cmt and k not in real:
                m = re.match(r'map(\d+)_(\d+)', tex)
                src = (int(m.group(1)), int(m.group(2)))
                if src in real: mock[k] = real[src]
        for k in sorted(set(real) | set(mock)):
            if k in real: w1(f'\t\t["{k[0]:02d}x{k[1]:02d}"] = {real[k]},\n')
            else: w1(f'\t\t["{k[0]:02d}x{k[1]:02d}"] = {mock[k]}, -- mocking up\n')
        w1('\t},\n')
        stats[d] = (len(real), len(mock))
    w1('};\n\n')
    print('  tiles', stats, file=log)

    # ------------------------------------------------ AreaTable.db2 (only areas of the shown maps)
    w1('-- Data from AreaTable.db2 (areas of the maps above)\n')
    w1('-- enUS names; localized at load time through C_Map.GetAreaInfo() (see Data/Localize.lua)\n')
    w1('Yatlas_areadb = \n{\n')
    shown = set(WORLD_IDS)
    for k in sorted(Area):
        n = Area[k]['AreaName_lang']
        if n and (int(Area[k]['ContinentID']) in shown or name != 'Mainline'):
            w1(f'\t[{k}] = {luastr(n)},\n')
    w1('};\n\n')

    # ------------------------------------------------ UiMap / UiMapAssignment (replaces WorldMapArea)
    by_ui = {}
    for a in UiA: by_ui.setdefault(int(a['UiMapID']), []).append(a)
    for v in by_ui.values(): v.sort(key=lambda a: int(a['OrderIndex']))
    mapareas, uimapids = {}, {}
    # the continent entry of every shown map is the WORLD uiMap
    for mid, uid in WANT.items():
        for a in by_ui.get(uid, []):
            if int(a['MapID']) == mid and not int(a['AreaID']) and not int(a['WMOGroupID']):
                mapareas.setdefault(mid, {})[0] = (bounds(a), uid, UiMap[uid]['Name_lang'])
                uimapids.setdefault(mid, {})[0] = uid
                break
    for uid in sorted(UiMap):
        u = UiMap[uid]; typ = int(u['Type'])
        if typ not in (2, 3, 6) or uid not in by_ui: continue
        a = by_ui[uid][0]                      # OrderIndex 0 = the UiMap's own map
        mid = int(a['MapID'])
        if typ == 6 and mid not in WORLD_IDS: continue
        if name == 'Mainline' and mid not in WORLD_IDS: continue
        if int(a['WMOGroupID']) or int(a['WMODoodadPlacementID']): continue
        if typ == 2:
            aid = 0
            if mid in WANT and WANT[mid] in UiMap and int(UiMap[WANT[mid]]['Type']) == 2: continue
        else:
            aid = int(a['AreaID'])
            if not aid: continue
        d = mapareas.setdefault(mid, {})
        if aid in d: continue                  # first (lowest) UiMap wins (phased copies come later)
        d[aid] = (bounds(a), uid, u['Name_lang'])
        uimapids.setdefault(mid, {})[aid] = uid

    w1('-- Map ID from Map.db2; Area ID mapped to AreaTable.db2\n')
    w1('-- Coordination from UiMapAssignment.db2 (WorldMapArea.dbc was removed in 8.0; values are\n')
    w1('-- {LocLeft, LocRight, LocTop, LocBottom} = {maxWorldY, minWorldY, maxWorldX, minWorldX}\n')
    w1('-- extrapolated to the full 0..1 UiMap rectangle, i.e. identical to the old WorldMapArea layout)\n')
    w1('Yatlas_mapareas = {\n')
    for mid in sorted(mapareas):
        w1(f'\t-- Map ID: {mid}\n\t[{luastr(Dir.get(mid, str(mid)))}] = {{\n')
        for aid in sorted(mapareas[mid]):
            (l, r, t, b), uid, nm = mapareas[mid][aid]
            w1(f'\t\t[{aid}] = {{{num(l)}, {num(r)}, {num(t)}, {num(b)}}}, -- {nm} (uiMapID {uid})\n')
        w1('\t},\n')
    w1('};\n\n')
    w1('-- [Directory] = { [areaID] = uiMapID }   ([0] = continent UiMap). For C_Map.* calls.\n')
    w1('Yatlas_UiMapIds = {\n')
    for mid in sorted(uimapids):
        w1(f'\t[{luastr(Dir.get(mid, str(mid)))}] = {{')
        w1(', '.join(f'[{a}]={u}' for a, u in sorted(uimapids[mid].items())))
        w1('},\n')
    w1('};\n')

    # ------------------------------------------------ mapdb2: map list
    w2('-- Maps shown in the map drop-down: [display name] = {Map.db2 Directory}.\n')
    w2('-- Display names come from the client (C_Map.GetMapInfo / GetRealZoneText), so they are localized.\n')
    w2('YA_MAPS = {\n')
    for w in WORLD:
        mid, uid, en = w[:3]
        if len(w) > 3 and w[3] == 'map':
            w2(f'\t[Yatlas_MapName({mid}, {luastr(en)})] = {{{luastr(Dir[mid])}}},\n')
        else:
            w2(f'\t[Yatlas_UiMapName({uid}, {luastr(en)})] = {{{luastr(Dir[mid])}}},\n')
    w2('};\n\n')
    w2('-- Drop-down order of the maps above (Map.db2 Directory)\n')
    w2('YA_MAPS_ORDER = {' + ', '.join(luastr(Dir[w[0]]) for w in WORLD) + '};\n\n')
    w2('-- [Directory] = uiMapID of the map shown for it (continent, or the zone for single-zone maps).\n')
    w2('Yatlas_WorldMapIds = {\n')
    for w in WORLD:
        w2(f'\t[{luastr(Dir[w[0]])}] = {w[1]},\n')
    w2('};\n\n')

    # zones whose terrain lives on each tile map (grouped by MapID, not by UI parent)
    zone_ids = {}
    for mid in WORLD_IDS:
        lst = {}
        for uid in sorted(UiMap):
            u = UiMap[uid]
            if int(u['Type']) not in (3, 6) or uid not in by_ui: continue
            a = by_ui[uid][0]; aid = int(a['AreaID'])
            if int(a['MapID']) == mid and aid and aid not in lst and aid in mapareas.get(mid, {}) \
                    and mapareas[mid][aid][1] == uid:
                lst[aid] = Area[aid]['AreaName_lang'] if aid in Area else u['Name_lang']
        zone_ids[mid] = ([0] if 0 in mapareas.get(mid, {}) else []) + sorted(lst, key=lambda k: lst[k])
    w2(f'-- Zones per tile map, from UiMap.db2 + UiMapAssignment.db2; [1] = 0 is the continent itself\n')
    w2('-- (order is alphabetical by enUS name)\n')
    w2('Yatlas_ZoneIds = {\n')
    for mid, l in zone_ids.items():
        if not l: continue
        w2(f'\t-- Map ID = {mid}\n\t[{luastr(Dir[mid])}] = {{\n\t\t')
        w2(', '.join(str(x) for x in l))
        w2(',\n\t},\n')
    w2('};\n\n')

    # ------------------------------------------------ instance entrances
    entries = {mid: [] for mid in WORLD_IDS}
    found = set()
    retired = cfg.get('retired', set())
    sources = []
    if cfg.get('journal'):
        JI = {int(r['ID']): r for r in B.table('JournalInstance')}
        for r in B.table('JournalInstanceEntrance'):
            cont = int(r['MapID']); ji = JI.get(int(r['JournalInstanceID']))
            if cont not in entries or not ji: continue
            tmap = int(ji['MapID'])
            if tmap not in Map or int(Map[tmap]['InstanceType']) not in (1, 2): continue
            entries[cont].append((tmap, float(r['Position_1']), float(r['Position_0']),
                                  f'JournalInstanceEntrance {r["ID"]}'))
            found.add(tmap)
        sources.append('the client JournalInstanceEntrance.db2 (entrance position + JournalInstance.MapID)')
    if cfg.get('teleports'):
        AT = {int(r['ID']): r for r in B.table('AreaTrigger')}
        fn = os.path.join(HERE, 'data', f'areatrigger_teleport_{cfg["teleports"]}.csv')
        for r in csv.DictReader(open(fn, encoding='utf-8')):
            tid, tmap = int(r['AreaTriggerID']), int(r['TargetMapID'])
            if tid not in AT or tmap not in Map or tmap in retired: continue
            if int(Map[tmap]['InstanceType']) not in (1, 2): continue
            a = AT[tid]; cont = int(a['ContinentID'])
            if cont not in entries: continue
            e = (tmap, float(a['Pos_1']), float(a['Pos_0']), f'AreaTrigger {tid}')
            if not any(x[0] == e[0] and x[1:3] == e[1:3] for x in entries[cont]):
                entries[cont].append(e)
            found.add(tmap)
        sources.append(f'the client AreaTrigger.db2 row that teleports into the instance '
                       f'(trigger -> instance from {os.path.basename(fn)})')
    if cfg.get('corpse'):
        if cfg['corpse'] == 'self':
            old = Map; tag = BUILD
        else:
            tag = cfg['corpse']
            old = {int(r['ID']): r for r in csv.DictReader(open(os.path.join(HERE, 'data', f'map_corpse_{tag}.csv'),
                                                                 encoding='utf-8'))}
        for k, r in Map.items():
            if int(r['InstanceType']) not in (1, 2) or k in retired or k in found: continue
            o = old.get(k)
            if o and int(o['CorpseMapID']) in entries and (float(o['Corpse_0']) or float(o['Corpse_1'])):
                entries[int(o['CorpseMapID'])].append((k, float(o['Corpse_1']), float(o['Corpse_0']),
                                                       f'Map.db2 {tag} Corpse'))
                found.add(k)
        sources.append(f'Map.db2 Corpse_0/Corpse_1 (entrance) of build {tag}')
    for cont, tmap, y, x, src in cfg.get('instance_fixes', []):
        entries[cont].append((tmap, y, x, src)); found.add(tmap)

    w2('-- Instances (entrances)\n')
    for i, s in enumerate(sources):
        w2(f'-- {"Primary source" if i == 0 else "Fallback"}: {s}\n')
    w2('-- {name, worldY, worldX, instanceMapID, instanceType}; name is localized at load time via GetRealZoneText(mapID)\n')
    w2('-- instanceType from Map.db2 InstanceType: 1 = dungeon (party), 2 = raid\n')
    w2('Yatlas_instances = {\n')
    total = 0
    for mid in WORLD_IDS:
        rows = sorted(entries[mid], key=lambda r: (r[0], r[3]))
        kept = []
        for r in rows:
            if any(k[0] == r[0] and abs(k[1] - r[1]) < 150 and abs(k[2] - r[2]) < 150 for k in kept): continue
            kept.append(r)
        if not kept: continue
        total += len(kept)
        w2(f'\t[{luastr(Dir[mid])}] = {{\n')
        for tmap, y, x, src in kept:
            w2(f'\t\t{{{luastr(Map[tmap]["MapName_lang"])}, {num(y)}, {num(x)}, {tmap}, {int(Map[tmap]["InstanceType"])}}}, -- {src}\n')
        w2('\t},\n')
    w2('};\n\n')
    print('  instances', total, file=log)

    # ------------------------------------------------ taxi nodes (flight paths)
    # TaxiNodes.db2 Flags: 0x1 = shown on the Alliance map, 0x2 = shown on the Horde map,
    # 0x80 = hidden from the world map UI. Pos_0 = world X, Pos_1 = world Y.
    taxi = {mid: [] for mid in WORLD_IDS}
    for r in B.table('TaxiNodes'):
        cont, fl = int(r['ContinentID']), int(r['Flags'])
        if cont not in taxi or not (fl & 3) or (fl & 0x80): continue
        faction = 0 if (fl & 3) == 3 else (2 if fl & 1 else 1)
        cond = 1 if int(r['ConditionID']) else 0
        taxi[cont].append((int(r['ID']), r['Name_lang'], float(r['Pos_1']), float(r['Pos_0']), faction, cond))
    w2('-- Flight paths, from TaxiNodes.db2\n')
    w2('-- {name, worldY, worldX, taxiNodeID, faction (0 neutral, 1 horde, 2 alliance), conditional}\n')
    w2('-- name is localized at runtime from C_TaxiMap.GetTaxiNodesForMap (see Modules/taxinodes.lua)\n')
    w2('Yatlas_taxinodes = {\n')
    for mid in WORLD_IDS:
        if not taxi[mid]: continue
        w2(f'\t[{luastr(Dir[mid])}] = {{\n')
        for nid, nm, y, x, fac, cond in sorted(taxi[mid]):
            w2(f'\t\t{{{luastr(nm)}, {num(y)}, {num(x)}, {nid}, {fac}, {cond}}},\n')
        w2('\t},\n')
    w2('};\n\n')
    print('  taxi nodes', sum(len(v) for v in taxi.values()), file=log)

    # ------------------------------------------------ towns
    w2('-- Towns: the hand picked list of the original Yatlas, matched to AreaTable IDs of this client\n')
    w2('-- {name, worldY, worldX, AreaTableID}; name is localized at load time via C_Map.GetAreaInfo\n')
    cities_lua, cities_pos = cities_block(B.table('AreaPOI'), Area, Dir, set(WORLD_IDS), BUILD, log)
    w2(towns_block(Area, set(WORLD_IDS), log, cities_pos))

    # ------------------------------------------------ towns and capitals
    w2(cities_lua)

    # ------------------------------------------------ write
    head = (f'-- Yatlas map database for {cfg["label"]} ({BUILD})\n'
            f'-- {DATE}: generated by tools/yatlas_data.py from wago.tools DB2 exports and WDT files.\n'
            f'-- See Docs/DataSources.md for the source of every table.\n'
            f'if not (YATLAS_CLIENT and YATLAS_CLIENT.{cfg["check"]}) then return end\n\n')
    od = os.path.join(ROOT, 'Data', name); os.makedirs(od, exist_ok=True)
    open(os.path.join(od, 'mapdb.lua'), 'w', encoding='utf-8').write(head + ''.join(out1))
    open(os.path.join(od, 'mapdb2.lua'), 'w', encoding='utf-8').write(head + ''.join(out2))
    print('  written', od, file=log)


if __name__ == '__main__':
    names = sys.argv[1:] or list(FLAVORS)
    for n in names:
        generate(n, FLAVORS[n])
