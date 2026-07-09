import AVFoundation
import SwiftUI

struct CameraView: View {
    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.authorizationState {
            case .authorized:
                authorizedContent
            case .notDetermined:
                ProgressView("Requesting camera access…")
                    .tint(.white)
                    .foregroundStyle(.white)
            case .denied, .restricted:
                permissionDeniedView
            }
        }
        .task {
            await camera.checkAuthorization()
        }
        .onDisappear {
            camera.stopSession()
        }
    }

    @ViewBuilder
    private var authorizedContent: some View {
        if let errorMessage = camera.errorMessage {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.yellow)

                Text("Camera Unavailable")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(errorMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 32)
            }
        } else {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                Spacer()

                captureControls
                    .padding(.bottom, 36)
            }
        }
    }

    private var captureControls: some View {
        HStack {
            Spacer()

            Circle()
                .strokeBorder(.white, lineWidth: 4)
                .background(Circle().fill(.white.opacity(0.25)))
                .frame(width: 72, height: 72)
                .accessibilityLabel("Capture photo")

            Spacer()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white.opacity(0.9))

            Text("Camera Access Required")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Enable camera access in Settings to use klik.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 32)

            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: settingsURL)
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.white)
                    .foregroundStyle(.black)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    CameraView()
}
