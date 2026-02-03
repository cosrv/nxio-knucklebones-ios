# Knucklebones iOS

Native SwiftUI-Implementierung des Würfelspiels Knucklebones (bekannt aus "Cult of the Lamb").

## Status

🚧 **In Planung** - Design abgeschlossen, Implementierung startet

## Projektstruktur

```
nxio-knucklebones-ios/
├── README.md                      # Diese Datei
├── task_plan.md                   # Manus-Style Fortschritts-Tracking
├── notes.md                       # Recherche & technische Details
├── knucklebones-claude-code-plan.md  # Implementierungsplan (7 Phasen)
├── knucklebones-v4.jsx            # React-Prototyp (Referenz)
└── Knucklebones/                  # iOS App (wird erstellt)
    ├── KnucklebonesApp.swift
    ├── Models/
    │   └── GameState.swift
    └── Views/
        ├── ContentView.swift
        ├── DiceView.swift
        ├── ColumnView.swift
        └── GridView.swift
```

## Spielregeln

- 2 Spieler mit jeweils einem 3x3 Grid (3 Spalten à 3 Slots)
- Abwechselnd würfeln und Würfel in eine eigene Spalte platzieren
- **Multiplikator:** Gleiche Würfel in einer Spalte multiplizieren ihren Wert
  - Beispiel: Drei 3er = 3×3 + 3×3 + 3×3 = 27 Punkte
- **Zerstörung:** Platzierte Würfel entfernen gleiche Würfel in der gegnerischen Spalte
- Spiel endet wenn ein Grid voll ist, höchste Punktzahl gewinnt

## Features (V1)

- Light & Dark Mode Support
- Minimalistisches Würfel-Design
- KI-Gegner mit 3 Schwierigkeitsgraden (Easy/Medium/Hard)
- Haptic Feedback (Würfeln, Platzieren)
- Portrait-Modus optimiert für iPhone

## V2 Roadmap

- Lokaler 2-Spieler-Modus
- Online Multiplayer (Game Center)
- Statistiken & Highscores

## Tech Stack

- **iOS 17+** (für @Observable)
- **SwiftUI** (100% native)
- **iPhone-only**, Portrait
- **Keine externen Dependencies**

## Referenzen

- [React-Prototyp](./knucklebones-v4.jsx) - Funktionierende Spiellogik
- [Implementierungsplan](./knucklebones-claude-code-plan.md) - Detaillierte Phasen
