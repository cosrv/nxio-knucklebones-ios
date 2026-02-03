import SwiftUI

struct GridView: View {
    let grid: [[Int?]]  // 3 Spalten
    let isPlayer: Bool
    let availableColumns: [Int]
    let onColumnTap: (Int) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { colIndex in
                ColumnView(
                    cells: grid[colIndex],
                    score: Self.calculateColumnScore(grid[colIndex]),
                    isPlayer: isPlayer,
                    isClickable: availableColumns.contains(colIndex),
                    onTap: { onColumnTap(colIndex) }
                )
            }
        }
    }

    // Score-Berechnung: Gleiche Würfel multiplizieren sich
    static func calculateColumnScore(_ column: [Int?]) -> Int {
        let values = column.compactMap { $0 }
        var counts: [Int: Int] = [:]

        for value in values {
            counts[value, default: 0] += 1
        }

        var score = 0
        for value in values {
            score += value * counts[value]!
        }

        return score
    }
}

#Preview {
    VStack(spacing: 40) {
        // Gegner
        GridView(
            grid: [[5, nil, nil], [2, 2, nil], [1, 3, 6]],
            isPlayer: false,
            availableColumns: [],
            onColumnTap: { _ in }
        )

        // Spieler
        GridView(
            grid: [[3, 3, nil], [4, nil, nil], [6, 6, 6]],
            isPlayer: true,
            availableColumns: [0, 1],
            onColumnTap: { col in print("Tapped column \(col)") }
        )
    }
    .padding(24)
    .background(Color(.systemBackground))
}
