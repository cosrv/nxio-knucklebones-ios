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
}
