import SwiftUI

struct ColumnView: View {
    let cells: [Int?]  // 3 Werte
    let score: Int
    let isPlayer: Bool
    let isClickable: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            // Score oben (nur für Gegner)
            if !isPlayer {
                scoreLabel
            }

            // 3 Slots
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { visualIndex in
                    let cellIndex = isPlayer ? visualIndex : (2 - visualIndex)
                    SlotView(value: cells[cellIndex])
                }
            }
            .padding(6)
            .background(isClickable ? Color.green.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isClickable ? Color.green : Color(.separator), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(height: 20)
    }
}

struct SlotView: View {
    let value: Int?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)

            if let value = value {
                DiceView(value: value, size: 40)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        ColumnView(
            cells: [3, 3, nil],
            score: 12,
            isPlayer: true,
            isClickable: true,
            onTap: {}
        )

        ColumnView(
            cells: [5, nil, nil],
            score: 5,
            isPlayer: false,
            isClickable: false,
            onTap: {}
        )
    }
    .padding()
}
