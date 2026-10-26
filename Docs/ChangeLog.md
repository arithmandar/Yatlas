# Yatlas ChangeLog


### v1.0.0 (in development)

- Yatlas is now licensed under the GNU General Public License, version 2 (LICENSE, ## X-License)
- Multi-client support with one download and one TOC (## Interface: 11509, 20506, 50504, 120105):
  Retail 12.1.5, Mists of Pandaria Classic 5.5.4, Anniversary 2.5.6 and Classic Era 1.15.9
- Client detection in Core/Constants.lua (YATLAS_CLIENT, from WOW_PROJECT_ID, the same approach as Atlas)
- Map data split per client: Data/ClassicEra, Data/TBC, Data/Mists, Data/Mainline. Data/Data.xml loads
  them all, and each file returns at once unless it matches the running client
- Shared data and helpers moved to Data/Common.lua; the localization of names moved to Data/Localize.lua
- New maps for Retail: Draenor, Broken Isles, Argus, Zandalar, Kul Tiras, Nazjatar, The Shadowlands,
  Zereth Mortis, Dragon Isles, The Forbidden Reach, Zaralek Cavern, Emerald Dream, Khaz Algar
  (surface and underground), Undermine, Siren Isle, K'aresh, Harandar, Voidstorm, and Quel'Thalas
  on the Eastern Kingdoms map
- Retail instance entrances come from the client JournalInstanceEntrance table; Classic Era and
  Anniversary entrances from the client AreaTrigger table and AzerothCore server data
- The map menu now lists the maps in expansion order (it used to be random)
- Removed the hand-made "mocking up" ocean filler tiles (232 per client); only real minimap tiles are drawn
- Towns and capitals of the world map (AreaPOI.db2) are now part of the data for every client and use the
  game's town / major city icons. Before, only Classic Era showed them (as the old blue circle and star
  icons), because MoP Classic and Retail hide these markers from C_AreaPoiInfo
- Other area POIs without an atlas use the game's own POI icons, the same as the world map
- Mainline: new point set "Delves" with the delve entrances from C_AreaPoiInfo.GetDelvesForMap
  (regular and bountiful icons, like the world map); it can be switched off in the point menu
- New minimap button look: the game's world map icon (Interface\WorldMap\WorldMap-Icon, also the
  TOC icon) in the round minimap button frame of the game (UI-Minimap-Background and
  MiniMap-TrackingBorder), sized per client. Images/Button.blp and Button-Down.blp were removed
- Landmarks submenu in the point menu: instances (dungeons and raids), capitals, towns, travel
  (mainline: boats, zeppelins, portals and teleport networks from the map API) and other landmarks
  can be switched on and off separately; "Landmarks" itself still switches all of them
- The point menu lists the point sets in a fixed order (the load order of Modules/index.xml)
- The map zooms out about four times further (down to 8 pixels per tile in the small window): map
  tile textures are created on demand (up to 4096) instead of the fixed 256 from the XML. The mouse
  wheel and the +/- buttons now zoom by about 20% per step
- Mainline: new point set "Skyriding Races" with the race start points from
  C_AreaPoiInfo.GetDragonridingRacesForMap; it can be switched off in the point menu
