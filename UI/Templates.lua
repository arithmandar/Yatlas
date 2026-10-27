-- Frame factories shared by the Yatlas, options and minimap button frames.
-- This replaces UI\Templates.xml: every <Frame virtual="true"> template is now a function here.
-- Specs are plain tables; anchors are {point, relativeTo, relativePoint, x, y} where
-- relativeTo (a frame or a global frame name) defaults to the parent, relativePoint to point.
-- Texts that name a global string (YATLAS_TITLE, CLOSE, ...) are resolved to its value.

local _G = _G;

local function L(s)
    return s and (_G[s] or s);
end

local function resolve(v)
    if(type(v) == "string") then
        return _G[v];
    end
    return v;
end

function Yatlas_Anchor(region, anchor)
    if(not anchor) then
        return;
    end
    if(type(anchor[1]) == "table") then
        for _,a in ipairs(anchor) do
            Yatlas_Anchor(region, a);
        end
        return;
    end
    local point, rel, relPoint, x, y = unpack(anchor, 1, 5);
    region:SetPoint(point, resolve(rel) or region:GetParent(), relPoint or point, x or 0, y or 0);
end

-- spec: file, layer, name, size = {w, h}, anchor
function Yatlas_CreateTexture(parent, spec)
    local t = parent:CreateTexture(spec.name, spec.layer or "ARTWORK");
    if(spec.file) then
        t:SetTexture(spec.file);
    end
    if(spec.size) then
        t:SetSize(unpack(spec.size));
    end
    Yatlas_Anchor(t, spec.anchor);
    return t;
end

-- spec: name, layer, font, text, size, anchor, justify, color = {r, g, b}
function Yatlas_CreateText(parent, spec)
    local fs = parent:CreateFontString(spec.name, spec.layer or "ARTWORK");
    fs:SetFontObject(_G[spec.font or "GameFontNormal"]);
    if(spec.text) then
        fs:SetText(L(spec.text));
    end
    if(spec.size) then
        fs:SetSize(unpack(spec.size));
    end
    if(spec.justify) then
        fs:SetJustifyH(spec.justify);
    end
    if(spec.color) then
        fs:SetTextColor(unpack(spec.color));
    end
    Yatlas_Anchor(fs, spec.anchor);
    return fs;
end

-- Plain frame: name, parent, type, template, size, anchor, strata, level, hidden,
-- toplevel, movable, mouse, backdrop = <YATLAS_BACKDROP_*>, scripts = {OnX = fn}
function Yatlas_CreateFrame(spec)
    local template = spec.template;
    if(spec.backdrop) then
        template = template and (template..",BackdropTemplate") or "BackdropTemplate";
    end
    local f = CreateFrame(spec.type or "Frame", spec.name, spec.parent, template);
    if(spec.size) then
        f:SetSize(unpack(spec.size));
    end
    if(spec.strata) then
        f:SetFrameStrata(spec.strata);
    end
    if(spec.toplevel) then
        f:SetToplevel(true);
    end
    if(spec.movable) then
        f:SetMovable(true);
    end
    if(spec.mouse) then
        f:EnableMouse(true);
    end
    if(spec.backdrop) then
        Yatlas_ApplyBackdrop(f, spec.backdrop);
    end
    if(spec.allPoints) then
        f:SetAllPoints(spec.allPoints);
    end
    Yatlas_Anchor(f, spec.anchor);
    if(spec.raise) then
        f:SetFrameLevel(f:GetFrameLevel() + 4);
    end
    for _,e in ipairs(spec.events or {}) do
        f:RegisterEvent(e);
    end
    for h,fn in pairs(spec.scripts or {}) do
        f:SetScript(h, fn);
    end
    if(spec.hidden) then
        f:Hide();
    end
    return f;
end

-- ---------------------------------------------------------------------------
-- Tooltips of buttons
-- ---------------------------------------------------------------------------

