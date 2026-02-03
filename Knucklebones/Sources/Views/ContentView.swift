import SwiftUI

struct ContentView: View {
    @State private var game = GameState()
    @State private var showSettings = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Hintergrund mit Gradient
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top Bar mit Settings
                HStack {
                    Spacer()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                    }
                }
                .padding(.horizontal, 4)

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
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
        .overlay {
            // Coin Flip Overlay
            if game.gamePhase == .coinFlip || game.gamePhase == .flipping {
                CoinFlipOverlay(game: game)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            // Game Over Overlay
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: game.gamePhase)
        .onChange(of: game.isPlayerTurn) { _, isPlayerTurn in
            if !isPlayerTurn && !game.gameOver && game.gamePhase == .playing {
                game.performAITurn()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(game: game, isPresented: $showSettings)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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
}

// MARK: - Settings Sheet

struct SettingsSheet: View {
    @Bindable var game: GameState
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            List {
                // Schwierigkeit
                Section {
                    ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                        Button {
                            if game.difficulty != difficulty {
                                game.difficulty = difficulty
                                withAnimation {
                                    game.reset()
                                }
                            }
                            isPresented = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(difficulty.rawValue)
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.primary)

                                    Text(difficultyDescription(difficulty))
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if game.difficulty == difficulty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Difficulty")
                } footer: {
                    Text("Changing difficulty will start a new game")
                        .font(.system(size: 12, design: .rounded))
                }

                // Spiel-Aktionen
                Section {
                    Button {
                        withAnimation {
                            game.reset()
                        }
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16))
                            Text("New Game")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.blue)
                    }

                    if gameInProgress {
                        Button(role: .destructive) {
                            withAnimation {
                                game.reset()
                            }
                            isPresented = false
                        } label: {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 16))
                                Text("Give Up")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                            }
                        }
                    }
                } header: {
                    Text("Game")
                }

                // Spielregeln
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        RuleRow(icon: "dice.fill", text: "Roll the dice and place it in a column")
                        RuleRow(icon: "plus.circle.fill", text: "Matching dice in a column multiply their value")
                        RuleRow(icon: "xmark.circle.fill", text: "Your dice remove opponent's matching dice in the same column")
                        RuleRow(icon: "flag.checkered", text: "Game ends when any grid is full")
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Rules")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private var gameInProgress: Bool {
        !game.playerGrid.allSatisfy { $0.allSatisfy { $0 == nil } } ||
        !game.opponentGrid.allSatisfy { $0.allSatisfy { $0 == nil } }
    }

    private func difficultyDescription(_ difficulty: AIDifficulty) -> String {
        switch difficulty {
        case .easy: "Random moves"
        case .medium: "Basic strategy"
        case .hard: "Advanced tactics"
        }
    }
}

struct RuleRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.primary)
        }
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
        ZStack {
            if let dice = game.displayDice {
                VStack(spacing: 4) {
                    DiceView(value: dice, size: 56, isRolling: game.isRolling)

                    Text("Select column")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.green)
                        .opacity(game.isPlayerTurn && !game.isRolling && game.currentDice != nil ? 1 : 0)
                }
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
            } else {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .frame(height: 76)
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
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: winnerIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(winnerColor)
                    .shadow(color: winnerColor.opacity(0.5), radius: 12)

                Text(winnerText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 16) {
                    ScoreDisplay(label: "You", score: playerScore, isWinner: winner == .player)
                    Text("–")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    ScoreDisplay(label: "Opponent", score: opponentScore, isWinner: winner == .opponent)
                }

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

// MARK: - Coin Flip Overlay

struct CoinFlipOverlay: View {
    @Bindable var game: GameState
    @Environment(\.colorScheme) private var colorScheme

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Who goes first?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Coin
                ZStack {
                    // Münze
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: coinColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 8)

                    // Icon auf der Münze
                    Image(systemName: coinIcon)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.white)
                }
                .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0))
                .scaleEffect(scale)

                // Status Text
                if game.gamePhase == .flipping {
                    Text("Flipping...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else if let result = game.coinFlipResult {
                    Text(result ? "You start!" : "Opponent starts!")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(result ? .green : .orange)
                } else {
                    // Tap to Flip Button
                    Button {
                        startFlipAnimation()
                        game.performCoinFlip()
                    } label: {
                        Text("Tap to Flip")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.purple.opacity(0.4), radius: 8, y: 4)
                            }
                    }
                }
            }
            .padding(40)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThickMaterial)
                    .shadow(color: Color.black.opacity(0.3), radius: 24, y: 12)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 1)
            )
        }
        .onChange(of: game.coinFlipResult) { _, result in
            if result != nil && game.gamePhase == .flipping {
                // Kurzer Bounce bei jedem Flip
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    scale = 1.1
                    rotation += 180
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.1)) {
                    scale = 1.0
                }
            }
        }
    }

    private var coinColors: [Color] {
        if let result = game.coinFlipResult, game.gamePhase != .flipping {
            return result
                ? [Color.green.opacity(0.8), Color.green]
                : [Color.orange.opacity(0.8), Color.orange]
        }
        return [Color.yellow.opacity(0.8), Color.yellow, Color.orange.opacity(0.8)]
    }

    private var coinIcon: String {
        if let result = game.coinFlipResult, game.gamePhase != .flipping {
            return result ? "person.fill" : "desktopcomputer"
        }
        return "questionmark"
    }

    private func startFlipAnimation() {
        // Kontinuierliche Rotation während des Flippens
        withAnimation(.linear(duration: 0.15).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            scale = 0.95
        }
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
