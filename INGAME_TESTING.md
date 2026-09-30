# Ingame Testing – PaTiAlerts

World of Warcraft: Forever
Interface: 16001

Diese Datei dokumentiert ausschließlich Tests im echten WoW-Client.

Automatisierte Tests, CI und Code Review zählen NICHT als Ingame-Verifikation.
Regeln und Eintragen von Ergebnissen: [PaTiAdmin/docs/TESTING.md](https://github.com/patpaskoch/PaTiAdmin/blob/main/docs/TESTING.md#in-game-test-files).

Die Meldungen der Producer (PaTiTank, PaTiAuras, PaTiHeal) werden in deren eigener INGAME_TESTING.md geführt
(Abschnitt „Integration“ unten verweist darauf) — ein Test hat genau eine Quelle.

## Legende

- [ ] offen / noch nicht bestätigt
- [x] vom Owner im echten Client bestätigt
- ❌ FAIL = im echten Client fehlgeschlagen
- 🔧 FIX IMPLEMENTED = Codefix vorhanden, Retest noch offen
- ✅ VERIFIED = erfolgreich im echten Client bestätigt
- MANUAL RETEST REQUIRED = erneuter Test notwendig

## Installation / Laden

- [ ] PT-ALERTS-001 Fresh Install aus dem Release-ZIP: genau ein Ordner `PaTiAlerts/`, Addon lädt allein
- [ ] PT-ALERTS-002 PaTiAlerts erscheint in der AddOn-Liste mit Beschreibung
- [ ] PT-ALERTS-003 Icon (Glocke) in der AddOn-Liste korrekt, keine weiße oder fehlende Textur
- [ ] PT-ALERTS-004 Login ohne Lua-Fehler
- [ ] PT-ALERTS-005 `/reload` ohne Lua-Fehler

## Fenster

- [ ] PT-ALERTS-010 `/pal` bzw. `/palerts` blendet das Fenster ein und aus; `/pal show`, `/pal hide`
- [x] PT-ALERTS-011 Test Mode `/pal test` zeigt Beispielmeldungen
  - ✅ VERIFIED 2026-09-30
- [ ] PT-ALERTS-012 Fenster am Header verschieben (entsperrt)
- [ ] PT-ALERTS-013 Position bleibt nach `/reload`
- [ ] PT-ALERTS-014 Lock/Unlock (••• und `/pal lock` / `unlock`): gesperrt nicht verschiebbar
- [ ] PT-ALERTS-015 Größe (Scale) wirkt
- [ ] PT-ALERTS-016 Collapse/Expand über •••, Zustand bleibt nach `/reload`
- [ ] PT-ALERTS-017 Einstellungen öffnen (`/pal settings` und •••) und speichern
- [ ] PT-ALERTS-018 Auto-Hide: gesperrt und leer → Fenster verschwindet; entsperrt oder im Test Mode bleibt es
- [ ] PT-ALERTS-019 Panel-Deckkraft 30–100 %: nur der Hintergrund ändert sich
- [ ] PT-ALERTS-020 Keine Einrast-Einstellung mehr, Fenster frei verschiebbar
- [ ] PT-ALERTS-021 `/pal reset` setzt die Position zurück

## Prioritäten

- [ ] PT-ALERTS-030 CRITICAL rot
- [ ] PT-ALERTS-031 WARNING gelb
- [ ] PT-ALERTS-032 INFO blau
- [ ] PT-ALERTS-033 Dringendste Meldung oben
- [ ] PT-ALERTS-034 Neue (oder schwerer gewordene) Meldung: kurzer einmaliger Pulse
- [ ] PT-ALERTS-035 Kein permanentes Blinken
- [ ] PT-ALERTS-036 Einstellung „kurz hervorheben“ aus → kein Pulse

## Filter

- [ ] PT-ALERTS-040 Quelle PaTiTank an/aus
- [ ] PT-ALERTS-041 Quelle PaTiAuras an/aus
- [ ] PT-ALERTS-042 Quelle PaTiHeal an/aus
- [ ] PT-ALERTS-043 Prioritäten kritisch / Warnungen / Hinweise einzeln an/aus
- [ ] PT-ALERTS-044 Abgeschaltete Quelle: das Producer-Addon selbst arbeitet unverändert weiter

## SavedVariables

- [ ] PT-ALERTS-050 Einstellungen bleiben nach `/reload`
- [ ] PT-ALERTS-051 Einstellungen bleiben nach Relog
- [ ] PT-ALERTS-052 „Standard wiederherstellen“ setzt die Einstellungen zurück

## Sprachen

- [ ] PT-ALERTS-060 deDE: alle Texte deutsch
- [ ] PT-ALERTS-061 Sprache enUS in den Einstellungen: nach `/reload` englisch
- [ ] PT-ALERTS-062 zhCN/zhTW/koKR: Englisch als Rückfall, keine Schlüsselnamen oder Kästchen
- [ ] PT-ALERTS-063 Keine abgeschnittenen wichtigen Texte (deDE), lange Gegnernamen

## Integration (Tests in den Producer-Dateien)

- PaTiTank: LOST, DANGER, gleiche Nummer, Alert verschwindet, ohne PaTiAlerts → PT-TANK-090 bis PT-TANK-094
- PaTiAuras: fehlender/auslaufender Selbst-Buff → PT-AURAS-064; Waffenbuff fehlt, ACTIVE entfernt, nie bei UNKNOWN →
  PT-AURAS-057 (❌ FAIL 2026-09-30: Warnung bleibt bei aktivem Felsbeißer, Ursache upstream in PaTiAuras);
  fehlende beobachtete Gruppenbuffs → PT-AURAS-112 bis PT-AURAS-116; Procs nie → PT-AURAS-072;
  ohne PaTiAlerts → PT-AURAS-110
- PaTiHeal: bannbarer Debuff, nach dem Bannen weg → PT-HEAL-094; ohne PaTiAlerts → PT-HEAL-100

## Combat / Sicherheit

- [ ] PT-ALERTS-080 Kein Lua-Fehler im Kampf, auch bei vielen Meldungen
- [ ] PT-ALERTS-081 Keine `ADDON_ACTION_BLOCKED` / `ADDON_ACTION_FORBIDDEN`
- [ ] PT-ALERTS-082 `taint.log` (`/console taintLog 1`) ohne PaTiAlerts-Eintrag

## Combined

- [ ] PT-ALERTS-090 Zusammen mit allen PaTi-Addons geladen: kein Lua-Fehler
- [ ] PT-ALERTS-091 Keine Slash-Command-Kollision: `/pal` und `/palerts` antworten nur PaTiAlerts
- [ ] PT-ALERTS-092 Eigene Einstellungen speichern nur PaTiAlerts-Werte; Fenster erscheint in PaTiSuite
