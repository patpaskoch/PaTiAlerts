# PaTiAlerts

<img src="assets/icon-128.png" width="96" alt="PaTiAlerts icon">

A small window for World of Warcraft: Forever (Interface 16001) that answers one question: **what needs my attention
right now?** It lists the open problems the other PaTi addons report — and nothing else. An alert stays while the
problem exists and disappears when it is solved. No combat log, no chat spam, no toasts, no automatic actions.

> Status: 0.1.0, in development, not yet released. Not yet tested in game.

## Features
- One line per open problem, most urgent first: **red** critical, **yellow** warning, **blue** note
- From **PaTiTank:** enemies you lost (`1 Kultist → Healer`, critical) or barely hold (warning) — with the same number
  that PaTiTank shows in its panel and above the enemy's nameplate
- From **PaTiAuras:** your watched buffs and (Shaman) weapon imbues that are missing or expiring (warning).
  "Unclear" data never shows up as missing
- From **PaTiHeal:** party members with a debuff you can dispel (note)
- A new alert (or one that got more severe) is highlighted once, briefly; nothing blinks
- Hides itself when there is nothing to show (while locked); unlocked or in test mode it stays so you can place it
- Rows are not clickable: to act on `1 Kultist`, click that enemy's nameplate marked "1" and taunt yourself
- ••• menu: Settings, Lock, Collapse, Test Mode, Hide. Languages: English, Deutsch (others fall back to English)

PaTiAlerts is **optional**: PaTiTank, PaTiAuras and PaTiHeal work exactly the same without it. It only shows what
they report while it is installed.

## Installation
1. Download the release zip (`PaTiAlerts-<version>.zip`).
2. Unpack it and copy the folder `PaTiAlerts` into `World of Warcraft/<client>/Interface/AddOns/`.
3. Start WoW and enable PaTiAlerts (plus any of PaTiTank, PaTiAuras, PaTiHeal) in the AddOns list.

## First steps
- `/pal test` shows one example of each priority — move the window where you look while playing, then lock it
- `/pal settings` to choose sources and priorities

## Settings
`/pal settings` or ••• → Settings:
- **Sources:** PaTiTank, PaTiAuras, PaTiHeal on/off (only what PaTiAlerts shows; the addons keep working)
- **Priorities:** critical, warnings, notes on/off
- **Behaviour:** briefly highlight new alerts; hide automatically when empty
- **General:** language, scale, window lock
- **Window:** panel opacity (30–100 %) and snapping to other PaTi windows while dragging

## Commands
`/pal` or `/palerts` — alone: show/hide · `settings` · `test` · `show` · `hide` · `lock` · `unlock` · `reset` (position) ·
`debug` · `version`

## For addon authors (PaTiSuite)
Local API, version 1 — call it only if it exists, never depend on it:
```lua
local api = _G.PaTiAlertsAPI
if type(api) == "table" and api.version == 1 then
    pcall(api.Sync, "PaTiTank", { { id = "aggro:<guid>", priority = "CRITICAL", kind = "AGGRO_LOST",
        number = 1, name = enemyName, detail = "Healer" } })
end
```
`Sync(source, list)` replaces the source's alerts (missing ones disappear); also `Upsert(alert)`, `Remove(source, id)`,
`ClearSource(source)`. `source`, `id`, `kind`, `priority` (`CRITICAL` / `WARNING` / `INFO`), `text`, `detail` must be
plain strings; `name` may be a restricted value (only displayed). Invalid data is dropped, never an error.

## Known limitations
- Not yet tested in game; the producers' alerts depend on their own (partly unconfirmed) WoW APIs.
- No alerts from PaTiGroup, PaTiQuest or PaTiDungeon yet.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.
