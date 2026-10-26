# Yatlas

Yet another atlas: a World of Warcraft addon that shows the whole world at minimap detail.

Yatlas builds its maps from the game's minimap terrain tiles, not from the illustrated world map. The result is a seamless top-down view of each continent that you can zoom, with the same terrain, roads and coastlines you see on your minimap.

## Supported clients

| Client | Status |
|---|---|
| **Retail (Midnight, 12.1.5)** | Supported from v1.0.0 |
| **Mists of Pandaria Classic (5.5.4)** | Supported from v0.9.4 |
| **Anniversary / Burning Crusade (2.5.6)** | Supported from v1.0.0 |
| **Classic Era (1.15.9)** | Supported from v1.0.0 (Season of Discovery maps are not included) |
| Other clients (Wrath, Cataclysm Classic) | Not supported |

One download works in all supported clients: Yatlas detects the game version and loads only the map data for that client.

Releases are published on [CurseForge](https://www.curseforge.com/wow/addons/yatlas). Releases older than v0.9.4 (up to 0.9.1 for WoW 5.2) do not work with current clients.

## Maps

| Client | Maps |
|---|---|
| Classic Era | Eastern Kingdoms, Kalimdor |
| Anniversary (TBC) | Eastern Kingdoms, Kalimdor, Outland |
| Mists of Pandaria Classic | Eastern Kingdoms, Kalimdor, Outland, Northrend, Pandaria, Deepholm, Tol Barad, Isle of Thunder, Darkmoon Island |
| Retail | Eastern Kingdoms (with Quel'Thalas), Kalimdor, Outland, Northrend, Deepholm, Tol Barad, Pandaria, Isle of Thunder, Draenor, Broken Isles, Argus, Zandalar, Kul Tiras, Nazjatar, The Shadowlands, Zereth Mortis, Dragon Isles, The Forbidden Reach, Zaralek Cavern, Emerald Dream, Khaz Algar (surface and underground), Undermine, Siren Isle, K'aresh, Harandar, Voidstorm, Darkmoon Island |

## Usage

Yatlas has two views:

- **Normal view** works much like Atlas: a window you can move around. You can open it in three ways:
  - Click the minimap button.
  - Type `/yatlas`.
  - Press the key binding.
- **Large view** is a bigger, centred map window, shown like the world map. Open it with `/bigyatlas` or its key binding. Press Esc or the binding again to close it.

Both views use the same controls:

- Click and drag to move the map. Use the mouse wheel to zoom.
- Choose a map or jump to a zone from the drop-down menus at the top.
- Hover over a point to see a tooltip.
- **Goto Player** centres the map on your character. Shift-click it to keep following you as you move.
- The button next to the close button switches between the normal and the large view, keeping the current map and position.

You can set the key bindings under **Key Bindings → AddOns → Yatlas** (Toggle Yatlas Frame, Toggle Large Yatlas Frame).

### Points on the map

- Towns and landmarks, read live from the game
- Dungeon and raid entrances, using the game's own icons
- Smaller settlements, with localized names
- Flight paths for your faction. Undiscovered ones are dimmed.
- Party and raid members

You can turn each type of point on or off from the options menu.

### Known limitations

- Graveyards are not shown. The client files no longer contain graveyard locations, so this feature stays off until a reliable source is found.
- The old integrations with Gatherer, MapNotes and CT_MapMod are not loaded.
- The game does not report your position inside dungeons and raids, so Yatlas cannot track you there.

## Installation

1. Download the latest release from [CurseForge](https://www.curseforge.com/wow/addons/yatlas) or from [GitHub Releases](https://github.com/arithmandar/Yatlas/releases).
2. Extract it into the AddOns folder of your client, for example `World of Warcraft\_retail_\Interface\AddOns\Yatlas\`, `_classic_` (Mists), `_anniversary_` or `_classic_era_`.
3. Restart the game or reload the UI, then enable Yatlas in the AddOns list.

## Repository layout

| Path | Contents |
|---|---|
| `Yatlas.toc` | Addon metadata and load order |
| `Bindings.xml` | Key bindings (must stay in the addon root folder) |
| `Core/` | `Compat.lua` (wrappers for the modern API), `Constants.lua` (client detection `YATLAS_CLIENT`, addon metadata from the TOC, incl. author and credits, texture paths, option defaults, backdrops), `Core.lua` (map drawing and frame logic), `Points.lua` (point framework) |
| `UI/` | Frames and templates: `Yatlas.xml` (normal and large frames), `Templates.xml`, `OptionsFrame.xml`, `Button.xml`/`Button.lua` (minimap button) |
| `Modules/` | Point sets loaded by `Modules/index.xml` (landmarks, flight paths, players, ...) |
| `Data/` | `Data.xml` loads `Common.lua` (shared data), one generated `mapdb.lua` + `mapdb2.lua` per client in `ClassicEra/`, `TBC/`, `Mists/`, `Mainline/` (minimap tiles, map areas, instances, towns, flight paths; each file returns at once on other clients) and `Localize.lua` |
| `Locale/` | UI strings: enUS (default), deDE, esES/esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, zhTW |
| `Images/` | Addon textures and icons (BLP) |
| `tools/` | Python scripts that regenerate the map data (not included in releases) |
| `Docs/` | Changelog, data sources and the CurseForge description |

## Map data

The map data is generated from the client DB2 tables and WDT files of each supported build, which can be browsed on wago.tools: [1.15.9.70003](https://wago.tools/db2?build=1.15.9.70003), [2.5.6.70006](https://wago.tools/db2?build=2.5.6.70006), [5.5.4.70579](https://wago.tools/db2?build=5.5.4.70579) and [12.1.5.70575](https://wago.tools/db2?build=12.1.5.70575). [`Docs/DataSources.md`](Docs/DataSources.md) describes where each table comes from and the API changes. [`tools/README.md`](tools/README.md) explains how to regenerate the files in `Data/`.
