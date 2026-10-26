<!--
CurseForge project page text for Yatlas (project ID 2172).
Summary field (short description):
  Yet another atlas: browse the whole world on minimap terrain in Retail, Mists of Pandaria Classic, Anniversary and Classic Era, with dungeon and raid entrances, towns and group members.
Paste everything below the line into the CurseForge description editor (Markdown mode).
-->

---

# Yatlas

**Yet another atlas: browse the whole world at minimap detail.**

Yatlas draws the world from the game's own minimap terrain tiles instead of the illustrated world map. You get a seamless, zoomable, top-down view of every continent, with the real terrain, roads and coastlines you see on your minimap.

## Supported clients

| Client | Status |
|---|---|
| **Retail (Midnight, 12.1.5)** | Supported from v1.0.0 |
| **Mists of Pandaria Classic (5.5.4)** | Supported from v0.9.4 |
| **Anniversary / Burning Crusade (2.5.6)** | Supported from v1.0.0 |
| **Classic Era (1.15.9)** | Supported from v1.0.0 (Season of Discovery maps are not included) |
| Other clients (Wrath, Cataclysm Classic) | Not supported |

One download works in all supported clients: Yatlas detects the game version and loads only the map data for that client.

Version 1.0.0 adds Retail, Anniversary and Classic Era. The map data of every client is rebuilt from that client's own files.

## Maps

| Client | Maps |
|---|---|
| Classic Era | Eastern Kingdoms, Kalimdor |
| Anniversary (TBC) | Eastern Kingdoms, Kalimdor, Outland |
| Mists of Pandaria Classic | Eastern Kingdoms, Kalimdor, Outland, Northrend, Pandaria, Deepholm, Tol Barad, Isle of Thunder, Darkmoon Island |
| Retail | Eastern Kingdoms (with Quel'Thalas), Kalimdor, Outland, Northrend, Deepholm, Tol Barad, Pandaria, Isle of Thunder, Draenor, Broken Isles, Argus, Zandalar, Kul Tiras, Nazjatar, The Shadowlands, Zereth Mortis, Dragon Isles, The Forbidden Reach, Zaralek Cavern, Emerald Dream, Khaz Algar (surface and underground), Undermine, Siren Isle, K'aresh, Harandar, Voidstorm, Darkmoon Island |

## Features

- **Two views**
  - **Normal view:** a movable window, similar to Atlas. Open it with the minimap button, `/yatlas`, or a key binding.
  - **Large view:** a bigger map window, shown like the world map. Open it with `/bigyatlas` or a key binding. Press Esc or the binding again to close it.
- **Navigation:** click and drag to pan, use the mouse wheel to zoom, and pick a map or jump to a zone from the drop-down menus.
- **Goto Player:** click to centre the map on your character. Shift-click to keep following you as you move. The option "Zoom to Player on Show" centres on you every time the map opens.
- **Party and raid members** are shown on the map in real time.
- **Points of interest:**
  - Towns and landmarks, read live from the game
  - Dungeon and raid entrances for every supported client
  - Smaller settlements and flight-path towns
  - Flight paths for your faction, with undiscovered ones dimmed
- **Tooltips** when you hover over a point.
- **Options:** transparency, icon size, which point types to show, and the minimap button and its position.

## Key bindings

Under **Key Bindings → AddOns → Yatlas**:

- Toggle Yatlas Frame
- Toggle Large Yatlas Frame

## Known limitations

- **Graveyards are not shown.** Graveyard locations are no longer in the client data, so this feature is turned off until a reliable source is found.
- **No support for Gatherer, MapNotes or CT_MapMod.** Those integrations were written for addons that are no longer maintained, and they are not loaded.
- Inside dungeons and raids, positions are not available, so the map does not track you there.

## Feedback and source

- Source code and issue tracker: [github.com/arithmandar/Yatlas](https://github.com/arithmandar/Yatlas)
- Please report bugs on GitHub. Include your client version and the full Lua error text, for example from BugSack.

## Credits

- Original author: Boo Diddly
- Maintained by arithmandar
