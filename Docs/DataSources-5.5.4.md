# Yatlas 資料更新與 API 檢視：WoW MoP Classic 5.5.4.70579

更新日期：2026-10-25　目標用戶端：`wow_classic` 5.5.4.70579（目前正式服最新組建，TOC Interface `50504`）

## 一、資料表對應總覽

| Yatlas 資料表 | 舊來源 (≤ 6.2) | 5.5.4 來源 | 狀態 |
|---|---|---|---|
| `Yatlas_WorldMapIds2` | Map.dbc | `Map` DB2 | 重新產生，共 290 張地圖；`[Directory] = MapID` |
| `Yatlas_mapdb1` | 手動從 `World\Minimaps\` 取出 | 每張地圖 WDT 的 `MAID` chunk（第 8 欄 = minimap texture FileDataID） | 重新產生；值改為 **FileDataID 數字** |
| `Yatlas_areadb` | AreaTable.dbc + LibBabble-SubZone | `AreaTable` DB2（enUS）＋載入時 `C_Map.GetAreaInfo(id)` 在地化 | 重新產生 4078 筆，不再需要 LibBabble |
| `Yatlas_mapareas` | **WorldMapArea.dbc（8.0 起已移除）** | **`UiMapAssignment` + `UiMap`** | 重新產生 17 張地圖、123 個區域 |
| `Yatlas_UiMapIds`（新增） | — | `UiMap` | `[Directory][areaID] = uiMapID`，供 C_Map API 使用 |
| `Yatlas_ZoneIds` | 手動，需與 `GetMapZones()` 對齊 | `UiMap` 階層＋`UiMapAssignment.MapID` | 重新產生；`GetMapZones()` 已不存在 |
| `Yatlas_WorldMapIds` | `SetMapZoom()` 的大陸索引 1..6 | uiMapID | 值改為 uiMapID（13/12/101/113/424/207/244/504/407） |
| `YA_MAPS` | LibBabble 顯示名稱 | `C_Map.GetMapInfo(uiMapID).name` | 移除德拉諾，新增地深之源、托巴拉德、雷霆島、暗月島 |
| `Yatlas_instances` | Map.dbc 的 Corpse 座標 | `AreaTrigger` DB2 ＋ MoP 伺服器端 `areatrigger_teleport`；7.3.5 `Map.Corpse_*` 補缺 | 重新產生，新增 MoP 副本與團隊副本 |
| `Yatlas_graveyards` | **WorldSafeLocs.dbc（已不在用戶端）** | 19005 組建的萃取資料，移除德拉諾與 WoD 專屬條目 | 重新啟用（原本整段被註解掉） |
| `Yatlas_towns2`、`Yatlas_mapareas_adjust`、`Yatlas_Mobs` | 手動 | — | 保留不變 |

### 已更名或移除的資料表

- **WorldMapArea** → 8.0 起由 `UiMap`、`UiMapAssignment`、`UiMapLink`、`UiMapArt*` 取代。`UiMapAssignment.Region_0..5` 是世界座標的 min(x,y,z)/max(x,y,z)，`UiMin/UiMax` 是該矩形在 UiMap 上的 0..1 位置。外推到整張 UiMap 後，就能得到與舊版完全相同的 `{LocLeft, LocRight, LocTop, LocBottom}`。以丹莫洛（Dun Morogh）與東部王國比對，數值完全一致（`{2137.5, -2760.416504, -3941.666504, -7206.249512}`）。
- **WorldSafeLocs** → 已移到伺服器端。5.5.4，甚至 wago.tools 收錄的任何組建（1.13、2.5、3.4、4.4、7.3.5、8.x、9.x）都沒有這張表。`AreaPOI` 只有戰場的墓地。
- **DungeonMap / DungeonMapChunk / WorldMapContinent / WorldMapTransforms** → 5.5.4 皆不存在。
- `Map` 的 `Corpse_0/Corpse_1`（副本入口座標）→ 8.0 起移除，7.3.5.26972 是最後一個有這兩欄的組建。

## 二、各資料表的萃取方式

### Yatlas_mapdb1（小地圖圖塊）
- 從 `https://wago.tools/api/files?search=world/maps/<dir>/<dir>.wdt` 取得 WDT 的 FileDataID，再以 `https://wago.tools/api/casc/<fdid>?version=5.5.4.70579&download` 下載 5.5.4 原始檔。
- `MAID` chunk 共 64×64 筆，每筆 8 個 uint32：rootADT、obj0、obj1、tex0、lod、mapTexture、mapTextureN、**minimapTexture**。索引 `i` 對應圖塊 `(x = i % 64, y = i // 64)`，也就是 `mapXX_YY`。實測東部王國 `map32_48` = FileDataID 204493，與 listfile 相符。
- 舊資料中的 110 個 `noLiquid_mapXX_YY` 在新版都成為一般圖塊。舊有的「mocking up」海洋填補圖塊保留，並改成對應的新 FileDataID。
- 圖塊數量：東部王國 839(+108 填補)、卡林多 1002(+124)、外域 826、北裂境 1131、潘達利亞 684（比舊版多 12）、地深之源 100、托巴拉德 42、雷霆島 64、暗月島 49。
- 為什麼改用 FileDataID：現代用戶端只有在 CASC root 帶有檔名雜湊時，才能用路徑載入檔案；`SetTexture(fileID)` 一律可用。DandyMap 作者在 [Blizzard 論壇](https://us.forums.blizzard.com/en/wow/t/2386382) 說明，它是直接用遊戲內建的小地圖地形來繪製世界地圖，與 Yatlas 的做法相同。

### Yatlas_mapareas / Yatlas_ZoneIds
- 取 `UiMap.Type` 為 2（大陸）、3（區域）、6（孤立地圖，例如暗月島）的地圖，並使用其 `OrderIndex = 0` 的 assignment。
- 以 assignment 的 `MapID` 分組（不是 UI 的父節點），因此永歌森林、鬼魂之地、奎爾達納斯島會正確歸到 `Expansion01` 圖塊。
- 大陸的鍵值為 `[0]`；同一個 AreaID 若有多個（相位版本）UiMap，取最小的 uiMapID。

### Yatlas_instances（副本入口）
1. 主要來源：用戶端 `AreaTrigger`（5.5.4）的 `Pos_0/Pos_1/ContinentID`，加上 MoP 模擬器資料庫中「哪個 trigger 傳送到哪個副本」的對應：[MistCore 5.0.5 areatrigger_teleport](https://github.com/MistCore/MC-Database/blob/master/main_db/world/areatrigger_teleport.sql)，以及 [SkyFire_548](https://github.com/ProjectSkyfire/SkyFire_548) 5.4.8 的 SQL 更新（MSV、HoF、ToES、雷霆王座及 5 人副本）。
2. 補缺來源：7.3.5.26972 `Map` 的 `CorpseMapID/Corpse_0/Corpse_1`（大災變副本、新血色修道院大廳、新通靈學院等）。
3. 手動補上兩筆：
   - 血色修道院（1004）：沿用舊修道院中庭 trigger 45 的座標（近似值）。
   - 圍攻奧格瑪（1136）：使用 WorldSafeLocs 的「Garrosh Raid - Exit Target」座標。
4. 排除已停用的舊地圖：189（Scarlet Monastery of Old）、289（Scholomance OLD）、309（Ancient Zul'Gurub）等。
5. 格式為 `{name, worldY, worldX, instanceMapID}`，第 4 欄是新增的，載入時會用 `GetRealZoneText(mapID)` 換成在地化名稱。

### Yatlas_graveyards（0.9.4 起停用）
- `WorldSafeLocs` 在現代用戶端只存在伺服器端，5.5.4 的 DB2 與 wago.tools 都沒有這個表，因此**目前沒有任何來自遊戲資料檔的墓地座標**。
- 先前的版本曾沿用 git 歷史中 6.0（19005）的舊資料，但那不是 5.5.4 用戶端的資料，無法確認是否正確，因此改為停用：
  - `sets/index.xml` 不再載入 `sets/graveyards.lua`（檔案保留，方便日後恢復）。
  - `mapdb.lua` 的 `Yatlas_graveyards` 改為空表；`mapdb2.lua` 的 `YA_BL_gy()` 黑名單一併移除；`tools/assemble.py` 也不再產生墓地資料。
- 日後可能的線索：5.5.4 的 API 文件中有 `C_DeathInfo.GetGraveyardsForMap(uiMapID)`（執行期 API，回傳 UiMap 正規化座標）。目前**尚未實作**，待確認在 MoP Classic 中的實際行為後再處理。

## 三、驗證
- 兩個檔案都能在 Lua 5.1 正確載入（以 lupa 搭配 WoW API stub 測試）。
- 每個 `YA_MAPS` 項目都有圖塊、`mapareas` 與 `WorldMapIds`；`Yatlas_ZoneIds` 的每個區域都能在 `mapareas` 與 `areadb` 中查到。
- 111 個副本入口換算成小地圖座標後都落在存在的圖塊上（墓地已停用，見上）。
- 產生器放在 `tools/`（README 內有步驟）。重跑後輸出與提交的檔案逐位元組相同。

## 四、API 遷移（0.9.4 已實作，以 Gethe/wow-ui-source `classic` 分支 5.5.4 (70579) 的 Blizzard_APIDocumentationGenerated 為準）

新增 `Compat.lua`（在 TOC 中最先載入），把所有新 API 包成 Yatlas 自己的函式，其餘程式只處理 Yatlas 的座標系統（Directory + bigx/bigy）：

| 函式 | 說明 |
|---|---|
| `Yatlas_GetUnitLocation(unit)` → `map, bigx, bigy` | 先用 `UnitPosition(unit)`；取不到時改用 `C_Map.GetBestMapForUnit` → `C_Map.GetPlayerMapPosition` → `C_Map.GetWorldPosFromMapPos`。instanceID 以 `Yatlas_WorldMapIds2` 反查 Directory，只接受有圖塊的地圖 |
| `Yatlas_MapIDToDirectory(mapID)` | Map.db2 ID → Directory（延遲建立反查表） |
| `Yatlas_LoadLandmarks(map)` / `Yatlas_ResetLandmarks()` | 依 `Yatlas_UiMapIds[map]` 逐一呼叫 `C_AreaPoiInfo.GetAreaPOIForMap` / `GetAreaPOIInfo`，轉成世界座標後依 areaPoiID 去重，存成舊格式 `{bigx, bigy, name, description, textureIndex, atlasName}` |
| `Yatlas_GetAddOnMetadata`、`Yatlas_GetPOITextureCoords` | 優先使用 `C_AddOns.GetAddOnMetadata`、`C_Minimap.GetPOITextureCoords`，舊全域函式作為退路 |
| `YATLAS_BACKDROP_*`、`Yatlas_ApplyBackdrop()`、`Yatlas_PlaySound()` | 取代 XML `<Backdrop>` 與字串音效 |

| 位置 | 舊 API | 0.9.4 的改法 |
|---|---|---|
| Yatlas.lua | `GetMapInfo()`、`SetMapZoom()`、`SetMapToCurrentZone()`、逐一切換大陸找玩家 | 全部移除。`YatlasFramePlayerJumpButton_Seek` 直接用 `Yatlas_GetUnitLocation` 定位並置中；追蹤模式在 OnUpdate（0.5 秒節流）中更新 |
| Yatlas.lua、players.lua | `GetPlayerMapPosition(unit)` + `Yatlas_mapareas` 換算 | `Yatlas_GetUnitLocation(unit)` + `Yatlas_Big2Mini_Coord` |
| Yatlas.lua | `GetNumMapLandmarks()` / `GetMapLandmarkInfo()` | `Yatlas_LoadLandmarks()`（C_AreaPoiInfo）；`AREA_POIS_UPDATED` 時清除重建 |
| Yatlas.lua、players.lua | 事件 `WORLD_MAP_UPDATE` | `PLAYER_ENTERING_WORLD`、`ZONE_CHANGED_NEW_AREA`、`AREA_POIS_UPDATED`，加上 OnUpdate 輪詢 |
| players.lua | `RAID_ROSTER_UPDATE`、`PARTY_MEMBERS_CHANGED`；團隊迴圈誤用 `GetNumSubgroupMembers()` | `GROUP_ROSTER_UPDATE`；團隊時 `IsInRaid()` + `GetNumGroupMembers()`，隊伍時 `GetNumSubgroupMembers()`；OnEvent 改用參數 `event` |
| sets/landmarks.lua | `GetPOITextureCoords()` | `Yatlas_GetPOITextureCoords()`；沒有 textureIndex 但有 atlasName 時用 `SetAtlas()` |
| Locale/Yatlas-enUS.lua | `GetAddOnMetadata()` | `Yatlas_GetAddOnMetadata()` |
| OptionsFrame.xml、Templates.xml | XML `<Backdrop>` | `inherits="BackdropTemplate"`，在 OnLoad 呼叫 `Yatlas_ApplyBackdrop()` |
| OptionsFrame.xml | `OptionFrameBoxTemplate`（已不存在） | 自訂 `YatlasOptionBoxTemplate` |
| OptionsFrame.xml | `PlaySound("gsTitleOptionOK")` | `Yatlas_PlaySound("GS_TITLE_OPTION_OK")`（`SOUNDKIT`） |
| Yatlas.xml | `UIPanelButtonTemplate2`（已不存在） | `UIPanelButtonTemplate` |
| Yatlas.xml | OnKeyDown 使用全域 `arg1`，且會吞掉所有按鍵 | 改用參數 `key`；未處理的按鍵用 `SetPropagateKeyboardInput` 交還給遊戲（戰鬥中不呼叫） |
| Yatlas.lua、Templates.xml、YatlasButton.xml | `ADDON_LOADED` 用全域 `arg1`；`self:OnEvent(event)` 沒有傳遞參數 | `OnEvent(event, ...)` 一路傳遞參數 |
| Yatlas.lua | `SetupFullscreenScale()`（已移除） | 先檢查函式是否存在 |
| Yatlas.lua | 既有錯誤：`YF_GetZoneIDs` 未定義、全域變數 `i` | 改為 `self:GetZoneIDs()`、`local i` |

### 仍可使用（未變更）
- `UIDropDownMenu_*`、`ToggleDropDownMenu`、`UIDROPDOWNMENU_MENU_LEVEL`、`OptionsSliderTemplate`、`UICheckButtonTemplate`、`GameMenuButtonTemplate`、`UIPanelCloseButton`。
- `getn`、`tinsert`、`GetZoneText`、`GetRealZoneText(mapID)`、`UnitName`、`UnitExists`、`UnitInParty`、`GetCursorPosition`、`ShowUIPanel`、`UIPanelWindows`、`GetBindingKey`、`RunBinding`、`TOOLTIP_DEFAULT_COLOR`。

### 外掛整合（`sets/`）
- `sets/index.xml` 只載入 `landmarks.lua`、`players.lua`。`gatherer.lua`、`mapnotes.lua`、`ctmapmod.lua`、`gathermate.lua` 依賴的外掛都已停止維護，維持不載入。

### TOC 與打包
- `## Interface: 50504`，版本 0.9.4。
- 移除 `LibBabble-SubZone-3.0`、`AceLocale-3.0`、`LibStub`：`Libs/`、`Locale/LibBabble.lua`、`.pkgmeta` 的 externals 都已刪除，`OptionalDeps` 只留 `myAddOns`。

### 尚未在遊戲內測試
以上修改只通過語法檢查（lupa）、XML 格式檢查與 API stub 測試，**尚未在 5.5.4 用戶端實際載入**。

## 五、DandyMap 參考（1.6.3，僅作為線索）
來源：[CurseForge DandyMap 1.6.3](https://www.curseforge.com/api/v1/mods/1713483/files/9317439/download)，目標用戶端為 WoW Forever（`## Interface: 16001`）。DandyMap 只用來**確認方向與交叉比對資料**，Yatlas 的程式碼都是依 Yatlas 原本的架構與 Blizzard API 文件自行撰寫，沒有沿用 DandyMap 的程式結構或寫法。

### 資料交叉比對
- DandyMap 的 `data/ClientTerrainData.lua` 同樣來自 WDT MAID 的 FileDataID。用 `tools/compare_dandymap.py`（只讀取資料、不複製程式）比對：
  - 東部王國：重疊 703 格，**703 格完全相同**。
  - 卡林多：重疊 979 格，**979 格完全相同**。
  - Yatlas 多出的格子（東部王國 136、卡林多 23）是大災變之後的地形，WoW Forever 沒有這些區域。

### 從中得到的線索（皆可在 Blizzard API 文件中查到）
- `UnitPosition(unit)` 的回傳順序為世界 X、世界 Y、Z、instanceID，與 [HereBeDragons](https://github.com/Nevcairiel/HereBeDragons) 一致。
- 圖塊接縫：Texture 的 `SetTexture(fileID, "CLAMP", "CLAMP")`、`SetSnapToPixelGrid(false)`、`SetTexelSnappingBias(0)` 屬於一般的材質設定方式。
- 5.5.4 的 DB2 中沒有 `JournalInstanceEntrance`，精確的副本入口只能在遊戲內用 `C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)` 取得（日後可用來修正 `Yatlas_instances` 中的近似值）。
- 區域邊界也可以在執行時以 `C_Map.GetWorldPosFromMapPos` 計算地圖四個角點取得，可作為 `Yatlas_mapareas` 的驗證方式。
