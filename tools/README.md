# Yatlas data generator

Regenerates the per-client data files `Data/<Flavor>/mapdb.lua` and `Data/<Flavor>/mapdb2.lua`.
Run it from this `tools/` folder (Python 3, `curl` and `git` needed; no other packages).

```sh
python3 yatlas_data.py                 # every flavor in flavors.py
python3 yatlas_data.py Mists Mainline  # only these
```

| File | Purpose |
|---|---|
| `flavors.py` | One entry per client flavor: build, `YATLAS_CLIENT` check flag, shown maps (MapID, uiMapID, English name), instance entrance sources, retired instances and hand fixes |
| `yatlas_data.py` | The generator. Downloads the DB2 CSV exports and WDT files of each build from [wago.tools](https://wago.tools) into `tools/.cache/<build>/` (git-ignored) and writes the Lua files |
| `data/areatrigger_teleport_mists.csv` | AreaTrigger → instance map for MoP (MistCore 5.0.5 + SkyFire 5.4.8 server data) |
| `data/areatrigger_teleport_azerothcore.csv` | AreaTrigger → instance map for Classic Era / TBC (AzerothCore `areatrigger_teleport`) |
| `data/map_corpse_*.csv` | `Map.db2` Corpse_0/1 (instance entrance) of old clients (7.3.5.26972 and 1.13.0.28211); used where no AreaTrigger is known |
| `compare_dandymap.py` | Optional cross-check of the tile lists against DandyMap's terrain data (reference only) |

The generator also reads the original Yatlas data with `git show bf9badf:mapdb2.lua`
for the hand-picked town list.
Each generated file starts with `if not (YATLAS_CLIENT and YATLAS_CLIENT.<flag>) then return end`,
so only the data of the running client is kept in memory.

To add a client: add an entry to `flavors.py`, add its flag to `YATLAS_CLIENT` in `Core/Constants.lua`,
its two files to `Data/Data.xml` and its interface number to `Yatlas.toc`.
See [`Docs/DataSources.md`](../Docs/DataSources.md) for where every table comes from.

## UI load test (`uitest/`)

`python3 tools/uitest/run.py [ClassicEra|TBC|Mists|Forever|Retail ...]` loads every file of
`Yatlas.toc` in a minimal WoW UI mock (`uitest/mock.lua`, needs `pip install lupa`), fires the login
events and clicks through the frames (zoom, drag, lock, drop-downs, options, large frame, minimap
button, slash commands). It reports Lua errors, script errors and reads of undefined globals and
exits with 1 when it finds any. It is a smoke test, not an emulation of the client: check layouts
and textures in the game.
