# AGENTS.md — PaTiAlerts

**Read the suite rules first: [`../../PaTiAdmin/AGENTS.md`](../../PaTiAdmin/AGENTS.md).** They apply here in full.
Addon facts: `../../PaTiAdmin/docs/ARCHITECTURE.md` · open issues: `../../PaTiAdmin/docs/FOLLOW_UPS.md`.

## This addon
- Purpose: show the open problems other PaTi addons report ("what needs my attention right now?"). Display only,
  except rows whose producer sends a `cast` (owner 2026-10-14: PaTiAuras buffs) — clickable out of combat.
- Optional receiver: no addon depends on PaTiAlerts and PaTiAlerts reads no other addon. Producers call
  `PaTiAlertsAPI` only if it exists (AGENTS.md §3 exception). Keep the API small: `Sync`, `Upsert`, `Remove`, `ClearSource`.
- Files: `Logic.lua` (settings, migration, auto-hide rule; pure, tested) · `State.lua` (alert store: validation, upsert,
  sync, sort, filters, cast validation; pure, tested) · `Clicks.lua` (secure click buttons over rows) ·
  `PaTiAlerts.lua` (window, API, settings, commands, events) · `Locales/` ·
  `Shared/` (PaTiShared, synced — never edit).
- SavedVariables: `PaTiAlertsDB` (per character), schema 1: point, relativePoint, x, y, locked, collapsed, scale,
  language, autoHide, pulseNew, sourceFilters { [source] = false }, priorityFilters { [priority] = false }.
  **Alerts are never saved.**
- Secure / combat-sensitive: `Clicks.lua` only. SecureActionButtons (type1 spell, spell1, unit) on a holder frame
  parented to UIParent — not children of the window, so the window stays movable and hideable in combat. The holder
  is hidden in combat by a state driver (`[combat] hide`); buttons are armed, moved and cleared only out of combat
  (cleared on PLAYER_REGEN_DISABLED and window drag, re-armed on PLAYER_REGEN_ENABLED and every render). Units:
  player, party1-4 only (State.CAST_UNITS). Never target, dispel or act without the click.
- Secret values: `source`, `id`, `kind`, `priority`, `text`, `detail`, `number` must be readable — checked with
  `isSecret` first, else the alert (or field) is dropped. Only `name` may be secret and only reaches SetText.
- Performance: no polling. Rendering is coalesced to the next frame; the only OnUpdate besides that is the short
  highlight, which stops by itself.
- Slash commands: `/pal`, `/palerts`.

## Checks
`bash ../../PaTiAdmin/tools/check.sh .` before every commit. Manual WoW tests: `../../PaTiAdmin/docs/TESTING.md`.
