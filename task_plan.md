# Task Plan: Knucklebones iOS App

## Goal
Umsetzung des funktionierenden React-Prototyps (`knucklebones-v4.jsx`) als native SwiftUI iOS-App mit AI-Gegner.

## Referenzen
- **React-Prototyp:** `knucklebones-v4.jsx` - Vollständige Spiellogik
- **Implementierungsplan:** `knucklebones-claude-code-plan.md` - 7 Phasen

---

## Phasen

### Phase 1: Projekt-Setup ✅
- [x] Xcode-Projekt erstellen (iOS 17+, SwiftUI)
- [x] Projektstruktur anlegen (Models/, Views/)
- [x] App-Icons integriert
- [x] Validierung: Projekt kompiliert

### Phase 2: Datenmodell ✅
- [x] `GameState.swift` mit @Observable
- [x] Grids, Dice-State, Turn-Management
- [x] `AIDifficulty` enum
- [x] Validierung: GameState instanziierbar

### Phase 3: Spiellogik (teilweise)
- [ ] `rollDice()` - Würfeln mit Zufall
- [ ] `placeDice(column:)` - Würfel platzieren
- [x] `calculateColumnScore()` - Score-Berechnung (Multiplikator-Regel)
- [ ] `removeMatchingDice()` - Gegner-Würfel entfernen
- [ ] `checkGameOver()` - Spielende prüfen
- [ ] Validierung: Score-Tests bestehen

### Phase 4: UI-Komponenten (Grundgerüst)
- [x] `DiceView.swift` - Würfel-Darstellung (Dots)
- [x] `ColumnView.swift` - Spalte mit 3 Slots + Score
- [x] `GridView.swift` - 3 Spalten
- [x] `ContentView.swift` - Hauptscreen (Platzhalter)
- [ ] Validierung: Grids werden gerendert, Interaktion funktioniert

### Phase 5: KI-Gegner
- [ ] `performAITurn()` - Automatischer Zug
- [ ] `chooseBestColumn()` - Strategie (Stacking + Zerstörung)
- [ ] `AIDifficulty` enum (Easy/Medium/Hard)
- [ ] Schwierigkeits-Auswahl im UI
- [ ] Validierung: KI macht automatisch Züge, Schwierigkeit beeinflusst Verhalten

### Phase 6: Animationen
- [ ] Roll-Animation (Flackern)
- [ ] Platzierungs-Animation (Scale + Opacity)
- [ ] Haptic Feedback
- [ ] Validierung: Animationen sichtbar

### Phase 7: Game Over
- [ ] `GameOverOverlay.swift`
- [ ] Winner-Anzeige + Reset
- [ ] Validierung: Overlay erscheint, Reset funktioniert

---

## Design-Entscheidungen (abgeschlossen)

### 1. Visual Design ✅
- [x] **Farbschema:** Light + Dark Mode Support
- [x] **Dice-Style:** Minimalistisch (weiß/schwarz + Dots)
- [x] **Grid-Hervorhebung:** Grün für klickbare Spalten (wie Prototyp)

### 2. Layout ✅
- [x] **Orientierung:** Portrait-only
- [x] **Geräte:** iPhone-only (kein iPad)
- [x] Safe Area: Standard iOS Handling

### 3. UX Details ✅
- [x] **Haptic Feedback:** Würfeln + Platzieren
- [x] **Sound-Effekte:** Keine
- [x] **Undo:** Nein

### 4. KI-Verhalten ✅
- [x] **Schwierigkeitsgrade:** Ja, wählbar (Easy/Medium/Hard)

### 5. V2 Roadmap (später)
- [ ] Lokaler 2-Spieler-Modus
- [ ] Online Multiplayer (Game Center)
- [ ] Statistiken/Highscores

---

## Entscheidungen

| Thema | Entscheidung | Begründung |
|-------|--------------|------------|
| Dark Mode | Ja | Systemstandard, bessere UX |
| Dice-Style | Minimalistisch | Konsistent mit Prototyp |
| Portrait-only | Ja | Einfacheres Layout |
| iPhone-only | Ja | Fokus auf Hauptplattform |
| Haptics | Roll + Place | Taktiles Feedback ohne Überladung |
| Sound | Nein | Minimalistisch halten |
| KI-Difficulty | Wählbar | Mehr Spielvariation |

---

## Fehler & Lösungen
(Werden während der Entwicklung dokumentiert)

---

## Status
**Aktuell: Phase 3/4** - Projekt-Setup und Grundgerüst fertig, Spiellogik und UI-Integration ausstehend
