-- PaTiAlerts: saved settings (PaTiAlertsDB), no WoW API calls (tested in tests/logic_spec.lua).
-- Alerts themselves are never saved: after /reload the producers report their current state again.
local _, ns = ...
local Logic = {}
ns.Logic = Logic

Logic.SCHEMA = 1
Logic.SCALES = { 0.8, 0.9, 1, 1.1, 1.25, 1.5 }
Logic.SOURCES = { "PaTiTank", "PaTiAuras", "PaTiHeal" } -- producers offered in the source filter (V1)

-- Position (point, relativePoint, x, y) is written by the PaTiShared window, not listed here.
Logic.DEFAULTS = {
    opacity = 0.75, -- panel body opacity (PaTiShared window; 0.3–1)
    theme = "default", -- "default" | "woforever" | "dracula" (PaTiShared UI.THEMES; colours only)
    locked = false,
    collapsed = false,
    scale = 1,
    language = "auto",
    autoHide = true, -- hide the window while there is nothing to show (only when locked, never in test mode)
    pulseNew = true, -- a short highlight when an alert appears or gets more severe
}

-- Fills missing values, keeps every existing one (also false). Filters: [name] = false hides that source/priority.
function Logic.Migrate(db)
    if type(db) ~= "table" then db = {} end -- nil or a broken save (string, number …): start fresh
    for key, value in pairs(Logic.DEFAULTS) do
        if db[key] == nil then db[key] = value end
    end
    -- A broken scale would make SetScale fail on login: only a sane number is kept (saved values elsewhere stay).
    if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then db.scale = Logic.DEFAULTS.scale end
    -- Theme: one of the three PaTiShared themes; a typo or an old value falls back to the default look.
    if db.theme ~= "default" and db.theme ~= "woforever" and db.theme ~= "dracula" then db.theme = "default" end
    if type(db.sourceFilters) ~= "table" then db.sourceFilters = {} end
    if type(db.priorityFilters) ~= "table" then db.priorityFilters = {} end
    db.schema = Logic.SCHEMA
    return db
end

-- "Restore Defaults": settings and filters back, position kept.
function Logic.RestoreDefaults(db)
    for key, value in pairs(Logic.DEFAULTS) do db[key] = value end
    db.sourceFilters, db.priorityFilters = {}, {}
    return db
end

-- Pure: should the window be visible? Hidden by the player wins; otherwise auto-hide only when there is nothing to
-- show, the window is locked (an unlocked window stays so it can be placed) and test mode is off.
function Logic.ShouldShow(db, count, testMode, hiddenByPlayer)
    if hiddenByPlayer then return false end
    if db.autoHide and count == 0 and db.locked and not testMode then return false end
    return true
end
