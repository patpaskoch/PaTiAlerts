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
- From **PaTiAuras:** your watched buffs and (Shaman) weapon imbues that are missing or expiring (warning), and
  watched group buffs someone lacks — one line per buff (`Power Word: Fortitude · Missing on 2`), names stay in the
  PaTiAuras tooltip. "Unclear" data, offline and dead members never show up as missing
- From **PaTiHeal:** party members with a debuff you can dispel (note)
- A new alert (or one that got more severe) is highlighted once, briefly; nothing blinks
- Hides itself when there is nothing to show (while locked); unlocked or in test mode it stays so you can place it
- Rows are not clickable: to act on `1 Kultist`, click that enemy's nameplate marked "1" and taunt yourself
- ••• menu: Settings, Lock, Collapse, Test Mode, Hide. Languages: English, Deutsch (others fall back to English)

PaTiAlerts is **optional**: PaTiTank, PaTiAuras and PaTiHeal work exactly the same without it. It only shows what
they report while it is installed.

## PaTiSuite

This addon is part of the **PaTiSuite** — a collection of small addons for World of Warcraft: Forever.
Each one is installed on its own and works on its own; none of them is needed by another.

- [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) – optional control panel to show and hide the PaTi windows
- [PaTiHeal](https://github.com/patpaskoch/PaTiHeal) – healing: party frames, heal target, click casting, HoTs, dispels
- [PaTiAuras](https://github.com/patpaskoch/PaTiAuras) – buffs, procs, tracking, group buffs and weapon imbues
- [PaTiTank](https://github.com/patpaskoch/PaTiTank) – tank HUD and aggro monitor
- [PaTiRota](https://github.com/patpaskoch/PaTiRota) – your own skill priority with cooldowns and fixed cast buttons
- [PaTiGroup](https://github.com/patpaskoch/PaTiGroup) – party awareness: tank, healer, roles and the tank's target
- [PaTiLead](https://github.com/patpaskoch/PaTiLead) – lead the group: raid markers, ready check and pull timer
- [PaTiQuest](https://github.com/patpaskoch/PaTiQuest) – selected quest and its objectives
- [PaTiDungeon](https://github.com/patpaskoch/PaTiDungeon) – instance, group and combat status
- [PaTiSocial](https://github.com/patpaskoch/PaTiSocial) – "Party Social": quick emote and message buttons
- **PaTiAlerts** – one window for open problems *(this addon)*

### Current sources

- [PaTiTank](https://github.com/patpaskoch/PaTiTank) – enemies you lost or barely hold (same number as in PaTiTank and on the nameplate)
- [PaTiAuras](https://github.com/patpaskoch/PaTiAuras) – your watched buffs, weapon imbues and group buffs that are missing or expiring
- [PaTiHeal](https://github.com/patpaskoch/PaTiHeal) – party members with a debuff you can dispel

PaTiAlerts is optional: PaTiTank, PaTiAuras and PaTiHeal work fully without it. [PaTiSuite](https://github.com/patpaskoch/PaTiSuite) can show and hide this window together with the others.

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
- **Window:** panel opacity (30–100 %)

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
- In-game test status: [`INGAME_TESTING.md`](INGAME_TESTING.md). The producers' alerts depend on their own (partly
  unconfirmed) WoW APIs; Shaman weapon imbues currently read "missing" even while active (PaTiAuras).
- No alerts from PaTiGroup, PaTiLead, PaTiRota, PaTiQuest or PaTiDungeon yet.

## Development

Architecture, tests and engineering rules of the suite: [PaTiAdmin](https://github.com/patpaskoch/PaTiAdmin). PaTiAdmin is not a WoW addon — players do not install it. The shared UI code (PaTiShared) is already embedded in this addon's `Shared/` folder; there is nothing extra to install.

## License
MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Patrick Koch.
