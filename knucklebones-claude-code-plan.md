# Knucklebones → SwiftUI Implementierung

Agent: **Claude Code**
Ziel: Umsetzung des funktionierenden React-Prototyps als native iOS App

**Status: ✅ V1.1 ABGESCHLOSSEN**

---

## Implementierte Features

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
- ✅ **KeyframeAnimator** für konsistente Würfel-Animation
  - Dezentes Tumbling (360° X, 180° Y)
  - Sanftes Hüpfen mit Bounce-Landung
  - Dynamischer Schatten
- ✅ **KeyframeAnimator** für Coin-Flip
  - Gold-Metallic Design mit Glanz-Effekt
  - 2 Umdrehungen mit weicher Landung
  - Farbwechsel nach Ergebnis (Grün/Orange)
- ✅ Spring-Animationen für UI-Übergänge
- ✅ Haptic Feedback beim Würfeln und Platzieren

### Technische Details
- ✅ Kryptographische Entropie (SecRandomCopyBytes + Rejection Sampling)
- ✅ iOS 17+ mit @Observable und KeyframeAnimator
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
│       ├── DiceView.swift       # KeyframeAnimator Würfel
│       ├── ColumnView.swift     # Einzelne Spalte
│       └── GridView.swift       # 3-Spalten Grid
└── Resources/
    └── Assets.xcassets/
        ├── AppIcon.appiconset/  # 1024x1024 PNG ohne Alpha
        └── AccentColor.colorset/
```

---

## Gelöste Probleme

### App Icon nicht sichtbar
**Problem:** Icon wurde im Simulator nicht angezeigt
**Ursache:** `Resources/Assets.xcassets` war nicht als Build-Phase markiert
**Lösung:** In `project.yml` explizit `buildPhase: resources` setzen

### Inkonsistente Animationen
**Problem:** Würfel/Münze verhielten sich bei jedem Wurf anders
**Ursache:** `repeatForever` Animationen lassen sich nicht sauber stoppen
**Lösung:** `KeyframeAnimator` mit definierten Phasen und `onAppear`-Trigger

### Eskalierende Animationen
**Problem:** Würfel/Münze flogen über den Bildschirm
**Ursache:** Zu hohe Werte für Rotation (1080°+) und Offset (-120px)
**Lösung:** Dezentere Werte (360° Rotation, -35px Offset)

### Layout-Verschiebung beim Würfeln
**Problem:** UI verschob sich bei jedem Wurf
**Lösung:** Fixed-Height Container für CenterArea (`frame(height: 76)`)

---

## Animation-Referenz

### DiceView KeyframeAnimator
```swift
// Dezente Werte die gut funktionieren:
offsetY: -0.18 (relativ zur Größe)
rotationX: 360° (1 Umdrehung)
rotationY: 180° (halbe Umdrehung)
rotationZ: ±4° (minimales Wackeln)
scale: 0.94 - 1.04
```

### CoinFlip KeyframeAnimator
```swift
// Dezente Werte:
offsetY: -35px
rotationX: 720° (2 Umdrehungen)
rotationZ: ±3°
scale: 0.92 - 1.04
```

---

## Roadmap V2

- [ ] Lokaler Multiplayer (2 Spieler, 1 Gerät)
- [ ] Online Multiplayer (Game Center)
- [ ] Statistiken / Highscores
- [ ] Würfel-Skins (verschiedene Designs)
- [ ] Hintergrund-Themes

---

## Mögliche Erweiterungen (erforscht)

### SpriteKit (2D Physik)
- Aufwand: ~2-3 Stunden
- Würfel rollt physikalisch korrekt
- Shake-to-Roll möglich
- Einschränkung: Immer noch 2D

### SceneKit (Echtes 3D)
- Aufwand: ~4-6 Stunden
- Echter 3D-Würfel mit Physik
- 6 Texturen für Würfelseiten nötig
- Realistischstes Ergebnis

---

## Build & Run

```bash
cd Knucklebones
xcodegen generate
open Knucklebones.xcodeproj
```

Oder via CLI:
```bash
xcodebuild -scheme Knucklebones -destination 'platform=iOS Simulator,name=iPhone 17' build
xcrun simctl install "iPhone 17" ~/Library/Developer/Xcode/DerivedData/Knucklebones-*/Build/Products/Debug-iphonesimulator/Knucklebones.app
xcrun simctl launch "iPhone 17" com.nxio.Knucklebones
```
