import SwiftUI

struct DiceView: View {
    let value: Int
    var size: CGFloat = 40
    var isRolling: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var bounce: CGFloat = 1.0

    // Dot-Positionen für Werte 1-6 im 3x3 Grid
    private let dotPositions: [Int: [(Int, Int)]] = [
        1: [(1, 1)],
        2: [(0, 2), (2, 0)],
        3: [(0, 2), (1, 1), (2, 0)],
        4: [(0, 0), (0, 2), (2, 0), (2, 2)],
        5: [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
        6: [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)]
    ]

    private var dotSize: CGFloat {
        size * 0.18
    }

    private var diceBackground: Color {
        colorScheme == .dark
            ? Color(white: 0.2)
            : Color.white
    }

    private var dotColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color(white: 0.15)
    }

    var body: some View {
        ZStack {
            // Würfel-Hintergrund mit Glaseffekt
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(diceBackground)
                .shadow(
                    color: colorScheme == .dark
                        ? Color.black.opacity(0.5)
                        : Color.black.opacity(0.15),
                    radius: isRolling ? size * 0.2 : size * 0.1,
                    y: isRolling ? size * 0.1 : size * 0.05
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.1)
                                : Color.black.opacity(0.08),
                            lineWidth: 0.5
                        )
                )
                // Innerer Glanz
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.4),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )

            // Dots Grid
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { col in
                            Circle()
                                .fill(shouldShowDot(row: row, col: col) ? dotColor : Color.clear)
                                .shadow(
                                    color: shouldShowDot(row: row, col: col)
                                        ? dotColor.opacity(0.3)
                                        : Color.clear,
                                    radius: 1,
                                    y: 1
                                )
                                .frame(width: dotSize, height: dotSize)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .padding(size * 0.15)
            .opacity(isRolling ? 0.7 : 1.0)
        }
        .frame(width: size, height: size)
        .scaleEffect(bounce)
        .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0))
        .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
        .rotation3DEffect(.degrees(rotationZ), axis: (x: 0, y: 0, z: 1))
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                startRollingAnimation()
            } else {
                stopRollingAnimation()
            }
        }
        .onChange(of: value) { _, _ in
            // Kleiner Bounce wenn sich der Wert ändert
            if !isRolling {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    bounce = 1.1
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.1)) {
                    bounce = 1.0
                }
            }
        }
    }

    private func startRollingAnimation() {
        // Kontinuierliche Tumbling-Animation
        withAnimation(.linear(duration: 0.15).repeatForever(autoreverses: false)) {
            rotationX = 360
            rotationY = 360
        }
        withAnimation(.linear(duration: 0.2).repeatForever(autoreverses: false)) {
            rotationZ = 360
        }
        // Leichtes Hüpfen
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            bounce = 0.92
        }
    }

    private func stopRollingAnimation() {
        // Sanft zurück zur Ausgangsposition
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            rotationX = 0
            rotationY = 0
            rotationZ = 0
        }
        // Bounce-Landung
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            bounce = 1.15
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.15)) {
            bounce = 1.0
        }
    }

    private func shouldShowDot(row: Int, col: Int) -> Bool {
        guard let positions = dotPositions[value] else { return false }
        return positions.contains { $0.0 == row && $0.1 == col }
    }
}

#Preview {
    VStack(spacing: 24) {
        // Light Mode Preview
        HStack(spacing: 12) {
            ForEach(1...6, id: \.self) { value in
                DiceView(value: value, size: 50)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .environment(\.colorScheme, .light)

        // Dark Mode Preview
        HStack(spacing: 12) {
            ForEach(1...6, id: \.self) { value in
                DiceView(value: value, size: 50)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .environment(\.colorScheme, .dark)
    }
}