-- Shared button tooltip: a title line and an optional wrapped description.
function Yatlas_ShowButtonTooltip(self, title, text, anchor)
    if(not title) then
        return;
    end
    GameTooltip:SetOwner(self, anchor or "ANCHOR_BOTTOMLEFT");
    GameTooltip:SetText(title, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
    if(text) then
        GameTooltip:AddLine(text, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true);
    end
    GameTooltip:Show();
end

local function hideTooltip()
    GameTooltip:Hide();
end

function YatlasFrameSwitchButton_OnEnter(self)
    if(self:GetParent() == BigYatlasFrame) then
        Yatlas_ShowButtonTooltip(self, YATLAS_SWITCH_TO_NORMAL);
    else
        Yatlas_ShowButtonTooltip(self, YATLAS_SWITCH_TO_BIG);
    end
end

-- Also called from OnClick so the tooltip follows the new lock state.
function YatlasFrameLockButton_OnEnter(self)
    if(not self:IsMouseOver()) then
        return;
    end
    if(YatlasFrame.opt and YatlasFrame.opt.Locked) then
        Yatlas_ShowButtonTooltip(self, YATLAS_TOOLTIP_LOCKED_TITLE, YATLAS_TOOLTIP_LOCKED);
    else
        Yatlas_ShowButtonTooltip(self, YATLAS_TOOLTIP_UNLOCKED_TITLE, YATLAS_TOOLTIP_UNLOCKED);
    end
end

-- ---------------------------------------------------------------------------
-- Buttons
-- ---------------------------------------------------------------------------

-- spec: name, parent, template, size, text, anchor, raise (frame level + 4), events,
--   tooltip = {title, text, anchor} (global string names), hideTooltip (OnLeave only),
--   onClick, onEnter, scripts = {OnX = fn},
--   textures = {normal, pushed, disabled, highlight} (highlight is added additively)
function Yatlas_CreateButton(spec)
    local b = Yatlas_CreateFrame{
        type = "Button", name = spec.name, parent = spec.parent, template = spec.template,
        size = spec.size, anchor = spec.anchor, raise = spec.raise, events = spec.events,
    };
    if(spec.text) then
        b:SetText(L(spec.text));
    end
    local tip = spec.tooltip;
    if(tip) then
        b:SetScript("OnEnter", function(self)
            Yatlas_ShowButtonTooltip(self, L(tip[1]), L(tip[2]), tip[3]);
        end);
    end
    if(tip or spec.hideTooltip or spec.onEnter) then
        b:SetScript("OnLeave", hideTooltip);
    end
    if(spec.onEnter) then
        b:SetScript("OnEnter", spec.onEnter);
    end
    if(spec.onClick) then
        b:SetScript("OnClick", spec.onClick);
    end
    for h,fn in pairs(spec.scripts or {}) do
        b:SetScript(h, fn);
    end
    local tex = spec.textures;
    if(tex) then
        if(tex.normal) then b:SetNormalTexture(tex.normal); end
        if(tex.pushed) then b:SetPushedTexture(tex.pushed); end
        if(tex.disabled) then b:SetDisabledTexture(tex.disabled); end
        if(tex.highlight) then b:SetHighlightTexture(tex.highlight, "ADD"); end
    end
    return b;
end

local HILIGHT_CLOSE = "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight";
local HILIGHT_MOUSE = "Interface\\Buttons\\UI-Common-MouseHilight";

function Yatlas_CreateCloseButton(name, parent, anchor, raise)
    return Yatlas_CreateButton{
        name = name, parent = parent, template = "UIPanelCloseButton", anchor = anchor,
        raise = raise, tooltip = {"CLOSE"},
    };
end

-- The button that toggles between the normal and the large frame
function Yatlas_CreateSwitchButton(name, parent, anchor, look)
    return Yatlas_CreateButton{
        name = name, parent = parent, size = {32, 32}, anchor = anchor, raise = true,
        onClick = function(self) Yatlas_SwitchFrame(self:GetParent()); end,
        onEnter = YatlasFrameSwitchButton_OnEnter,
        textures = {
            normal = "Interface\\Buttons\\UI-Panel-"..look.."Button-Up",
            pushed = "Interface\\Buttons\\UI-Panel-"..look.."Button-Down",
            highlight = HILIGHT_CLOSE,
        },
    };
end

function Yatlas_CreateLockButton(name, parent, anchor)
    return Yatlas_CreateButton{
        name = name, parent = parent, size = {32, 32}, anchor = anchor, raise = true,
        onClick = function(self)
            parent:ToggleLock();
            YatlasFrameLockButton_OnEnter(self);
        end,
        onEnter = YatlasFrameLockButton_OnEnter,
        -- the lock textures are set by YatlasFrameTemplate:UpdateLock
        textures = {highlight = HILIGHT_CLOSE},
    };
end

function Yatlas_CreatePlayerJumpButton(name, parent, anchor)
    return Yatlas_CreateButton{
        name = name, parent = parent, template = "UIPanelButtonTemplate", size = {108, 24},
        text = "YATLAS_PLAYERJUMP", anchor = anchor, raise = true, events = {"VARIABLES_LOADED"},
        onClick = function(self)
            if(IsShiftKeyDown()) then
                YatlasFramePlayerJumpButton_Toggle(self);
            else
                YatlasFramePlayerJumpButton_Jump(self);
            end
        end,
        onEnter = YatlasFramePlayerJumpButton_OnEnter,
        scripts = {
            OnEvent = YatlasFramePlayerJumpButton_Update,
            OnMouseUp = YatlasFramePlayerJumpButton_Update,
            OnShow = YatlasFramePlayerJumpButton_Update,
        },
    };
end

-- Map and zone drop-downs; load / event are the YatlasFrameDropDown*_OnLoad / _OnEvent functions.
-- label is the small caption above the box (only the large frame has one).
function Yatlas_CreateDropDown(name, parent, anchor, load, event, label)
    local d = Yatlas_CreateFrame{
        type = "Button", name = name, parent = parent, template = "UIDropDownMenuTemplate",
        anchor = anchor,
        scripts = {OnEvent = function(self, e) event(self, e); end},
    };
    if(label) then
        Yatlas_CreateText(d, {
            layer = "OVERLAY", font = "GameFontNormalSmall", text = label,
            anchor = {"TOPLEFT", nil, nil, 20, 10},
        });
    end
    load(d);
    return d;
end

-- "Show points" pulldown button with its (hidden) menu frame <name>DropDown
function Yatlas_CreateYFOO(name, parent, anchor)
    local b = Yatlas_CreateButton{
        name = name, parent = parent, size = {24, 24}, anchor = anchor, raise = true,
        onClick = YFOO_OnClick,
        tooltip = {"YATLAS_POINTS_SHOWPOINTS_TITLE", "YATLAS_TOOLTIP_SHOWPOINTS", "ANCHOR_LEFT"},
        textures = {
            normal = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
            pushed = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down",
            disabled = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled",
            highlight = HILIGHT_MOUSE,
        },
    };
    local d = Yatlas_CreateFrame{
        name = name.."DropDown", parent = b, template = "UIDropDownMenuTemplate",
        anchor = {"TOP", nil, nil, -80, -35}, hidden = true,
    };
    YFOO_Init(d);
    return b;
end

-- The panel with the zoom in / out buttons. owner is the Yatlas frame it zooms.
local function createZoomPanel(name, parent, anchor, owner)
    local p = Yatlas_CreateFrame{
        name = name, parent = parent, size = {48, 72}, anchor = anchor, hidden = true,
        backdrop = YATLAS_BACKDROP_TOOLTIP,
    };
    p:SetBackdropBorderColor(1, 1, 1);
    p:SetBackdropColor(0, 0, 0, 1);
    local plus = Yatlas_CreateButton{
        name = name.."PlusButton", parent = p, template = "UIPanelButtonTemplate", size = {24, 24},
        text = "YATLAS_ZOOMIN", anchor = {"TOPLEFT", nil, nil, 11, -12},
        onClick = function() owner:StepZoom(1); end,
    };
    Yatlas_CreateButton{
        name = name.."MinusButton", parent = p, template = "UIPanelButtonTemplate", size = {24, 24},
        text = "YATLAS_ZOOMOUT", anchor = {"TOPLEFT", plus, "BOTTOMLEFT", 0, 1},
        onClick = function() owner:StepZoom(-1); end,
    };
    return p;
end

-- Magnifier button opening the zoom panel <name>Frame next to it
function Yatlas_CreateZoomButton(name, parent, anchor, panelName, panelAnchor, owner)
    local panel;
    local b = Yatlas_CreateButton{
        name = name, parent = parent, size = {24, 24}, anchor = anchor,
        tooltip = {"YATLAS_TOOLTIP_ZOOM_TITLE", "YATLAS_TOOLTIP_ZOOM", "ANCHOR_RIGHT"},
        onClick = function()
            panel:SetShown(not panel:IsShown());
        end,
        textures = {
            normal = YATLAS_IMAGE_PATH.."MagButton-Up",
            pushed = YATLAS_IMAGE_PATH.."MagButton-Down",
            disabled = YATLAS_IMAGE_PATH.."MagButton-Disabled",
            highlight = HILIGHT_MOUSE,
        },
    };
    panel = createZoomPanel(panelName, b, panelAnchor, owner);
    return b;
end

-- ---------------------------------------------------------------------------
-- Yatlas frames (YatlasFrame, BigYatlasFrame)
-- ---------------------------------------------------------------------------

function YatlasFrame_Bootstrap(self, frame)
    if(frame == nil) then
        frame = self;
    end

    for h,v in pairs(YatlasFrameTemplate) do
        if(frame[h]) then
            frame["old_"..h] = frame[h];
        end

        frame[h] = v;
    end
    frame:OnLoad();
end

-- Mouse view of the map: <frame>ViewFrame. Create it before the frame is bootstrapped.
function Yatlas_CreateViewFrame(parent, size, anchor)
    local v = Yatlas_CreateFrame{
        name = parent:GetName().."ViewFrame", parent = parent, mouse = true, size = size, anchor = anchor,
    };
    v.lastoux = 0;
    v.lastouy = 0;
    v:SetScript("OnEnter", function(self) self.inme = true; end);
    v:SetScript("OnLeave", function(self) self.inme = false; end);
    v:SetScript("OnDragStart", function(self)
        self.dragme = true;
        ya_lastdragx = nil;
        ya_lastdragy = nil;
        YA_elapsed = 0;
    end);
    v:SetScript("OnDragStop", function(self)
        self.dragme = false;
        self:GetParent():UpdateDropDown2();
    end);
    v:SetScript("OnHide", function(self) self.dragme = false; end);
    v:SetScript("OnUpdate", function(self)
        if(self.dragme) then
            YatlasFrameViewFrame_OnDrag(self);
        end
        if(self.inme and self:GetParent() == YatlasFrame and YatlasOptions.ShowCursorCoords) then
            YatlasFrameViewFrame_UpdateCursorCoord(self);
        end
        if(self.inpoint) then
            YatlasFrameViewFrame_UpdatePointTooltip(self);
        end
    end);
    v:SetScript("OnMouseWheel", function(self, delta) self:GetParent():StepZoom(delta); end);
    return v;
end

-- A Yatlas frame; the caller adds children, then calls YatlasFrame_Bootstrap.
-- spec: name, size, anchor, allPoints, strata, toplevel, movable
function Yatlas_CreateMapFrame(spec)
    spec.parent = spec.parent or UIParent;
    spec.mouse = true;
    spec.hidden = true;
    spec.scripts = {
        OnShow = function(self)
            if(YatlasOptions and YatlasOptions.Frames) then
                local o = YatlasOptions.Frames[self:GetName()];
                if(o.track) then
                    YatlasFramePlayerJumpButton_Seek(self, o.track);
                elseif(o.trackonshow) then
                    YatlasFramePlayerJumpButton_Seek(self, o.trackonshow);
                end
            end
        end,
        OnDragStart = function(self)
            if(YatlasOptions.Frames and not YatlasOptions.Frames[self:GetName()].Locked) then
                self:StartMoving();
                self.isMoving = true;
            end
        end,
        OnDragStop = function(self)
            if(self.isMoving) then
                self:StopMovingOrSizing();
                self.isMoving = false;
            end
        end,
        OnUpdate = function(self, elapsed)
            if(self.OnUpdate) then
                self:OnUpdate(elapsed);
            end
        end,
        OnEvent = function(self, event, ...)
            self:OnEvent(event, ...);
        end,
    };
    return Yatlas_CreateFrame(spec);
end

-- Map tile n of a Yatlas frame; created on demand by YatlasFrameTemplate:SetZoom
function Yatlas_CreateMapTexture(frame, n)
    return Yatlas_CreateTexture(frame, {
        name = frame:GetName().."MapTexture"..n, layer = "BACKGROUND",
        size = {64, 64}, anchor = {"TOPLEFT", nil, nil, 6, -4},
    });
end

-- ---------------------------------------------------------------------------
-- Point buttons: map points (Points.lua) and the lines of the hover tooltip
-- ---------------------------------------------------------------------------

function Yatlas_CreatePointButton(parent)
    local f = CreateFrame("Button", nil, parent);

    f:SetSize(16, 16);
    f:EnableMouse(true);

    f.Icon = f:CreateTexture(nil, "OVERLAY");
    f.Icon:SetPoint("TOPLEFT", f);

    f.Foreground = f:CreateFontString(nil, "ARTWORK");
    f.Foreground:SetFontObject(GameFontHighlight);
    f.Foreground:SetTextColor(0, 0, 0);
    f.Foreground:SetShadowOffset(-1, 0);
    f.Foreground:SetPoint("TOPLEFT", f);

    f:SetFrameLevel(f:GetFrameLevel() + 4);
    return f;
end

-- ---------------------------------------------------------------------------
-- Hover tooltip (YatlasTooltip, BigYatlasTooltip)
-- ---------------------------------------------------------------------------

YatlasTooltipTemplate = {};

function YatlasTooltipTemplate:OnLoad()
    self:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r,
                                TOOLTIP_DEFAULT_COLOR.g,
                                TOOLTIP_DEFAULT_COLOR.b);
    self:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.g,
                          TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
    self.lines = {};
    self.nextnew = 1;
    self.nextfree = 1;
