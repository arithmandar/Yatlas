-- Minimal WoW UI mock for load testing Yatlas (not a full emulation)
MOCK = {missing = {}, errors = {}, frames = {}, regions = {}, events = {}};
local missing = MOCK.missing;

local W = {};       -- widget methods
W.__index = function(t, k)
    local v = rawget(W, k);
    if v ~= nil then return v; end
    return nil;
end

local function new(otype, name, parent)
    local o = setmetatable({_type = otype, _name = name, _parent = parent, _points = {},
        _shown = true, _scripts = {}, _level = parent and ((parent._level or 0) + 1) or 0,
        _w = 0, _h = 0, _children = {}}, W);
    if parent then table.insert(parent._children, o); end
    if name then _G[name] = o; end
    return o;
end
MOCK.new = new;

function W:GetName() return self._name; end
function W:GetParent() return self._parent; end
function W:SetParent(p) self._parent = p; end
function W:GetObjectType() return self._type; end
function W:IsObjectType(t) return self._type == t; end
function W:SetPoint(p, rel, rp, x, y)
    if type(rel) == "number" then rel, rp, x, y = self._parent, p, rel, rp; end
    if type(rel) == "string" then rel = _G[rel]; end
    table.insert(self._points, {p, rel, rp or p, x or 0, y or 0});
end
function W:ClearAllPoints() self._points = {}; end
function W:SetAllPoints(rel) self._allpoints = rel or self._parent; end
function W:GetNumPoints() return #self._points; end
function W:SetSize(w, h) self._w, self._h = w, h; end
function W:SetWidth(w) self._w = w; end
function W:SetHeight(h) self._h = h; end
function W:GetWidth() return self._w; end
function W:GetHeight() return self._h; end
function W:GetSize() return self._w, self._h; end
function W:GetCenter() return 0, 0; end
function W:GetLeft() return 0; end
function W:GetTop() return 0; end
function W:GetRight() return self._w; end
function W:GetBottom() return 0; end
function W:GetEffectiveScale() return 1; end
function W:GetScale() return 1; end
function W:Show()
    local was = self._shown; self._shown = true;
    if not was then self:_run("OnShow"); end
end
function W:Hide()
    local was = self._shown; self._shown = false;
    if was then self:_run("OnHide"); end
end
function W:SetShown(s) if s then self:Show() else self:Hide() end end
function W:IsShown() return self._shown; end
function W:IsVisible()
    local f = self;
    while f do if not f._shown then return false end f = f._parent; end
    return true;
end
function W:SetScript(h, fn) self._scripts[h] = fn; end
function W:GetScript(h) return self._scripts[h]; end
function W:HookScript(h, fn)
    local old = self._scripts[h];
    self._scripts[h] = function(...) if old then old(...) end fn(...) end;
end
function W:HasScript() return true; end
function W:_run(h, ...)
    local fn = self._scripts[h];
    if fn then
        local ok, err = pcall(fn, self, ...);
        if not ok then table.insert(MOCK.errors, (self._name or "?")..":"..h..": "..tostring(err)); end
    end
