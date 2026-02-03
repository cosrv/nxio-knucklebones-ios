import SwiftUI

struct ContentView: View {
    @State private var game = GameState()

    var body: some View {
        VStack(spacing: 16) {
            // Titel
            Text("Knucklebones")
                .font(.title2.weight(.semibold))

            // Platzhalter für Gegner-Grid
            Text("Opponent: \(game.opponentScore)")
                .foregroundStyle(.secondary)

            Spacer()

            // Platzhalter für Center Area
            Text("Roll Button / Dice")
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()

            // Platzhalter für Spieler-Grid
            Text("You: \(game.playerScore)")
                .foregroundStyle(.secondary)

            // Schwierigkeits-Auswahl
            Picker("Difficulty", selection: $game.difficulty) {
                ForEach(AIDifficulty.allCases, id: \.self) { difficulty in
                    Text(difficulty.rawValue).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