end

function YatlasTooltipTemplate:Show()
    local r = getmetatable(self).__index.Show(self);
    self:FixSize();
    return r;
end

function YatlasTooltipTemplate:GetNext()
    if(self.nextfree < self.nextnew) then
        self.nextfree = self.nextfree + 1;
        return self.lines[self.nextfree-1];
    end

    if(self.nextnew > 32) then
        return;
    end

    local f = Yatlas_CreatePointButton(self);
    f.Clear = YP_Clear;
    f.SetOffset = function() end;

    f.Text = f:CreateFontString(nil, "ARTWORK");
    f.Text:SetFontObject(GameFontHighlight);
    f.Text:SetPoint("TOPLEFT", f.Icon, 24, 0);

    -- optional second line (set by setuplegend), like the description of the world map pins
    f.Desc = f:CreateFontString(nil, "ARTWORK");
    f.Desc:SetFontObject(GameFontNormalSmall);
    f.Desc:SetPoint("TOPLEFT", f.Text, "BOTTOMLEFT", 0, -1);

    if(self.nextnew == 1) then
        f:SetPoint("TOPLEFT", self, "TOPLEFT", 8, -8);
    else
        f:SetPoint("TOPLEFT", self.lines[self.nextnew-1], "BOTTOMLEFT", 0, -2);
    end

    tinsert(self.lines, f);
    self.nextnew = self.nextnew + 1;
    self.nextfree = self.nextfree + 1;
    return f;
