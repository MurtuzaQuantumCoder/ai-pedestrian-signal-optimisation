# klik

A SwiftUI iOS app with a live camera view as the main screen.

## Requirements

- Xcode 15 or later
- iOS 16.0+
- A physical iPhone or iPad (the Simulator does not provide a real camera feed)

## Getting Started

1. Open `klik.xcodeproj` in Xcode.
2. Select your development team under **Signing & Capabilities** for the `klik` target.
3. Choose a physical device as the run destination.
4. Build and run (`Cmd+R`).

On first launch, the app requests camera permission. If access is denied, the app shows a prompt with a link to Settings.

## Project Structure

```
klik/
├── klik.xcodeproj
└── klik/
    ├── klikApp.swift          # App entry point
    ├── Views/
    │   └── CameraView.swift   # Main camera screen
    ├── Models/
    │   └── CameraModel.swift  # AVCaptureSession management
    ├── Components/
    │   └── CameraPreview.swift # UIViewRepresentable preview layer
    ├── Assets.xcassets
    └── Info.plist
```

## Features

- Full-screen live camera preview using `AVCaptureSession`
- Camera permission handling with a settings fallback
- Portrait-oriented UI with a capture button placeholder

## Bundle Identifier

`com.klik.app`
