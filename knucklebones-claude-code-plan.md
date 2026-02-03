# Knucklebones → SwiftUI Implementierung

Agent: **Claude Code**
Ziel: Umsetzung des funktionierenden React-Prototyps als native iOS App

**Status: ✅ V1 ABGESCHLOSSEN**

---

## Implementierte Features (V1)

### Core Features
- ✅ Vollständiges Spielfeld mit 3x3 Grid pro Spieler
- ✅ Würfel-Platzierung mit Entfernung gegnerischer Würfel
- ✅ Score-Berechnung mit Multiplikator für gleiche Würfel
- ✅ Game Over Erkennung und Winner-Overlay
- ✅ KI-Gegner mit wählbarer Schwierigkeit (Easy/Medium/Hard)

### UI/UX
- ✅ Dark Mode + Light Mode Support
- ✅ Minimalistisches Würfel-Design
- ✅ iPhone-only, Portrait-only
- ✅ Glassy Apple-Style mit `.ultraThinMaterial`
- ✅ Settings-Sheet über Zahnrad-Icon
- ✅ Clean Spielfeld ohne Header-Text

### Animationen & Feedback
- ✅ 3D-Würfel-Animation beim Rollen (Tumbling Effect)
- ✅ Spring-Animationen für UI-Übergänge
- ✅ Haptic Feedback beim Würfeln und Platzieren
- ✅ Coin-Flip Animation zu Spielbeginn

### Technische Details
- ✅ Kryptographische Entropie für Würfel (SecRandomCopyBytes + Rejection Sampling)
- ✅ iOS 17+ mit @Observable
- ✅ XcodeGen für Projekt-Generierung
- ✅ App Icon korrekt eingebunden (1024x1024 Single-Asset Format)

---

## Projektstruktur

```
Knucklebones/
├── project.yml              # XcodeGen Konfiguration
├── Sources/
│   ├── KnucklebonesApp.swift
│   ├── Models/
│   │   └── GameState.swift  # Spiellogik, KI, Crypto-Random
│   └── Views/
│       ├── ContentView.swift    # Hauptscreen + Settings + Overlays
│       ├── DiceView.swift       # 3D-animierter Würfel
│       ├── ColumnView.swift     # Einzelne Spalte
│       └── GridView.swift       # 3-Spalten Grid
└── Resources/
    └── Assets.xcassets/
        ├── AppIcon.appiconset/  # 1024x1024 PNG ohne Alpha
        └── AccentColor.colorset/
```

---

## Checkliste V1

| Phase | Prüfung | Status |
|-------|---------|--------|
| 1 | Projekt kompiliert | ✅ |
| 2 | GameState instanziierbar | ✅ |
| 3 | Score-Berechnung korrekt | ✅ |
| 4 | Grids werden gerendert | ✅ |
| 5 | Tap auf Spalte platziert Würfel | ✅ |
| 6 | KI macht automatisch Züge | ✅ |
| 7 | Roll-Animation sichtbar | ✅ |
| 8 | Game Over wird erkannt | ✅ |
| 9 | Reset funktioniert | ✅ |
| 10 | Dark/Light Mode | ✅ |
| 11 | Haptic Feedback | ✅ |
| 12 | Settings Sheet | ✅ |
| 13 | Coin-Flip zu Beginn | ✅ |
| 14 | Crypto-Random Würfel | ✅ |
| 15 | App Icon wird angezeigt | ✅ |

---

## Gelöste Probleme

### App Icon nicht sichtbar
**Problem:** Icon wurde im Simulator nicht angezeigt
**Ursache:** `Resources/Assets.xcassets` war nicht als Build-Phase im Xcode-Projekt markiert
**Lösung:** In `project.yml` explizit `buildPhase: resources` setzen:
```yaml
sources:
  - Sources
  - path: Resources
    buildPhase: resources
```

### Layout-Verschiebung beim Würfeln
**Problem:** UI verschob sich bei jedem Wurf
**Lösung:** Fixed-Height Container für CenterArea (`frame(height: 76)`)

### HierarchicalShapeStyle Compile-Error
**Problem:** `.foregroundStyle(.primary : .clear)` nicht erlaubt
**Lösung:** Stattdessen `.opacity()` verwenden

---

## Roadmap V2

- [ ] Lokaler Multiplayer (2 Spieler, 1 Gerät)
- [ ] Online Multiplayer (Game Center)
- [ ] Statistiken / Highscores

---

## Referenz-Datei

Die Datei `knucklebones-v4.jsx` enthält die ursprüngliche React-Implementierung als Referenz.

---

## Build & Run

```bash
# Projekt generieren
cd Knucklebones
xcodegen generate

# Im Simulator starten
xcodebuild -scheme Knucklebones -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install "iPhone 17" ~/Library/Developer/Xcode/DerivedData/Knucklebones-*/Build/Products/Debug-iphonesimulator/Knucklebones.app
xcrun simctl launch "iPhone 17" com.nxio.Knucklebones
```

Oder einfach in Xcode öffnen: `open Knucklebones.xcodeproj`
