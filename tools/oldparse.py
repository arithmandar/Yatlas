import re
import os
# pre-5.5.4 mapdb.lua, e.g. `git show bf9badf:mapdb.lua > /tmp/mapdb_old.lua`
src=open(os.environ.get('YATLAS_OLD_MAPDB','/tmp/mapdb_old.lua'),encoding='utf-8-sig').read()
def block(name):
    i=src.index('\n'+name); j=src.index('\n}',i); return src[i:j]
def mapdb1():
    b=block('Yatlas_mapdb1'); res={}; cur=None
    for line in b.split('\n'):
        m=re.match(r'\t\["(\w+)"\] = \{',line)
        if m: cur=m.group(1); res[cur]={}; continue
        m=re.match(r'\t\t\["(\d+)x(\d+)"\] = \{"(\w+)", \{(\d+),(\d+)\}\}(.*)',line)
        if m and cur: res[cur][(int(m.group(1)),int(m.group(2)))]=(m.group(3),m.group(6).strip())
    return res
