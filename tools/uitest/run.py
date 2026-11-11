# Load test of the whole addon in a minimal WoW UI mock (tools/uitest/mock.lua), one run per client.
# Loads every file of Yatlas.toc in order, fires the login events, then clicks through the frames.
# Usage: python3 tools/uitest/run.py [ClassicEra|TBC|Mists|Forever|Retail ...]   (needs: pip install lupa)
import sys, os, re
import lupa.lua51 as lua51
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
MOCK = os.path.join(HERE, 'mock.lua')
# globals that may be nil: optional third-party addons, Blizzard strings the mock does not define,
# tile textures created on demand and the probes of the point framework
IGNORE = re.compile(r'^(GatherMate|Gatherer_\w+|Magellan_\w+|MapNotes_\w+|myAddOns\w*|MYADDONS_\w+|SetupFullscreenScale|'
                    r'DELVES_LABEL|DRAGONRIDING_RACES_MAP_TOGGLE|WOW_PROJECT_CAMELOT|YATLAS_NO_DATA|YA_PD_ResetList|'
                    r'Yatlas_MapList|LibStub|GetMinimapShape|AddonCompartmentFrame|nil|\w+MapTexture\d+|\w+Point\d+|BigYatlasFrameLockButton) @')
FLAVORS = [  # (label, WOW_PROJECT_ID, build, toc, extra project constants)
    ('ClassicEra', 2, '1.15.9', 11509),
    ('TBC', 5, '2.5.6', 20506),
    ('Mists', 19, '5.5.4', 50504),
    ('Forever', 18, '1.60.1', 16001),
    ('Retail', 1, '12.1.5', 120105),
]