end
MOCK.evorder = {};
function W:RegisterEvent(e) self._events = self._events or {}; self._events[e] = true; if not MOCK.events[self] then MOCK.events[self] = true; table.insert(MOCK.evorder, self); end end
function W:UnregisterEvent(e) if self._events then self._events[e] = nil end end
function W:RegisterUnitEvent(e) self:RegisterEvent(e); end
function W:UnregisterAllEvents() self._events = {}; end
function W:IsEventRegistered(e) return self._events and self._events[e]; end
function W:GetFrameLevel() return self._level; end
function W:SetFrameLevel(l) self._level = l; end
function W:SetFrameStrata(s) self._strata = s; end
function W:GetFrameStrata() return self._strata or (self._parent and self._parent:GetFrameStrata()) or "MEDIUM"; end
function W:SetText(t) self._text = t; end
function W:GetText() return self._text; end
function W:SetFormattedText(f, ...) self._text = string.format(f, ...); end
function W:GetStringWidth() return self._text and #tostring(self._text) * 6 or 0; end
function W:SetTexture(t) self._texture = t; return true; end
function W:GetTexture() return self._texture; end
function W:SetAtlas(a) self._atlas = a; end
function W:SetNormalTexture(t) self._normal = t; end
function W:SetPushedTexture(t) self._pushed = t; end
function W:SetDisabledTexture(t) self._disabled = t; end
function W:SetHighlightTexture(t, m) self._highlight = t; self._hlmode = m; end
function W:GetNormalTexture() self._normalT = self._normalT or new("Texture", nil, self); return self._normalT; end
function W:GetPushedTexture() self._pushedT = self._pushedT or new("Texture", nil, self); return self._pushedT; end
function W:GetHighlightTexture() self._hlT = self._hlT or new("Texture", nil, self); return self._hlT; end
function W:SetChecked(c) self._checked = c and true or false; end
function W:GetChecked() return self._checked; end
function W:SetMinMaxValues(a, b) self._min, self._max = a, b; if (self._value or 0) < a then self._value = a end if (self._value or 0) > b then self._value = b end end
function W:GetMinMaxValues() return self._min, self._max; end
function W:SetValue(v)
    if self._min then v = math.max(self._min, math.min(self._max, v)); end
    local changed = v ~= self._value; self._value = v;
    if changed then self:_run("OnValueChanged", v, true); end
end
function W:GetValue() return self._value or 0; end
function W:GetID() return self._id or 0; end
function W:SetID(i) self._id = i; end
function W:IsMouseOver() return false; end
function W:IsMouseEnabled() return self._mouse; end
function W:EnableMouse(e) self._mouse = e; end
function W:SetAlpha(a) self._alpha = a; end
function W:GetAlpha() return self._alpha or 1; end
function W:CreateTexture(name, layer, template)
    if name then name = name:gsub("%$parent", self._name or ""); end
    local t = new("Texture", name, self); t._layer = layer; table.insert(MOCK.regions, t); return t;
end
function W:CreateFontString(name, layer, template)
    if name then name = name:gsub("%$parent", self._name or ""); end
    local t = new("FontString", name, self); t._layer = layer; t._font = template; table.insert(MOCK.regions, t); return t;
