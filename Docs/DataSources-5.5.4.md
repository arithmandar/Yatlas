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

### Yatlas_graveyards
- git 歷史中 `bfe6a9f`（MoP 5.2 / 16634）與 `adaeff5`（6.0 / 19005）兩個版本都有完整資料。後者是前者的超集，另含永恆之島、巨獸島、恆春谷團隊副本與地深之源的墓地，因此採用後者。
- 移除項目：整個德拉諾、角色直升 Hearth/Start Loc、6.0 入侵事件營地、6.0 黑石塔重製的出口。
- `Deepholm` 鍵值修正為實際的目錄名稱 `Deephome`。`YA_BL_gy()` 也加上 nil 防護。
- 執行期替代方案：`C_DeathInfo.GetGraveyardsForMap(uiMapID)`（5.5.4 有此 API，回傳 `position` 為 UiMap 正規化座標）。

## 三、驗證
- 兩個檔案都能在 Lua 5.1 正確載入（以 lupa 搭配 WoW API stub 測試）。
- 每個 `YA_MAPS` 項目都有圖塊、`mapareas` 與 `WorldMapIds`；`Yatlas_ZoneIds` 的每個區域都能在 `mapareas` 與 `areadb` 中查到。
- 111 個副本入口與 1149 個墓地，換算成小地圖座標後都落在存在的圖塊上。
- 產生器放在 `tools/`（README 內有步驟）。重跑後輸出與提交的檔案逐位元組相同。

## 四、API 檢視（5.5.4 = 現代用戶端，以 Gethe/wow-ui-source `classic` 分支 5.5.4 (70579) 的 Blizzard_APIDocumentationGenerated 為準）

### 已移除，必須改寫

| 位置 | 舊 API | 5.5.4 替代方案 |
|---|---|---|
| Yatlas.lua 444/447/872/990、players.lua | `GetMapInfo()`、`SetMapZoom(n)`、`SetMapToCurrentZone()` | 不再需要操作世界地圖狀態：`C_Map.GetBestMapForUnit("player")` 取得 uiMapID，用 `Yatlas_WorldMapIds` / `Yatlas_UiMapIds` 對應 Directory |
| Yatlas.lua 879、players.lua 56 | `GetPlayerMapPosition(unit)` | 最簡單的是 `local wx, wy, _, instanceID = UnitPosition(unit)`：wx = 世界 X（bigy），wy = 世界 Y（bigx），instanceID 用 `Yatlas_WorldMapIds2` 反查 Directory，接著直接呼叫 `Yatlas_Big2Mini_Coord(wy, wx)`，**完全不需要 mapareas**。在副本內受限時，改用 `C_Map.GetPlayerMapPosition(uiMapID, unit)` 搭配 `C_Map.GetWorldPosFromMapPos(uiMapID, pos)` |
| Yatlas.lua 847–854 | `GetNumMapLandmarks()` / `GetMapLandmarkInfo(i)` | `C_AreaPoiInfo.GetAreaPOIForMap(uiMapID)` + `C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID)`，再用 `C_Map.GetWorldPosFromMapPos` 轉成世界座標；副本入口可用 `C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)` |
| Yatlas.lua 57/164、players.lua 107/124 | 事件 `WORLD_MAP_UPDATE` | 改用 `ZONE_CHANGED_NEW_AREA`、`ZONE_CHANGED`、`PLAYER_ENTERING_WORLD`，並在 OnUpdate 節流輪詢 `UnitPosition` |
| players.lua 109/125/126 | `RAID_ROSTER_UPDATE`、`PARTY_MEMBERS_CHANGED` | `GROUP_ROSTER_UPDATE` |
| players.lua 46/49 | `GetNumSubgroupMembers()` | 仍可用，但團隊時建議改成 `GetNumGroupMembers()` + `IsInRaid()` |
| Yatlas.lua 1011 | `Yatlas_GetMapZones()`（依賴 `GetMapZones` 的順序） | 已改由 `Yatlas_ZoneIds`（新產生）提供，邏輯可不變 |
| OptionsFrame.xml 10、Templates.xml 850/914/964 | XML `<Backdrop>`、`SetBackdropColor` | 9.0 起需要 `inherits="BackdropTemplate"`，並以 `KeyValue backdropInfo` 或 `self:SetBackdrop()` 設定 |
| OptionsFrame.xml 297 | `PlaySound("gsTitleOptionOK")` | `PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)` |
| Yatlas.xml 631–644 | OnKeyDown 使用全域 `arg1` | 改成 handler 參數 `key`（`function(self, key)`） |
| Yatlas.lua 176 | `ADDON_LOADED` 判斷用全域 `arg1` | 改用 `OnEvent(self, event, ...)` 的第一個參數 |

### 仍可使用
- `UIDropDownMenu_*`、`ToggleDropDownMenu`、`UIDROPDOWNMENU_MENU_LEVEL`（5.5.4 仍有 `UIDropDownMenu.lua`）。
- `getn`、`tinsert`（`Compat.lua` 仍保留 `getn = table.getn`）。
- `GetPOITextureCoords`、`GetZoneText`、`GetRealZoneText(mapID)`、`UnitName`、`UnitExists`、`UnitInParty`、`GetCursorPosition`、`ShowUIPanel`、`UIPanelWindows`、`UISpecialFrames`、`GetBindingKey`、`RunBinding`。
- Texture、Frame、Slider、FontString 的各種方法（SetTexture 也接受 FileDataID）。

### 外掛整合（`sets/`）
- `gatherer.lua`、`mapnotes.lua`、`ctmapmod.lua`、`gathermate.lua` 依賴的 Gatherer、MapNotes、CT_MapMod 舊版及 GatherMate（非 GatherMate2）都已停止維護，建議停用或改接 GatherMate2 / HandyNotes。
- `myAddOns` 已不存在，可以移除。

### TOC
- `## Interface: 60200` → `50504`（或在 API 遷移完成後，新增 `Yatlas_Mists.toc`）。
- `OptionalDeps` 中的 `LibBabble-SubZone-3.0` 已不再被資料表使用，可以移除（`.pkgmeta` 的 externals 也一併移除）。
- 目前**刻意保持 TOC 不變**：API 尚未遷移前，在 5.5.4 載入會因 `SetMapZoom` 等函式不存在而出錯。

## 五、DandyMap 參考
- 主程式只在 CurseForge 發佈（有 Cloudflare 驗證，無法自動下載），沒有公開的原始碼庫。
- 公開的資料包 [nutiler/dandymapdata](https://github.com/nutiler/dandymapdata) 目標是 WoW Forever（Interface 16001）。其中 `tools/` 的流程（以 CASC/listfile 取得小地圖與 WMO 圖塊、`DANDEMap`）與本次採用的 FileDataID 方式一致。作者也說明主程式不需資料包，直接使用用戶端內建的小地圖地形。
