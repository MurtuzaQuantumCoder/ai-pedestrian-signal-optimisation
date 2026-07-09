# CommandHub

**Universal remote for real-world services.** Point your phone at a parking meter, hotel door, laundromat machine, or restaurant table — CommandHub recognizes it and shows the right action. A built-in Cursor AI agent learns your patterns and predicts what you'll need next.

## Requirements

- Xcode 15+
- iOS 17.0+
- Physical iPhone recommended (camera + location)

## Quick Start

1. Open `CommandHub.xcodeproj` in Xcode
2. Set your Development Team in Signing & Capabilities
3. Run on a device (Cmd+R)
4. Grant camera and location permissions

## Demo Flow (10-minute hackathon script)

### 1. Home screen
- Shows current GPS location (reverse-geocoded)
- Big **Scan Service** camera button
- AI learning progress bar (pre-loaded with demo patterns)
- Optional prediction card if patterns match current time

### 2. Scan a service
- Tap **Scan Service** → point at a printed image or real object
- Tap the cyan scan button to capture + analyze
- Vision framework uses **text recognition** + **image classification**
- If recognition is uncertain, tap **Manual** to pick a service

### 3. Action + AI suggestion
- Shows detected service with confidence %
- **Cursor AI agent** compares against learned patterns:
  - *"You usually park here Thursdays, but it's Tuesday — unusual for you"*
  - *"You're at your usual laundromat on Tuesdays. Ready to go?"*
- Tap the action button to simulate completing the service

### 4. History
- Tap the brain icon → see learned patterns, confidence levels, and action log
- Pre-loaded demo data:
  - **Tuesday 7pm** → Laundromat
  - **Thursday 9am** → Parking meter
  - **Friday 6pm** → Hotel door
  - **Saturday 11am** → Restaurant table

## Demo Services

| Service | Action |
|---------|--------|
| Parking Meter | Pay £2.50 for 2 hours |
| Hotel Door | Unlock door |
| Laundromat Machine | Start wash cycle (40 min, £4) |
| Restaurant Table | Order cappuccino |

## Architecture

```
CommandHub/
├── CommandHubApp.swift
├── Models/
│   ├── ServiceType.swift      # 4 demo services + keywords
│   └── UserAction.swift       # Action log + pattern models
├── Services/
│   ├── LocationService.swift          # CLLocationManager
│   ├── CameraSessionProvider.swift    # AVFoundation capture
│   ├── CameraRecognitionService.swift # Vision text + classify
│   ├── ActionHistoryStore.swift       # Local persistence + demo seed
│   └── PatternLearningAgent.swift     # Cursor AI pattern engine
├── Views/
│   ├── HomeView.swift
│   ├── CameraScanView.swift
│   ├── ServiceActionView.swift
│   └── HistoryView.swift
└── Components/
    └── ConfidenceBadge.swift
```

## Recognition Tips

For reliable hackathon demos:
- Print photos of parking meters, hotel doors, washing machines, or café tables
- Ensure visible text (PARKING, MENU, WASH, HOTEL) improves text-based detection
- Use **Manual** picker as fallback — always works
- Use **Demo Services** grid on home screen to skip camera entirely

## AI Learning

The `PatternLearningAgent` analyzes:
- Day of week + hour of each action
- Service type frequency
- Anomaly detection (right service, wrong day/time)

Predictions unlock after **3 actions**. Confidence shown as percentage badges throughout the UI.

## Privacy

- All data stored locally in UserDefaults
- No network calls
- Camera and location used only on-device
