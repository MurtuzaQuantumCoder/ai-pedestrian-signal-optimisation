# Klik — Hackathon Submission

**The universal remote for real life.** Point your phone at anything — the right action appears. One tap, done.

## Download & run (judges / reviewers)

**Full source code:**  
https://github.com/MurtuzaQuantumCoder/ai-pedestrian-signal-optimisation/tree/klik-ios-export

**Download ZIP (open in Xcode):**  
https://github.com/MurtuzaQuantumCoder/ai-pedestrian-signal-optimisation/releases/tag/klik-v1.0

### How to run
1. Download the release ZIP (or clone the branch above)
2. Unzip → open `Klik.xcodeproj` in **Xcode 15+**
3. Set your Development Team under Signing
4. Run on a physical **iPhone** (camera + location)
5. Grant camera and location permissions

## What it does

- **Camera recognition** — Vision framework detects parking meters, doors, machines, tables
- **Location** — shows where you are (CoreLocation)
- **4 demo services** — pay parking, unlock door, start wash, order coffee
- **AI learning** — learns your patterns and predicts next actions

## Demo services

| Service | Action |
|---------|--------|
| Parking Meter | Pay £2.50 for 2 hours |
| Hotel Door | Unlock door |
| Laundromat | Start wash cycle (40 min, £4) |
| Restaurant Table | Order cappuccino |

## Tech stack

SwiftUI · iOS 17 · AVFoundation · Vision · CoreLocation · Local persistence

## Demo script (10 min)

1. Open app → see location + **Scan Service**
2. Point at a service → tap scan → action appears
3. Tap action button → AI shows learned pattern suggestion
4. Tap **History** → see patterns AI learned (pre-loaded demo data included)

---

Built for hackathon submission · iOS SwiftUI MVP
