import SwiftUI

struct ContentView: View {
    @State private var game = GameState()

    var body: some View {
        VStack(spacing: 16) {
            // Titel
            Text("Knucklebones")
                .font(.title2.weight(.semibold))

            // Gegner-Bereich
            VStack(spacing: 8) {
                Text("Opponent: \(game.opponentScore)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                GridView(
                    grid: game.opponentGrid,
                    isPlayer: false,
                    availableColumns: [],
                    onColumnTap: { _ in }
                )
            }

            // Center Area: Roll Button / Dice
            CenterArea(game: game)

            // Spieler-Bereich
            VStack(spacing: 8) {
                GridView(
                    grid: game.playerGrid,
                    isPlayer: true,
                    availableColumns: game.isPlayerTurn && game.currentDice != nil
                        ? game.getAvailableColumns(for: true)
                        : [],
                    onColumnTap: { column in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            game.placeDice(column: column)
                        }
                    }
                )

                Text("You: \(game.playerScore)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Schwierigkeits-Auswahl (nur wenn Spiel nicht läuft)
            if !gameInProgress {
                VStack(spacing: 8) {
                    Text("Difficulty")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("Difficulty", selection: $game.difficulty) {
                        ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
            }

            // Regeln
            RulesFooter()
        }
        .padding()
        .overlay {
            if game.gameOver, let winner = game.winner {
                GameOverOverlay(
                    winner: winner,
                    playerScore: game.playerScore,
                    opponentScore: game.opponentScore,
                    onPlayAgain: {
                        withAnimation {
                            game.reset()
                        }
                    }
                )
            }
        }
    }

    /// Prüft ob das Spiel bereits begonnen hat
    private var gameInProgress: Bool {
        !game.playerGrid.allSatisfy { $0.allSatisfy { $0 == nil } } ||
        !game.opponentGrid.allSatisfy { $0.allSatisfy { $0 == nil } }
    }
}

// MARK: - Center Area

struct CenterArea: View {
    @Bindable var game: GameState

    var body: some View {
        HStack {
            // Turn Indicator
            Text(game.isPlayerTurn ? "Your turn" : "Opponent...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Spacer()

            // Dice oder Roll Button
            if let dice = game.displayDice {
                VStack(spacing: 4) {
                    DiceView(value: dice, size: 48, isRolling: game.isRolling)

                    if game.isPlayerTurn && !game.isRolling && game.currentDice != nil {
                        Text("Select column")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            } else if game.isPlayerTurn {
                Button(action: {
                    game.rollDice()
                }) {
                    Text("Roll")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(game.isRolling)
            } else {
                // Platzhalter während Gegner-Zug
                Rectangle()
                    .fill(.clear)
                    .frame(width: 48, height: 48)
            }

            Spacer()

            // Symmetrie-Platzhalter
            Color.clear
                .frame(width: 80)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    let winner: Winner
    let playerScore: Int
    let opponentScore: Int
    let onPlayAgain: () -> Void

    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Content
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
    }

    private var winnerText: String {
        switch winner {
        case .player: "You win!"
        case .opponent: "Opponent wins!"
        case .tie: "Draw!"
        }
    }
}

// MARK: - Rules Footer

struct RulesFooter: View {
    var body: some View {
        Text("Place dice in columns. Matching dice multiply. Your dice remove matching opponent dice in the same column.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
