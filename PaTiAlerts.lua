-- PaTiAlerts: "What needs my attention right now?" A small window listing the open problems other PaTi addons
-- report. Optional receiver only: no addon depends on it, it depends on none. Alerts stay while the problem exists.
-- Display only: rows are not clickable (no row does a safe action yet), nothing is cast, targeted or dispelled.
local addonName, ns = ...
local UI, L, Logic, State = ns.UI, ns.UI.L, ns.Logic, ns.State

local DB
local testMode = false
local hiddenByPlayer = false -- runtime only: "Hide" until /pal show

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end
local store = State.New(isSecret)

local function say(key, ...)
    print("|cff68caffPaTiAlerts:|r " .. L[key]:format(...))
end

local function addonVersion()
    local getMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    return getMetadata and getMetadata(addonName, "Version") or "?"
end

-- Window ---------------------------------------------------------------------------------------

local WIDTH, LINE, PAD, NUMBER_WIDTH, DETAIL_WIDTH, MAX_ROWS = 250, 20, UI.Spacing.MD, 14, 110, 8
local PULSE_SECONDS, PULSE_ALPHA = 0.45, 0.35
local PRIORITY_COLOR = { CRITICAL = "Danger", WARNING = "Warning", INFO = "Accent" }

local window = UI.CreateWindow("PaTiAlertsFrame", "PaTiAlerts", WIDTH, UI.Sizes.HeaderHeight + 2 * LINE)
local content = CreateFrame("Frame", nil, window)
content:SetPoint("TOPLEFT", 0, -UI.Sizes.HeaderHeight)
content:SetPoint("BOTTOMRIGHT")

