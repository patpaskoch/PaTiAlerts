-- PaTiAlerts settings. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local function load()
    return wow.loadAddonFile("Logic.lua", {}).Logic
end

describe("Logic.Migrate", function()
    it("creates the defaults for a new character", function()
        local db = load().Migrate(nil)
        assert.same({ false, false, 1, "auto", true, true }, { db.locked, db.collapsed, db.scale, db.language, db.autoHide, db.pulseNew })
        assert.same({}, db.sourceFilters)
        assert.same({}, db.priorityFilters)
        assert.equal(1, db.schema)
        assert.is_nil(db.alerts) -- alerts are never saved
    end)

    it("keeps saved values, also false, the filters and the position", function()
        local db = load().Migrate({ autoHide = false, pulseNew = false, locked = true, collapsed = true, scale = 1.25,
            x = 5, point = "TOPLEFT", sourceFilters = { PaTiHeal = false }, priorityFilters = { INFO = false } })
        assert.same({ false, false, true, true, 1.25, 5, "TOPLEFT" },
            { db.autoHide, db.pulseNew, db.locked, db.collapsed, db.scale, db.x, db.point })
        assert.same({ PaTiHeal = false }, db.sourceFilters)
        assert.same({ INFO = false }, db.priorityFilters)
    end)

    it("repairs broken filter tables", function()
        local db = load().Migrate({ sourceFilters = "x", priorityFilters = 3 })
        assert.same({}, db.sourceFilters)
        assert.same({}, db.priorityFilters)
    end)
end)

describe("Logic.RestoreDefaults", function()
    it("resets settings and filters, keeps the position", function()
        local db = load().RestoreDefaults({ autoHide = false, scale = 1.5, x = 7, sourceFilters = { PaTiTank = false } })
        assert.is_true(db.autoHide)
        assert.equal(1, db.scale)
        assert.equal(7, db.x)
        assert.same({}, db.sourceFilters)
    end)
end)

describe("Logic.ShouldShow", function()
    it("auto-hides only when empty, locked and not in test mode; a player's Hide always wins", function()
        local Logic = load()
        local db = { autoHide = true, locked = true }
        assert.is_false(Logic.ShouldShow(db, 0, false, false))
        assert.is_true(Logic.ShouldShow(db, 1, false, false))
        assert.is_true(Logic.ShouldShow(db, 0, true, false)) -- test mode
        assert.is_true(Logic.ShouldShow({ autoHide = true, locked = false }, 0, false, false)) -- unlocked: to place it
        assert.is_true(Logic.ShouldShow({ autoHide = false, locked = true }, 0, false, false))
        assert.is_false(Logic.ShouldShow(db, 3, false, true))
    end)
end)

describe("Window settings (panel opacity, snapping)", function()
    it("old saves get 75 % and snapping on; saved values stay; Restore Defaults resets them", function()
        local M = load()
        local db = M.Migrate({ x = 12, y = 34 })
        assert.equal(0.75, db.opacity)
        assert.is_true(db.snapWindows)
        assert.equal(12, db.x)
        db = M.Migrate({ opacity = 0.4, snapWindows = false })
        assert.equal(0.4, db.opacity)
        assert.is_false(db.snapWindows)
        db = M.RestoreDefaults({ opacity = 0.4, snapWindows = false, bindings = {}, bindingRanks = {}, watch = {} })
        assert.equal(0.75, db.opacity)
        assert.is_true(db.snapWindows)
    end)
end)
