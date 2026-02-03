import SwiftUI

struct ContentView: View {
    @State private var game = GameState()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Hintergrund mit Gradient
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Titel
                Text("Knucklebones")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                // Gegner-Bereich
                PlayerSection(
                    title: "Opponent",
                    score: game.opponentScore,
                    isOpponent: true
                ) {
                    GridView(
                        grid: game.opponentGrid,
                        isPlayer: false,
                        availableColumns: [],
                        onColumnTap: { _ in }
                    )
                }

                // Center Area: Roll Button / Dice
                CenterArea(game: game)
                    .padding(.vertical, 8)

                // Spieler-Bereich
                PlayerSection(
                    title: "You",
                    score: game.playerScore,
                    isOpponent: false
                ) {
                    GridView(
                        grid: game.playerGrid,
                        isPlayer: true,
                        availableColumns: game.isPlayerTurn && game.currentDice != nil
                            ? game.getAvailableColumns(for: true)
                            : [],
                        onColumnTap: { column in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                game.placeDice(column: column)
                            }
                        }
                    )
                }

                Spacer()

                // Footer mit Schwierigkeit und Regeln
                FooterSection(game: game, gameInProgress: gameInProgress)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .overlay {
            if game.gameOver, let winner = game.winner {
                GameOverOverlay(
                    winner: winner,
                    playerScore: game.playerScore,
                    opponentScore: game.opponentScore,
                    onPlayAgain: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            game.reset()
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.gameOver)
        .onChange(of: game.isPlayerTurn) { _, isPlayerTurn in
            if !isPlayerTurn && !game.gameOver {
                game.performAITurn()
            }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.08), Color(white: 0.12), Color(white: 0.08)]
                : [Color(white: 0.94), Color(white: 0.98), Color(white: 0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var gameInProgress: Bool {
        !game.playerGrid.allSatisfy { $0.allSatisfy { $0 == nil } } ||
        !game.opponentGrid.allSatisfy { $0.allSatisfy { $0 == nil } }
    }
}

// MARK: - Player Section

struct PlayerSection<Content: View>: View {
    let title: String
    let score: Int
    let isOpponent: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 10) {
            if isOpponent {
                scoreHeader
                content
            } else {
                content
                scoreHeader
            }
        }
    }

    private var scoreHeader: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text("\(score)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4), value: score)
        }
    }
}

// MARK: - Center Area

struct CenterArea: View {
    @Bindable var game: GameState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            // Turn Indicator
            turnIndicator
                .frame(width: 90, alignment: .leading)

            Spacer()

            // Dice oder Roll Button
            centerContent

            Spacer()

            // Symmetrie-Platzhalter
            Color.clear
                .frame(width: 90)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.4 : 0.1),
                    radius: 12,
                    y: 4
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                    lineWidth: 1
                )
        )
    }

    private var turnIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(game.isPlayerTurn ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: game.isPlayerTurn ? Color.green.opacity(0.5) : Color.orange.opacity(0.5), radius: 4)

            Text(game.isPlayerTurn ? "Your turn" : "Opponent")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        if let dice = game.displayDice {
            VStack(spacing: 6) {
                DiceView(value: dice, size: 56, isRolling: game.isRolling)
                    .shadow(
                        color: Color.black.opacity(0.2),
                        radius: 8,
                        y: 4
                    )

                if game.isPlayerTurn && !game.isRolling && game.currentDice != nil {
                    Text("Select column")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.spring(response: 0.3), value: game.currentDice != nil)
        } else if game.isPlayerTurn {
            Button(action: {
                game.rollDice()
            }) {
                Text("Roll")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 8, y: 4)
                    }
            }
            .disabled(game.isRolling)
            .scaleEffect(game.isRolling ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: game.isRolling)
        } else {
            // Platzhalter während Gegner-Zug
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 56, height: 56)
        }
    }
}

// MARK: - Footer Section

struct FooterSection: View {
    @Bindable var game: GameState
    let gameInProgress: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Schwierigkeits-Auswahl (nur wenn Spiel nicht läuft)
            if !gameInProgress {
                VStack(spacing: 8) {
                    Text("Difficulty")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Picker("Difficulty", selection: $game.difficulty) {
                        ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Regeln
            RulesFooter()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: gameInProgress)
    }
}

// MARK: - Game Over Overlay

struct GameOverOverlay: View {
    let winner: Winner
    let playerScore: Int
    let opponentScore: Int
    let onPlayAgain: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Content Card
            VStack(spacing: 20) {
                // Winner Icon
                Image(systemName: winnerIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(winnerColor)
                    .shadow(color: winnerColor.opacity(0.5), radius: 12)

                // Winner Text
                Text(winnerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Score
                HStack(spacing: 16) {
                    ScoreDisplay(label: "You", score: playerScore, isWinner: winner == .player)
                    Text("–")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    ScoreDisplay(label: "Opponent", score: opponentScore, isWinner: winner == .opponent)
                }

                // Play Again Button
                Button(action: onPlayAgain) {
                    Text("Play Again")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [winnerColor, winnerColor.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: winnerColor.opacity(0.4), radius: 8, y: 4)
                        }
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThickMaterial)
                    .shadow(
                        color: Color.black.opacity(0.3),
                        radius: 24,
                        y: 12
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 1)
            )
        }
    }

    private var winnerText: String {
        switch winner {
        case .player: "You Win!"
        case .opponent: "You Lose"
        case .tie: "It's a Tie!"
        }
    }

    private var winnerIcon: String {
        switch winner {
        case .player: "trophy.fill"
        case .opponent: "xmark.circle.fill"
        case .tie: "equal.circle.fill"
        }
    }

    private var winnerColor: Color {
        switch winner {
        case .player: .green
        case .opponent: .red
        case .tie: .orange
        }
    }
}

struct ScoreDisplay: View {
    let label: String
    let score: Int
    let isWinner: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(score)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(isWinner ? .primary : .secondary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Rules Footer

struct RulesFooter: View {
    var body: some View {
        Text("Place dice in columns. Matching dice multiply. Your dice remove opponent's matching dice.")
            .font(.system(size: 11, weight: .regular, design: .rounded))
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
