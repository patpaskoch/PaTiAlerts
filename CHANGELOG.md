# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Added
- Window settings (PaTiShared): panel opacity 30–100 % (default 75 %, the header stays opaque). The window registers
  itself for the optional PaTiSuite control panel, which shows/hides it with this addon's own rules. (Snapping to
  other PaTi windows was tried and removed again: it did not work in the client.)
- Window "What needs my attention right now?": one line per open problem, sorted critical → warning → note, stable
  order within a priority; a short one-time highlight for new or escalated alerts; auto-hide when empty (locked only).
- Local API `PaTiAlertsAPI` version 1: `Sync(source, list)`, `Upsert(alert)`, `Remove(source, id)`,
  `ClearSource(source)`. Producer data is validated (secrecy first); invalid alerts are dropped without an error.
- Settings: sources (PaTiTank, PaTiAuras, PaTiHeal), priorities, highlight, auto-hide, language, scale, lock.
  `PaTiAlertsDB` saves settings only — alerts are never saved; producers report them again after `/reload`.
- Test mode with one alert of each priority; `/pal`, `/palerts` with show, hide, test, lock, unlock, reset, settings,
  debug, version. English texts, German translation. MIT license.
- Icon (golden alarm bell, PaTiSuite style): `Media/icon.tga` for the AddOns list, platform images in `assets/`.
- PaTiAuras now also reports watched group buffs that a living, online member lacks: one warning per buff
  ("Missing" solo, "Missing on N" in a group). No change in PaTiAlerts itself.
### Known Issues
- Owner-confirmed 2026-09-30: `/pal test`. The weapon imbue warning stays while Rockbiter is active — cause upstream
  in PaTiAuras (active imbue read as missing), no PaTiAlerts workaround. Details: `INGAME_TESTING.md`.
