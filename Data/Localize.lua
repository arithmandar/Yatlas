-- Localize the enUS names of the loaded data with the client's own tables
-- (replaces LibBabble-SubZone-3.0). Runs after the flavour data in Data/Data.xml.
if not Yatlas_mapdb1 then
	-- No data for this client (see YATLAS_CLIENT in Core/Constants.lua).
	-- Define empty tables so the rest of the addon loads; the frames refuse to open.
	YATLAS_NO_DATA = true;
	Yatlas_mapdb1, Yatlas_areadb, Yatlas_mapareas = {}, {}, {};
	Yatlas_UiMapIds, Yatlas_WorldMapIds, Yatlas_WorldMapIds2, Yatlas_ZoneIds = {}, {}, {}, {};
	Yatlas_instances, Yatlas_taxinodes, Yatlas_towns2 = {}, {}, {};
	YA_MAPS, YA_MAPS_ORDER = {}, {};
	return;
end

if C_Map and C_Map.GetAreaInfo then
	-- area names (AreaTable)
	for id in pairs(Yatlas_areadb) do
		local name = C_Map.GetAreaInfo(id);
		if name and name ~= "" then Yatlas_areadb[id] = name; end
	end
	-- town names (4th field = AreaTable ID)
	for _, towns in pairs(Yatlas_towns2) do
		for _, v in ipairs(towns) do
			local name = v[4] and C_Map.GetAreaInfo(v[4]);
			if name and name ~= "" then v[1] = name; end
		end
	end
end

-- instance names (Map table)
if GetRealZoneText then
	for _, list in pairs(Yatlas_instances) do
		for _, v in ipairs(list) do
			local name = GetRealZoneText(v[4]);
			if name and name ~= "" then v[1] = name; end
		end
	end
end
