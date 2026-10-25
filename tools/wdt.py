import csv,json,subprocess,struct,os,pickle
def get(url,fn=None):
    a=['curl','-s','-A','Mozilla/5.0',url]+(['-o',fn] if fn else [])
    return subprocess.run(a,capture_output=True).stdout
maps={r['ID']:r for r in csv.DictReader(open('Map.csv'))}
targets=[0,1,530,571,870,974,646,732,1064,648,654,730,860]
out={}
for mid in targets:
    d=maps[str(mid)]['Directory']; path=f"world/maps/{d.lower()}/{d.lower()}.wdt"
    j=json.loads(get(f"https://wago.tools/api/files?search={path}") or b'{}')
    fd=[k for k,v in j.items() if v==path]
    if not fd: print(mid,d,'no wdt',j); continue
    fn=f"/tmp/wdt/{d}.wdt"
    if not os.path.exists(fn): get(f"https://wago.tools/api/casc/{fd[0]}?version=5.5.4.70579&download",fn)
    b=open(fn,'rb').read(); p=0; tiles={}
    while p+8<=len(b):
        tag=b[p:p+4][::-1].decode('latin1'); sz=struct.unpack('<I',b[p+4:p+8])[0]; data=b[p+8:p+8+sz]
        if tag=='MAID':
            for i in range(min(4096,sz//32)):
                e=struct.unpack('<8I',data[i*32:i*32+32])
                if any(e): tiles[(i%64,i//64)]=e
        p+=8+sz
    out[d]=(mid,int(fd[0]),tiles)
    xs=[k[0] for k in tiles]; ys=[k[1] for k in tiles]
    print(mid,d,'wdt',fd[0],len(b),'tiles',len(tiles), sum(1 for e in tiles.values() if e[7]),(min(xs),max(xs),min(ys),max(ys)) if tiles else None)
pickle.dump(out,open('/tmp/wdt/tiles.pkl','wb'))
t=out['Azeroth'][2]; print('az (32,48)->', t.get((32,48)), ' (48,32)->', t.get((48,32)))