-- Rows are plain frames without mouse handling: nothing here looks clickable because nothing is.
local rows = {}
for index = 1, MAX_ROWS + 1 do -- the last row can carry "+N more"
    local top = UI.Spacing.SM + (index - 1) * LINE
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("TOPLEFT", PAD, -top)
    row:SetSize(WIDTH - 2 * PAD, LINE)
    row.flash = row:CreateTexture(nil, "BACKGROUND")
    row.flash:SetAllPoints()
    row.flash:Hide()
    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetPoint("TOPLEFT", 0, -3)
    row.bar:SetSize(3, LINE - 6)
    row.number = row:CreateFontString(nil, "OVERLAY", UI.Fonts.Title)
    row.number:SetPoint("LEFT", 3 + UI.Spacing.SM, 0)
    row.number:SetWidth(NUMBER_WIDTH)
    row.number:SetJustifyH("LEFT")
    row.detail = row:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    row.detail:SetPoint("RIGHT")
    row.detail:SetWidth(DETAIL_WIDTH)
    row.detail:SetJustifyH("RIGHT")
    row.detail:SetWordWrap(false)
    row.text = row:CreateFontString(nil, "OVERLAY", UI.Fonts.Text)
    row.text:SetPoint("LEFT", row.number, "RIGHT", UI.Spacing.XS, 0)
    row.text:SetPoint("RIGHT", row.detail, "LEFT", -UI.Spacing.SM, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(false)
    row:Hide()
    rows[index] = row
end

-- New / escalated alerts: one short highlight of their row, then the normal look. Never repeats on refreshes.
local pulseUntil = {} -- alert key -> GetTime() when the highlight ends
local pulse = CreateFrame("Frame")
pulse:Hide()
pulse:SetScript("OnUpdate", function(self)
    local now, running = GetTime(), false
    for _, row in ipairs(rows) do
        local untilTime = row.key and pulseUntil[row.key]
        if untilTime and untilTime > now then
            local r, g, b = UI.Color("PanelHover")
            row.flash:SetColorTexture(r, g, b, PULSE_ALPHA * (untilTime - now) / PULSE_SECONDS + 0.05)
            row.flash:Show()
            running = true
        else
            row.flash:Hide()
        end
    end
    for key, untilTime in pairs(pulseUntil) do
        if untilTime <= now then pulseUntil[key] = nil end
    end
    if not running then self:Hide() end
end)

local function startPulse(keys)
    if not DB or not DB.pulseNew or #keys == 0 then return end
    local untilTime = GetTime() + PULSE_SECONDS
    for _, key in ipairs(keys) do pulseUntil[key] = untilTime end
    pulse:Show()
end

-- Test mode shows one alert of each priority from a separate store; real alerts are kept meanwhile.
local testStore = State.New(isSecret)
local function fillTestStore()
    State.Sync(testStore, "PaTiTank", { { id = "test:1", priority = "CRITICAL", kind = "AGGRO_LOST", number = 1,
        text = L.TEST_ENEMY, detail = L.TEST_HEALER } })
    State.Sync(testStore, "PaTiAuras", {
        { id = "test:aura", priority = "WARNING", kind = "AURA_MISSING", text = L.TEST_AURA, detail = L.TEST_MISSING },
        { id = "test:weapon", priority = "WARNING", kind = "WEAPON_IMBUE_MISSING", text = L.TEST_WEAPON,
            detail = L.TEST_IMBUE_MISSING },
        { id = "test:unknown", priority = "INFO", kind = "AURA_UNKNOWN", text = L.TEST_UNCLEAR, detail = L.TEST_UNCLEAR_DETAIL },
    })
end

local function render()
    if not DB then return end
    local list = State.Visible(testMode and testStore or store,
        { sources = DB.sourceFilters, priorities = DB.priorityFilters })
    window:SetShown(Logic.ShouldShow(DB, #list, testMode, hiddenByPlayer))
    window:SetTestMode(testMode)
    content:SetShown(not DB.collapsed)
    local used = 0
    if #list == 0 then
        used = 1
        local row = rows[1]
        row.key = nil
        row.bar:Hide()
        row.number:SetText("")
        row.text:SetText(L.NO_ALERTS)
        row.text:SetTextColor(UI.Color("TextMuted"))
        row.detail:SetText("")
        row:Show()
    end
    for index, alert in ipairs(list) do
        if index > MAX_ROWS then break end
        used = index
        local row, color = rows[index], PRIORITY_COLOR[alert.priority]
        row.key = alert.key
        row.bar:SetColorTexture(UI.Color(color))
        row.bar:Show()
        row.number:SetText(alert.number and tostring(alert.number) or "")
        row.number:SetTextColor(UI.Color(color))
        -- A secret name is handed to SetText unchanged (allowed for widgets); it is never compared or joined.
        if alert.name ~= nil then row.text:SetText(alert.name) else row.text:SetText(alert.text) end
        row.text:SetTextColor(UI.Color("Text"))
        row.detail:SetText(alert.detail or "")
        row.detail:SetTextColor(UI.Color(color))
        row:Show()
    end
    if #list > MAX_ROWS then
        used = MAX_ROWS + 1
        local row = rows[used]
        row.key = nil
        row.bar:Hide()
        row.number:SetText("")
        row.text:SetText(L.MORE_ALERTS:format(#list - MAX_ROWS))
        row.text:SetTextColor(UI.Color("TextMuted"))
        row.detail:SetText("")
        row:Show()
    end
    for index = used + 1, #rows do rows[index].key = nil; rows[index]:Hide() end
    window:SetHeight(DB.collapsed and UI.Sizes.HeaderHeight
        or UI.Sizes.HeaderHeight + UI.Spacing.SM + used * LINE + UI.Spacing.SM)
end

-- Producers may report many times per second; the window is drawn once, on the next frame.
local renderer = CreateFrame("Frame")
renderer:Hide()
renderer:SetScript("OnUpdate", function(self) self:Hide(); render() end)
local function requestRender() renderer:Show() end

-- Local API for other PaTi addons (optional for them: they call it only if it exists) ------------------
-- Every entry point is pcall-protected: bad producer data never raises an error in the producer.

local function receive(pulseKeys, changed)
    if #pulseKeys > 0 then startPulse(pulseKeys) end
    if changed or #pulseKeys > 0 then requestRender() end
end

PaTiAlertsAPI = {
    version = 1,
    -- alert = { source, id, priority = "CRITICAL" | "WARNING" | "INFO", kind, text | name, detail?, number? }
    Upsert = function(alert)
        local ok, result, key = pcall(State.Upsert, store, type(alert) == "table" and alert.source, alert)
        if not ok or not result then return false end
        receive((result == "new" or result == "escalated") and { key } or {}, true)
        return true
    end,
    Remove = function(source, id)
        local ok, removed = pcall(State.Remove, store, source, id)
        if ok and removed then requestRender() end
        return ok and removed
    end,
    ClearSource = function(source)
        local ok, removed = pcall(State.ClearSource, store, source)
        if ok and removed then requestRender() end
        return ok and removed
    end,
    -- The producer's complete current list for its source: new ones appear, missing ones disappear.
    Sync = function(source, list)
        local ok, pulseKeys, changed = pcall(State.Sync, store, source, list)
        if ok then receive(pulseKeys, changed) end
        return ok
    end,
}

-- Settings -------------------------------------------------------------------------------------

local modal

local function buildSettings()
    modal = UI.CreateModal("PaTiAlertsSettings", function() return "PaTiAlerts " .. L.SETTINGS end, 380)
    local function filterBox(label, filters, key)
        return UI.CreateCheckbox(modal, label, {
            get = function() return DB[filters][key] ~= false end,
            set = function(shown) DB[filters][key] = shown and nil or false; render() end,
        })
    end
    local function box(label, key)
        return UI.CreateCheckbox(modal, label, {
            get = function() return DB[key] end,
            set = function(value) DB[key] = value; render() end,
        })
    end
    modal:AddSection("SOURCES")
    local sources = Logic.SOURCES
    for index = 1, #sources, 2 do
        modal:AddControls(filterBox(sources[index], "sourceFilters", sources[index]),
            sources[index + 1] and filterBox(sources[index + 1], "sourceFilters", sources[index + 1]))
    end
    modal:AddSection("PRIORITIES")
    modal:AddControls(filterBox("PRIORITY_CRITICAL", "priorityFilters", "CRITICAL"),
        filterBox("PRIORITY_WARNING", "priorityFilters", "WARNING"))
    modal:AddControls(filterBox("PRIORITY_INFO", "priorityFilters", "INFO"))
    modal:AddSection("BEHAVIOR")
    modal:AddControl(box("PULSE_NEW", "pulseNew"))
    modal:AddControl(box("AUTO_HIDE", "autoHide"))
    modal:AddLabel("AUTO_HIDE_TIP")
    modal:AddSection("GENERAL")
    modal:AddRow("LANGUAGE", UI.CreateLanguageDropdown(modal, DB, 170))
    local scales = {}
    for _, scale in ipairs(Logic.SCALES) do
        scales[#scales + 1] = { value = scale, text = function() return ("%d %%"):format(scale * 100 + 0.5) end }
    end
    modal:AddRow("SCALE", UI.CreateDropdown(modal, 170, {
        items = function() return scales end,
        get = function() return DB.scale end,
        set = function(scale) DB.scale = scale; window:SetScale(scale) end, -- no secure frames: fine in combat
    }))
    modal:AddControls(UI.CreateCheckbox(modal, "LOCK_WINDOW", {
        get = function() return window:IsLocked() end,
        set = function(locked) window:SetLocked(locked); render() end,
    }))
    UI.AddWindowSettings(modal, window) -- panel opacity + snapping (PaTiShared)
    modal:Finish(function()
        Logic.RestoreDefaults(DB)
        window:ApplyOpacity()
        UI.SetLanguage(DB.language)
        window:SetLocked(DB.locked)
        window:SetScale(DB.scale)
        render()
    end)
end

local function openSettings()
    if not modal then buildSettings() end
    modal:Show()
end

-- Commands -------------------------------------------------------------------------------------

local function setShown(shown, quiet)
    hiddenByPlayer = not shown
    render()
    if not shown and not quiet then say("HIDDEN_HINT") end
    return true
end

-- Optional PaTiSuite control panel: the same rules as the commands, without chat lines (false = not possible now).
-- "Shown" means "not hidden by you": an auto-hidden empty window still counts as on.
window.suiteSetShown = function(shown) return setShown(shown, true) end
window.suiteIsShown = function() return not hiddenByPlayer end

local function toggleTestMode()
    testMode = not testMode
    if testMode then fillTestStore() end
    render()
end

local function toggleCollapsed()
    DB.collapsed = not DB.collapsed
    render()
end

local function resetPosition()
    DB.point, DB.relativePoint, DB.x, DB.y = nil, nil, nil, nil
    window:Attach(DB, 0, 200)
end

local function printDebug()
    local version, build, _, interface = GetBuildInfo()
    local counts, parts = State.Counts(store), {}
    for source, count in pairs(counts) do parts[#parts + 1] = source .. " " .. count end
    table.sort(parts)
    print("|cff68caffPaTiAlerts Debug:|r")
    for _, line in ipairs({
        ("Addon %s %s · PaTiShared UI %s · API version %d"):format(addonName, addonVersion(), tostring(UI.VERSION),
            PaTiAlertsAPI.version),
        ("WoW %s (build %s, interface %s) · locale %s · UI language %s"):format(tostring(version), tostring(build),
            tostring(interface), GetLocale(), UI.GetLanguage()),
        ("Alerts: %s · shown %d · test mode %s · hidden by you %s · auto-hide %s"):format(
            #parts > 0 and table.concat(parts, ", ") or "none",
            #State.Visible(store, { sources = DB.sourceFilters, priorities = DB.priorityFilters }),
            testMode and "on" or "off", hiddenByPlayer and "yes" or "no", DB.autoHide and "on" or "off"),
    }) do print("  " .. line) end
end

local COMMANDS = {
    [""] = function() setShown(not window:IsShown()) end,
    show = function() setShown(true) end,
    hide = function() setShown(false) end,
    test = toggleTestMode,
    lock = function() window:SetLocked(true); render() end,
    unlock = function() window:SetLocked(false); render() end,
    reset = resetPosition,
    settings = openSettings,
    debug = printDebug,
    version = function() say("VERSION", addonVersion()) end,
}

SLASH_PATIALERTS1 = "/palerts"
SLASH_PATIALERTS2 = "/pal"
SlashCmdList.PATIALERTS = function(message)
    local command = COMMANDS[(message or ""):match("^%s*(.-)%s*$"):lower()]
    if command and DB then command() else say("HELP") end
end

window:SetMenu(function()
    if not DB then return {} end
    return {
        { text = "SETTINGS", onClick = openSettings },
        { text = window:IsLocked() and "UNLOCK" or "LOCK",
            onClick = function() window:SetLocked(not window:IsLocked()); render() end },
        { text = DB.collapsed and "EXPAND" or "COLLAPSE", onClick = toggleCollapsed },
        { text = "TEST_MODE", checked = testMode, onClick = toggleTestMode },
        { text = "HIDE", onClick = function() setShown(false) end },
    }
end)

-- Events ---------------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
    PaTiAlertsDB = Logic.Migrate(PaTiAlertsDB)
    DB = PaTiAlertsDB
    UI.SetLanguage(DB.language)
    window:Attach(DB, 0, 200)
    window:SetScale(DB.scale)
    render() -- producers that loaded earlier may already have reported; the others report on their next refresh
end)
UI.OnLanguageChanged(function()
    if testMode then fillTestStore() end
    render()
end)
