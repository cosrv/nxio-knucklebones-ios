import SwiftUI

// MARK: - Enums

enum Winner {
    case player, opponent, tie
}

enum AIDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

// MARK: - GameState

@Observable
class GameState {
    // Spielfelder: 3 Spalten à 3 Slots, nil = leer
    // Index 0 = erste platzierte Position (Mitte, zum Gegner hin)
    var playerGrid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)
    var opponentGrid: [[Int?]] = Array(repeating: Array(repeating: nil, count: 3), count: 3)

    // Aktueller Zustand
    var currentDice: Int? = nil
    var displayDice: Int? = nil  // Für Roll-Animation
    var isPlayerTurn: Bool = true
    var isRolling: Bool = false
    var gameOver: Bool = false
    var winner: Winner? = nil

    // Einstellungen
    var difficulty: AIDifficulty = .medium

    // Computed Properties
    var playerScore: Int {
        calculateTotalScore(for: playerGrid)
    }

    var opponentScore: Int {
        calculateTotalScore(for: opponentGrid)
    }

    // MARK: - Initialisierung

    init() {
        reset()
    }

    // MARK: - Reset

    func reset() {
        playerGrid = Array(repeating: Array(repeating: nil, count: 3), count: 3)
        opponentGrid = Array(repeating: Array(repeating: nil, count: 3), count: 3)
        currentDice = nil
        displayDice = nil
        isPlayerTurn = true
        isRolling = false
        gameOver = false
        winner = nil
    }

    // MARK: - Score-Berechnung

    /// Berechnet den Score einer einzelnen Spalte
    /// Gleiche Würfel multiplizieren sich: [3,3,nil] = 3×2 + 3×2 = 12
    func calculateColumnScore(_ column: [Int?]) -> Int {
        let values = column.compactMap { $0 }
        var counts: [Int: Int] = [:]

        for value in values {
            counts[value, default: 0] += 1
        }

        var score = 0
        for value in values {
            score += value * counts[value]!
        }

        return score
    }

    /// Berechnet den Gesamtscore eines Grids
    func calculateTotalScore(for grid: [[Int?]]) -> Int {
        grid.reduce(0) { total, column in
            total + calculateColumnScore(column)
        }
    }

    // MARK: - Spiellogik

    /// Würfelt einen neuen Würfel (1-6)
    func rollDice() {
        guard !isRolling && currentDice == nil && !gameOver else { return }

        isRolling = true
        let finalValue = Int.random(in: 1...6)

        // Roll-Animation: Zufällige Werte anzeigen, dann finaler Wert
        let iterations = Int.random(in: 8...12)

        for i in 0..<iterations {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.displayDice = Int.random(in: 1...6)
            }
        }

        // Finaler Wert nach Animation
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(iterations) * 0.05 + 0.1) {
            self.displayDice = finalValue
            self.currentDice = finalValue
            self.isRolling = false
        }
    }

    /// Platziert den aktuellen Würfel in einer Spalte (für Spieler)
    func placeDice(column: Int) {
        guard isPlayerTurn,
              let dice = currentDice,
              !gameOver,
              isColumnAvailable(column, for: true) else { return }

        // Würfel platzieren
        placeInGrid(column: column, value: dice, isPlayer: true)

        // Gegner-Würfel entfernen
        removeMatchingDice(column: column, value: dice, fromPlayerGrid: false)

        // Würfel zurücksetzen
        currentDice = nil
        displayDice = nil

        // Spielende prüfen
        if checkGameOver() {
            return
        }

        // Zug wechseln
        isPlayerTurn = false
    }

    /// Platziert einen Würfel in einem Grid
    private func placeInGrid(column: Int, value: Int, isPlayer: Bool) {
        if isPlayer {
            if let emptyIndex = playerGrid[column].firstIndex(where: { $0 == nil }) {
                playerGrid[column][emptyIndex] = value
            }
        } else {
            if let emptyIndex = opponentGrid[column].firstIndex(where: { $0 == nil }) {
                opponentGrid[column][emptyIndex] = value
            }
        }
    }

    /// Entfernt alle Würfel mit dem gegebenen Wert aus der gegnerischen Spalte
    func removeMatchingDice(column: Int, value: Int, fromPlayerGrid: Bool) {
        if fromPlayerGrid {
            // Entferne aus Spieler-Grid
            let filtered = playerGrid[column].filter { $0 != value }
            playerGrid[column] = filtered + Array(repeating: nil, count: 3 - filtered.count)
        } else {
            // Entferne aus Gegner-Grid
            let filtered = opponentGrid[column].filter { $0 != value }
            opponentGrid[column] = filtered + Array(repeating: nil, count: 3 - filtered.count)
        }
    }

    /// Prüft ob das Spiel vorbei ist
    @discardableResult
    func checkGameOver() -> Bool {
        let playerFull = isGridFull(playerGrid)
        let opponentFull = isGridFull(opponentGrid)

        if playerFull || opponentFull {
            gameOver = true

            if playerScore > opponentScore {
                winner = .player
            } else if opponentScore > playerScore {
                winner = .opponent
            } else {
                winner = .tie
            }
            return true
        }
        return false
    }

    /// Prüft ob ein Grid komplett gefüllt ist
    func isGridFull(_ grid: [[Int?]]) -> Bool {
        grid.allSatisfy { column in
            column.allSatisfy { $0 != nil }
        }
    }

    /// Prüft ob eine Spalte noch Platz hat
    func isColumnAvailable(_ column: Int, for isPlayer: Bool) -> Bool {
        let grid = isPlayer ? playerGrid : opponentGrid
        return grid[column].contains(where: { $0 == nil })
    }

    /// Gibt alle verfügbaren Spalten zurück
    func getAvailableColumns(for isPlayer: Bool) -> [Int] {
        (0..<3).filter { isColumnAvailable($0, for: isPlayer) }
    }

    // MARK: - KI-Gegner

    /// Führt den KI-Zug aus
    func performAITurn() {
        guard !isPlayerTurn && !gameOver else { return }

        // Verzögerung vor dem Würfeln
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.rollAIDice()
        }
    }

    /// KI würfelt
    private func rollAIDice() {
        guard !gameOver else { return }

        isRolling = true
        let finalValue = Int.random(in: 1...6)

        // Roll-Animation
        let iterations = Int.random(in: 8...12)

        for i in 0..<iterations {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                self.displayDice = Int.random(in: 1...6)
            }
        }

        // Finaler Wert und Platzierung
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(iterations) * 0.05 + 0.1) {
            self.displayDice = finalValue
            self.currentDice = finalValue
            self.isRolling = false

            // Verzögerung vor dem Platzieren
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.placeAIDice(value: finalValue)
            }
        }
    }

    /// KI platziert den Würfel
    private func placeAIDice(value: Int) {
        guard !gameOver else { return }

        let column = chooseBestColumn(for: value)

        // Würfel platzieren
        placeInGrid(column: column, value: value, isPlayer: false)

        // Spieler-Würfel entfernen
        removeMatchingDice(column: column, value: value, fromPlayerGrid: true)

        // Würfel zurücksetzen
        currentDice = nil
        displayDice = nil

        // Spielende prüfen
        if checkGameOver() {
            return
        }

        // Zug wechseln
        isPlayerTurn = true
    }

    /// Wählt die beste Spalte basierend auf Schwierigkeitsgrad
    private func chooseBestColumn(for dice: Int) -> Int {
        let available = getAvailableColumns(for: false)
        guard !available.isEmpty else { return 0 }

        switch difficulty {
        case .easy:
            return chooseRandomColumn(available: available)
        case .medium:
            return chooseMediumColumn(available: available, dice: dice)
        case .hard:
            return chooseHardColumn(available: available, dice: dice)
        }
    }

    /// Easy: Zufällige Spalte
    private func chooseRandomColumn(available: [Int]) -> Int {
        available.randomElement() ?? 0
    }

    /// Medium: Basis-Strategie (Stacking + Zerstörung)
    private func chooseMediumColumn(available: [Int], dice: Int) -> Int {
        var bestCol = available[0]
        var bestScore = Int.min

        for col in available {
            var score = 0

            // Bonus für Stacking (gleiche Würfel in eigener Spalte)
            let existingCount = opponentGrid[col].compactMap { $0 }.filter { $0 == dice }.count
            score += existingCount * 10

            // Bonus für Zerstörung (gleiche Würfel beim Spieler entfernen)
            let destroyCount = playerGrid[col].compactMap { $0 }.filter { $0 == dice }.count
            score += destroyCount * dice * 5

            if score > bestScore {
                bestScore = score
                bestCol = col
            }
        }

        return bestCol
    }

    /// Hard: Erweiterte Strategie
    private func chooseHardColumn(available: [Int], dice: Int) -> Int {
        var bestCol = available[0]
        var bestScore = Int.min

        for col in available {
            var score = 0

            // Bonus für Stacking (noch stärker gewichtet)
            let existingCount = opponentGrid[col].compactMap { $0 }.filter { $0 == dice }.count
            score += existingCount * 15

            // Bonus für Zerstörung
            let destroyCount = playerGrid[col].compactMap { $0 }.filter { $0 == dice }.count
            let destroyValue = playerGrid[col].compactMap { $0 }.filter { $0 == dice }.reduce(0, +)
            score += destroyCount * destroyValue * 3

            // Bonus für hohe Stacks beim Spieler zerstören
            let playerStackSize = playerGrid[col].compactMap { $0 }.count
            if destroyCount > 0 && playerStackSize >= 2 {
                score += 20
            }

            // Bonus für Spalten die fast voll sind (Spiel schneller beenden wenn vorne)
            let ownFillLevel = opponentGrid[col].compactMap { $0 }.count
            if opponentScore > playerScore && ownFillLevel == 2 {
                score += 10
            }

            // Malus: Vermeide Spalten wo Spieler uns zerstören könnte
            let vulnerableCount = playerGrid[col].compactMap { $0 }.filter { $0 == dice }.count
            if vulnerableCount == 0 {
                // Spieler hat keine passenden Würfel, gut für uns
                score += 5
            }

            if score > bestScore {
                bestScore = score
                bestCol = col
            }
        }

        return bestCol
    }
}
