import SwiftUI

struct DiceView: View {
    let value: Int
    var size: CGFloat = 40
    var isRolling: Bool = false

    // Dot-Positionen für Werte 1-6 im 3x3 Grid
    // [row, col] wobei 0,0 = oben links
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

    var body: some View {
        ZStack {
            // Würfel-Hintergrund
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color(.separator), lineWidth: 1)
                )

            // Dots Grid
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(0..<3, id: \.self) { row in
                    GridRow {
                        ForEach(0..<3, id: \.self) { col in
                            Circle()
                                .fill(shouldShowDot(row: row, col: col) ? Color.primary : Color.clear)
                                .frame(width: dotSize, height: dotSize)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .padding(size * 0.15)
        }
        .frame(width: size, height: size)
        .rotationEffect(isRolling ? .degrees(Double(value * 30)) : .zero)
        .animation(isRolling ? nil : .easeOut(duration: 0.1), value: isRolling)
    }

    private func shouldShowDot(row: Int, col: Int) -> Bool {
        guard let positions = dotPositions[value] else { return false }
        return positions.contains { $0.0 == row && $0.1 == col }
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(1...6, id: \.self) { value in
            DiceView(value: value)
        }
    }
    .padding()
}