end
function W:CreateMaskTexture(name) return self:CreateTexture(name); end
function W:SetFontObject(f) self._fontobj = f; end
function W:GetRegions() return unpack(self._children); end
function W:GetChildren() local r = {}; for _,c in ipairs(self._children) do if c._type ~= "Texture" and c._type ~= "FontString" then r[#r+1] = c end end return unpack(r); end
function W:SetTexCoord(...) self._texcoord = {...}; end
function W:SetVertexColor(...) self._vc = {...}; end
function W:GetVertexColor() return 1, 1, 1, 1; end
function W:SetTextColor(...) self._tc = {...}; end
function W:SetDesaturated(d) self._desat = d; end
function W:SetBackdrop(b) self._backdrop = b; end
function W:SetBackdropColor(...) self._bdc = {...}; end
function W:SetBackdropBorderColor(...) self._bdbc = {...}; end
function W:ApplyBackdrop() end
function W:SetJustifyH(j) self._justifyH = j; end
function W:SetJustifyV(j) self._justifyV = j; end
function W:SetMovable(m) self._movable = m; end
function W:IsMovable() return self._movable; end
function W:SetToplevel(t) self._toplevel = t; end
function W:SetClampedToScreen(c) self._clamped = c; end
function W:StartMoving() self._moving = true; end
function W:StopMovingOrSizing() self._moving = false; end
function W:RegisterForDrag(...) self._drag = {...}; end
function W:RegisterForClicks(...) self._clicks = {...}; end
function W:LockHighlight() end
function W:UnlockHighlight() end
function W:SetValueStep(s) self._step = s; end
function W:SetObeyStepOnDrag(o) end
function W:SetOrientation(o) end
function W:SetThumbTexture(t) end
function W:SetShadowOffset() end
function W:SetShadowColor() end
function W:SetFont() return true; end
function W:SetDrawLayer(l) self._layer = l; end
function W:SetBlendMode(m) self._blend = m; end
function W:SetRotation(r) self._rot = r; end
function W:Enable() self._enabled = true; end
function W:Disable() self._enabled = false; end
function W:IsEnabled() return self._enabled ~= false; end
function W:SetEnabled(e) self._enabled = e; end
function W:SetHitRectInsets() end
function W:SetIgnoreParentAlpha() end
function W:SetMouseClickEnabled() end
function W:SetMouseMotionEnabled() end
function W:EnableMouseWheel(e) self._wheel = e; end
function W:SetPropagateKeyboardInput() end
function W:SetWordWrap() end
function W:SetNonSpaceWrap() end
function W:SetMaxLines() end
function W:SetHighlightLocked() end
function W:Raise() end
function W:Lower() end
function W:SetUserPlaced() end
function W:IsUserPlaced() return false; end
function W:SetDontSavePosition() end
function W:SetFixedFrameStrata() end
function W:SetFixedFrameLevel() end
function W:SetScale(s) self._scale = s; end
function W:GetPoint(i) local p = self._points[i or 1]; if p then return unpack(p) end end
function W:GetDebugName() return self._name or "anon"; end
function W:SetFrameRef() end
function W:SetAttribute(k, v) self._attr = self._attr or {}; self._attr[k] = v; end
function W:GetAttribute(k) return self._attr and self._attr[k]; end

local function applyTemplate(f, template)
    if not template then return; end
    for t in template:gmatch("[^,%s]+") do
        local n = f._name;
        if t == "UIDropDownMenuTemplate" then
            if n then
                f:CreateFontString(n.."Text"); f:CreateTexture(n.."Left"); f:CreateTexture(n.."Middle"); f:CreateTexture(n.."Right");
                new("Button", n.."Button", f); f:CreateTexture(n.."Icon");
            end
            f.Text = n and _G[n.."Text"];
        elseif t == "OptionsSliderTemplate" or t == "UISliderTemplate" then
            if n then f:CreateFontString(n.."Text"); f:CreateFontString(n.."Low"); f:CreateFontString(n.."High"); end
        elseif t == "UICheckButtonTemplate" then
            if n then f.text = f:CreateFontString(n.."Text"); f.Text = f.text; end
        elseif t == "UIPanelCloseButton" then
            f._w, f._h = 32, 32;
        elseif t == "UIPanelButtonTemplate" or t == "GameMenuButtonTemplate" then
            if n then f:CreateFontString(n.."Text"); end
        elseif t == "BackdropTemplate" then
            f._backdropTemplate = true;
        else
            MOCK.unknownTemplates = MOCK.unknownTemplates or {};
            MOCK.unknownTemplates[t] = true;
        end
    end
end

function CreateFrame(otype, name, parent, template, id)
    if type(parent) == "string" then parent = _G[parent]; end
    local f = new(otype, name, parent);
    f._template = template;
    table.insert(MOCK.frames, f);
    applyTemplate(f, template);
    if id then f._id = id; end
    return f;
end

UIParent = new("Frame", "UIParent", nil); UIParent._w, UIParent._h = 1920, 1080;
WorldFrame = new("Frame", "WorldFrame", nil);
Minimap = new("Frame", "Minimap", UIParent); Minimap._w, Minimap._h = 198, 198;
WorldMapFrame = new("Frame", "WorldMapFrame", UIParent); WorldMapFrame._shown = false;
GameTooltip = new("GameTooltip", "GameTooltip", UIParent); GameTooltip._shown = false;
function GameTooltip:SetOwner(o, a) self._owner = o; end
function GameTooltip:AddLine(t) end
function GameTooltip:AddDoubleLine() end
function GameTooltip:NumLines() return 0; end
function GameTooltip:IsOwned(o) return self._owner == o; end
function GameTooltip:ClearLines() end
DEFAULT_CHAT_FRAME = new("Frame", "DEFAULT_CHAT_FRAME", UIParent);
function DEFAULT_CHAT_FRAME:AddMessage(m) table.insert(MOCK.chat, tostring(m)); end
MOCK.chat = {};
GameFontNormal = {}; GameFontHighlight = {}; GameFontNormalSmall = {}; GameFontHighlightSmall = {};
GameFontGreenSmall = {}; GameFontDisable = {}; GameFontWhite = {}; GameFontNormalLarge = {};
NumberFontNormal = {}; GameFontHighlightLarge = {};

UISpecialFrames = {}; UIPanelWindows = {};
HIGHLIGHT_FONT_COLOR = {r = 1, g = 1, b = 1}; NORMAL_FONT_COLOR = {r = 1, g = 0.82, b = 0};
TOOLTIP_DEFAULT_COLOR = {r = 1, g = 1, b = 1}; TOOLTIP_DEFAULT_BACKGROUND_COLOR = {r = 0, g = 0, b = 0};
RAID_CLASS_COLORS = setmetatable({}, {__index = function() return {r = 1, g = 1, b = 1} end});
CLOSE = "Close"; OKAY = "Okay"; CONTINENT = "Continent"; ZONE = "Zone"; LOW = "Low"; HIGH = "High";
NONE = "None"; UNKNOWN = "Unknown"; ALL = "All";
SlashCmdList = {}; hash_SlashCmdList = {};
UIDROPDOWNMENU_MENU_LEVEL = 1; UIDROPDOWNMENU_MENU_VALUE = nil; UIDROPDOWNMENU_OPEN_MENU = nil;

MOCK.ddButtons = 0;
function UIDropDownMenu_Initialize(f, init, disp, level)
    f._init = init;
    local ok, err = pcall(init, f, level or 1);
    if not ok then table.insert(MOCK.errors, "UIDropDownMenu_Initialize "..tostring(f._name)..": "..tostring(err)); end
end
function UIDropDownMenu_AddButton(info, level) MOCK.ddButtons = MOCK.ddButtons + 1; MOCK.lastdd = info; end
function UIDropDownMenu_CreateInfo() return {}; end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_SetSelectedID(f, id) f._selid = id; end
function UIDropDownMenu_SetSelectedValue(f, v) f._selval = v; end
function UIDropDownMenu_SetSelectedName(f, v) f._selname = v; end
function UIDropDownMenu_GetSelectedID(f) return f._selid; end
function UIDropDownMenu_GetSelectedValue(f) return f._selval; end
function UIDropDownMenu_SetText(f, t) f._ddtext = t; end
function UIDropDownMenu_GetText(f) return f._ddtext; end
function UIDropDownMenu_Refresh() end
function UIDropDownMenu_EnableDropDown() end
function UIDropDownMenu_DisableDropDown() end
function ToggleDropDownMenu(level, value, frame) MOCK.toggled = (MOCK.toggled or 0) + 1;
    if frame and frame._init then UIDROPDOWNMENU_MENU_LEVEL = level or 1; UIDROPDOWNMENU_MENU_VALUE = value;
        local ok, err = pcall(frame._init, frame, level or 1); if not ok then table.insert(MOCK.errors, "ToggleDropDownMenu: "..tostring(err)); end
        UIDROPDOWNMENU_MENU_LEVEL = 1; end
end
function CloseDropDownMenus() end
function UIDropDownMenu_SetButtonWidth() end
function UIDropDownMenu_ClearAll(f) f._selid = nil; f._selval = nil; end
function UIDropDownMenu_JustifyText() end
function UnitPosition(u) if u == "player" then return -9000, 300, 0, 0 end end
function GetPlayerFacing() return 0; end
SOUNDKIT = setmetatable({}, {__index = function(t, k) return 1 end});
getn = table.getn; table.getn = table.getn or function(t) return #t end; getn = table.getn;
foreach = table.foreach; foreachi = table.foreachi;
function ShowUIPanel(f) f:Show(); end
function HideUIPanel(f) f:Hide(); end
function PlaySound() end
function PlaySoundFile() end
function GetTime() return MOCK.time or 100; end
function GetCursorPosition() return 500, 500; end
function IsShiftKeyDown() return MOCK.shift; end
function IsControlKeyDown() return false; end
function IsAltKeyDown() return false; end
function InCombatLockdown() return false; end
function GetLocale() return "enUS"; end
function GetBuildInfo() return MOCK.build, "1", "Oct 1 2026", MOCK.toc; end
function GetAddOnMetadata(a, k) return ({Version = "1.1.0", Author = "arithmandar", ["X-Date"] = "2026-10-27", Title = "Yatlas"})[k]; end
C_AddOns = {GetAddOnMetadata = GetAddOnMetadata, IsAddOnLoaded = function() return false end, LoadAddOn = function() end};
function IsAddOnLoaded() return false; end
function UnitName(u) return u == "player" and "Tester" or nil; end
function UnitClass(u) return "Warrior", "WARRIOR", 1; end
function UnitFactionGroup() return "Alliance", "Alliance"; end
function UnitIsConnected() return true; end
function UnitInParty() return false; end
function UnitInRaid() return nil; end
function UnitExists(u) return u == "player"; end
function UnitIsUnit(a, b) return a == b; end
function UnitLevel() return 60; end
function UnitRace() return "Human", "Human"; end
function UnitGUID() return "Player-1-0001"; end
function IsInGroup() return false; end
function IsInRaid() return false; end
function GetNumGroupMembers() return 0; end
function GetNumSubgroupMembers() return 0; end
function GetRealZoneText(id) return "Zone"..tostring(id or ""); end
function GetZoneText() return "Elwynn Forest"; end
function GetSubZoneText() return ""; end
function GetMinimapZoneText() return "Goldshire"; end
function IsInInstance() return false, "none"; end
function GetInstanceInfo() return "Eastern Kingdoms", "none", 0, "", 5, 0, false, 0, 0; end
function GetCVar() return "0"; end
function GetCVarBool() return false; end
function SetCVar() end
function hooksecurefunc(t, n, fn) if type(t) == "string" then fn = n; n = t; t = _G; end local old = t[n]; t[n] = function(...) local r = {old(...)}; fn(...); return unpack(r); end end
function securecall(fn, ...) if type(fn) == "string" then fn = _G[fn] end return fn(...); end
function geterrorhandler() return function(e) table.insert(MOCK.errors, "errorhandler: "..tostring(e)) end; end
function seterrorhandler() end
function GetScreenWidth() return 1920; end
function GetScreenHeight() return 1080; end
function GetMouseFocus() return nil; end
function GetMouseFoci() return {}; end
function RegisterAddonMessagePrefix() end
C_ChatInfo = {RegisterAddonMessagePrefix = function() end, SendAddonMessage = function() end};
function SendAddonMessage() end
function GetNumTaxiNodes() return 0; end
function format(...) return string.format(...); end
strfind = string.find; strsub = string.sub; strlen = string.len; strlower = string.lower; strupper = string.upper;
strsplit = function(d, s, n) local r = {}; for p in (s..d):gmatch("(.-)"..d:gsub("%p","%%%0")) do r[#r+1] = p end return unpack(r); end
strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")); end
gsub = string.gsub; strrep = string.rep; strbyte = string.byte; strchar = string.char; strmatch = string.match; gmatch = string.gmatch;
tinsert = table.insert; tremove = table.remove; wipe = function(t) for k in pairs(t) do t[k] = nil end return t; end
table.wipe = wipe; sort = table.sort; tContains = function(t, v) for _,x in pairs(t) do if x == v then return true end end return false; end
floor = math.floor; ceil = math.ceil; abs = math.abs; max = math.max; min = math.min; sqrt = math.sqrt; mod = math.fmod;
sin = function(d) return math.sin(math.rad(d)); end; cos = function(d) return math.cos(math.rad(d)); end
atan2 = function(y, x) return math.deg(math.atan2(y, x)); end; deg = math.deg; rad = math.rad; random = math.random;
date = os.date; time = os.time;
Mixin = function(o, ...) for _,m in ipairs({...}) do for k,v in pairs(m) do o[k] = v end end return o; end
CreateFromMixins = function(...) return Mixin({}, ...); end
CreateColor = function(r, g, b, a) return {r = r, g = g, b = b, a = a, GetRGB = function(s) return s.r, s.g, s.b end}; end
CreateVector2D = function(x, y) return {x = x, y = y, GetXY = function(s) return s.x, s.y end}; end
BackdropTemplateMixin = {};
Enum = {UIMapType = {Cosmic = 0, World = 1, Continent = 2, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6}};

-- C_Map: a tiny world with Eastern Kingdoms 1415 (map 0) / Elwynn 1429
C_Map = {
    GetBestMapForUnit = function(u) return MOCK.playerMap; end,
    GetPlayerMapPosition = function(m, u) if MOCK.playerMap then return CreateVector2D(0.5, 0.5) end end,
    GetMapInfo = function(id) return {mapID = id, name = "Map"..id, mapType = 3, parentMapID = 1415}; end,
    GetAreaInfo = function(id) return "Area"..id; end,
    GetWorldPosFromMapPos = function(m, pos) return 0, CreateVector2D(-9000, 300); end,
    GetMapPosFromWorldPos = function(c, pos, m) return m, CreateVector2D(0.5, 0.5); end,
    GetMapChildrenInfo = function() return {}; end,
    GetMapGroupID = function() return nil; end,
    GetMapArtID = function() return 1; end,
};
C_Texture = {GetAtlasInfo = function(a) return {width = 32, height = 32, file = 1, leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1}; end};
C_TaxiMap = {GetTaxiNodesForMap = function() return {}; end, GetAllTaxiNodes = function() return {}; end};
C_AreaPoiInfo = {GetAreaPOIForMap = function() return {}; end, GetAreaPOIInfo = function() return nil; end,
    GetDelvesForMap = function() return {}; end, GetDragonridingRacesForMap = function() return {}; end};
C_DeathInfo = {GetGraveyardsForMap = function() return {}; end};
C_ClassColor = {GetClassColor = function() return CreateColor(1, 1, 1); end};
C_Minimap = {GetPOITextureCoords = function() return 0, 1, 0, 1; end};
C_Timer = {After = function(s, fn) MOCK.timers = MOCK.timers or {}; table.insert(MOCK.timers, fn); end,
    NewTicker = function() return {Cancel = function() end}; end, NewTimer = function() return {Cancel = function() end}; end};
C_CVar = {GetCVar = function() return "0" end, GetCVarBool = function() return false end};

function MOCK.fire(event, ...)
    local list = {};
    for _,f in ipairs(MOCK.evorder) do if f._events and f._events[event] then list[#list+1] = f end end
    for _,f in ipairs(list) do f:_run("OnEvent", event, ...); end
    return #list;
end

function MOCK.tick(n)
    for i = 1, n or 1 do
        MOCK.time = (MOCK.time or 100) + 0.1;
        for _,f in ipairs(MOCK.frames) do
            if f._scripts.OnUpdate and f:IsVisible() then f:_run("OnUpdate", 0.1); end
        end
    end
end

function MOCK.trackGlobals()
    setmetatable(_G, {__index = function(t, k)
        local info = debug.getinfo(2, "Sl");
        local where = info and (info.short_src..":"..(info.currentline or 0)) or "?";
        local key = tostring(k).." @ "..where;
        missing[key] = (missing[key] or 0) + 1;
        return nil;
    end});
end
