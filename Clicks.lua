-- PaTiAlerts: click a row to do what its producer offers (owner 2026-10-14) — for now PaTiAuras: cast a missing buff,
-- weapon imbue or tracking on you, or a missing group buff on the member PaTiAuras chose. One click = one cast.
-- WoW only lets secure buttons cast, and their spell and position may change only out of combat. The rows move in
-- combat (alerts come and go), so a button could end up over another row: all buttons hang on one holder that WoW
-- itself hides in combat (state driver "[combat] hide"), and they are re-armed after combat. They are not children of
-- the window, so the display-only window stays movable and hideable in combat.
local _, ns = ...
local UI, L = ns.UI, ns.UI.L

local Clicks = {}
ns.Clicks = Clicks

local holder = CreateFrame("Frame", nil, UIParent)
holder:SetAllPoints(UIParent)
if RegisterStateDriver then RegisterStateDriver(holder, "visibility", "[combat] hide; show") end

local buttons = {}
local window -- the PaTiAlerts window (strata and level for the buttons)

local function isSecret(value) return issecretvalue ~= nil and issecretvalue(value) == true end

-- Tooltip: the alert, what the click casts and on whom (a name only when it is readable).
local function tooltip(button)
    local info = button.info
    if not info then return nil end
    local lines = { info.text or info.spell, L.CLICK_CAST:format(info.spell) }
    if info.unit ~= "player" then
        local name = UnitName(info.unit)
        if not isSecret(name) and type(name) == "string" then lines[#lines + 1] = L.CLICK_ON:format(name) end
    end
    return lines
end

local function newButton()
    local button = CreateFrame("Button", nil, holder, "SecureActionButtonTemplate")
    button:RegisterForClicks("AnyUp", "AnyDown")
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    UI.Paint(highlight, "SetColorTexture", "Accent", 0.12)
    UI.SetTooltip(button, function() return tooltip(button) end)
    button:Hide()
    return button
end

function Clicks.Init(mainWindow)
    window = mainWindow
end

-- Lays a button exactly over a row, in UIParent coordinates (the row may sit in a scaled window).
local function cover(button, frame)
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then return false end -- not laid out yet
    local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, top * ratio)
    button:SetSize(frame:GetWidth() * ratio, frame:GetHeight() * ratio)
    return true
end

local function disarm(button)
    button:SetAttribute("type1", nil)
    button:SetAttribute("spell1", nil)
    button:SetAttribute("unit", nil)
    button.info = nil
    button:Hide()
end

-- entries: { { frame, cast = { spell, unit }, text } } for the shown rows that offer a click; {} clears all.
-- Out of combat only (in combat the holder is hidden anyway; the caller re-arms after combat). Returns false when a
-- row was not laid out yet, so the caller tries again on the next frame.
function Clicks.Arm(entries)
    if InCombatLockdown() then return true end
    local complete = true
    for index, entry in ipairs(entries) do
        buttons[index] = buttons[index] or newButton()
        local button = buttons[index]
        if window then
            button:SetFrameStrata(window:GetFrameStrata())
            button:SetFrameLevel(window:GetFrameLevel() + 10)
        end
        if cover(button, entry.frame) then
            button:SetAttribute("type1", "spell")
            button:SetAttribute("spell1", entry.cast.spell)
            button:SetAttribute("unit", entry.cast.unit)
            button.info = { spell = entry.cast.spell, unit = entry.cast.unit, text = entry.text }
            button:Show()
        else
            disarm(button)
            complete = false
        end
    end
    for index = #entries + 1, #buttons do disarm(buttons[index]) end
    return complete
end

-- Number of armed buttons (/pal debug).
function Clicks.Count()
    local count = 0
    for _, button in ipairs(buttons) do
        if button.info then count = count + 1 end
    end
    return count
end
