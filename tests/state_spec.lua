-- PaTiAlerts alert store. Run via PaTiAdmin/tools/check.sh.
local wow = require("wow_api")

local SECRET = setmetatable({}, { __eq = function() error("secret compared") end, __lt = function() error("secret compared") end,
    __concat = function() error("secret concatenated") end })
local function isSecret(value) return rawequal(value, SECRET) end

local function new()
    local State = wow.loadAddonFile("State.lua", {}).State
    return State, State.New(isSecret)
end

local function alert(id, priority, extra)
    local data = { id = id, priority = priority or "WARNING", kind = "TEST", text = "Alert " .. id }
    for key, value in pairs(extra or {}) do data[key] = value end
    return data
end

local function ids(list)
    local result = {}
    for _, item in ipairs(list) do result[#result + 1] = item.id end
    return result
end

describe("State.Upsert", function()
    it("adds a new alert and updates the same source + id instead of duplicating it", function()
        local State, store = new()
        assert.equal("new", (State.Upsert(store, "PaTiTank", alert("a"))))
        assert.equal("updated", (State.Upsert(store, "PaTiTank", alert("a", "WARNING", { text = "changed" }))))
        local list = State.Visible(store)
        assert.equal(1, #list)
        assert.equal("changed", list[1].text)
    end)

    it("keeps the same id from two sources apart", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("x"))
        State.Upsert(store, "PaTiAuras", alert("x"))
        assert.equal(2, #State.Visible(store))
    end)

    it("reports an escalation (WARNING → CRITICAL) so the row can be highlighted again", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("a", "WARNING"))
        assert.equal("escalated", (State.Upsert(store, "PaTiTank", alert("a", "CRITICAL"))))
        assert.equal("updated", (State.Upsert(store, "PaTiTank", alert("a", "WARNING"))))
    end)
end)

describe("State.Remove and ClearSource", function()
    it("removes exactly one alert, the others stay", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("a"))
        State.Upsert(store, "PaTiTank", alert("b"))
        assert.is_true(State.Remove(store, "PaTiTank", "a"))
        assert.same({ "b" }, ids(State.Visible(store)))
        assert.is_false(State.Remove(store, "PaTiTank", "a"))
    end)

    it("clears only the alerts of one source", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("a"))
        State.Upsert(store, "PaTiAuras", alert("b"))
        assert.is_true(State.ClearSource(store, "PaTiTank"))
        assert.same({ "b" }, ids(State.Visible(store)))
    end)
end)

describe("State.Sync", function()
    it("adds new alerts, removes the source's missing ones, and reports what to highlight", function()
        local State, store = new()
        State.Upsert(store, "PaTiAuras", alert("other"))
        local pulse, changed = State.Sync(store, "PaTiTank", { alert("a"), alert("b") })
        assert.equal(2, #pulse)
        assert.is_true(changed)
        pulse, changed = State.Sync(store, "PaTiTank", { alert("b") })
        assert.equal(0, #pulse)
        assert.is_true(changed) -- "a" removed
        assert.same({ "other", "b" }, ids(State.Visible(store)))
        changed = select(2, State.Sync(store, "PaTiTank", { alert("b") }))
        assert.is_false(changed) -- same content: no redraw
    end)

    it("runs the lifecycle WARNING → CRITICAL → gone → back as a new alert", function()
        local State, store = new()
        State.Sync(store, "PaTiTank", { alert("mob", "WARNING") })
        local pulse = State.Sync(store, "PaTiTank", { alert("mob", "CRITICAL") })
        assert.equal(1, #pulse)
        assert.equal("CRITICAL", State.Visible(store)[1].priority)
        State.Sync(store, "PaTiTank", {})
        assert.same({}, State.Visible(store))
        pulse = State.Sync(store, "PaTiTank", { alert("mob", "WARNING") })
        assert.equal(1, #pulse)
    end)
end)

describe("State.Visible", function()
    it("sorts CRITICAL, WARNING, INFO and keeps the first-seen order within a priority", function()
        local State, store = new()
        State.Upsert(store, "PaTiAuras", alert("w1", "WARNING"))
        State.Upsert(store, "PaTiAuras", alert("i1", "INFO"))
        State.Upsert(store, "PaTiTank", alert("c1", "CRITICAL"))
        State.Upsert(store, "PaTiAuras", alert("w2", "WARNING"))
        assert.same({ "c1", "w1", "w2", "i1" }, ids(State.Visible(store)))
        State.Upsert(store, "PaTiAuras", alert("w1", "WARNING", { text = "refresh" })) -- update keeps its place
        assert.same({ "c1", "w1", "w2", "i1" }, ids(State.Visible(store)))
    end)

    it("hides a switched-off source or priority", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("c", "CRITICAL"))
        State.Upsert(store, "PaTiAuras", alert("w", "WARNING"))
        assert.same({ "w" }, ids(State.Visible(store, { sources = { PaTiTank = false }, priorities = {} })))
        assert.same({ "c" }, ids(State.Visible(store, { sources = {}, priorities = { WARNING = false } })))
    end)
end)

describe("Validation", function()
    it("drops invalid producer data without an error", function()
        local State, store = new()
        assert.is_nil(State.Upsert(store, "PaTiTank", nil))
        for _, bad in ipairs({ 42, {}, { id = "x" }, { id = "x", kind = "K" }, { id = SECRET, kind = "K", text = "t" },
            { id = "x", kind = SECRET, text = "t" }, { id = "", kind = "K", text = "t" } }) do
            assert.is_nil(State.Upsert(store, "PaTiTank", bad))
        end
        assert.is_nil(State.Upsert(store, SECRET, alert("a")))
        assert.is_nil(State.Upsert(store, nil, alert("a")))
        local pulse, changed = State.Sync(store, "PaTiTank", "not a list")
        assert.same({}, pulse)
        assert.is_false(changed)
        assert.same({}, State.Visible(store))
    end)

    it("falls back to INFO for an unknown priority and drops bad optional fields", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", alert("a", "URGENT!!", { number = 1.5, detail = SECRET }))
        local item = State.Visible(store)[1]
        assert.equal("INFO", item.priority)
        assert.is_nil(item.number)
        assert.is_nil(item.detail)
    end)

    it("keeps a secret name only for display and never compares it", function()
        local State, store = new()
        State.Upsert(store, "PaTiTank", { id = "a", priority = "CRITICAL", kind = "AGGRO_LOST", name = SECRET, number = 1 })
        local item = State.Visible(store)[1]
        assert.is_true(rawequal(SECRET, item.name))
        local _, changed = State.Sync(store, "PaTiTank", { { id = "a", priority = "CRITICAL", kind = "AGGRO_LOST",
            name = SECRET, number = 1 } })
        assert.is_false(changed)
    end)
end)
