"""Add AreaTable IDs to Yatlas_towns2 so the names can be localized in game.

Yatlas_towns2 is hand-made data (English names only). Each entry
    {"Name", worldY, worldX}
becomes
    {"Name", worldY, worldX, areaID}
and mapdb2.lua replaces the name with C_Map.GetAreaInfo(areaID) at load time.

Matching: same continent, name compared without case / punctuation. When a
name exists more than once, the candidate inside the zone of the preceding
"-- Zone --" comment wins. A few names changed after Cataclysm (or were typos)
and are mapped by hand in RENAMED; places that no longer exist are dropped.
"""
import csv, re, sys

CONTINENT = {'Azeroth': 0, 'Kalimdor': 1, 'Expansion01': 530, 'Northrend': 571, 'HawaiiMainLand': 870}

# old name -> AreaTable ID in 5.5.4
RENAMED = {
    'Magram Village': 4797,             # now "Magram Territory" (Desolace)
    'Sandsorrow Warch': 979,            # typo, "Sandsorrow Watch" (Tanaris)
    'Dalaran': 279,                     # "Dalaran Crater" (city left for Northrend)
    'Stromgarde': 324,                  # "Stromgarde Keep"
    'Azurlode Mine': 288,               # typo, "Azurelode Mine"
    'Ruins of Andorhal': 193,           # "Andorhal"
}
# no longer exists in the 5.5.4 client (removed in Cataclysm)
REMOVED = {'Lordamere Internment Camp'}


def norm(x):
    return re.sub(r'[^a-z0-9]', '', x.lower())


def load_areas(path):
    rows = list(csv.DictReader(open(path, encoding='utf-8')))
    byid = {int(r['ID']): r for r in rows}
    idx = {}
    for r in rows:
        idx.setdefault((int(r['ContinentID']), norm(r['AreaName_lang'])), []).append(r)
    return byid, idx


def parents(byid, r):
    out = set()
    while r is not None:
        out.add(norm(r['AreaName_lang']))
        r = byid.get(int(r['ParentAreaID']))
    return out


def annotate(block, areatable='/tmp/AreaTable.csv', log=sys.stderr):
    byid, idx = load_areas(areatable)
    out, cur, zone, missing = [], None, None, []
    for line in block.split('\n'):
        m = re.match(r'\t\["(\w+)"\] = \{', line)
        if m:
            cur = m.group(1)
        m = re.match(r'\s*--\s*(.+?)\s*--\s*$', line)
        if m:
            zone = norm(m.group(1))
        m = re.match(r'(\s*)\{"([^"]+)",(\s*-?[\d.]+),(\s*-?[\d.]+)\}(.*)$', line)
        if m and cur in CONTINENT:
            ind, name, y, x, tail = m.groups()
            if name in REMOVED:
                continue
            if name in RENAMED:
                aid = RENAMED[name]
            else:
                cands = idx.get((CONTINENT[cur], norm(name)), [])
                if zone:
                    inzone = [c for c in cands if zone in parents(byid, c)]
                    cands = inzone or cands
                aid = int(cands[0]['ID']) if cands else None
            if aid is None:
                missing.append((cur, name))
            else:
                line = f'{ind}{{"{name}",{y},{x}, {aid}}}{tail}'
        out.append(line)
    if missing:
        print('towns2: no AreaTable match for', missing, file=log)
    return '\n'.join(out)


LOCALIZE = '''
-- Localize town names with the client's own AreaTable (4th field = AreaTable ID).
if C_Map and C_Map.GetAreaInfo then
\tfor _, towns in pairs(Yatlas_towns2) do
\t\tfor _, v in ipairs(towns) do
\t\t\tlocal name = v[4] and C_Map.GetAreaInfo(v[4]);
\t\t\tif name and name ~= "" then v[1] = name; end
\t\tend
\tend
end
'''


def process(rest, areatable='/tmp/AreaTable.csv'):
    """rest starts with 'Yatlas_towns2 = {'; annotate it and add the localize loop."""
    j = rest.index('\n}\n') + 3
    return annotate(rest[:j], areatable) + LOCALIZE + rest[j:]
