import SwiftUI
import UIKit
import Security

// MARK: - Enums

enum Winner {
    case player, opponent, tie
}

enum AIDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

enum GamePhase {
    case coinFlip      // Münzwurf um zu entscheiden wer beginnt
    case flipping      // Münzwurf-Animation läuft
    case playing       // Normales Spiel
    case gameOver      // Spiel beendet
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

    // Coin Flip
    var gamePhase: GamePhase = .coinFlip
    var coinFlipResult: Bool? = nil  // true = Spieler beginnt

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
        gamePhase = .coinFlip
        coinFlipResult = nil
    }

    // MARK: - Crypto Random

    /// Kryptographisch sicherer Zufallswert 1-6
    private func cryptoRandomDice() -> Int {
        var randomBytes = [UInt8](repeating: 0, count: 1)
        let result = SecRandomCopyBytes(kSecRandomDefault, 1, &randomBytes)

        if result == errSecSuccess {
            // Modulo-Bias vermeiden durch Rejection Sampling
            let maxUnbiased = UInt8(252) // 252 ist das größte Vielfache von 6 unter 256
            var value = randomBytes[0]

            while value >= maxUnbiased {
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &randomBytes)
                value = randomBytes[0]
            }

            return Int(value % 6) + 1
        }

        // Fallback auf Standard-Random
        return Int.random(in: 1...6)
    }

    /// Kryptographisch sicherer Coin-Flip
    private func cryptoRandomBool() -> Bool {
        var randomByte: UInt8 = 0
        let result = SecRandomCopyBytes(kSecRandomDefault, 1, &randomByte)

        if result == errSecSuccess {
            return randomByte % 2 == 0
        }

        return Bool.random()
    }

    // MARK: - Coin Flip

    func performCoinFlip() {
        guard gamePhase == .coinFlip else { return }

        gamePhase = .flipping

        // Haptic Feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Animation: Mehrere "Flips"
        let totalDuration: Double = 1.2
        let flips = 8

        for i in 0..<flips {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (totalDuration / Double(flips))) {
                self.coinFlipResult = Bool.random()
            }
        }

        // Finales Ergebnis
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            self.coinFlipResult = self.cryptoRandomBool()
            self.isPlayerTurn = self.coinFlipResult!

            // Haptic Feedback für Ergebnis
            let resultImpact = UINotificationFeedbackGenerator()
            resultImpact.notificationOccurred(self.coinFlipResult! ? .success : .warning)

            // Kurze Pause, dann Spiel starten
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.gamePhase = .playing

                // Wenn KI beginnt, automatisch starten
                if !self.isPlayerTurn {
                    self.performAITurn()
                }
            }
        }
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

    /// Würfelt einen neuen Würfel (1-6) mit kryptographischer Entropy
    func rollDice() {
        guard !isRolling && currentDice == nil && !gameOver && gamePhase == .playing else { return }

        // Haptic Feedback beim Start
        let startImpact = UIImpactFeedbackGenerator(style: .medium)
        startImpact.impactOccurred()

        isRolling = true

        // Kryptographisch sicherer Zufallswert für das Endergebnis
        let finalValue = cryptoRandomDice()

        // Roll-Animation: Schnell am Anfang, langsamer am Ende (Easing)
        let totalDuration: Double = 0.9
        let iterations = 14
        var delays: [Double] = []

        // Cubic Easing für natürlicheres Abbremsen
        for i in 0..<iterations {
            let progress = Double(i) / Double(iterations)
            let easedProgress = progress * progress * progress
            delays.append(easedProgress * totalDuration)
        }

        // Zufällige Werte während der Animation (auch crypto-random)
        for (index, delay) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if index == iterations - 1 {
                    self.displayDice = finalValue
                } else {
                    self.displayDice = self.cryptoRandomDice()
                }
            }
        }

        // Animation beenden
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.15) {
            self.currentDice = finalValue
            self.isRolling = false

            // Haptic Feedback beim Landen
            let landImpact = UIImpactFeedbackGenerator(style: .rigid)
            landImpact.impactOccurred()
        }
    }

    /// Platziert den aktuellen Würfel in einer Spalte (für Spieler)
    func placeDice(column: Int) {
        guard isPlayerTurn,
              let dice = currentDice,
              !gameOver,
              isColumnAvailable(column, for: true) else { return }

        // Haptic Feedback beim Platzieren
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

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

    /// KI würfelt mit kryptographischer Entropy
    private func rollAIDice() {
        guard !gameOver && gamePhase == .playing else { return }

        isRolling = true
        let finalValue = cryptoRandomDice()

        // Roll-Animation: Schnell am Anfang, langsamer am Ende
        let totalDuration: Double = 0.8
        let iterations = 12
        var delays: [Double] = []

        for i in 0..<iterations {
            let progress = Double(i) / Double(iterations)
            let easedProgress = progress * progress * progress
            delays.append(easedProgress * totalDuration)
        }

        for (index, delay) in delays.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if index == iterations - 1 {
                    self.displayDice = finalValue
                } else {
                    self.displayDice = self.cryptoRandomDice()
                }
            }
        }

        // Animation beenden und platzieren
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.15) {
            self.currentDice = finalValue
            self.isRolling = false

            // Verzögerung vor dem Platzieren
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
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
