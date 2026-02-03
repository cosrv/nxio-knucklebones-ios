# Knucklebones → SwiftUI Implementierung

Agent: **Claude Code**  
Ziel: Umsetzung des funktionierenden React-Prototyps als native iOS App

---

## Referenz-Datei

Die Datei `knucklebones-v4.jsx` enthält die vollständige Spiellogik und dient als Referenz.  
→ Bei Projektstart in Claude Code laden oder Inhalt in ersten Prompt kopieren.

---

## Phase 1: Projekt-Setup

```
Erstelle ein neues SwiftUI-Projekt "Knucklebones" mit folgenden Specs:

- iOS 17+ (für @Observable)
- Keine externen Dependencies
- Single-Target App
- Projektstruktur:
  Knucklebones/
  ├── KnucklebonesApp.swift
  ├── Models/
  │   └── GameState.swift
  └── Views/
      ├── ContentView.swift
      ├── DiceView.swift
      ├── ColumnView.swift
      └── GridView.swift
```

**Validierung:** Projekt kompiliert ohne Errors.

---

## Phase 2: Datenmodell

```
Erstelle das Datenmodell in Models/GameState.swift:

@Observable class GameState {
    // Spielfelder: 3 Spalten à 3 Slots, nil = leer
    var playerGrid: [[Int?]]    // Index 0 = erste platzierte Position (Mitte)
    var opponentGrid: [[Int?]]
    
    // Aktueller Zustand
    var currentDice: Int?       // Gewürfelter Wert, nil = noch nicht gewürfelt
    var isPlayerTurn: Bool
    var isRolling: Bool         // Für Roll-Animation
    var gameOver: Bool
    var winner: Winner?         // enum: .player, .opponent, .tie
    
    // Initialisierung
    init() { ... }
    
    // Reset
    func reset() { ... }
}

enum Winner {
    case player, opponent, tie
}
```

**Validierung:** `GameState()` lässt sich instanziieren.

---

## Phase 3: Spiellogik

```
Implementiere folgende Methoden auf GameState:

// 1. Würfeln mit echtem Zufall
func rollDice() {
    // Int.random(in: 1...6) nutzt bereits SecRandomCopyBytes intern
    // Animation: isRolling = true, nach Delay Wert setzen
}

// 2. Würfel platzieren
func placeDice(column: Int) {
    // Würfel in playerGrid[column] am ersten freien Index platzieren
    // Index 0 = Mitte (nächste zum Gegner)
    // Dann: removeMatchingDice() aufrufen
    // Dann: checkGameOver()
    // Dann: Zug wechseln
}

// 3. Spalten-Score berechnen
func calculateColumnScore(_ column: [Int?]) -> Int {
    // Gleiche Würfel multiplizieren sich:
    // [3, 3, nil] → 3×2 + 3×2 = 12
    // [3, 3, 3]   → 3×3 + 3×3 + 3×3 = 27
    // [2, 3, 4]   → 2 + 3 + 4 = 9
}

// 4. Gesamt-Score
func calculateTotalScore(for grid: [[Int?]]) -> Int {
    // Summe aller Spalten-Scores
}

// 5. Gegner-Würfel entfernen
func removeMatchingDice(column: Int, value: Int) {
    // Aus opponentGrid[column] alle Würfel mit 'value' entfernen
    // Array kompaktieren (nils ans Ende)
}

// 6. Spielende prüfen
func checkGameOver() {
    // Wenn playerGrid ODER opponentGrid voll → gameOver = true
    // Winner basierend auf Scores setzen
}

// 7. Spalte verfügbar?
func isColumnAvailable(_ column: Int, for player: Bool) -> Bool {
    // true wenn mindestens ein Slot nil ist
}

func getAvailableColumns(for player: Bool) -> [Int] {
    // Liste aller Spalten mit freien Slots
}
```

**Validierung:** 
- `calculateColumnScore([3, 3, nil])` returns `12`
- `calculateColumnScore([3, 3, 3])` returns `27`

---

## Phase 4: UI-Komponenten

### 4.1 DiceView

