# AGENTS.md — PaTiAlerts

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: show the open problems other PaTi addons report ("what needs my attention right now?"). Display only.
- Optional receiver: no addon depends on PaTiAlerts and PaTiAlerts reads no other addon. Producers call
  `PaTiAlertsAPI` only if it exists (AGENTS.md §3 exception). Keep the API small: `Sync`, `Upsert`, `Remove`, `ClearSource`.
- Files: `Logic.lua` (settings, migration, auto-hide rule; pure, tested) · `State.lua` (alert store: validation, upsert,
  sync, sort, filters; pure, tested) · `PaTiAlerts.lua` (window, API, settings, commands, events) · `Locales/` ·
  `Shared/` (PaTiShared, synced — never edit).
- SavedVariables: `PaTiAlertsDB` (per character), schema 1: point, relativePoint, x, y, locked, collapsed, scale,
  language, autoHide, pulseNew, sourceFilters { [source] = false }, priorityFilters { [priority] = false }.
  **Alerts are never saved.**
- Secure / combat-sensitive: none. Rows are not clickable; a row may only become clickable for a safe action.
- Secret values: `source`, `id`, `kind`, `priority`, `text`, `detail`, `number` must be readable — checked with
  `isSecret` first, else the alert (or field) is dropped. Only `name` may be secret and only reaches SetText.
- Performance: no polling. Rendering is coalesced to the next frame; the only OnUpdate besides that is the short
  highlight, which stops by itself.
- Slash commands: `/pal`, `/palerts`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `../../PaTiAdmin/docs/TESTING.md`.
