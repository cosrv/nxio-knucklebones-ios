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

struct CoinAnimationValues {
    var offsetY: CGFloat = 0
    var rotationX: Double = 0
    var rotationZ: Double = 0
    var scale: CGFloat = 1.0
    var shadowRadius: CGFloat = 12
    var shadowY: CGFloat = 8
}

struct CoinFlipOverlay: View {
    @Bindable var game: GameState
    @Environment(\.colorScheme) private var colorScheme

    @State private var flipTrigger: Int = 0
    @State private var showResult: Bool = false

    private let coinSize: CGFloat = 130

    var body: some View {
        ZStack {
            // Dimmed Background mit Blur
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Titel
                Text("Who goes first?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                // Münze mit KeyframeAnimator
                KeyframeAnimator(
                    initialValue: CoinAnimationValues(),
                    trigger: flipTrigger
                ) { values in
                    coinView
                        .offset(y: values.offsetY)
                        .rotation3DEffect(.degrees(values.rotationX), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
                        .rotation3DEffect(.degrees(values.rotationZ), axis: (x: 0, y: 0, z: 1))
                        .scaleEffect(values.scale)
                        .shadow(
                            color: Color.black.opacity(0.4),
                            radius: values.shadowRadius,
                            y: values.shadowY
                        )
                } keyframes: { _ in
                    // Dezentes Hochwerfen
                    KeyframeTrack(\.offsetY) {
                        CubicKeyframe(-25, duration: 0.12)
                        CubicKeyframe(-35, duration: 0.25)
                        CubicKeyframe(-30, duration: 0.30)
                        CubicKeyframe(-20, duration: 0.20)
                        CubicKeyframe(4, duration: 0.10)
                        CubicKeyframe(-6, duration: 0.08)
                        SpringKeyframe(0, duration: 0.15, spring: .snappy)
                    }

                    // 2 Umdrehungen (720°)
                    KeyframeTrack(\.rotationX) {
                        LinearKeyframe(90, duration: 0.12)
                        LinearKeyframe(270, duration: 0.25)
                        LinearKeyframe(450, duration: 0.30)
                        LinearKeyframe(630, duration: 0.20)
                        CubicKeyframe(700, duration: 0.10)
                        SpringKeyframe(720, duration: 0.23, spring: .snappy)
                    }

                    // Minimales Wackeln
                    KeyframeTrack(\.rotationZ) {
                        CubicKeyframe(3, duration: 0.20)
                        CubicKeyframe(-2, duration: 0.35)
                        CubicKeyframe(1, duration: 0.30)
                        SpringKeyframe(0, duration: 0.15, spring: .snappy)
                    }

                    // Subtile Skalierung
                    KeyframeTrack(\.scale) {
                        CubicKeyframe(0.92, duration: 0.10)
                        CubicKeyframe(1.02, duration: 0.55)
                        CubicKeyframe(1.04, duration: 0.10)
                        CubicKeyframe(0.97, duration: 0.08)
                        SpringKeyframe(1.0, duration: 0.17, spring: .bouncy)
                    }

                    // Schatten folgt der Höhe
                    KeyframeTrack(\.shadowRadius) {
                        CubicKeyframe(16, duration: 0.12)
                        CubicKeyframe(20, duration: 0.55)
                        CubicKeyframe(8, duration: 0.10)
                        CubicKeyframe(14, duration: 0.08)
                        SpringKeyframe(12, duration: 0.15, spring: .snappy)
                    }

                    KeyframeTrack(\.shadowY) {
                        CubicKeyframe(12, duration: 0.12)
                        CubicKeyframe(16, duration: 0.55)
                        CubicKeyframe(5, duration: 0.10)
                        CubicKeyframe(10, duration: 0.08)
                        SpringKeyframe(8, duration: 0.15, spring: .snappy)
                    }
                }
                .frame(height: coinSize + 60)

                // Status Text
                Group {
                    if game.gamePhase == .flipping && !showResult {
                        Text("Flipping...")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    } else if showResult, let result = game.coinFlipResult {
                        VStack(spacing: 8) {
                            Text(result ? "You start!" : "Opponent starts!")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(result ? .green : .orange)

                            Text(result ? "Good luck!" : "Watch and learn...")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    } else {
                        // Tap to Flip Button
                        Button {
                            flipTrigger += 1
                            game.performCoinFlip()

                            // Result nach Animation zeigen
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showResult = true
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 18))
                                Text("Tap to Flip")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 36)
                            .padding(.vertical, 16)
                            .background {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.95, green: 0.75, blue: 0.2), Color(red: 0.85, green: 0.55, blue: 0.1)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: Color.orange.opacity(0.5), radius: 12, y: 6)
                            }
                        }
                        .scaleEffect(game.gamePhase == .coinFlip ? 1.0 : 0.9)
                        .opacity(game.gamePhase == .coinFlip ? 1.0 : 0.5)
                        .disabled(game.gamePhase != .coinFlip)
                    }
                }
                .frame(height: 60)
                .animation(.spring(response: 0.3), value: showResult)
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 36)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThickMaterial)
                    .shadow(color: Color.black.opacity(0.4), radius: 30, y: 15)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    // MARK: - Coin View

    private var coinView: some View {
        ZStack {
            // Münzen-Basis (Gold-Metallic)
            Circle()
                .fill(
                    RadialGradient(
                        colors: resultColors,
                        center: .center,
                        startRadius: 0,
                        endRadius: coinSize / 2
                    )
                )
                .frame(width: coinSize, height: coinSize)
                .overlay(
                    // Äußerer Ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.6), Color.white.opacity(0.1), Color.white.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                )
                .overlay(
                    // Innerer Glanz
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.4), Color.clear],
                                center: UnitPoint(x: 0.3, y: 0.3),
                                startRadius: 0,
                                endRadius: coinSize / 2
                            )
                        )
                )
                .overlay(
                    // Geprägter Rand-Effekt
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.black.opacity(0.3), Color.clear, Color.white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .padding(6)
                )

            // Icon
            VStack(spacing: 4) {
                Image(systemName: coinIcon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, y: 2)

                if showResult {
                    Text(game.coinFlipResult == true ? "YOU" : "CPU")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.3), radius: 1, y: 1)
                }
            }
        }
    }

    private var resultColors: [Color] {
        if showResult, let result = game.coinFlipResult {
            return result
                ? [Color.green.opacity(0.9), Color.green, Color(red: 0.1, green: 0.5, blue: 0.2)]
                : [Color.orange.opacity(0.9), Color.orange, Color(red: 0.7, green: 0.3, blue: 0.1)]
        }
        // Gold-Metallic
        return [
            Color(red: 1.0, green: 0.85, blue: 0.4),
            Color(red: 0.95, green: 0.75, blue: 0.2),
            Color(red: 0.8, green: 0.55, blue: 0.1)
        ]
    }

    private var coinIcon: String {
        if showResult, let result = game.coinFlipResult {
            return result ? "person.fill" : "desktopcomputer"
        }
        return "questionmark"
    }
}

#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}