```
Erstelle Views/DiceView.swift:

struct DiceView: View {
    let value: Int
    var size: CGFloat = 40
    var isRolling: Bool = false
    
    // Dot-Positionen für Werte 1-6 (3x3 Grid)
    // Minimales Design:
    // - Weißer Hintergrund
    // - 1px hellgraue Border (#ccc)
    // - Border-Radius: 4pt
    // - Schwarze Dots (#333)
    
    // Optional: Bei isRolling leichte Rotation
}

#Preview {
    HStack {
        ForEach(1...6, id: \.self) { value in
            DiceView(value: value)
        }
    }
}
```

### 4.2 ColumnView

```
Erstelle Views/ColumnView.swift:

struct ColumnView: View {
    let cells: [Int?]           // 3 Werte
    let score: Int
    let isPlayer: Bool          // Bestimmt Reihenfolge
    let isClickable: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Score oben (nur für Gegner)
            if !isPlayer { ScoreLabel(score) }
            
            // 3 Slots
            // isPlayer: cells[0] oben (Mitte), cells[2] unten (Rand)
            // !isPlayer: cells[0] unten (Mitte), cells[2] oben (Rand)
            VStack(spacing: 4) {
                ForEach(0..<3) { visualIndex in
                    let cellIndex = isPlayer ? visualIndex : (2 - visualIndex)
                    SlotView(value: cells[cellIndex])
                }
            }
            .padding(6)
            .background(isClickable ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isClickable ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .onTapGesture { if isClickable { onTap() } }
            
            // Score unten (nur für Spieler)
            if isPlayer { ScoreLabel(score) }
        }
    }
}
```

### 4.3 GridView

```
Erstelle Views/GridView.swift:

struct GridView: View {
    let grid: [[Int?]]          // 3 Spalten
    let isPlayer: Bool
    let availableColumns: [Int]
    let onColumnTap: (Int) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { colIndex in
                ColumnView(
                    cells: grid[colIndex],
                    score: calculateColumnScore(grid[colIndex]),
                    isPlayer: isPlayer,
                    isClickable: availableColumns.contains(colIndex),
                    onTap: { onColumnTap(colIndex) }
                )
            }
        }
    }
}
```

### 4.4 GameView (Hauptscreen)

```
Erstelle Views/ContentView.swift:

struct ContentView: View {
    @State private var game = GameState()
    
    var body: some View {
        VStack(spacing: 16) {
            // Titel
            Text("Knucklebones")
                .font(.title2.weight(.semibold))
            
            // Gegner
            VStack(spacing: 8) {
                Text("Opponent: \(game.opponentScore)")
                    .foregroundStyle(.secondary)
                GridView(
                    grid: game.opponentGrid,
                    isPlayer: false,
                    availableColumns: [],
                    onColumnTap: { _ in }
                )
            }
            
            // Mitte: Würfel / Roll-Button
            CenterArea(game: game)
            
            // Spieler
            VStack(spacing: 8) {
                GridView(
                    grid: game.playerGrid,
                    isPlayer: true,
                    availableColumns: game.isPlayerTurn && game.currentDice != nil 
                        ? game.getAvailableColumns(for: true) 
                        : [],
                    onColumnTap: { col in game.placeDice(column: col) }
                )
                Text("You: \(game.playerScore)")
                    .foregroundStyle(.secondary)
            }
            
            // Regeln
            RulesFooter()
        }
        .padding()
    }
}

struct CenterArea: View {
    @Bindable var game: GameState
    
    var body: some View {
        // Wenn gameOver: Winner-Anzeige + Reset-Button
        // Wenn currentDice != nil: DiceView + "Select column"
        // Sonst: Roll-Button
    }
}
```

**Validierung:** App zeigt beide Grids, Würfel-Button funktioniert.

---

## Phase 5: KI-Gegner

```
Füge GameState eine AI-Methode hinzu:

func performAITurn() {
    guard !isPlayerTurn && !gameOver else { return }
    
    // 1. Kurzer Delay, dann würfeln
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.rollDice()
        
        // 2. Kurzer Delay, dann platzieren
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let column = self.chooseBestColumn()
            self.placeAIDice(column: column)
        }
    }
}

private func chooseBestColumn() -> Int {
    let available = getAvailableColumns(for: false)
    guard let dice = currentDice else { return available[0] }
    
    var bestCol = available[0]
    var bestScore = Int.min
    
    for col in available {
        var score = 0
        
        // Bonus für Stacking (gleiche Würfel in eigener Spalte)
        let existingCount = opponentGrid[col].compactMap { $0 }.filter { $0 == dice }.count
        score += existingCount * 10
        
        // Bonus für Zerstörung (gleiche Würfel beim Spieler)
        let destroyCount = playerGrid[col].compactMap { $0 }.filter { $0 == dice }.count
        score += destroyCount * dice * 5
        
        if score > bestScore {
            bestScore = score
            bestCol = col
        }
    }
    
    return bestCol
}
```