end

function YatlasTooltipTemplate:FixSize()
    local hei = 16;
    local wid = 4;

    for h = 1,(self.nextfree-1) do
        hei = hei + self.lines[h]:GetHeight() + 2;
        if(self.lines[h].Text:GetWidth() > wid) then
            wid = self.lines[h].Text:GetWidth();
        end
        if(self.lines[h].Desc:GetText() and self.lines[h].Desc:GetWidth() > wid) then
            wid = self.lines[h].Desc:GetWidth();
        end
    end
    self:SetHeight(hei);
    self:SetWidth(wid+64);
end

function YatlasTooltipTemplate:Clear()
    for h = 1,(self.nextfree-1) do
        self.lines[h]:Hide();
    end
    self.nextfree = 1;
    self:FixSize();
    self:Hide();
end

function Yatlas_CreateTooltip(name, parent, anchor)
    local t = Yatlas_CreateFrame{
        name = name, parent = parent, strata = "TOOLTIP", anchor = anchor, hidden = true,
        backdrop = YATLAS_BACKDROP_TOOLTIP,
    };
    for h,v in pairs(YatlasTooltipTemplate) do
        t[h] = v;
    end
    t:OnLoad();
    return t;
end

-- ---------------------------------------------------------------------------
-- Options widgets
-- ---------------------------------------------------------------------------

