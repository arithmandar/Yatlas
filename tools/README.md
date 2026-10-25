# Yatlas data generator (MoP Classic 5.5.4)

Regenerates `mapdb.lua` / `mapdb2.lua` data tables. Run from this `tools/` folder.

```sh
B=5.5.4.70579
cd /tmp && for t in Map AreaTable UiMap UiMapAssignment AreaTrigger AreaPOI; do
  curl -s -o $t.csv "https://wago.tools/db2/$t/csv?build=$B"; done
curl -s -o Map_7.3.5.26972.csv "https://wago.tools/db2/Map/csv?build=7.3.5.26972"
curl -sL -o at_mc.sql https://raw.githubusercontent.com/MistCore/MC-Database/master/main_db/world/areatrigger_teleport.sql
# SkyFire 5.4.8 areatrigger_teleport updates -> /tmp/at_sf.sql (see Docs/DataSources-5.5.4.md)
git -C .. show bf9badf:mapdb.lua  > /tmp/mapdb_old.lua
git -C .. show bf9badf:mapdb2.lua > /tmp/mapdb2_old.lua
mkdir -p /tmp/wdt && cp oldparse.py /tmp/
python3 wdt.py        # downloads WDTs from wago.tools, parses MAID -> /tmp/wdt/tiles.pkl
python3 gen.py        # writes /tmp/gen/*.lua
python3 assemble.py   # splices into ../mapdb.lua and ../mapdb2.lua (uses towns.py for town area IDs)
# optional: cross-check tiles with DandyMap 1.6.3 (WoW Forever client WDTs)
python3 compare_dandymap.py <DandyMap>/data/ClientTerrainData.lua ../mapdb.lua
```