**Trigger in placeDice():**
```
// Am Ende von placeDice(), nach Zugwechsel:
if !isPlayerTurn && !gameOver {
    performAITurn()
}
```

**Validierung:** Gegner macht nach Spielerzug automatisch seinen Zug.

---

## Phase 6: Animationen

```
Füge Animationen hinzu:

// 1. Roll-Animation in rollDice()
func rollDice() {
    isRolling = true
    
    // Flackern durch zufällige Werte
    let iterations = Int.random(in: 8...12)
    for i in 0..<iterations {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
            self.currentDice = Int.random(in: 1...6)
        }
    }
    
    // Finaler Wert
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(iterations) * 0.05 + 0.1) {
        self.currentDice = Int.random(in: 1...6)
        self.isRolling = false
    }
}

// 2. In Views: withAnimation nutzen
.onChange(of: game.playerGrid) {
    withAnimation(.easeInOut(duration: 0.2)) {
        // View wird automatisch animiert
    }
}

// 3. Transition für Würfel in Slots
if let value = cell {
    DiceView(value: value)
        .transition(.scale.combined(with: .opacity))
}

// 4. Optional: Haptic Feedback
func rollDice() {
    let impact = UIImpactFeedbackGenerator(style: .medium)
    impact.impactOccurred()
    // ...
}
```

**Validierung:** Würfel flackert beim Rollen, Platzierung ist animiert.

---

## Phase 7: Game Over

```
Erstelle eine Overlay-View für Spielende:

struct GameOverOverlay: View {
    let winner: Winner
    let playerScore: Int
    let opponentScore: Int
    let onPlayAgain: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(winnerText)
                .font(.title.weight(.semibold))
            
            Text("\(playerScore) - \(opponentScore)")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Button("Play again") {
                onPlayAgain()
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    var winnerText: String {
        switch winner {
        case .player: "You win!"
        case .opponent: "Opponent wins!"
        case .tie: "Draw!"
        }
    }
}

// In ContentView:
.overlay {
    if game.gameOver, let winner = game.winner {
        GameOverOverlay(
            winner: winner,
            playerScore: game.playerScore,
            opponentScore: game.opponentScore,
            onPlayAgain: { game.reset() }
        )
    }
}
```

**Validierung:** Nach Spielende erscheint Overlay, Reset funktioniert.

---

## Checkliste

| Phase | Prüfung | ✓ |
|-------|---------|---|
| 1 | Projekt kompiliert | ☐ |
| 2 | GameState instanziierbar | ☐ |
| 3 | Score-Berechnung korrekt | ☐ |
| 4 | Grids werden gerendert | ☐ |
| 5 | Tap auf Spalte platziert Würfel | ☐ |
| 6 | KI macht automatisch Züge | ☐ |
| 7 | Roll-Animation sichtbar | ☐ |
| 8 | Game Over wird erkannt | ☐ |
| 9 | Reset funktioniert | ☐ |

---

## Tipps für Claude Code

1. **Iterativ arbeiten:** Nach jeder Phase testen, nicht alles auf einmal
2. **Fehler teilen:** Bei Compiler-Errors den vollständigen Error-Text an Claude geben
3. **Previews nutzen:** Für jede View einen `#Preview` Block anlegen lassen
4. **Referenz:** Die React-Datei `knucklebones-v4.jsx` als Kontext mitgeben

---

## Optionale Erweiterungen

- [ ] Sound-Effekte (Würfel-Roll, Platzierung, Zerstörung)
- [ ] Schwierigkeitsgrade für KI
- [ ] Lokaler Multiplayer (zwei Spieler, ein Gerät)
- [ ] Online Multiplayer (Game Center)
- [ ] Statistiken / Highscores
- [ ] Themes / Dark Mode