- Retail: capitals use the faction icons of the world map (Alliance / Horde)
- Retail: dungeon, raid and flight path icons are scaled up to match the larger Retail atlases
- Minimap button: circles the real minimap center and size (Retail's minimap is 198x198, Classic 140x140),
  and follows minimap size changes
- Retail API: MouseIsOver() no longer exists, Region:IsMouseOver() is used instead; secret values from
  UnitClass / UnitIsUnit are checked with issecretvalue before use
- On an unsupported client Yatlas prints a message instead of raising Lua errors
- Removed `## OptionalDeps: myAddOns` from the TOC (myAddOns is a 2005 addon manager that no longer exists;
  Yatlas has no myAddOns code left)
- Mists of Pandaria Classic data is unchanged (identical to v0.9.6)
- One generator for all clients: tools/yatlas_data.py with tools/flavors.py
  (replaces gen.py, assemble.py, towns.py, wdt.py); Docs/DataSources-5.5.4.md is now Docs/DataSources.md

### v0.9.6 (Oct. 26, 2026)

- Reorganized the addon folders: Core/, Data/, UI/, Modules/ (was sets/), Images/ (was images/)
- Textures converted from TGA to BLP; texture paths now use Images\
- Bindings.xml stays in the addon root folder (WoW only loads it from there)
- New Core/Constants.lua collects the constants: addon metadata, texture paths, coordinate scale,
  frame option defaults and backdrops
- Title, version, author, website and release date now all come from the TOC
  (new ## Author, ## X-Credits for the original author Boo Diddly, and ## X-Date: @project-date-iso@); the author e-mail field was removed
- Player position uses the game's world map arrow (Interface\WorldMap\WorldMapArrow) and turns
  with the facing (GetPlayerFacing); position and facing update every 0.05 s while Yatlas is open
- Party and raid members use the game's WhiteCircle-RaidBlips dot in class colour
  (Icon-PartyUnit is kept only as a fallback)
- The big frame is now called the "large" frame in the key binding and tooltips (it is not fullscreen),
  in all 10 languages
- New tooltips for the lock/unlock button (shows the current state), the close buttons,
  the Show Points button (bottom right) and the zoom button (bottom left)
- New tooltips for Goto Player (in both frames; also shows when the map is following you)
  and the Options button
- Version text moved left so it no longer overlaps the switch, lock and close buttons
- Fixed: "Outland" was the only continent not localized in the map menu. It used uiMapID 101,
  which does not exist in 5.5.4; Outland is uiMapID 1467 there (987 is an orphan copy outside the
  world map tree). This also fixes the continent-level flight path and landmark lookups for Outland
- Fixed: pressing Esc in the large frame caused ADDON_ACTION_FORBIDDEN (RunBinding() is protected).
  The large frame no longer captures the keyboard; Esc closes it through the game's own panel handling,
  and the toggle and screenshot keys go straight to their normal bindings

### v0.9.5 (Oct. 26, 2026)

- Town names (Yatlas_towns2) are now localized from the client AreaTable
- Map icons use the game's own atlases: Dungeon (blue) / Raid (green) for instance entrances, poi-town for towns (old Yatlas icons kept as fallback)
- New point set: Flight Paths, from the client TaxiNodes.db2 (5.5.4.70579);
  names / discovered state from C_TaxiMap.GetTaxiNodesForMap when available,
  icons TaxiNode_Neutral / Horde / Alliance, only neutral and own-faction nodes shown
- Fixed: the Show Points menu toggles had no effect. The modern UIDropDownMenu
  switches the check mark before calling the handler, so the stored state was inverted
- Translations for all client languages: deDE, esES/esMX, frFR, itIT, koKR, ptBR, ruRU,
  zhCN, zhTW (new: esES, frFR, itIT, koKR, ptBR, ruRU, zhTW); deDE keys renamed from the
  obsolete YATLAS_OVERLAY_* to YATLAS_POINTS_*; TOC Notes in every language
- TOC Version is now @project-version@ (filled in by the packager; shows "dev" when unpackaged)
- New button to switch between the normal and the fullscreen view (keeps the map and
  the centre of the view); Blizzard UI-Panel-Bigger/SmallerButton textures
- Fixed: the map and zone menus of the fullscreen view (/bigyatlas) changed the hidden
  normal frame instead, because both menus were hard-wired to YatlasFrame
- Readme.md rewritten (usage, installation, repository layout, data and release notes); old Docs/README.txt removed

### v0.9.4 (Oct. 26, 2026)

- Map data regenerated for WoW MoP Classic 5.5.4.70579 (see Docs/DataSources-5.5.4.md)
- Yatlas_mapdb1 now stores minimap tile FileDataIDs read from the 5.5.4 WDT files
- Yatlas_mapareas rebuilt from UiMapAssignment (WorldMapArea no longer exists)
- Instance entrances rebuilt from AreaTrigger; MoP dungeons/raids added
- Graveyards disabled: WorldSafeLocs is server-side only, no client data source in 5.5.4
- Area / map / instance names localized from the client instead of LibBabble-SubZone-3.0
- Draenor removed; Deepholm, Tol Barad, Isle of Thunder and Darkmoon Island added
- Minimap tiles drawn with CLAMP wrap and pixel snapping disabled to avoid seams
- Tile data cross-checked against DandyMap 1.6.3 data (tools/compare_dandymap.py)
- API migration for the modern Classic client (new Compat.lua):
  - player / party / raid positions from UnitPosition (C_Map fallback)
  - landmarks from C_AreaPoiInfo instead of GetMapLandmarkInfo
  - GetMapInfo / SetMapZoom / WORLD_MAP_UPDATE removed; GROUP_ROSTER_UPDATE
  - BackdropTemplate, SOUNDKIT, C_AddOns.GetAddOnMetadata, C_Minimap.GetPOITextureCoords
  - OnKeyDown / OnEvent no longer use the global arg1
  - fixed undefined YF_GetZoneIDs and a leaked global
- TOC Interface 50504; LibBabble-SubZone-3.0 / AceLocale-3.0 / LibStub removed

### v0.9.1 (Feb. XX, 2013)

- TOC update to support WoW 5.2

### v0.9.0 (September XX, 2012)

- TOC update to support WoW 5.0

### v0.8.5 (August 15, 2011)

- Tag for official release

### v0.8.5 beta 2 (July 17, 2011)

- Enable no-libs packaging in CurseForge

### v0.8.5 beta 1 (June 28, 2011) - never release

- TOC update to support WoW 4.2

### v0.8.4 beta 1, 2 (June 08, 2011)

- Map data update to WoW 4.1

### v0.8.3 (8/5/2009)

- Updated world map for 3.2

### v0.8.0 (12/24/2008)

Update for WoW 3.0 (smexy)

- Quick and dirty updates to make it work again, not sure if all bugs have been burnt.

### v0.7.8 (11/25/2007)

- Update for WoW 2.3.x  As a result of updating, the complete area ids are no longer stored, and thus the detection of the current zone is less accurate.
- Update German localization (blackrat)

### v0.7.7 (07/16/2007)

- Update for WoW 2.1.x
- NOTE: Much of the support for other AddOns might not work at this point in time.

### v0.7.6 (01/09/2007)

- Update for WoW 2.0.3
- Update German localization (Singler)

### v0.7.5 (12/26/2006)

- Fix a bug with CT_MapMod support

### v0.7.4 (12/24/2006)

- Update for WoW 2.0

### v0.7.3 (08/24/2006)

- Fix the fullscreen window on certain screen resolutions

### v0.7.2 (08/22/2006)

- Update map information for 1.12

### v0.7.1 (06/23/2006)

- Minor bugfixes (Reported by Hevanus, Maniacski)
- Fix German localization (PsyZo, AbuDun)

### v0.7 (06/21/2006)

- Rewrite of point handling code for consistancy and expandability, including a way to setup points specifically to be moved.
- Add Party and Raid positions
- Add some raid boss data in backend (not yet used!)
- Button+pulldown for zooming without a mouse scrollwheel
- New tooltip that shows icons in addition to names.
- The main YatlasFrame's popout has been removed in favor of a seperate options window, and mouseover point tooltips.
- Runtime generation of point frames instead of preallocating.
- Goto button will now continuously track if shift clicked.
- Addition of an option to automatically seek player on show.
- myAddOns data will now correctly show release date
- Minor bugfixes
- Minor xml validity fixes
- Some of the icons have been tweaked.
- Addition of a new README.txt file
- German localization added (antikleia.wow@ffohol.de)
- Update map table for WoW 1.11
- Drastically decrease the size of the generated map table

### v0.6.3 (03/28/2006)

- Fix an issue where Gatherer minimap icons would become misplaced if the Yatlas frame was open.
- Update map table for WoW 1.10

### v0.6.2 (01/16/2006)

- Fix bug where jump to player would fail to find the player.

### v0.6.1 (01/06/2006)

- Fix bug where the fullscreen yatlas view would partially fall offscreen at some resolutions.
- Fix bug where player location would not be updated properly
- Fix bug where position slider tooltip would show when it shouldn't
- Update the slider when the mouse is dragged.

### v0.6 (01/06/2006)

- Add a dropdown to control which points to show
- Add myAddons support
- Modularize the way "overlays" work
- Make icons resizable
- In the normal YatlasFrame, clicking on points on the lengend causes them to blink on the map.
- Switch from using POI data to getting landmarks data during runtime.  Add extra points by hand.
- Add a option to display cursor coordinates in the YatlasFrame
- Fix a bug for when the map would be dragged, closed, then reopened, the map would continue being "stuck" to the cursor
- Add zooming using the mouse scroll button
- Make it easier to create new Yatlas Frames
- Add a "Big" world map view.  This is similar to the World Map window ('m' key).  To show either use the /bigyatlas command or set the key binding.
- Increase the number of displayable points
- Minor speed increases by lazily generating area ids, and not querying for them while dragging the map.
- Add compatibility for WoW 1.9
- Show CTMapMod points

### v0.5 (10/26/2005)

- Show player's location (backend partially exists for raid/party members)
- Add a button to allow jumping to the player's location
- Dropdown bugfixes.
- Pull data "on the fly" from MapNotes and Gatherer.
- Allow map movement by left mouse button as well as right now.
- Right-clicking and dragging on the minimap button moves it around.
- Show graveyards
- Increase number of textures and properly handle having a limit of textures.

### v0.4 (10/11/2005)

- Introduction of this ChangeLog.
- Add key binding.
- Add alpha transparency.
- Add a pulldown for zones to replace the zone text field.
- Update textures translation table for WoW 1.8 content patch.
- Other minor bug fixes.