def toc_files(root):
    out = []
    for line in open(os.path.join(root, 'Yatlas.toc'), encoding='utf-8-sig'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        out += expand(root, line.replace('\\', '/'))
    return out

def expand(root, rel):
    if rel.endswith('.lua'):
        return [rel]
    if rel.endswith('.xml'):
        d = os.path.dirname(rel)
        src = open(os.path.join(root, rel), encoding='utf-8-sig').read()
        res = []
        for m in re.finditer(r'<(Script|Include)\s+file="([^"]+)"', src):
            p = (d + '/' + m.group(2).replace('\\', '/')) if d else m.group(2).replace('\\', '/')
            res += expand(root, p)
        if re.search(r'<(Frame|Button|Texture|FontString|Slider|CheckButton)\b', src):
            res.append('XMLFRAMES:' + rel)
        return res
    return []

def run(label, pid, build, toc, actions=True):
    L = lua51.LuaRuntime(unpack_returned_tuples=True)
    L.execute(open(MOCK, encoding='utf-8').read())
    L.execute(f'''
        WOW_PROJECT_MAINLINE = 1; WOW_PROJECT_CLASSIC = 2; WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5;
        WOW_PROJECT_WRATH_CLASSIC = 11; WOW_PROJECT_CATACLYSM_CLASSIC = 14; WOW_PROJECT_MISTS_CLASSIC = 19;
        WOW_PROJECT_ID = {pid}; MOCK.build = "{build}"; MOCK.toc = {toc};
        {'WOW_PROJECT_CAMELOT = 18;' if pid == 18 else ''}
        MOCK.playerMap = 1429;
    ''')
    if pid != 1:
        # Classic clients do not have these mainline-only APIs
        L.execute('C_AreaPoiInfo.GetDelvesForMap = nil; C_AreaPoiInfo.GetDragonridingRacesForMap = nil;')
    L.execute('MOCK.trackGlobals()')
    loader = L.eval('''function(src, name)
        local f, e = loadstring(src, "@"..name)
        if not f then return "SYNTAX "..e end
        local ok, err = pcall(f, "Yatlas", {})
        if not ok then return "RUNTIME "..tostring(err) end
    end''')
    problems = []
    for rel in toc_files(ROOT):
        if rel.startswith('XMLFRAMES:'):
            problems.append('XML still defines frames: ' + rel[10:])
            continue
        if '/Yatlas-' in rel and not rel.endswith(('enUS.lua', 'zhTW.lua')):
            continue
        src = open(os.path.join(ROOT, rel), encoding='utf-8-sig').read()
        r = loader(src, rel)
        if r:
            problems.append(f'{rel}: {r}')
    steps = []
    if actions:
        steps = [
            ('ADDON_LOADED', 'YatlasOptions = {ShowButton = false, ButtonLocation = 90}; MOCK.fire("ADDON_LOADED", "Yatlas"); '
                             'assert(YatlasOptions.Minimap.hide == true and YatlasOptions.Minimap.minimapPos == 90, "old button settings not migrated"); '
                             'assert(YatlasOptions.ShowButton == nil and YatlasOptions.ButtonLocation == nil, "old button settings kept"); '
                             'YatlasButton_SetShown(true)'),
            ('VARIABLES_LOADED', 'MOCK.fire("VARIABLES_LOADED")'),
            ('PLAYER_LOGIN', 'MOCK.fire("PLAYER_LOGIN")'),
            ('PLAYER_ENTERING_WORLD', 'MOCK.fire("PLAYER_ENTERING_WORLD", true, false)'),
            ('timers', 'local t = MOCK.timers or {}; MOCK.timers = {}; for _,fn in ipairs(t) do fn() end'),
            ('tick', 'MOCK.tick(3)'),
            ('YatlasFrame:Toggle', 'YatlasFrame:Toggle()'),
            ('tick shown', 'MOCK.tick(5)'),
            ('zoom +', 'YatlasFrameZoomFramePlusButton:_run("OnClick")'),
            ('zoom -', 'YatlasFrameZoomFrameMinusButton:_run("OnClick")'),
            ('wheel', 'YatlasFrameViewFrame:_run("OnMouseWheel", -1); YatlasFrameViewFrame:_run("OnMouseWheel", -1)'),
            ('lock', 'YatlasFrameLockButton:_run("OnClick"); YatlasFrameLockButton:_run("OnClick")'),
            ('lock enter', 'YatlasFrameLockButton:_run("OnEnter"); YatlasFrameLockButton:_run("OnLeave")'),
            ('drag map', 'YatlasFrameViewFrame:_run("OnDragStart"); MOCK.tick(2); YatlasFrameViewFrame:_run("OnDragStop")'),
            ('drag frame', 'YatlasFrame:_run("OnDragStart"); YatlasFrame:_run("OnDragStop")'),
            ('YFOO click', 'YFOO:_run("OnClick")'),
            ('YFOO dropdown L1', 'if YFOODropDown._init then UIDROPDOWNMENU_MENU_LEVEL=1; YFOODropDown._init(YFOODropDown, 1) end'),
            ('dropdown init', 'YatlasFrameDropDown._init(YatlasFrameDropDown, 1)'),
            ('dropdown2 open', 'if YatlasFrameDropDown2._init then YatlasFrameDropDown2._init(YatlasFrameDropDown2, 1) end'),
            ('player jump', 'YatlasFramePlayerJumpButton:_run("OnClick")'),
            ('player jump shift', 'MOCK.shift=true; YatlasFramePlayerJumpButton:_run("OnClick"); MOCK.shift=false'),
            ('player jump enter', 'YatlasFramePlayerJumpButton:_run("OnEnter")'),
            ('options button', 'YatlasFrameOptionsButton:_run("OnClick")'),
            ('options sliders', 'YatlasOptionsAlphaSlider:SetValue(0.5); YatlasOptionsIconSizeSlider:SetValue(20); YatlasOptionsButtonSlider:SetValue(90); YatlasOptionsButtonSlider:_run("OnEnter")'),
            ('options checks', 'YatlasOptionsButtonEnable:SetChecked(false); YatlasOptionsButtonEnable:_run("OnClick"); YatlasOptionsButtonEnable:SetChecked(true); YatlasOptionsButtonEnable:_run("OnClick"); YatlasOptionsTrackOnShow:SetChecked(true); YatlasOptionsTrackOnShow:_run("OnClick")'),
            ('options okay', 'YatlasOptionsFrameOkay:_run("OnClick")'),
            ('switch to big', 'YatlasFrameSwitchButton:_run("OnClick")'),
            ('tick big', 'MOCK.tick(5)'),
            ('big zoom', 'BigYatlasFrameZoomButton:_run("OnClick"); BigYatlasFrameZoomFramePlusButton:_run("OnClick")'),
            ('big switch back', 'BigYatlasFrameSwitchButton:_run("OnClick")'),
            ('close', 'YatlasFrame:Hide()'),
            ('minimap button', 'local b = LibDBIcon10_Yatlas; assert(b, "LibDBIcon button not registered"); '
                               'b:_run("OnEnter"); b:_run("OnLeave"); b:_run("OnMouseDown"); b:_run("OnMouseUp"); '
                               'b:_run("OnClick", "LeftButton"); b:_run("OnClick", "RightButton"); b:_run("OnClick", "RightButton"); '
                               'b:_run("OnDragStart"); MOCK.tick(1); b:_run("OnDragStop"); '
                               'YatlasOptionsButtonSlider:SetValue(45); assert(YatlasOptions.Minimap.minimapPos == 45, "slider did not move the button"); '
                               'YatlasButton_SetShown(false); assert(YatlasOptions.Minimap.hide, "hide not saved"); YatlasButton_SetShown(true)'),
            ('zone change', 'MOCK.fire("ZONE_CHANGED_NEW_AREA"); MOCK.tick(2)'),
            # event driven point rebuilds are coalesced into one timer, hidden frames only get marked
            ('timers flushed', 'local t = MOCK.timers or {}; MOCK.timers = {}; for _,fn in ipairs(t) do fn() end'),
            ('coalesce', 'YatlasFrame:Show(); MOCK.fire("AREA_POIS_UPDATED"); MOCK.fire("AREA_POIS_UPDATED"); '
                         'MOCK.fire("PLAYER_ENTERING_WORLD", false, false); '
                         'assert(#MOCK.timers == 1, "expected 1 coalesced update, got "..#MOCK.timers); local t = MOCK.timers or {}; MOCK.timers = {}; for _,fn in ipairs(t) do fn() end; '
                         'assert(not YatlasFrame.yap_dirty, "shown frame left dirty")'),
            ('hidden dirty', 'YatlasFrame:Hide(); BigYatlasFrame:Hide(); MOCK.fire("AREA_POIS_UPDATED"); local t = MOCK.timers or {}; MOCK.timers = {}; for _,fn in ipairs(t) do fn() end; '
                             'assert(YatlasFrame.yap_dirty and BigYatlasFrame.yap_dirty, "hidden frames not marked dirty")'),
            ('rebuild on show', 'YatlasFrame:Show(); assert(not YatlasFrame.yap_dirty, "OnShow did not rebuild"); '
                                'MOCK.tick(2); YatlasFrame:Hide()'),
            # hover tooltip: icons stay inside their slot and the line is as tall as the icon
            ('tooltip layout', 'YatlasFrame:Show(); MOCK.tick(2); local p; '
                               'for _,v in ipairs(YatlasFrame.pointframes) do if v:IsShown() and v.dat then p = v; break end end; '
                               'assert(p, "no point shown"); YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "add"); '
                               'local l = YatlasTooltip.lines[1]; assert(l and l:IsShown(), "no tooltip line"); '
                               'assert(l.Icon:GetWidth() <= YATLAS_LEGEND_SLOT and l:GetHeight() >= l.Icon:GetHeight(), "icon outside its line"); '
                               'l.Icon:SetWidth(25.6); l.Icon:SetHeight(25.6); YatlasTooltip:LayoutLine(l); '
                               'assert(l.Icon:GetWidth() == YATLAS_LEGEND_SLOT and l:GetHeight() == YATLAS_LEGEND_SLOT, "large icon not fitted"); '
                               'YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "remove"); YatlasFrame:Hide()'),
            # a reused tooltip line must not keep the crop of the icon it showed before (POIIcons capital)
            ('tooltip reuse', 'YatlasFrame:Show(); MOCK.tick(2); local p; '
                              'for _,v in ipairs(YatlasFrame.pointframes) do if v:IsShown() and v.dat then p = v; break end end; '
                              'YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "add"); YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "remove"); '
                              'local l = YatlasTooltip.lines[1]; l.Icon:SetTexCoord(0.5, 0.625, 0, 0.125); '
                              'YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "add"); '
                              'local c = l.Icon._texcoord or {}; '
                              'assert(l.Icon._atlas == nil or (c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 1), '
                              '       "atlas drawn with old crop "..table.concat(c, ",")); '
                              'YAPoints_UpdateTooltip(YatlasFrame, YatlasTooltip, p, "remove"); YatlasFrame:Hide()'),
            # map tiles: a full size grid on the clipped canvas; panning inside a tile only moves the canvas
            ('tile grid', 'local f = YatlasFrame; f:Show(); MOCK.tick(2); f:StepZoom(-1); f:StepZoom(-1); f:StepZoom(-1); '
                          'local vf = YatlasFrameViewFrame; assert(vf._clips, "view does not clip"); local z = f:GetZoom(); '
                          'assert(f.tilecols == math.ceil(vf:GetWidth()/z)+1 and f.tilerows == math.ceil(vf:GetHeight()/z)+1, "grid size"); '
                          'for hx = 1,f.tilecols do for hy = 1,f.tilerows do local t = f.texturelayout[hx][hy]; '
                          '  assert(t:GetWidth() == z and t:GetHeight() == z, "tile not full size"); local c = t._texcoord; '
                          '  assert(c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 1, "tile cropped"); '
                          '  local _, rel, _, px, py = t:GetPoint(1); assert(rel == vf.Canvas and px == z*(hx-1) and py == -z*(hy-1), "tile anchor") end end; '
                          'local n = f.tilecols*f.tilerows + 1; while _G["YatlasFrameMapTexture"..n] do assert(not _G["YatlasFrameMapTexture"..n]:IsShown(), "stray tile "..n); n = n + 1 end; '
                          'local calls = 0; local old = YAPoints_Update; YAPoints_Update = function(...) calls = calls + 1; return old(...) end; '
                          'local x, y = f:GetLocation(); local bx, by = math.floor(x), math.floor(y); '
                          'f:SetLocation(bx + 0.25, by + 0.5); calls = 0; f:SetLocation(bx + 0.75, by + 0.125); '
                          'local _, rel, _, cx, cy = vf.Canvas:GetPoint(1); '
                          'assert(rel == vf and math.abs(cx + 0.75*z) < 1e-6 and math.abs(cy - 0.125*z) < 1e-6, "canvas offset "..cx..","..cy); '
                          'assert(calls == 0, "points rebuilt inside one tile"); f:SetLocation(bx + 1.5, by + 0.5); '
                          'YAPoints_Update = old; assert(calls == 1, "points not rebuilt on a new tile: "..calls); f:Hide()'),
            ('drag state', 'assert(rawget(_G, "YATLAS_LASTDRAGX") == nil and rawget(_G, "YA_elapsed") == nil, "drag globals leaked"); '
                           'assert(rawget(_G, "point") == nil, "global point leaked")'),
            ('bindings', 'YatlasFrame:Toggle(); BigYatlasFrame:Toggle(); BigYatlasFrame:Toggle(); YatlasFrame:Toggle()'),
            ('slash', 'for k,fn in pairs(SlashCmdList) do if k:find("YATLAS") then fn("") end end'),
        ]
        for name, code in steps:
            r = L.eval(f'function() local ok, e = pcall(function() {code} end) if not ok then return tostring(e) end end')()
            if r:
                problems.append(f'step {name}: {r}')
    g = L.globals()
    errors = list(g.MOCK.errors.values())
    missing = dict(g.MOCK.missing.items())
    unknown = dict((g.MOCK.unknownMethods or L.table()).items())
    templates = list((g.MOCK.unknownTemplates or L.table()).keys())
    chat = list(g.MOCK.chat.values())
    return problems, errors, missing, unknown, templates, chat, L

if __name__ == '__main__':
    want = sys.argv[1:] or [f[0] for f in FLAVORS]
    failed = 0
    for f in FLAVORS:
        if f[0] not in want:
            continue
        problems, errors, missing, unknown, templates, chat, L = run(*f)
        print(f'===== {f[0]}')
        nils = [k for k in sorted(missing) if '/Data/' not in k and '<python>' not in k and not IGNORE.match(k)]
        for p in problems: print('  PROBLEM', p)
        for e in errors: print('  SCRIPT ERROR', e)
        for k in nils: print('  nil global', k, missing[k])
        if templates: print('  templates the mock does not know:', templates)
        if chat: print('  chat:', chat[:5])
        n = len(problems) + len(errors) + len(nils)
        print('  OK' if n == 0 else f'  {n} issue(s)')
        failed += n
    sys.exit(1 if failed else 0)
