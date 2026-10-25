"""Cross-check Yatlas_mapdb1 against DandyMap's ClientTerrainData.lua.

DandyMap (WoW Forever, Interface 16001) stores minimap tile FileDataIDs from
the client WDT MAID records as  ["7/<x>/<y>"]=fileDataID  (zoom level 7 = ADT
grid), which is the same source used by tools/wdt.py.

usage: python3 compare_dandymap.py <DandyMap>/data/ClientTerrainData.lua [../mapdb.lua]
"""
import re, sys

dandy_path = sys.argv[1]
yatlas_path = sys.argv[2] if len(sys.argv) > 2 else '../mapdb.lua'

dm, cur = {}, None
for line in open(dandy_path, encoding='utf-8'):
    m = re.match(r'ns\.ClientTerrain\.tiles\["([^"]+)"\]', line)
    if m:
        cur = m.group(1); dm[cur] = {}; continue
    m = re.match(r'\["7/(\d+)/(\d+)"\]=(\d+)', line)
    if m and cur:
        dm[cur][(int(m[1]), int(m[2]))] = int(m[3])

y = open(yatlas_path, encoding='utf-8').read()
for yk, dk in [('Azeroth', 'local-azeroth'), ('Kalimdor', 'local-kalimdor')]:
    s = y.index('["%s"] = { -- MapID' % yk); e = y.index('\n\t},', s)
    real, mock = {}, {}
    for a, b, c, rest in re.findall(r'\["(\d+)x(\d+)"\]\s*=\s*(\d+),?([^\n]*)', y[s:e]):
        (mock if 'mocking' in rest else real)[(int(a), int(b))] = int(c)
    A = dm.get(dk, {})
    common = set(A) & set(real)
    same = sum(A[k] == real[k] for k in common)
    print(f'{yk}: dandy={len(A)} yatlas={len(real)}(+{len(mock)} mock) '
          f'common={len(common)} identical={same} '
          f'dandy-only={len(set(A) - set(real) - set(mock))} yatlas-only={len(set(real) - set(A))}')
    for k in sorted(common):
        if A[k] != real[k]:
            print('  DIFF', k, 'dandy', A[k], 'yatlas', real[k])
