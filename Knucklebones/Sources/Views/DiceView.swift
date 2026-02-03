import SwiftUI

struct DiceView: View {
    let value: Int
    var size: CGFloat = 40
    var isRolling: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    // Animation States
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @State private var rotationZ: Double = 0
    @State private var offsetY: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 4
    @State private var shadowY: CGFloat = 2

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
                    radius: shadowRadius,
                    y: shadowY
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
            .opacity(isRolling ? 0.6 : 1.0)
        }
        .frame(width: size, height: size)
        .scaleEffect(scale)
        .offset(y: offsetY)
        .rotation3DEffect(.degrees(rotationX), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(rotationZ), axis: (x: 0, y: 0, z: 1))
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                startNaturalRoll()
            } else {
                landDice()
            }
        }
        .onChange(of: value) { _, _ in
            // Kleiner Pulse wenn sich der Wert ändert (während nicht rollend)
            if !isRolling {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    scale = 1.08
                }
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.08)) {
                    scale = 1.0
                }
            }
        }
    }

    // MARK: - Natural Roll Animation

    private func startNaturalRoll() {
        // Phase 1: Hochwerfen (0 - 0.15s)
        withAnimation(.easeOut(duration: 0.15)) {
            offsetY = -size * 0.6
            scale = 0.9
            shadowRadius = size * 0.3
            shadowY = size * 0.25
        }

        // Phase 2: Schnelle Rotation in der Luft (0.15s - 0.7s)
        withAnimation(.linear(duration: 0.12).repeatForever(autoreverses: false)) {
            rotationX = 360
        }
        withAnimation(.linear(duration: 0.15).repeatForever(autoreverses: false)) {
            rotationY = 360
        }
        withAnimation(.linear(duration: 0.25).repeatForever(autoreverses: false)) {
            rotationZ = 360
        }

        // Phase 3: Schwebend oben (während Werte wechseln)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.4)) {
                self.offsetY = -size * 0.4
            }
        }

        // Phase 4: Oszillation/Wobble während des Rollens
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) {
                    self.offsetY = -size * (0.35 + CGFloat(i % 2) * 0.1)
                }
            }
        }
    }

    private func landDice() {
        // Rotation stoppen und auf "saubere" Position bringen
        withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
            rotationX = 0
            rotationY = 0
            rotationZ = 0
        }

        // Phase 1: Runter kommen (Schwerkraft)
        withAnimation(.easeIn(duration: 0.12)) {
            offsetY = size * 0.05
            scale = 1.05
            shadowRadius = size * 0.05
            shadowY = size * 0.02
        }

        // Phase 2: Erster Bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.1)) {
                self.offsetY = -size * 0.15
                self.scale = 0.95
                self.shadowRadius = size * 0.12
                self.shadowY = size * 0.08
            }
        }

        // Phase 3: Zweiter (kleinerer) Aufprall
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeIn(duration: 0.08)) {
                self.offsetY = size * 0.02
                self.scale = 1.02
                self.shadowRadius = size * 0.04
                self.shadowY = size * 0.02
            }
        }

        // Phase 4: Mini-Bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.06)) {
                self.offsetY = -size * 0.04
                self.scale = 0.98
            }
        }

        // Phase 5: Settle (zur Ruhe kommen)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                self.offsetY = 0
                self.scale = 1.0
                self.shadowRadius = size * 0.1
                self.shadowY = size * 0.05
            }
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

        // Rolling Preview
        DiceView(value: 4, size: 60, isRolling: true)
            .padding()
    }
}
