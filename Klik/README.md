# Klik

Klik is a SwiftUI iOS app with a full-screen camera as its main screen.

## Requirements

- Xcode 15 or later
- iOS 17.0+
- A physical iPhone or iPad with a camera (the Simulator does not provide a live camera feed)

## Getting Started

1. Open `Klik.xcodeproj` in Xcode.
2. Select the **Klik** scheme and your device or simulator.
3. Build and run with **Cmd+R**.

On first launch, the app requests camera permission. After granting access, the live camera preview fills the screen.

## Features

- Full-screen live camera preview
- Photo capture with shutter button
- Front/back camera switching
- Permission handling with a Settings shortcut when access is denied

## Project Structure

```
Klik/
├── KlikApp.swift           # App entry point
├── CameraView.swift        # Main camera screen
├── CameraService.swift     # AVFoundation session management
├── CameraPreviewView.swift # UIViewRepresentable preview layer
├── Info.plist              # Camera usage description
└── Assets.xcassets         # App icon and accent color
```

## Privacy

The app includes `NSCameraUsageDescription` in `Info.plist` explaining why camera access is required.
