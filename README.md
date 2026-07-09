# Klik

**Universal remote for real-world services.** Point your phone at a parking meter, hotel door, laundromat machine, or restaurant table — Klik recognizes it and shows the right action. A built-in Cursor AI agent learns your patterns and predicts what you'll need next.

## Requirements

- Xcode 15+
- iOS 17.0+
- Physical iPhone recommended (camera + location)

## Quick Start

1. Open `Klik.xcodeproj` in Xcode
2. Set your Development Team in Signing & Capabilities
3. Run on a device (Cmd+R)
4. Grant camera and location permissions

## Demo Services

| Service | Action |
|---------|--------|
| Parking Meter | Pay £2.50 for 2 hours |
| Hotel Door | Unlock door |
| Laundromat | Start wash cycle (40 min, £4) |
| Restaurant Table | Order cappuccino |

## Features

- Location detection with reverse geocoding
- Camera recognition (Vision framework)
- One-tap service actions
- Cursor AI pattern learning and predictions
- History screen showing learned habits

## Demo Flow

1. Home → location + scan button
2. Point camera → tap scan → service detected
3. Action screen → tap button + see AI suggestion
4. History → view learned patterns

Pre-loaded demo patterns: Tuesday 7pm laundromat, Thursday 9am parking, Friday 6pm hotel, Saturday 11am café.

## Project Structure

```
Klik/
├── KlikApp.swift
├── Models/
├── Services/
├── Views/
└── Components/
```

## Privacy

All data stored locally on device. No network calls required.
