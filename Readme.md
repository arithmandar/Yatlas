# Yatlas

Yet another atlas: a World of Warcraft addon that shows the whole world at minimap detail.

Yatlas builds its maps from the game's minimap terrain tiles, not from the illustrated world map. The result is a seamless top-down view of each continent that you can zoom, with the same terrain, roads and coastlines you see on your minimap.

## Supported client

| Client | Status |
|---|---|
| **Mists of Pandaria Classic (5.5.4)** | Supported from v0.9.4 |
| Retail, Classic Era, other Classic versions | Not supported |

Releases are published on [CurseForge](https://www.curseforge.com/wow/addons/yatlas). Releases older than v0.9.4 (up to 0.9.1 for WoW 5.2) do not work with current clients.

## Maps

Eastern Kingdoms, Kalimdor, Outland, Northrend, Pandaria, Deepholm, Tol Barad, Isle of Thunder and Darkmoon Island.

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
2. Extract it so that the folder path is `World of Warcraft\_classic_\Interface\AddOns\Yatlas\`.
3. Restart the game or reload the UI, then enable Yatlas in the AddOns list.

## Repository layout

| Path | Contents |
|---|---|
| `Yatlas.toc` | Addon metadata and load order |
| `Bindings.xml` | Key bindings (must stay in the addon root folder) |
| `Core/` | `Compat.lua` (wrappers for the modern Classic API), `Constants.lua` (addon metadata from the TOC, incl. author and credits, texture paths, option defaults, backdrops), `Core.lua` (map drawing and frame logic), `Points.lua` (point framework) |
| `UI/` | Frames and templates: `Yatlas.xml` (normal and large frames), `Templates.xml`, `OptionsFrame.xml`, `Button.xml`/`Button.lua` (minimap button) |
| `Modules/` | Point sets loaded by `Modules/index.xml` (landmarks, flight paths, players, ...) |
| `Data/` | Generated map data `mapdb.lua` and `mapdb2.lua`: minimap tiles, map areas, instances, towns, flight paths |
| `Locale/` | UI strings: enUS (default), deDE, esES/esMX, frFR, itIT, koKR, ptBR, ruRU, zhCN, zhTW |
| `Images/` | Addon textures and icons (BLP) |
| `tools/` | Python scripts that regenerate the map data (not included in releases) |
| `Docs/` | Changelog, data sources and the CurseForge description |

## Map data

The map data is generated from the client DB2 tables of build 5.5.4.70579, which can be browsed on [wago.tools](https://wago.tools/db2?build=5.5.4.70579). The tile lists come from the client WDT files. [`Docs/DataSources-5.5.4.md`](Docs/DataSources-5.5.4.md) describes where each table comes from and the API changes. [`tools/README.md`](tools/README.md) explains how to regenerate `Data/mapdb.lua` and `Data/mapdb2.lua`.

## Releases

Pushing a version tag (`v*`) starts the GitHub Actions workflow in `.github/workflows/release.yml`. The workflow uses the [BigWigs packager](https://github.com/BigWigsMods/packager) to build the release and upload it to CurseForge. The release notes come from [`Docs/ChangeLog.md`](Docs/ChangeLog.md).

## Feedback

Please report bugs in the [GitHub issue tracker](https://github.com/arithmandar/Yatlas/issues). Include your client version and the full Lua error text (for example from BugSack).

## Credits

- Original author: Boo Diddly
- Maintained by arithmandar
