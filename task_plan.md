# Task Plan: Knucklebones iOS App

## Goal
Umsetzung des funktionierenden React-Prototyps (`knucklebones-v4.jsx`) als native SwiftUI iOS-App mit AI-Gegner.

## Referenzen
- **React-Prototyp:** `knucklebones-v4.jsx` - Vollständige Spiellogik
- **Implementierungsplan:** `knucklebones-claude-code-plan.md` - 7 Phasen

---

## Phasen

### Phase 1: Projekt-Setup
- [ ] Xcode-Projekt erstellen (iOS 17+, SwiftUI)
- [ ] Projektstruktur anlegen (Models/, Views/)
- [ ] Validierung: Projekt kompiliert

### Phase 2: Datenmodell
- [ ] `GameState.swift` mit @Observable
- [ ] Grids, Dice-State, Turn-Management
- [ ] Validierung: GameState instanziierbar

### Phase 3: Spiellogik
- [ ] `rollDice()` - Würfeln mit Zufall
- [ ] `placeDice(column:)` - Würfel platzieren
- [ ] `calculateColumnScore()` - Score-Berechnung (Multiplikator-Regel)
- [ ] `removeMatchingDice()` - Gegner-Würfel entfernen
- [ ] `checkGameOver()` - Spielende prüfen
- [ ] Validierung: Score-Tests bestehen

### Phase 4: UI-Komponenten
- [ ] `DiceView.swift` - Würfel-Darstellung (Dots)
- [ ] `ColumnView.swift` - Spalte mit 3 Slots + Score
- [ ] `GridView.swift` - 3 Spalten
- [ ] `ContentView.swift` - Hauptscreen
- [ ] Validierung: Grids werden gerendert, Interaktion funktioniert

### Phase 5: KI-Gegner
- [ ] `performAITurn()` - Automatischer Zug
- [ ] `chooseBestColumn()` - Strategie (Stacking + Zerstörung)
- [ ] Validierung: KI macht automatisch Züge

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

## Offene Design-Fragen

### 1. Visual Design
- [ ] Farbschema: Hell (wie React-Prototyp) oder Dark Mode Support?
- [ ] Dice-Style: Minimalistisch (weiß + schwarze Dots) oder stilisiert?
- [ ] Grid-Hervorhebung: Grün für klickbar (wie Prototyp) oder andere Farbe?

### 2. Layout
- [ ] Portrait-only oder auch Landscape?
- [ ] iPad-Support oder nur iPhone?
- [ ] Safe Area Handling?

### 3. UX Details
- [ ] Haptic Feedback bei welchen Aktionen? (Roll, Place, Destroy, GameOver)
- [ ] Sound-Effekte gewünscht?
- [ ] Undo-Funktion?

### 4. KI-Verhalten
- [ ] Schwierigkeitsgrade (Easy/Medium/Hard)?
- [ ] KI-Verzögerung anpassbar?

### 5. Erweiterungen (später)
- [ ] Lokaler Multiplayer?
- [ ] Online Multiplayer (Game Center)?
- [ ] Statistiken/Highscores?

---

## Entscheidungen
(Werden nach Klärung hier dokumentiert)

---

## Fehler & Lösungen
(Werden während der Entwicklung dokumentiert)

---

## Status
**Aktuell: Planungsphase** - Warte auf Design-Entscheidungen
