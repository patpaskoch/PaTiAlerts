# Changelog

Format: `## [Unreleased]` / `## [x.y.z] - YYYY-MM-DD` with Added, Changed, Fixed, Removed, Known Issues.

## [Unreleased] — 0.1.0
### Added
- Window "What needs my attention right now?": one line per open problem, sorted critical → warning → note, stable
  order within a priority; a short one-time highlight for new or escalated alerts; auto-hide when empty (locked only).
- Local API `PaTiAlertsAPI` version 1: `Sync(source, list)`, `Upsert(alert)`, `Remove(source, id)`,
  `ClearSource(source)`. Producer data is validated (secrecy first); invalid alerts are dropped without an error.
- Settings: sources (PaTiTank, PaTiAuras, PaTiHeal), priorities, highlight, auto-hide, language, scale, lock.
  `PaTiAlertsDB` saves settings only — alerts are never saved; producers report them again after `/reload`.
- Test mode with one alert of each priority; `/pal`, `/palerts` with show, hide, test, lock, unlock, reset, settings,
  debug, version. English texts, German translation. MIT license.
- Icon (golden alarm bell, PaTiSuite style): `Media/icon.tga` for the AddOns list, platform images in `assets/`.
### Known Issues
- Not tested in game yet.
