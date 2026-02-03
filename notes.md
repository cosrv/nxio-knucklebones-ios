# Notes: Knucklebones iOS Implementierung

## Spielregeln (aus React-Prototyp)

### Grundprinzip
- 2 Spieler, jeweils 3x3 Grid (3 Spalten à 3 Slots)
- Abwechselnd würfeln und in eigene Spalte platzieren
- Spiel endet wenn EIN Grid voll ist

### Score-Berechnung
- Einzelner Würfel: Augenzahl = Punkte
- **Multiplikator-Regel:** Gleiche Würfel in einer Spalte multiplizieren sich
  - `[3, 3, nil]` → 3×2 + 3×2 = **12** (nicht 6!)
  - `[3, 3, 3]` → 3×3 + 3×3 + 3×3 = **27**
  - `[2, 3, 4]` → 2 + 3 + 4 = **9**

### Zerstörungs-Mechanik
- Wenn Spieler einen Würfel platziert, werden **alle** gleichen Würfel in der **gleichen Spalte des Gegners** entfernt
- Beispiel: Spieler platziert 5 in Spalte 2 → Gegner verliert alle 5er in Spalte 2

---

## React-Implementierung - Key Details

### Datenstruktur
```javascript
playerGrid: [[Int?], [Int?], [Int?]]  // 3 Spalten
// Index 0 = erste platzierte Position (Mitte, zum Gegner hin)
// Index 2 = letzte Position (Rand, weg vom Gegner)
```

### Visual Mapping
- **Spieler-Grid:** Index 0 wird OBEN angezeigt (näher zum Gegner)
- **Gegner-Grid:** Index 0 wird UNTEN angezeigt (näher zum Spieler)
- Das heißt: `visualRow = isPlayer ? index : (2 - index)`

### Dice-Dots Layout (3x3 Grid)
```
Wert 1: [1,1] (Mitte)
Wert 2: [0,2], [2,0] (Diagonal)
Wert 3: [0,2], [1,1], [2,0] (Diagonal + Mitte)
Wert 4: [0,0], [0,2], [2,0], [2,2] (Ecken)
Wert 5: [0,0], [0,2], [1,1], [2,0], [2,2] (Ecken + Mitte)
Wert 6: [0,0], [0,2], [1,0], [1,2], [2,0], [2,2] (Links + Rechts)
```

### KI-Strategie
```
Für jede verfügbare Spalte:
  score = 0
  // Bonus für Stacking (gleiche Würfel in eigener Spalte)
  score += existingCount * 10
  // Bonus für Zerstörung (gleiche Würfel beim Spieler entfernen)
  score += destroyCount * diceValue * 5

Wähle Spalte mit höchstem Score
```

### Roll-Animation
- 10-15 zufällige "Flacker"-Werte
- Intervall: 50ms + ticks*8ms (wird langsamer)
- Finale Verzögerung: 400ms vor KI-Platzierung

---

## SwiftUI Mapping

### Technologien
- `@Observable` (iOS 17+) für GameState
- `Int.random(in: 1...6)` für Zufall (nutzt SecRandomCopyBytes)
- `withAnimation` für Transitions
- `UIImpactFeedbackGenerator` für Haptics
- `DispatchQueue.main.asyncAfter` für Delays

### Farben (aus Prototyp)
- Background: `#fafafa`
- Text: `#333`
- Secondary: `#666`
- Border: `#e0e0e0`, `#ccc`
- Clickable: `#e8f5e9` (background), `#4caf50` (border)
- Dice dots: `#333`
- Button: `#333` background, `#fff` text

---

## Offene Recherche
- [ ] iOS 17 @Observable Syntax verifizieren
- [ ] SwiftUI Grid vs LazyVGrid für Dice-Dots
- [ ] Beste Praxis für Timer/Animation in SwiftUI