-- Titled box (replaces OptionFrameBoxTemplate, which no longer exists in the client)
function Yatlas_CreateOptionBox(name, parent, anchor, height)
    local box = Yatlas_CreateFrame{
        name = name, parent = parent, anchor = anchor, backdrop = YATLAS_BACKDROP_TOOLTIP,
    };
    box:SetHeight(height);
    box:SetBackdropBorderColor(0.4, 0.4, 0.4);
    box:SetBackdropColor(0, 0, 0);
    Yatlas_CreateText(box, {
        name = name.."Title", layer = "BACKGROUND", font = "GameFontHighlightSmall",
        anchor = {"BOTTOMLEFT", nil, "TOPLEFT", 9, 3},
    });
    return box;
end

-- spec: name, parent, anchor, label (global string name), onEvent, onClick (VARIABLES_LOADED events)
function Yatlas_CreateCheckBox(spec)
    local c = Yatlas_CreateFrame{
        type = "CheckButton", name = spec.name, parent = spec.parent, template = "UICheckButtonTemplate",
        size = {24, 24}, anchor = spec.anchor, raise = true, events = {"VARIABLES_LOADED"},
        scripts = {OnEvent = spec.onEvent, OnClick = spec.onClick},
    };
    Yatlas_CreateText(c, {
        font = "GameFontHighlight", text = spec.label, size = {275, 16}, justify = "LEFT",
        anchor = {"LEFT", nil, nil, 24, 0},
    });
    return c;
end

-- spec: name, parent, anchor, label (global string name), min, max, step, onChange, tooltip (onEnter)
function Yatlas_CreateOptionSlider(spec)
    local s = Yatlas_CreateFrame{
        type = "Slider", name = spec.name, parent = spec.parent, template = "OptionsSliderTemplate",
        size = {180, 16}, anchor = spec.anchor, raise = true,
    };
    _G[spec.name.."Text"]:SetText(L(spec.label));
    _G[spec.name.."High"]:SetText();
    _G[spec.name.."Low"]:SetText();
    s:SetMinMaxValues(spec.min, spec.max);
    s:SetValueStep(spec.step);
    s:SetScript("OnValueChanged", spec.onChange);
    if(spec.onEnter) then
        s:SetScript("OnEnter", spec.onEnter);
        s:SetScript("OnLeave", hideTooltip);
    end
    return s;
end
