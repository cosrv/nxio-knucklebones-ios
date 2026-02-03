import SwiftUI

// MARK: - Animation Values

struct DiceAnimationValues {
    var offsetY: CGFloat = 0
    var scale: CGFloat = 1.0
    var rotationX: Double = 0
    var rotationY: Double = 0
    var rotationZ: Double = 0
    var shadowRadius: CGFloat = 1.0
}

// MARK: - DiceView

struct DiceView: View {
    let value: Int
    var size: CGFloat = 40
    var isRolling: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    // Animation trigger - startet bei 0, wird incrementiert für jede Animation
    @State private var animationCounter: Int = 0
    @State private var valuePulse: CGFloat = 1.0
    @State private var hasAppeared: Bool = false

    // Dot-Positionen für Werte 1-6 im 3x3 Grid
    private let dotPositions: [Int: [(Int, Int)]] = [
        1: [(1, 1)],
        2: [(0, 2), (2, 0)],
        3: [(0, 2), (1, 1), (2, 0)],
        4: [(0, 0), (0, 2), (2, 0), (2, 2)],
        5: [(0, 0), (0, 2), (1, 1), (2, 0), (2, 2)],
        6: [(0, 0), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)]
    ]

    private var dotSize: CGFloat { size * 0.18 }

    private var diceBackground: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.white
    }

    private var dotColor: Color {
        colorScheme == .dark ? Color.white : Color(white: 0.15)
    }

    var body: some View {
        KeyframeAnimator(
            initialValue: DiceAnimationValues(),
            trigger: animationCounter
        ) { values in
            diceContent
                .scaleEffect(isRolling ? values.scale : valuePulse)
                .offset(y: isRolling ? values.offsetY * size : 0)
                .rotation3DEffect(
                    .degrees(isRolling ? values.rotationX : 0),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.3
                )
                .rotation3DEffect(
                    .degrees(isRolling ? values.rotationY : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.3
                )
                .rotation3DEffect(
                    .degrees(isRolling ? values.rotationZ : 0),
                    axis: (x: 0, y: 0, z: 1)
                )
                .shadow(
                    color: shadowColor,
                    radius: size * 0.08 * (isRolling ? values.shadowRadius : 1.0),
                    y: size * 0.04 * (isRolling ? values.shadowRadius : 1.0)
                )
        } keyframes: { _ in
            // Dezentes Hüpfen - nicht zu hoch
            KeyframeTrack(\.offsetY) {
                CubicKeyframe(-0.18, duration: 0.08)
                CubicKeyframe(-0.12, duration: 0.20)
                CubicKeyframe(-0.15, duration: 0.20)
                CubicKeyframe(-0.10, duration: 0.20)
                CubicKeyframe(0.02, duration: 0.06)
                CubicKeyframe(-0.04, duration: 0.05)
                SpringKeyframe(0, duration: 0.14, spring: .snappy)
            }

            // Subtile Skalierung
            KeyframeTrack(\.scale) {
                CubicKeyframe(0.94, duration: 0.08)
                CubicKeyframe(0.97, duration: 0.60)
                CubicKeyframe(1.04, duration: 0.06)
                CubicKeyframe(0.98, duration: 0.05)
                SpringKeyframe(1.0, duration: 0.14, spring: .snappy)
            }

            // Vorwärts-Rotation (wie ein rollender Würfel)
            KeyframeTrack(\.rotationX) {
                LinearKeyframe(45, duration: 0.10)
                LinearKeyframe(135, duration: 0.15)
                LinearKeyframe(270, duration: 0.20)
                CubicKeyframe(340, duration: 0.18)
                SpringKeyframe(360, duration: 0.20, spring: .snappy)
            }

            // Seitwärts-Neigung
            KeyframeTrack(\.rotationY) {
                LinearKeyframe(30, duration: 0.12)
                LinearKeyframe(90, duration: 0.18)
                LinearKeyframe(150, duration: 0.20)
                CubicKeyframe(175, duration: 0.15)
                SpringKeyframe(180, duration: 0.18, spring: .snappy)
            }

            // Minimales Wackeln
            KeyframeTrack(\.rotationZ) {
                CubicKeyframe(4, duration: 0.15)
                CubicKeyframe(-3, duration: 0.20)
                CubicKeyframe(2, duration: 0.20)
                CubicKeyframe(-1, duration: 0.15)
                SpringKeyframe(0, duration: 0.13, spring: .snappy)
            }

            // Schatten folgt der Höhe
            KeyframeTrack(\.shadowRadius) {
                CubicKeyframe(1.4, duration: 0.08)
                CubicKeyframe(1.2, duration: 0.60)
                CubicKeyframe(0.7, duration: 0.06)
                CubicKeyframe(0.9, duration: 0.05)
                SpringKeyframe(1.0, duration: 0.14, spring: .snappy)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            // Wenn der View erscheint und bereits rolling ist, Animation starten
            if isRolling && !hasAppeared {
                hasAppeared = true
                animationCounter += 1
            }
        }
        .onChange(of: isRolling) { oldValue, newValue in
            if newValue && !oldValue {
                // Rolling startet - Animation triggern
                animationCounter += 1
            }
        }
        .onChange(of: value) { _, _ in
            if !isRolling {
                withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
                    valuePulse = 1.08
                }
                withAnimation(.spring(response: 0.15, dampingFraction: 0.6).delay(0.08)) {
                    valuePulse = 1.0
                }
            }
        }
    }

    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.5)
            : Color.black.opacity(0.2)
    }

    // MARK: - Dice Content

    private var diceContent: some View {
        ZStack {
            // Würfel-Hintergrund
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(diceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.15)
                                : Color.black.opacity(0.08),
                            lineWidth: 0.5
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.15 : 0.5),
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
            .opacity(isRolling ? 0.5 : 1.0)
        }
        .frame(width: size, height: size)
    }

    private func shouldShowDot(row: Int, col: Int) -> Bool {
        guard let positions = dotPositions[value] else { return false }
        return positions.contains { $0.0 == row && $0.1 == col }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewContainer: View {
        @State private var isRolling = false
        @State private var value = 4

        var body: some View {
            VStack(spacing: 32) {
                HStack(spacing: 12) {
                    ForEach(1...6, id: \.self) { v in
                        DiceView(value: v, size: 50)
                    }
                }

                VStack(spacing: 16) {
                    DiceView(value: value, size: 80, isRolling: isRolling)
                        .padding(.vertical, 20)

                    Button(isRolling ? "Rolling..." : "Roll Dice") {
                        isRolling = true
                        for i in 1...10 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                                value = Int.random(in: 1...6)
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.93) {
                            isRolling = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRolling)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }

    return PreviewContainer()
}
