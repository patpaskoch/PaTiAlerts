-- PaTiAlerts: the current alerts, without WoW API calls (tested in tests/state_spec.lua).
-- An alert stays while its producer reports it; a producer removes it when the problem is gone. Nothing is saved.
-- Producer data is untrusted: every field is checked (secrecy first), invalid alerts are dropped, never an error.
local _, ns = ...
local State = {}
ns.State = State

State.PRIORITIES = { "CRITICAL", "WARNING", "INFO" }
local RANK = { CRITICAL = 1, WARNING = 2, INFO = 3 }
local LIMITS = { source = 40, id = 120, kind = 40, priority = 20, text = 80, detail = 40, name = 60 }

-- isSecret(value) -> true for restricted values (issecretvalue in WoW), injected so this file stays pure.
function State.New(isSecret)
    return { alerts = {}, seq = 0, isSecret = isSecret or function() return false end }
end

-- A readable, non-empty string (cut to the field's limit), or nil. Secrecy is checked before anything else.
local function plain(store, value, field)
    if store.isSecret(value) or type(value) ~= "string" or value == "" then return nil end
    return value:sub(1, LIMITS[field])
end

-- Producer table → clean alert, or nil if unusable. Keys (source, id, kind, priority) must be plain strings;
-- an unknown priority falls back to INFO. `name` may be a secret value: it is only ever handed to SetText.
function State.Clean(store, source, alert)
    source = plain(store, source, "source")
    if not source or type(alert) ~= "table" then return nil end
    local id, kind = plain(store, alert.id, "id"), plain(store, alert.kind, "kind")
    if not id or not kind then return nil end
    local priority = plain(store, alert.priority, "priority")
    local clean = { source = source, id = id, kind = kind, priority = RANK[priority] and priority or "INFO" }
    clean.text = plain(store, alert.text, "text")
    clean.detail = plain(store, alert.detail, "detail")
    local name = alert.name
    if store.isSecret(name) then clean.name = name
    elseif type(name) == "string" and name ~= "" then clean.name = name:sub(1, LIMITS.name) end
    local number = alert.number
    if not store.isSecret(number) and type(number) == "number" and number >= 1 and number <= 99 and number % 1 == 0 then
        clean.number = number
    end
    if not clean.text and clean.name == nil then return nil end -- nothing to show
    return clean
end

local function key(source, id) return source .. "\0" .. id end

-- Adds or updates one alert. Returns "new" | "escalated" (more severe than before) | "updated" | nil (invalid),
-- and the alert's key.
-- An updated alert keeps its place (seq); only a new one gets a new place → stable order within a priority.
function State.Upsert(store, source, alert)
    local clean = State.Clean(store, source, alert)
    if not clean then return nil end
    local k = key(clean.source, clean.id)
    local old = store.alerts[k]
    if old then
        clean.seq = old.seq
        store.alerts[k] = clean
        return RANK[clean.priority] < RANK[old.priority] and "escalated" or "updated", k
    end
    store.seq = store.seq + 1
    clean.seq = store.seq
    store.alerts[k] = clean
    return "new", k
end

-- Returns true if an alert was removed.
function State.Remove(store, source, id)
    source, id = plain(store, source, "source"), plain(store, id, "id")
    if not source or not id or not store.alerts[key(source, id)] then return false end
    store.alerts[key(source, id)] = nil
    return true
end

function State.ClearSource(store, source)
    source = plain(store, source, "source")
    local removed = false
    if not source then return false end
    for k, alert in pairs(store.alerts) do
        if alert.source == source then store.alerts[k] = nil; removed = true end
    end
    return removed
end

-- The producer's complete current list: upserts every alert and removes the source's alerts that are not in it.
-- Returns pulse (keys of new or escalated alerts) and changed (anything added, removed or modified).
function State.Sync(store, source, list)
    source = plain(store, source, "source")
    local pulse, changed, keep = {}, false, {}
    if not source then return pulse, false end
    for _, alert in ipairs(type(list) == "table" and list or {}) do
        local id = type(alert) == "table" and plain(store, alert.id, "id")
        local before = id and store.alerts[key(source, id)]
        local result, k = State.Upsert(store, source, alert)
        if result then
            keep[k] = true
            if result == "new" or result == "escalated" then pulse[#pulse + 1] = k; changed = true
            elseif not State.Same(before, store.alerts[k]) then changed = true end
        end
    end
    for k, alert in pairs(store.alerts) do
        if alert.source == source and not keep[k] then store.alerts[k] = nil; changed = true end
    end
    return pulse, changed
end

-- Same display content (plain fields; a secret name counts as changed only if it is a different value).
function State.Same(a, b)
    if not a or not b then return false end
    for _, field in ipairs({ "priority", "kind", "text", "detail", "number" }) do
        if a[field] ~= b[field] then return false end
    end
    return rawequal(a.name, b.name)
end

-- filters = { sources = { [source] = false }, priorities = { [priority] = false } } (missing = shown).
-- Returns the shown alerts: CRITICAL, WARNING, INFO; within a priority in the order they first appeared.
function State.Visible(store, filters)
    local list = {}
    local sources = filters and filters.sources or {}
    local priorities = filters and filters.priorities or {}
    for k, alert in pairs(store.alerts) do
        if sources[alert.source] ~= false and priorities[alert.priority] ~= false then
            list[#list + 1] = alert
            alert.key = k
        end
    end
    table.sort(list, function(a, b)
        if a.priority ~= b.priority then return RANK[a.priority] < RANK[b.priority] end
        return a.seq < b.seq
    end)
    return list
end

-- Counts per source for /pal debug.
function State.Counts(store)
    local counts = {}
    for _, alert in pairs(store.alerts) do counts[alert.source] = (counts[alert.source] or 0) + 1 end
    return counts
end
