import SwiftUI

struct ColumnView: View {
    let cells: [Int?]  // 3 Werte
    let score: Int
    let isPlayer: Bool
    let isClickable: Bool
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            // Score oben (nur für Gegner)
            if !isPlayer {
                scoreLabel
            }

            // 3 Slots
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { visualIndex in
                    let cellIndex = isPlayer ? visualIndex : (2 - visualIndex)
                    SlotView(value: cells[cellIndex], isClickable: isClickable)
                }
            }
            .padding(8)
            .background {
                // Glasiger Hintergrund
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(
                        color: isClickable
                            ? Color.green.opacity(0.3)
                            : Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1),
                        radius: isClickable ? 8 : 4,
                        y: 2
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isClickable
                            ? Color.green.opacity(0.8)
                            : Color.white.opacity(colorScheme == .dark ? 0.1 : 0.5),
                        lineWidth: isClickable ? 2 : 1
                    )
            )
            .scaleEffect(isClickable ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isClickable)
            .onTapGesture {
                if isClickable {
                    onTap()
                }
            }

            // Score unten (nur für Spieler)
            if isPlayer {
                scoreLabel
            }
        }
    }

    private var scoreLabel: some View {
        Text(score > 0 ? "\(score)" : " ")
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)
            .opacity(score > 0 ? 1 : 0)
            .frame(height: 22)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: score)
    }
}

struct SlotView: View {
    let value: Int?
    var isClickable: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Slot Hintergrund
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    colorScheme == .dark
                        ? Color.white.opacity(0.05)
                        : Color.black.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            colorScheme == .dark
                                ? Color.white.opacity(0.08)
                                : Color.black.opacity(0.06),
                            lineWidth: 1
                        )
                )
                .frame(width: 52, height: 52)

            if let value = value {
                DiceView(value: value, size: 44)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.3)
                            .combined(with: .opacity)
                            .combined(with: .offset(y: -20)),
                        removal: .scale(scale: 1.5)
                            .combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
    }
}

#Preview {
    HStack(spacing: 20) {
        ColumnView(
            cells: [3, 3, nil],
            score: 12,
            isPlayer: true,
            isClickable: true,
            onTap: {}
        )

        ColumnView(
            cells: [5, 2, 6],
            score: 13,
            isPlayer: false,
            isClickable: false,
            onTap: {}
        )
    }
    .padding(32)
    .background(Color(.systemBackground))
}
