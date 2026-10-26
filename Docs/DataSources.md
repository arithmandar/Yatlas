# Yatlas 資料來源與 API 檢視

更新日期：2026-10-26（v1.0.0 開發中）

## 零、多用戶端架構（v1.0.0 起）

Yatlas 從 v1.0.0 起用**單一 TOC** 支援四種用戶端，每種用戶端各有一份資料：

| 版本旗標 (`YATLAS_CLIENT`) | 用戶端 | 組建 | TOC Interface | 資料目錄 | 地圖 | 副本入口 | 飛行點 |
|---|---|---|---|---|---|---|---|
| `isClassicEra` | Classic Era | [1.15.9.70003](https://wago.tools/db2?build=1.15.9.70003) | 11509 | `Data/ClassicEra/` | 2 | 34 | 67 |
| `isTBC` | Anniversary（燃燒的遠征） | [2.5.6.70006](https://wago.tools/db2?build=2.5.6.70006) | 20506 | `Data/TBC/` | 3 | 59 | 142 |
| `isMists` | Mists of Pandaria Classic | [5.5.4.70579](https://wago.tools/db2?build=5.5.4.70579) | 50504 | `Data/Mists/` | 9 | 111 | 337 |
| `isRetail` | 正式版（Midnight） | [12.1.5.70575](https://wago.tools/db2?build=12.1.5.70575) | 120105 | `Data/Mainline/` | 28 | 188 | 749 |

### 載入流程

1. `Core/Constants.lua` 依 `WOW_PROJECT_ID` 建立 `YATLAS_CLIENT`（寫法參照 Atlas 的 `Data/Constants.lua`）：`WOW_PROJECT_MAINLINE` = 1、`WOW_PROJECT_CLASSIC` = 2、`WOW_PROJECT_BURNING_CRUSADE_CLASSIC` = 5、`WOW_PROJECT_MISTS_CLASSIC` = 19。
2. `Data/Data.xml` 依序載入 `Common.lua`、四個版本的 `mapdb.lua`／`mapdb2.lua`，最後載入 `Localize.lua`。
3. 每個版本的資料檔第一行是 `if not (YATLAS_CLIENT and YATLAS_CLIENT.<旗標>) then return end`，所以只有符合目前用戶端的那一份會定義資料表，其他三份不佔記憶體。
4. `Localize.lua` 在載入後把英文名稱換成用戶端的在地化名稱（`C_Map.GetAreaInfo`、`GetRealZoneText`、`C_Map.GetMapInfo`）。如果沒有任何一份資料符合（不支援的用戶端），它會建立空表並設定 `YATLAS_NO_DATA`，開啟視窗時只在聊天框顯示「不支援此用戶端」，不會產生 Lua 錯誤。
5. `Data/Common.lua` 放各版本共用的手動資料（`Yatlas_PaperZoneNames`、`Yatlas_Landmarks`、`Yatlas_mapareas_adjust`、`Yatlas_Mobs`）與輔助函式（`Yatlas_UiMapName`、`Yatlas_MapName`、`Yatlas_GetMapList`）。地圖選單依 `YA_MAPS_ORDER`（資料片順序）排列。

產生器是 `tools/yatlas_data.py`，各版本的設定在 `tools/flavors.py`，見 [`tools/README.md`](../tools/README.md)。所有資料表的格式與 Mists 版本相同（第二～四節）。

### 各版本的差異

**Classic Era（1.15.9）**
- 地圖：東部王國（uiMap 1415）、卡林多（1414）。Classic 用戶端的大陸 uiMapID 與正式版不同（正式版是 13／12）。
- 副本入口：用戶端 `AreaTrigger` ＋ [AzerothCore `areatrigger_teleport`](https://github.com/azerothcore/azerothcore-wotlk/blob/master/data/sql/base/db_world/areatrigger_teleport.sql)；缺漏的用 1.13.0.28211 的 `Map.Corpse_*` 補上。
- 手動修正：納克薩瑪斯（533）的入口座標取 AreaTrigger 4055（東瘟疫之地上空的入口）。AzerothCore 是巫妖王版本，納克薩瑪斯已搬到北裂境，所以沒有對應的傳送資料。
- 排除：測試地圖與舊血色修道院（13、29、44、169、598）。
- **探索賽季（Season of Discovery）**的專屬地圖在用戶端中沒有入口資料，目前不列出。

**Anniversary（2.5.6）**
- 地圖：東部王國、卡林多、外域（uiMap 1945）。
- 副本入口的來源與 Classic Era 相同，加上外域的 AreaTrigger。

**Mists of Pandaria Classic（5.5.4）**
- 與 v0.9.6 的 `Data/mapdb.lua`、`Data/mapdb2.lua` 逐表比對完全相同，只是搬到 `Data/Mists/`。詳細說明見第一～四節。

**正式版（12.1.5）**
- 地圖（28 張，遊戲內會顯示在地化名稱）：Eastern Kingdoms、Kalimdor、Outland、Northrend、Deepholm、Tol Barad、Pandaria、Isle of Thunder、Draenor、Broken Isles、Argus、Zandalar、Kul Tiras、Nazjatar、The Shadowlands、Zereth Mortis、Dragon Isles、The Forbidden Reach、Zaralek Cavern、Emerald Dream、Khaz Algar (Surface)、Khaz Algar、Undermine、Siren Isle、K'aresh、Harandar、Voidstorm、Darkmoon Island。名單是依 `Map.db2` 有小地圖圖塊、且有對應大陸 UiMap 的地圖挑選的。
- 東部王國的圖塊包含 Midnight 新增的奎爾薩拉斯（共 1176 張）。
- 副本入口：主要用 `JournalInstanceEntrance` ＋ `JournalInstance`（只有正式版用戶端有這兩張表），再用正式版 `Map.db2` 本身的 `Corpse_0/Corpse_1` 補缺。
- 為了控制檔案大小，`Yatlas_areadb` 與 `Yatlas_mapareas` 只保留上述 28 張地圖用得到的區域。

### 城鎮與主城（`Yatlas_cities`，v1.0.0 新增）

原版 Yatlas 的 `Yatlas_towns2` 只收錄「其他城鎮」（小據點）。主要城鎮與主城原本交給遊戲 API（當年的 `GetMapLandmarkInfo`，現在的 `C_AreaPoiInfo`），並以 Yatlas 自己的藍色圓圈與星星圖示繪製。新版用戶端的情況是：

- **Classic Era／Anniversary**：[`AreaPOI`](https://wago.tools/db2/AreaPOI?build=1.15.9.70003) 的城鎮（Flags 13）與主城（Flags 29）仍會由 `C_AreaPoiInfo.GetAreaPOIForMap` 回傳，因此舊的藍圈與星星只出現在這兩個版本。
- **MoP Classic／正式版**：同樣的資料列還在，但多了 Flags 512（世界地圖不顯示），API 不回傳，所以主要城鎮原本完全沒有標示。

現在由 `tools/yatlas_data.py` 從各版本的 `AreaPOI.db2` 產生 `Yatlas_cities`，格式是 `{名稱, worldY, worldX, AreaPOI ID, 種類, AreaTable ID, POIIcons 編號}`：

- 種類：Flags（去掉 512 與 128）為 13 時是城鎮；為 29 時，如果 Icon 是主城圖示（Era／TBC 為 5，其他版本為 6 或 46～49）就是主城，否則是城鎮（例如 TBC 的 Thrallmar）。其他圖示（例如暗月馬戲團 181）不收錄。
- 排除：有 `UiTextureAtlasMemberID`（已由 API 以 atlas 顯示）、有 `PlayerConditionID`，以及所在區域已搬到其他地圖或是舊版副本（例如 Midnight 中的「Silvermoon City (Burning Crusade)」）的資料列。
- 名稱：`AreaPOI.AreaID` 是所在地區而不是城鎮本身，所以用名稱比對 `AreaTable` 取得 ID，在遊戲中以 `C_Map.GetAreaInfo` 換成在地化名稱。比對不到的保留英文名稱。
- 圖示：城鎮用 `poi-town`，主城用 `poi-majorcity`，四個用戶端都有這兩個 atlas。正式版的主城在 `AreaPOI.Icon` 中是陣營圖示（POIIcons 46～49，聯盟 46、部落 48），和遊戲世界地圖一樣以 `C_Minimap.GetPOITextureCoords` 繪製陣營圖示。
- 去重：`Yatlas_towns2` 中與 `Yatlas_cities` 相距 80 碼以內的項目會在產生時移除。執行時 `Yatlas_LoadLandmarks` 會略過 `Yatlas_cities` 已有的 AreaPOI ID。

| 用戶端 | 城鎮 | 主城 |
|---|---|---|
| Classic Era | 33 | 6 |
| Anniversary | 60 | 9 |
| MoP Classic | 115 | 10 |
| 正式版 | 62 | 6 |

其他仍由 API 回傳、沒有 atlas 的 POI，改用遊戲世界地圖相同的 `Interface\Minimap\POIIcons` 與 `C_Minimap.GetPOITextureCoords(textureIndex)` 繪製，不再套用舊的圓圈和星星。

### API 檢視（四個用戶端）

以 [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source) 對應組建的 `Blizzard_APIDocumentationGenerated` 為準：

- 四個用戶端都有：`C_Map`、`C_TaxiMap`、`C_AreaPoiInfo`、`C_ClassColor`、`UIDropDownMenu`、`BackdropTemplate`、`C_EncounterJournal.GetDungeonEntrancesForMap`，以及 Yatlas 用到的 atlas（`Dungeon`、`Raid`、`TaxiNode_*`、`WhiteCircle-RaidBlips`、`poi-town`）與 `Interface\WorldMap\WorldMapArrow`。
- 正式版把 `Dungeon`／`Raid` atlas 換成 50×50 的高解析版本（[UiTextureAtlasMember](https://wago.tools/db2/UiTextureAtlasMember?build=12.1.5.70575) 的 OverrideWidth 為 32；Classic 為 22×22），`TaxiNode_*` 從 18 變成 21。用同樣的尺寸繪製時圖案明顯較小，所以 `Yatlas_AtlasScale(atlas)` 依 `C_Texture.GetAtlasInfo` 的寬度和 Classic 尺寸的比例放大（上限 1.6 倍）。
- 正式版沒有全域函式 `MouseIsOver()`，改用 `Region:IsMouseOver()`（四個用戶端都有）。
- 正式版的「秘密值（secret values）」：`UnitName`、`UnitClass`、`UnitIsUnit` 在受限內容中可能回傳秘密值，不能拿來比較、做布林判斷或當作表格鍵值。`Core/Compat.lua` 新增 `Yatlas_NotSecret(v)`（以 `issecretvalue` 判斷），隊友的職業顏色與「是否為玩家本人」都先經過這個檢查。`FontString:SetText` 可以直接接受秘密值，所以名稱顯示不必處理。`UnitPosition`、`GetPlayerFacing`、`C_Map.GetPlayerMapPosition` 沒有秘密回傳值。
- `SetupFullscreenScale` 在四個用戶端都不存在，程式原本就有檢查。

以下第一～四節是 v0.9.4～v0.9.6 針對 MoP Classic 5.5.4 的原始分析，現在對應 `Data/Mists/`。

## Yatlas 資料更新與 API 檢視：WoW MoP Classic 5.5.4.70579

原始分析日期：2026-10-25　目標用戶端：`wow_classic` 5.5.4.70579（目前正式服最新組建，TOC Interface `50504`）

> 註：自 0.9.6 起檔案已重新整理目錄：`Compat.lua`、`Points.lua`、`Yatlas.lua` 移到 `Core/`（`Yatlas.lua` 改名為 `Core.lua`），`mapdb.lua`、`mapdb2.lua` 移到 `Data/`，`sets/` 改名為 `Modules/`，`images/` 改名為 `Images/`。本文以下仍沿用 0.9.4 當時的檔名。

## 一、資料表對應總覽

| Yatlas 資料表 | 舊來源 (≤ 6.2) | 5.5.4 來源 | 狀態 |
|---|---|---|---|
| `Yatlas_WorldMapIds2` | Map.dbc | `Map` DB2 | 重新產生，共 290 張地圖；`[Directory] = MapID` |
| `Yatlas_mapdb1` | 手動從 `World\Minimaps\` 取出 | 每張地圖 WDT 的 `MAID` chunk（第 8 欄 = minimap texture FileDataID） | 重新產生；值改為 **FileDataID 數字** |
| `Yatlas_areadb` | AreaTable.dbc + LibBabble-SubZone | `AreaTable` DB2（enUS）＋載入時 `C_Map.GetAreaInfo(id)` 在地化 | 重新產生 4078 筆，不再需要 LibBabble |
| `Yatlas_mapareas` | **WorldMapArea.dbc（8.0 起已移除）** | **`UiMapAssignment` + `UiMap`** | 重新產生 17 張地圖、123 個區域 |
| `Yatlas_UiMapIds`（新增） | — | `UiMap` | `[Directory][areaID] = uiMapID`，供 C_Map API 使用 |
| `Yatlas_ZoneIds` | 手動，需與 `GetMapZones()` 對齊 | `UiMap` 階層＋`UiMapAssignment.MapID` | 重新產生；`GetMapZones()` 已不存在 |
| `Yatlas_WorldMapIds` | `SetMapZoom()` 的大陸索引 1..6 | uiMapID | 值改為 uiMapID（13/12/1467/113/424/207/244/504/407）；外域在 5.5.4 是 1467（沒有 101，987 是不在地圖樹內的孤立項目） |
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
- 舊資料中的 110 個 `noLiquid_mapXX_YY` 在新版都成為一般圖塊。舊有的「mocking up」海洋填補圖塊原本保留並改成新的 FileDataID，v1.0.0 起已全部移除，沒有圖塊的位置一律顯示為黑色。
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
5. 格式為 `{name, worldY, worldX, instanceMapID, instanceType}`，第 4、5 欄是新增的。名稱在載入時用 `GetRealZoneText(mapID)` 換成在地化名稱；`instanceType` 取自 `Map.db2` 的 `InstanceType`（1 = 地城、2 = 團隊副本），用來選擇圖示：地城用 atlas `Dungeon`（藍色圓圈），團隊副本用 `Raid`（綠色圓圈），兩者都在 5.5.4 的 `UiTextureAtlasMember` 中。城鎮（`Yatlas_towns2`）改用 atlas `poi-town`。

### Yatlas_taxinodes（飛行點，0.9.4 新增）
1. 來源：用戶端 [`TaxiNodes`（5.5.4.70579）](https://wago.tools/db2/TaxiNodes?build=5.5.4.70579) 的 `Pos_0/Pos_1/ContinentID/Flags/ConditionID`，由 `tools/gen.py`（現為 `tools/yatlas_data.py`）產生到 `mapdb2.lua`。
2. 篩選：只保留 Yatlas 支援的大陸、`Flags & 3`（聯盟/部落可用）有設定，且排除 `Flags & 0x80` 的節點。共 337 筆：東部王國 108、卡林多 89、北裂境 52、潘達利亞 51、外域 37。
3. 格式為 `{name, worldY, worldX, nodeID, faction, conditional}`：`faction` 採用 `Enum.FlightPathFaction`（0 = 中立、1 = 部落、2 = 聯盟）；`ConditionID ≠ 0` 的節點標記為 `conditional`。
4. 執行期：`Compat.lua` 的 `Yatlas_GetTaxiInfo()` 呼叫 `C_TaxiMap.GetTaxiNodesForMap(uiMapID)`，取得在地化名稱、是否已探索及 atlas。API 沒有回傳資料時，使用靜態的英文名稱。條件式節點只在 API 有列出時才顯示。
5. 只顯示中立與玩家所屬陣營的節點，做法與 Blizzard 的 FlightPointDataProvider 相同。未探索的節點以半透明灰色顯示。
6. 注意：MoP Classic 的世界地圖中，FlightPointDataProvider 被註解掉了，所以 `C_TaxiMap` 在 Classic 中的實際回傳內容尚待遊戲內確認。

### Yatlas_graveyards（0.9.4 起停用）
- `WorldSafeLocs` 在現代用戶端只存在伺服器端，5.5.4 的 DB2 與 wago.tools 都沒有這個表，因此**目前沒有任何來自遊戲資料檔的墓地座標**。
- 先前的版本曾沿用 git 歷史中 6.0（19005）的舊資料，但那不是 5.5.4 用戶端的資料，無法確認是否正確，因此改為停用：
  - `sets/index.xml` 不再載入 `sets/graveyards.lua`（檔案保留，方便日後恢復）。
  - `mapdb.lua` 的 `Yatlas_graveyards` 改為空表；`mapdb2.lua` 的 `YA_BL_gy()` 黑名單一併移除；產生器也不再產生墓地資料。
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
- 移除 `LibBabble-SubZone-3.0`、`AceLocale-3.0`、`LibStub`：`Libs/`、`Locale/LibBabble.lua`、`.pkgmeta` 的 externals 都已刪除，`OptionalDeps` 只留 `myAddOns`（v1.0.0 也已移除，見下）。

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
